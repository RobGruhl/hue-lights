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
import threading
import time
import socket
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

# Room-to-light-ID mapping (mirrors scripts/lib/rooms.sh)
ROOM_LIGHTS = {
    "dining": [
        "fa08b99f-aa8a-4683-af76-c0e3fd566217", "03e56936-b959-4687-b2de-5f2f670c8674",
        "d1a940ac-c385-4857-88dc-bb89ff5ddfc4", "ca82265e-1ee9-4337-a0d4-e44b46b21b1d",
        "457a3777-b619-4765-92a0-7292cbbaab7b",  # Dining Signes
        "ca9107e3-4f2c-4383-bf1a-67ae0765bbdf", "52e22f83-a8c0-4ede-9a5e-68801c8c69f7",
        "bd5ef4f9-7258-4ee8-af97-851b9713c147",  # Kitchen West
        "dd90028e-5494-4585-9a75-cb593d1275ec", "7fabbbed-4222-4bf4-baee-64977ebc5dde",
        "f95f8da4-3dd0-4f80-91a5-ca8ad1a7ff22",  # Kitchen East
    ],
    "dining-signes-only": [
        "fa08b99f-aa8a-4683-af76-c0e3fd566217", "03e56936-b959-4687-b2de-5f2f670c8674",
        "d1a940ac-c385-4857-88dc-bb89ff5ddfc4", "ca82265e-1ee9-4337-a0d4-e44b46b21b1d",
        "457a3777-b619-4765-92a0-7292cbbaab7b",
    ],
    "kitchen": [
        "ca9107e3-4f2c-4383-bf1a-67ae0765bbdf", "52e22f83-a8c0-4ede-9a5e-68801c8c69f7",
        "bd5ef4f9-7258-4ee8-af97-851b9713c147", "dd90028e-5494-4585-9a75-cb593d1275ec",
        "7fabbbed-4222-4bf4-baee-64977ebc5dde", "f95f8da4-3dd0-4f80-91a5-ca8ad1a7ff22",
    ],
    "jamies-office": [
        "7f91bd72-a9eb-4310-bf9a-461db7d8635c", "74d25075-110e-4db5-b0e0-f3e60addb10b",  # Signes
        "d220cd0b-219f-4eae-8ea1-4fd20fa06275", "e1e48801-86bd-4725-8098-c6249a8d8346",  # Plays
    ],
    "master-bedroom": [
        "dfcfd007-8106-435e-80d3-4dc09174b783", "6ae37491-1a2f-470f-8204-9c0b7d01da8f",
        "52b7c364-3a09-4ada-9b7d-f1d687e4a6bf", "a15aef77-0db6-4480-a0a5-2a5aa4d74dd4",  # Signes
        "91b5c5db-296b-4491-b220-1cfa5231a875", "b703f623-4cd0-4325-9d93-660c48fb0199",  # Twilight backs
        "5396d289-b7e1-4bdb-90f6-2b57e0ad7fc5", "0d806f9b-0416-47bb-8583-e5461fecb669",  # Twilight fronts
    ],
    "master-bath": ["e15184b3-d09a-4b0a-b8b1-fd8a16f69a0c"],
    "jordans-room": [
        "9c26b749-70db-4492-996e-c0dad1e41cd1", "a2a890cf-6d44-480d-887f-14c711ba4821",
        "c75776ff-d48f-4ec8-b8cc-5dd45e50e9d7",
    ],
    "kestons-room": [
        "2d2cc7f7-9987-44d6-be2c-86420050157c", "585292eb-f27d-432d-a82f-db450c8c9fb2",
        "d3bbd5c5-585c-48b1-a01d-4eb5a4d7f4c6",
    ],
    "tv-room": ["aacd4d39-f3fa-42d4-9ac4-0abf1647854d"],
    "balcony": ["7b12ed85-aebe-4c3e-9471-ad8598443ef3"],
}

# Composite rooms
ROOM_LIGHTS["whole-house"] = (
    ROOM_LIGHTS["dining"] + ROOM_LIGHTS["jamies-office"] +
    ROOM_LIGHTS["master-bedroom"] + ROOM_LIGHTS["master-bath"] +
    ROOM_LIGHTS["jordans-room"] + ROOM_LIGHTS["kestons-room"] +
    ROOM_LIGHTS["tv-room"] + ROOM_LIGHTS["balcony"]
)
ROOM_LIGHTS["adults-only"] = (
    ROOM_LIGHTS["dining"] + ROOM_LIGHTS["jamies-office"] +
    ROOM_LIGHTS["master-bedroom"] + ROOM_LIGHTS["master-bath"]
)
ROOM_LIGHTS["bedrooms"] = (
    ROOM_LIGHTS["master-bedroom"] + ROOM_LIGHTS["jordans-room"] +
    ROOM_LIGHTS["kestons-room"]
)

