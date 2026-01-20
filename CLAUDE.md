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

## Adding New Palettes

When adding a new color palette, update **two files**:

### 1. control-panel.html (JavaScript)
Add to the `PALETTES` object (~line 805):
```javascript
NEWPALETTE: {
    name: 'Display Name',
    colors: [[x1,y1],[x2,y2],...],  // 12 CIE xy coordinates
    brightness: [100,100,...],       // 12 brightness values (0-100)
    preview: 'linear-gradient(90deg, #hex1, #hex2, ...)'  // CSS for UI
}
```

### 2. scripts/lib/palettes.sh (Shell)
Add parallel arrays:
```bash
P_NEWPALETTE_X=(x1 x2 x3 x4 x5 x6 x7 x8 x9 x10 x11 x12)
P_NEWPALETTE_Y=(y1 y2 y3 y4 y5 y6 y7 y8 y9 y10 y11 y12)
P_NEWPALETTE_B=(b1 b2 b3 b4 b5 b6 b7 b8 b9 b10 b11 b12)
```
Also update `list_palettes()` function with the new entry.

### RGB to CIE xy Conversion
```python
def rgb_to_xy(r, g, b):
    r, g, b = r/255, g/255, b/255
    r = ((r + 0.055) / 1.055) ** 2.4 if r > 0.04045 else r / 12.92
    g = ((g + 0.055) / 1.055) ** 2.4 if g > 0.04045 else g / 12.92
    b = ((b + 0.055) / 1.055) ** 2.4 if b > 0.04045 else b / 12.92
    X = r * 0.4124564 + g * 0.3575761 + b * 0.1804375
    Y = r * 0.2126729 + g * 0.7151522 + b * 0.0721750
    Z = r * 0.0193339 + g * 0.1191920 + b * 0.9503041
    total = X + Y + Z
    return (round(X/total, 2), round(Y/total, 2)) if total else (0.33, 0.33)
```

## Adding New Animations

When adding a new animation, update **two files**:

### 1. control-panel.html (JavaScript)
Add to the `ANIMATIONS` object (~line 850):
```javascript
newanimation: { name: 'Display Name', icon: '🎨', speed: 1000, description: 'Short desc' }
```
Note: `speed` is in milliseconds.

### 2. scripts/lib/animations.sh (Shell)
Add the animation function:
```bash
NEWANIMATION_STEP_TIME=1.0    # Seconds per step
NEWANIMATION_TRANSITION=800   # Transition duration in ms

run_newanimation() {
    local lights=("$@")
    local phase=0
    while true; do
        # ... animation logic using set_gradient/set_solid
        sleep "$NEWANIMATION_STEP_TIME"
    done
}
```

Then update:
- `run_animation()` case statement to include new animation
- `list_animations()` function with description

## Syncing Changes
After editing on laptop (wintermute), sync to Mac Mini:
```bash
scp control-panel.html hue.local:~/Projects/hue-lights/
```
Shell scripts are edited directly on Mac Mini or synced similarly.
