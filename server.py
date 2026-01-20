#!/usr/bin/env python3
"""
Hue Control Panel Server

A threaded HTTP server that:
- Proxies requests to the Hue bridge (bypasses CORS)
- Manages scene animations via subprocess
- Provides health checks for monitoring
- Binds to 0.0.0.0 for LAN access
"""

from http.server import HTTPServer, SimpleHTTPRequestHandler
from socketserver import ThreadingMixIn
import urllib.request
import ssl
import json
import os
import signal
import subprocess
import uuid
from pathlib import Path
from datetime import datetime

# Load .env file
def load_env():
    env_path = Path(__file__).parent / ".env"
    if env_path.exists():
        with open(env_path) as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#') and '=' in line:
                    key, value = line.split('=', 1)
                    os.environ.setdefault(key.strip(), value.strip())

load_env()

# Configuration from environment
HUE_BRIDGE = os.environ.get("HUE_BRIDGE", "192.168.1.209")
HUE_API_KEY = os.environ.get("HUE_USER", "")
PORT = int(os.environ.get("PORT", "8080"))
SCRIPT_DIR = Path(__file__).parent / "scripts"
STATE_FILE = Path(__file__).parent / ".scene-state.json"
FEATURE_REQUESTS_FILE = Path(__file__).parent / ".feature-requests.json"

if not HUE_API_KEY:
    print("Error: HUE_USER not set. Create a .env file with HUE_USER=your_api_key")
    exit(1)

# Scene state - tracks running animation process
scene_state = {
    "running": False,
    "process": None,
    "pid": None,  # For recovery after restart
    "palette": None,
    "animation": None,
    "rooms": [],
    "started_at": None
}

def log(msg):
    """Timestamped logging"""
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    print(f"[{timestamp}] {msg}")

def save_scene_state():
    """Persist scene state to disk"""
    if not scene_state["running"]:
        # Remove state file when not running
        if STATE_FILE.exists():
            STATE_FILE.unlink()
        return

    # Save state with PID for recovery
    pid = scene_state["process"].pid if scene_state["process"] else None
    state = {
        "running": scene_state["running"],
        "pid": pid,
        "palette": scene_state["palette"],
        "animation": scene_state["animation"],
        "rooms": scene_state["rooms"],
        "started_at": scene_state["started_at"]
    }
    with open(STATE_FILE, 'w') as f:
        json.dump(state, f)
    log(f"Scene state saved (PID: {pid})")

def load_feature_requests():
    """Load feature requests from file"""
    if not FEATURE_REQUESTS_FILE.exists():
        return {"palette": [], "animation": []}
    try:
        with open(FEATURE_REQUESTS_FILE) as f:
            return json.load(f)
    except Exception:
        return {"palette": [], "animation": []}

def save_feature_requests(data):
    """Save feature requests to file"""
    with open(FEATURE_REQUESTS_FILE, 'w') as f:
        json.dump(data, f, indent=2)

def is_process_running(pid):
    """Check if a process is running and is our scene script"""
    try:
        # Check if process exists
        os.kill(pid, 0)
        # Verify it's our scene script using ps
        result = subprocess.run(
            ['ps', '-p', str(pid), '-o', 'command='],
            capture_output=True, text=True
        )
        return 'run-scene' in result.stdout
    except (OSError, ProcessLookupError):
        return False

def kill_process_tree(pid):
    """Kill a process and all its children"""
    try:
        # Get child PIDs using pgrep
        result = subprocess.run(
            ['pgrep', '-P', str(pid)],
            capture_output=True, text=True
        )
        child_pids = [int(p) for p in result.stdout.strip().split() if p]

        # Kill children first
        for child_pid in child_pids:
            try:
                os.kill(child_pid, signal.SIGTERM)
            except (OSError, ProcessLookupError):
                pass

        # Kill parent
        os.kill(pid, signal.SIGTERM)
        return True
    except (OSError, ProcessLookupError):
        return False

def load_scene_state():
    """Load and recover scene state from disk"""
    global scene_state

    if not STATE_FILE.exists():
        return

    try:
        with open(STATE_FILE) as f:
            state = json.load(f)

        pid = state.get("pid")
        if not pid:
            STATE_FILE.unlink()
            return

        # Check if process is still running and is our script
        if is_process_running(pid):
            log(f"Recovered running scene (PID: {pid})")
            scene_state = {
                "running": True,
                "process": None,  # Can't recover subprocess object, but we have PID
                "pid": pid,
                "palette": state["palette"],
                "animation": state["animation"],
                "rooms": state["rooms"],
                "started_at": state["started_at"]
            }
            return

        # Process not running or not our script - clean up
        log("Previous scene no longer running, cleaning up state")
        STATE_FILE.unlink()
    except Exception as e:
        log(f"Error loading scene state: {e}")
        if STATE_FILE.exists():
            STATE_FILE.unlink()