def get_light_ids_for_rooms(rooms):
    """Get all light IDs for a list of room names"""
    light_ids = set()
    for room in rooms:
        if room in ROOM_LIGHTS:
            light_ids.update(ROOM_LIGHTS[room])
    return light_ids

# Scene state - tracks running animation process
scene_state = {
    "running": False,
    "process": None,
    "pid": None,  # For recovery after restart
    "palette": None,
    "animation": None,
    "rooms": [],
    "light_ids": set(),  # Light UUIDs being animated
    "started_at": None,
    "last_command_time": 0,  # Timestamp of last command we sent
}

# EventStream monitor state
event_monitor = {
    "thread": None,
    "stop_event": threading.Event(),
    "connected": False,
}

def log(msg):
    """Timestamped logging"""
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    print(f"[{timestamp}] {msg}")

# =============================================================================
# EVENTSTREAM MONITOR - Detects external light changes
# =============================================================================

# Debounce window: ignore events within this time after our commands
DEBOUNCE_WINDOW_MS = 2000  # 2 seconds

def parse_sse_events(data):
    """Parse SSE data into individual events"""
    events = []
    for line in data.split('\n'):
        line = line.strip()
        if line.startswith('data:'):
            try:
                event_data = json.loads(line[5:].strip())
                if isinstance(event_data, list):
                    events.extend(event_data)
                else:
                    events.append(event_data)
            except json.JSONDecodeError:
                pass
    return events

def is_external_change(event_time_ms):
    """Check if change happened outside our debounce window"""
    last_cmd = scene_state.get("last_command_time", 0)
    return (event_time_ms - last_cmd) > DEBOUNCE_WINDOW_MS

def handle_light_event(event):
    """Process a light change event, trigger override if external"""
    global scene_state

    if not scene_state["running"]:
        return

    # Check if this is a light update event
    if event.get("type") != "update":
        return

    for item in event.get("data", []):
        # Check if it's a light resource
        if item.get("type") != "light":
            continue

        light_id = item.get("id")
        if not light_id:
            continue

        # Check if this light is in our active animation
        if light_id not in scene_state.get("light_ids", set()):
            continue

        # Check if light was turned off (strongest override signal)
        on_state = item.get("on", {})
        if on_state.get("on") is False:
            current_time_ms = int(time.time() * 1000)
            if is_external_change(current_time_ms):
                log(f"Override detected: Light {light_id[:8]}... turned OFF externally")
                trigger_override_shutdown()
                return

        # Check for color/brightness changes (now reliable since animations route through server)
        if "color" in item or "dimming" in item:
            current_time_ms = int(time.time() * 1000)
            if (current_time_ms - scene_state.get("last_command_time", 0)) > (DEBOUNCE_WINDOW_MS * 2):
                log(f"Override detected: Light {light_id[:8]}... changed externally")
                trigger_override_shutdown()
                return

def trigger_override_shutdown():
    """Stop the animation due to external override"""
    log("Stopping animation due to external override")
    stop_scene()

def event_stream_monitor():
    """Background thread that monitors Hue EventStream for external changes"""
    global event_monitor

    # Create SSL context (bridge uses self-signed cert)
    ctx = ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_NONE

    url = f"https://{HUE_BRIDGE}/eventstream/clip/v2"

    while not event_monitor["stop_event"].is_set():
        try:
            req = urllib.request.Request(url)
            req.add_header('hue-application-key', HUE_API_KEY)
            req.add_header('Accept', 'text/event-stream')

            log("EventStream: Connecting to bridge...")

            with urllib.request.urlopen(req, context=ctx, timeout=None) as response:
                event_monitor["connected"] = True
                log("EventStream: Connected, monitoring for overrides")

                buffer = ""
                while not event_monitor["stop_event"].is_set():
                    try:
                        chunk = response.read(4096).decode('utf-8')
                        if not chunk:
                            break

                        buffer += chunk

                        # Process complete events (separated by double newlines)
                        while '\n\n' in buffer:
                            event_data, buffer = buffer.split('\n\n', 1)
                            events = parse_sse_events(event_data)
                            for event in events:
                                handle_light_event(event)
                    except socket.timeout:
                        # Normal timeout, just continue
                        continue

        except Exception as e:
            event_monitor["connected"] = False
            if not event_monitor["stop_event"].is_set():
                log(f"EventStream: Connection error: {e}, reconnecting in 5s...")
                time.sleep(5)

    event_monitor["connected"] = False
    log("EventStream: Monitor stopped")

