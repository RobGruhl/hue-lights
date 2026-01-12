#!/usr/bin/env python3
"""
Simple proxy server for Hue bridge API
Bypasses browser CORS restrictions by proxying requests through localhost
"""

from http.server import HTTPServer, SimpleHTTPRequestHandler
import urllib.request
import ssl
import json
import os
from pathlib import Path

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

if not HUE_API_KEY:
    print("Error: HUE_USER not set. Create a .env file with HUE_USER=your_api_key")
    exit(1)

class HueProxyHandler(SimpleHTTPRequestHandler):
    def do_OPTIONS(self):
        """Handle CORS preflight"""
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.end_headers()

    def do_GET(self):
        if self.path.startswith('/api/'):
            self.proxy_request('GET')
        else:
            # Serve static files
            super().do_GET()

    def do_PUT(self):
        if self.path.startswith('/api/'):
            self.proxy_request('PUT')

    def do_POST(self):
        if self.path.startswith('/api/'):
            self.proxy_request('POST')

    def proxy_request(self, method):
        """Proxy request to Hue bridge"""
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
            with urllib.request.urlopen(req, context=ctx) as response:
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
            self.send_response(500)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            self.wfile.write(json.dumps({'error': str(e)}).encode())

    def log_message(self, format, *args):
        """Custom logging"""
        if '/api/' in args[0]:
            print(f"[API] {args[0]}")
        # Suppress static file logs

def main():
    os.chdir(os.path.dirname(os.path.abspath(__file__)))

    server = HTTPServer(('localhost', PORT), HueProxyHandler)
    print(f"""
╔══════════════════════════════════════════════════════╗
║         Hue Control Panel Server                     ║
╠══════════════════════════════════════════════════════╣
║  Open in browser: http://localhost:{PORT}/control-panel.html
║  Bridge: {HUE_BRIDGE}
║  Press Ctrl+C to stop                                ║
╚══════════════════════════════════════════════════════╝
""")

    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nServer stopped.")

if __name__ == '__main__':
    main()