def stop_scene():
    """Stop any running scene animation"""
    global scene_state

    # Handle process object (normal case)
    if scene_state.get("process") and scene_state["process"].poll() is None:
        try:
            os.killpg(os.getpgid(scene_state["process"].pid), signal.SIGTERM)
        except ProcessLookupError:
            pass
        scene_state["process"].wait()

    # Handle recovered PID (after server restart)
    elif scene_state.get("pid"):
        if kill_process_tree(scene_state["pid"]):
            log(f"Stopped recovered scene (PID: {scene_state['pid']})")

    scene_state = {
        "running": False,
        "process": None,
        "pid": None,
        "palette": None,
        "animation": None,
        "rooms": [],
        "started_at": None
    }
    save_scene_state()  # Clear the state file

def start_scene(palette, animation, rooms, brightness=94):
    """Start a scene animation via run-scene.sh"""
    global scene_state

    # Stop any existing scene
    stop_scene()

    # Build command
    script = SCRIPT_DIR / "run-scene.sh"
    if not script.exists():
        return False, f"Script not found: {script}"

    cmd = [str(script), palette, animation, str(brightness)] + rooms
    log(f"Starting scene: {' '.join(cmd)}")

    try:
        # Start in new process group so we can kill all children
        process = subprocess.Popen(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            cwd=str(SCRIPT_DIR),
            preexec_fn=os.setsid
        )
        scene_state = {
            "running": True,
            "process": process,
            "pid": process.pid,
            "palette": palette,
            "animation": animation,
            "rooms": rooms,
            "started_at": datetime.now().isoformat()
        }
        save_scene_state()  # Persist for recovery after restart
        return True, "Scene started"
    except Exception as e:
        return False, str(e)


class ThreadingHTTPServer(ThreadingMixIn, HTTPServer):
    """Threaded HTTP server for concurrent requests"""
    daemon_threads = True


