# Hue Lights Project

## Overview
Python HTTP server providing a web control panel and REST API for Philips Hue smart lights.

## Quick Start

### Running Locally
```bash
python3.13 -u server.py
```
Server runs on port 8080. Access control panel at `http://localhost:8080/control-panel.html`

### Running on Mac Mini (headless server)
The server runs on `hue.local` (Mac Mini). Due to a known issue with launchd/detached processes, start interactively:
```bash
# From MacBook
ssh mini "cd ~/Projects/hue-lights && /opt/homebrew/bin/python3.13 -u server.py"
```

See `~/Projects/hello-mac-mini/MAC-MINI-SERVER.md` for full server documentation.

## Project Structure
```
server.py           - Main HTTP server with REST API
control-panel.html  - Web UI for controlling lights
start-server.sh     - Startup script for launchd
scripts/            - Scene scripts and animations
docs/               - API reference and documentation
.env                - Hue Bridge credentials (not in git)
logs/               - Server logs (not in git)
```

## Configuration
The `.env` file contains:
- `HUE_BRIDGE_IP` - IP address of Philips Hue Bridge
- `HUE_USERNAME` - API username for Hue Bridge

## API Endpoints
- `GET /health` - Health check
- `GET /api/lights` - List all lights
- `GET /api/clip/v2/resource/light` - Get light details (CLIP v2 format)
- `POST /api/scenes/start` - Start a scene
- `GET /api/scenes/status` - Get running scene status

See `docs/api-reference.md` for full API documentation.

## Known Issues

### Socket CLOSED with launchd
When started via launchd, screen, tmux, or nohup, the server's socket enters CLOSED state and won't accept connections. The Python process runs but the HTTP listener fails.

**Workaround**: Run from an interactive SSH session (keep terminal open).

## Documentation
- `docs/api-reference.md` - REST API documentation
- `docs/cli-commands.md` - Command line tools
- `docs/modular-scenes.md` - Scene system architecture
- `docs/light-inventory.md` - Light hardware details
- `docs/technical-learnings.md` - Development notes