def start_event_monitor():
    """Start the EventStream monitor thread"""
    global event_monitor

    if event_monitor["thread"] and event_monitor["thread"].is_alive():
        return  # Already running

    event_monitor["stop_event"].clear()
    event_monitor["thread"] = threading.Thread(
        target=event_stream_monitor,
        name="EventStreamMonitor",
        daemon=True
    )
    event_monitor["thread"].start()

def stop_event_monitor():
    """Stop the EventStream monitor thread"""
    global event_monitor

    event_monitor["stop_event"].set()
    if event_monitor["thread"]:
        event_monitor["thread"].join(timeout=2)

# =============================================================================
# SCENE STATE MANAGEMENT
# =============================================================================

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
        "light_ids": list(scene_state.get("light_ids", set())),  # Convert set to list for JSON
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
                "light_ids": set(state.get("light_ids", [])),  # Restore as set
                "started_at": state["started_at"],
                "last_command_time": 0,
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
        "light_ids": set(),
        "started_at": None,
        "last_command_time": 0,
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
        # Get light IDs for the rooms being animated
        light_ids = get_light_ids_for_rooms(rooms)

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
            "light_ids": light_ids,
            "started_at": datetime.now().isoformat(),
            "last_command_time": int(time.time() * 1000),  # Track when we started
        }
        save_scene_state()  # Persist for recovery after restart
        log(f"Tracking {len(light_ids)} lights for override detection")
        return True, "Scene started"
    except Exception as e:
        return False, str(e)


class ThreadingHTTPServer(ThreadingMixIn, HTTPServer):
    """Threaded HTTP server for concurrent requests

    Overrides socket creation to fix macOS non-interactive SSH issue where
    the socket enters CLOSED state instead of LISTEN when started via SSH.
    """
    daemon_threads = True
    allow_reuse_address = True

    def __init__(self, server_address, RequestHandlerClass):
        """Create server with manually configured socket (fixes macOS SSH issue)"""
        # Create and configure socket manually before parent init
        # This fixes the CLOSED socket state issue on macOS with non-interactive SSH
        self.address_family = socket.AF_INET
        self.socket_type = socket.SOCK_STREAM

        # Create socket explicitly
        sock = socket.socket(self.address_family, self.socket_type)
        sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)

        # Bind and listen before HTTPServer.__init__ tries to
        sock.bind(server_address)
        sock.listen(128)

        # Now init parent with bind_and_activate=False since we already did it
        HTTPServer.__init__(self, server_address, RequestHandlerClass, bind_and_activate=False)

        # Replace the socket HTTPServer created with our pre-configured one
        self.socket = sock
        self.server_address = sock.getsockname()


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
                "scene_running": scene_state["running"],
                "event_stream_connected": event_monitor.get("connected", False),
                "lights_tracked": len(scene_state.get("light_ids", set())),
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
        global scene_state

        # Track light commands for override detection
        # This keeps the debounce window current when animations route through the server
        if method == 'PUT' and '/resource/light/' in self.path:
            scene_state["last_command_time"] = int(time.time() * 1000)

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
        msg = str(args[0]) if args else ''
        if '/api/' in msg or '/health' in msg:
            log(f"[API] {msg}")
        # Suppress static file logs


def main():
    os.chdir(os.path.dirname(os.path.abspath(__file__)))

    # Recover scene state from previous run
    load_scene_state()

    # Start EventStream monitor for override detection
    start_event_monitor()

    # Get local IP for display (socket already imported at top)
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
        stop_event_monitor()
        stop_scene()
        server.shutdown()

    signal.signal(signal.SIGTERM, shutdown_handler)

    try:
        server.serve_forever()
    except KeyboardInterrupt:
        log("Server stopped.")
        stop_event_monitor()
        stop_scene()

if __name__ == '__main__':
    main()