class HueProxyHandler(SimpleHTTPRequestHandler):
    # 10 second timeout for bridge requests
    timeout = 10

    def send_json(self, data, status=200):
        """Helper to send JSON response with CORS headers"""
        self.send_response(status)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.end_headers()
        self.wfile.write(json.dumps(data).encode())

    def do_OPTIONS(self):
        """Handle CORS preflight"""
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.end_headers()

    def do_GET(self):
        # Redirect root to control panel
        if self.path == '/' or self.path == '':
            self.send_response(302)
            self.send_header('Location', '/control-panel.html')
            self.end_headers()
            return

        # Health check endpoint
        if self.path == '/health':
            self.send_json({
                "status": "ok",
                "bridge": HUE_BRIDGE,
                "scene_running": scene_state["running"]
            })
            return

        # Scene status endpoint
        if self.path == '/api/scenes/status':
            # Check if process is still running
            if scene_state.get("process") and scene_state["process"].poll() is not None:
                stop_scene()  # Process ended, clean up state
            # Check recovered PID is still running
            elif scene_state.get("pid") and not scene_state.get("process"):
                if not is_process_running(scene_state["pid"]):
                    stop_scene()

            self.send_json({
                "running": scene_state["running"],
                "palette": scene_state["palette"],
                "animation": scene_state["animation"],
                "rooms": scene_state["rooms"],
                "started_at": scene_state["started_at"]
            })
            return

        # Feature requests endpoint
        if self.path == '/api/feature-requests':
            data = load_feature_requests()
            self.send_json(data)
            return

        # Proxy to Hue bridge
        if self.path.startswith('/api/'):
            self.proxy_request('GET')
        else:
            # Serve static files
            super().do_GET()

    def do_PUT(self):
        if self.path.startswith('/api/'):
            self.proxy_request('PUT')

    def do_POST(self):
        # Scene start endpoint
        if self.path == '/api/scenes/start':
            content_length = int(self.headers.get('Content-Length', 0))
            body = json.loads(self.rfile.read(content_length)) if content_length > 0 else {}

            palette = body.get('palette')
            animation = body.get('animation')
            rooms = body.get('rooms', [])
            brightness = body.get('brightness', 94)

            if not palette or not animation or not rooms:
                self.send_json({"error": "Missing palette, animation, or rooms"}, 400)
                return

            success, message = start_scene(palette, animation, rooms, brightness)
            if success:
                self.send_json({"status": "started", "message": message})
            else:
                self.send_json({"error": message}, 500)
            return

        # Scene stop endpoint
        if self.path == '/api/scenes/stop':
            stop_scene()
            self.send_json({"status": "stopped"})
            return

        # Create feature request
        if self.path == '/api/feature-requests':
            content_length = int(self.headers.get('Content-Length', 0))
            body = json.loads(self.rfile.read(content_length)) if content_length > 0 else {}

            req_type = body.get('type')  # 'palette' or 'animation'
            text = body.get('text', '').strip()[:2000]  # Max 2000 chars

            if req_type not in ['palette', 'animation'] or not text:
                self.send_json({"error": "Invalid request"}, 400)
                return

            data = load_feature_requests()
            new_request = {
                "id": str(uuid.uuid4()),
                "text": text,
                "votes": 0,
                "createdAt": datetime.now().isoformat()
            }
            data[req_type].append(new_request)
            save_feature_requests(data)

            log(f"New {req_type} feature request: {text[:50]}...")
            self.send_json({"status": "created", "id": new_request["id"]})
            return

        # Upvote feature request
        if self.path.startswith('/api/feature-requests/') and self.path.endswith('/upvote'):
            request_id = self.path.split('/')[-2]

            data = load_feature_requests()
            found = False
            for req_type in ['palette', 'animation']:
                for req in data[req_type]:
                    if req['id'] == request_id:
                        req['votes'] += 1
                        found = True
                        break
                if found:
                    break

            if found:
                save_feature_requests(data)
                self.send_json({"status": "upvoted"})
            else:
                self.send_json({"error": "Request not found"}, 404)
            return

        # Proxy to Hue bridge
        if self.path.startswith('/api/'):
            self.proxy_request('POST')

    def proxy_request(self, method):
        """Proxy request to Hue bridge with timeout"""
        # Remove /api prefix and build bridge URL
        bridge_path = self.path[4:]  # Remove '/api'
        url = f"https://{HUE_BRIDGE}{bridge_path}"

        # Read request body if present
        content_length = int(self.headers.get('Content-Length', 0))
        body = self.rfile.read(content_length) if content_length > 0 else None

        # Create request to bridge
        req = urllib.request.Request(url, data=body, method=method)
        req.add_header('hue-application-key', HUE_API_KEY)
        req.add_header('Content-Type', 'application/json')

        # Disable SSL verification (bridge uses self-signed cert)
        ctx = ssl.create_default_context()
        ctx.check_hostname = False
        ctx.verify_mode = ssl.CERT_NONE

        try:
            # 10 second timeout on bridge requests
            with urllib.request.urlopen(req, context=ctx, timeout=10) as response:
                data = response.read()

                self.send_response(200)
                self.send_header('Content-Type', 'application/json')
                self.send_header('Access-Control-Allow-Origin', '*')
                self.end_headers()
                self.wfile.write(data)
        except urllib.error.HTTPError as e:
            self.send_response(e.code)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            self.wfile.write(e.read())
        except Exception as e:
            log(f"Bridge error: {e}")
            self.send_json({"error": str(e)}, 500)

    def log_message(self, format, *args):
        """Custom logging with timestamps"""
        if '/api/' in args[0] or '/health' in args[0]:
            log(f"[API] {args[0]}")
        # Suppress static file logs


def main():
    os.chdir(os.path.dirname(os.path.abspath(__file__)))

    # Recover scene state from previous run
    load_scene_state()

    # Get local IP for display
    import socket
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        local_ip = s.getsockname()[0]
        s.close()
    except Exception:
        local_ip = "your-ip"

    # Bind to all interfaces for LAN access
    server = ThreadingHTTPServer(('0.0.0.0', PORT), HueProxyHandler)

    log("Server starting...")
    print(f"""
╔═══════════════════════════════════════════════════════════════╗
║              Hue Control Panel Server                         ║
╠═══════════════════════════════════════════════════════════════╣
║  Local:   http://localhost:{PORT}/control-panel.html            ║
║  Network: http://{local_ip}:{PORT}/control-panel.html
║  Health:  http://localhost:{PORT}/health                        ║
║  Bridge:  {HUE_BRIDGE}                                    ║
║  Press Ctrl+C to stop                                         ║
╚═══════════════════════════════════════════════════════════════╝
""")

    # Handle graceful shutdown
    def shutdown_handler(signum, frame):
        log("Shutting down...")
        stop_scene()
        server.shutdown()

    signal.signal(signal.SIGTERM, shutdown_handler)

    try:
        server.serve_forever()
    except KeyboardInterrupt:
        log("Server stopped.")
        stop_scene()

if __name__ == '__main__':
    main()
