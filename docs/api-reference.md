# Philips Hue API Reference

> The "first 80%" - everything you need to control lights, manage rooms/zones, and create automations. Links to deeper documentation at the end.

## Quick Reference

| Resource | v1 Endpoint | v2 Endpoint |
|----------|-------------|-------------|
| Lights | `/api/{user}/lights` | `/clip/v2/resource/light` |
| Groups | `/api/{user}/groups` | `/clip/v2/resource/room`, `/clip/v2/resource/zone` |
| Scenes | `/api/{user}/scenes` | `/clip/v2/resource/scene` |
| Schedules | `/api/{user}/schedules` | `/clip/v2/resource/smart_scene` |
| Config | `/api/{user}/config` | `/clip/v2/resource/bridge` |

**Base URL:** `https://{bridge-ip}` (v2) or `http://{bridge-ip}` (v1, deprecated)

---

## 1. Bridge Discovery

### Method 1: Cloud Discovery (Recommended)
```bash
curl https://discovery.meethue.com
```
Returns: `[{"id":"001788...","internalipaddress":"192.168.1.x","port":443}]`

### Method 2: mDNS
Look for `_hue._tcp.local` service on your network.

### Method 3: Router DHCP Table
Find device named "Philips-hue" in your router's connected devices.

---

## 2. Authentication

### First-Time Setup (Link Button Auth)

**Step 1:** Press the physical link button on the bridge.

**Step 2:** Within 30 seconds, POST to create a user:
```bash
curl -X POST "http://{bridge-ip}/api" \
  -H "Content-Type: application/json" \
  -d '{"devicetype":"claude_hue#macbook"}'
```

**Success Response:**
```json
[{"success":{"username":"aBcD1234...generatedKey..."}}]
```

**Error (button not pressed):**
```json
[{"error":{"type":101,"description":"link button not pressed"}}]
```

Save the username - this is your API key for all future requests.

### Verify Authentication
```bash
curl "http://{bridge-ip}/api/{username}/lights"
```

---

## 3. Light Control

### List All Lights
```bash
GET /api/{username}/lights
```

Response structure:
```json
{
  "1": {
    "state": {
      "on": true,
      "bri": 254,
      "hue": 10000,
      "sat": 254,
      "xy": [0.5, 0.5],
      "ct": 250,
      "alert": "none",
      "effect": "none",
      "colormode": "xy",
      "reachable": true
    },
    "type": "Extended color light",
    "name": "Living Room Lamp",
    "modelid": "LCT016",
    "uniqueid": "00:17:88:01:xx:xx:xx:xx-0b"
  }
}
```

### Get Single Light
```bash
GET /api/{username}/lights/{id}
```

### Set Light State
```bash
PUT /api/{username}/lights/{id}/state
Content-Type: application/json

{"on": true, "bri": 254, "hue": 10000, "sat": 254}
```

### Light State Attributes

| Attribute | Type | Range | Description |
|-----------|------|-------|-------------|
| `on` | bool | - | Power state |
| `bri` | int | 1-254 | Brightness (1=min, 254=max). Note: 0 is NOT off |
| `hue` | int | 0-65535 | Color hue (0=red, 21845=green, 43690=blue) |
| `sat` | int | 0-254 | Saturation (0=white, 254=full color) |
| `xy` | [float,float] | 0.0-1.0 | CIE color space coordinates |
| `ct` | int | 153-500 | Color temp in mireds (153=6500K cold, 500=2000K warm) |
| `alert` | string | "none","select","lselect" | Flash once / flash for 10s |
| `effect` | string | "none","colorloop" | Color cycling effect |
| `transitiontime` | int | 0-65535 | Transition in deciseconds (10 = 1 second) |

### Color Modes

Setting any color attribute automatically changes `colormode`:
- `"hs"` - Hue/Saturation mode (set `hue` and/or `sat`)
- `"xy"` - CIE color space (set `xy`)
- `"ct"` - Color temperature (set `ct`)

### Color Conversion Formulas

**RGB to Hue/Sat (approximate):**
```python
import colorsys
def rgb_to_hue_sat(r, g, b):
    h, s, v = colorsys.rgb_to_hsv(r/255, g/255, b/255)
    return int(h * 65535), int(s * 254)
```

**Kelvin to Mireds:**
```python
def kelvin_to_mired(kelvin):
    return int(1000000 / kelvin)
# 6500K = 154 mired (cool), 2700K = 370 mired (warm)
```

### Common Color Presets

| Color | Hue | Sat | Bri |
|-------|-----|-----|-----|
| Warm White | - | - | 254 | (use `ct: 370` instead) |
| Cool White | - | - | 254 | (use `ct: 154` instead) |
| Red | 0 | 254 | 254 |
| Orange | 5000 | 254 | 254 |
| Yellow | 12750 | 254 | 254 |
| Green | 25500 | 254 | 254 |
| Cyan | 36210 | 254 | 254 |
| Blue | 46920 | 254 | 254 |
| Purple | 50000 | 254 | 254 |
| Pink | 56100 | 254 | 254 |

---

## 4. Groups (Rooms & Zones)

Groups allow controlling multiple lights simultaneously with a single API call.

### List All Groups
```bash
GET /api/{username}/groups
```

Response:
```json
{
  "1": {
    "name": "Living Room",
    "lights": ["1", "2", "3"],
    "type": "Room",
    "class": "Living room",
    "action": {
      "on": true,
      "bri": 254,
      "hue": 10000,
      "sat": 254
    }
  }
}
```

### Group Types

| Type | Description |
|------|-------------|
| `LightGroup` | User-created group (any lights) |
| `Room` | Physical room (light can only be in ONE room) |
| `Zone` | Logical grouping (lights can be in multiple zones) |
| `Entertainment` | For Hue Entertainment/Sync |
| `Luminaire` | Hardware-defined (multi-light fixture) |

### Create a Group
```bash
POST /api/{username}/groups
Content-Type: application/json

{
  "name": "Reading Nook",
  "type": "Zone",
  "lights": ["1", "4"]
}
```

### Create a Room
```bash
POST /api/{username}/groups
Content-Type: application/json

{
  "name": "Bedroom",
  "type": "Room",
  "class": "Bedroom",
  "lights": ["5", "6", "7"]
}
```

### Room Classes (for Room type)
`Living room`, `Kitchen`, `Dining`, `Bedroom`, `Kids bedroom`, `Bathroom`, `Nursery`, `Recreation`, `Office`, `Gym`, `Hallway`, `Toilet`, `Front door`, `Garage`, `Terrace`, `Garden`, `Driveway`, `Carport`, `Home`, `Downstairs`, `Upstairs`, `Top floor`, `Attic`, `Guest room`, `Staircase`, `Lounge`, `Man cave`, `Computer`, `Studio`, `Music`, `TV`, `Reading`, `Closet`, `Storage`, `Laundry room`, `Balcony`, `Porch`, `Barbecue`, `Pool`, `Other`

### Control a Group
```bash
PUT /api/{username}/groups/{id}/action
Content-Type: application/json

{"on": true, "bri": 200, "hue": 10000}
```

### Special Group 0 (All Lights)
Group `0` always exists and contains all lights:
```bash
PUT /api/{username}/groups/0/action
{"on": false}  # Turn off everything
```

### Modify Group
```bash
PUT /api/{username}/groups/{id}
{"name": "New Name", "lights": ["1", "2", "5"]}
```

### Delete Group
```bash
DELETE /api/{username}/groups/{id}
```

---

## 5. Scenes

Scenes store light states that can be recalled instantly.

### List All Scenes
```bash
GET /api/{username}/scenes
```

Response:
```json
{
  "abc123": {
    "name": "Relax",
    "type": "GroupScene",
    "group": "1",
    "lights": ["1", "2"],
    "owner": "username",
    "recycle": false,
    "locked": false,
    "appdata": {},
    "picture": "",
    "lastupdated": "2024-01-15T20:00:00",
    "version": 2
  }
}
```

### Scene Types
- `LightScene` - Applies to specific lights only
- `GroupScene` - Associated with a group/room

### Create a Scene
```bash
POST /api/{username}/scenes
Content-Type: application/json

{
  "name": "Movie Night",
  "type": "GroupScene",
  "group": "1",
  "recycle": false
}
```

Then set light states within the scene:
```bash
PUT /api/{username}/scenes/{scene_id}/lightstates/{light_id}
{"on": true, "bri": 50, "hue": 8000}
```

### Recall (Activate) a Scene

**v1 Method - via Group:**
```bash
PUT /api/{username}/groups/{group_id}/action
{"scene": "abc123"}
```

**v2 Method - Direct:**
```bash
PUT /clip/v2/resource/scene/{scene_id}
{"recall": {"action": "active"}}
```

### Modify Scene Name
```bash
PUT /api/{username}/scenes/{id}
{"name": "New Scene Name"}
```

### Delete Scene
```bash
DELETE /api/{username}/scenes/{id}
```

---

## 6. Schedules & Automations

### List Schedules
```bash
GET /api/{username}/schedules
```

### Create a Schedule

**One-time schedule:**
```bash
POST /api/{username}/schedules
{
  "name": "Wake up lights",
  "description": "Turn on bedroom at 7am",
  "command": {
    "address": "/api/{username}/groups/2/action",
    "method": "PUT",
    "body": {"on": true, "bri": 254, "ct": 300}
  },
  "localtime": "2024-12-25T07:00:00"
}
```

**Recurring schedule (using timers):**
```bash
POST /api/{username}/schedules
{
  "name": "Daily sunset",
  "command": {
    "address": "/api/{username}/groups/1/action",
    "method": "PUT",
    "body": {"on": true, "bri": 150, "ct": 400}
  },
  "localtime": "W127/T18:30:00"
}
```

### Time Format

| Format | Meaning |
|--------|---------|
| `YYYY-MM-DDTHH:MM:SS` | Absolute time (local) |
| `W[bitmask]/THH:MM:SS` | Weekly recurring |
| `PT00:05:00` | Timer (5 minutes from now) |
| `R[count]/PT01:00:00` | Repeating timer |

**Weekly Bitmask:** Sum of: Mon=64, Tue=32, Wed=16, Thu=8, Fri=4, Sat=2, Sun=1
- `W127` = Every day
- `W124` = Weekdays (Mon-Fri)
- `W003` = Weekends (Sat-Sun)

### Modify Schedule
```bash
PUT /api/{username}/schedules/{id}
{"status": "disabled"}  # or "enabled"
```

### Delete Schedule
```bash
DELETE /api/{username}/schedules/{id}
```

---

## 7. Rules (Advanced Automation)

Rules trigger actions based on sensor states or other conditions.

### List Rules
```bash
GET /api/{username}/rules
```

### Create a Rule
```bash
POST /api/{username}/rules
{
  "name": "Motion living room",
  "conditions": [
    {
      "address": "/sensors/1/state/presence",
      "operator": "eq",
      "value": "true"
    },
    {
      "address": "/sensors/1/state/presence",
      "operator": "dx"
    }
  ],
  "actions": [
    {
      "address": "/groups/1/action",
      "method": "PUT",
      "body": {"on": true, "bri": 254}
    }
  ]
}
```

### Condition Operators
- `eq` - equals
- `gt` - greater than
- `lt` - less than
- `dx` - value changed (triggers on delta)
- `ddx` - delayed value changed
- `stable` - no change for period
- `not stable` - changed within period

---

## 8. Sensors

### List Sensors
```bash
GET /api/{username}/sensors
```

### Sensor Types

| Type | Description |
|------|-------------|
| `ZLLPresence` | Motion sensor |
| `ZLLLightLevel` | Ambient light sensor |
| `ZLLTemperature` | Temperature sensor |
| `ZLLSwitch` | Dimmer switch / Tap |
| `Daylight` | Built-in sunrise/sunset |
| `CLIPGenericStatus` | Virtual sensor (user-created) |

### Daylight Sensor
Built-in sensor that tracks sunrise/sunset based on bridge location:
```json
{
  "state": {
    "daylight": true,
    "lastupdated": "2024-01-15T15:30:00"
  },
  "config": {
    "on": true,
    "configured": true,
    "sunriseoffset": 30,
    "sunsetoffset": -30
  }
}
```

### Create Virtual Sensor (for custom automations)
```bash
POST /api/{username}/sensors
{
  "name": "Home/Away Status",
  "type": "CLIPGenericStatus",
  "modelid": "GenericStatus",
  "manufacturername": "Claude",
  "swversion": "1.0",
  "uniqueid": "home-away-001"
}
```

Then update it programmatically:
```bash
PUT /api/{username}/sensors/{id}/state
{"status": 1}  # 1=home, 0=away
```

---

## 9. API v2 Differences

The v2 API uses HTTPS, UUIDs, and a different resource model:

| Feature | v1 | v2 |
|---------|----|----|
| Protocol | HTTP | HTTPS only |
| IDs | Integers | UUIDs |
| Base path | `/api/{user}` | `/clip/v2/resource` |
| Updates | Polling | Server-Sent Events (SSE) |
| Rooms/Zones | Group types | First-class resources |

### v2 Base URL
```
https://{bridge-ip}/clip/v2/resource/{resource_type}
```

### v2 Authentication
Same username, sent as header:
```bash
curl -k "https://{bridge-ip}/clip/v2/resource/light" \
  -H "hue-application-key: {username}"
```

### v2 Event Stream (SSE)
```bash
curl -k -N "https://{bridge-ip}/eventstream/clip/v2" \
  -H "hue-application-key: {username}" \
  -H "Accept: text/event-stream"
```

### v2 Scene Activation
```bash
PUT /clip/v2/resource/scene/{scene_uuid}
{"recall": {"action": "active"}}
```

### v2 Dynamic Scenes
v2 supports dynamic scenes that slowly transition colors:
```bash
PUT /clip/v2/resource/scene/{id}
{
  "recall": {"action": "dynamic_palette"},
  "speed": 0.5
}
```

---

## 10. Rate Limits

| Scope | Limit |
|-------|-------|
| Light state changes | 10/second per light |
| Group actions | 1/second per group |
| Overall API | ~10-12 requests/second |

For rapid updates, use the Entertainment API (UDP streaming).

---

## 11. Error Codes

| Code | Description |
|------|-------------|
| 1 | Unauthorized user |
| 2 | Body contains invalid JSON |
| 3 | Resource not available |
| 4 | Method not available |
| 5 | Missing parameters |
| 6 | Parameter not available |
| 7 | Invalid value |
| 101 | Link button not pressed |
| 201 | Parameter not modifiable |
| 301 | Group table full (max ~64) |
| 302 | Light table full (max ~200) |

---

## Deeper Resources (The "Last 80%")

### Official Documentation
- [Hue Developer Portal](https://developers.meethue.com) - Full API reference (requires free account)
- [v2 API Overview](https://developers.meethue.com/new-hue-api/) - Dynamic scenes, gradients, events

### Unofficial References
- [Burgestrand Hue API](https://www.burgestrand.se/hue-api/) - Detailed v1 endpoint documentation
- [OpenHAB Hue v2 Binding](https://www.openhab.org/addons/bindings/hue/doc/readme_v2.html) - v2 resource model details

### Libraries & SDKs
- [phue (Python)](https://github.com/studioimaginaire/phue) - Full-featured Python library
- [qhue (Python)](https://github.com/quentinsf/qhue) - Lightweight, close-to-API wrapper
- [huego (Go)](https://github.com/amimof/huego) - Complete Go client
- [node-hue-api (Node)](https://github.com/peter-murray/node-hue-api) - TypeScript/Node client

### Entertainment & Streaming
- [Hue Entertainment API](https://developers.meethue.com/develop/hue-entertainment/) - UDP streaming for fast updates
- [HyperHDR Hue Integration](https://github.com/awawa-dev/HyperHDR/discussions/512) - Example of v2 entertainment usage

### Example Projects
- [hue-mcp Python](https://github.com/ThomasRohde/hue-mcp) - Shows comprehensive light/group/scene control patterns
- [hue-mcp Node](https://github.com/rmrfslashbin/hue-mcp) - v2 API patterns with rooms/zones
- [tigoe/hue-control](https://github.com/tigoe/hue-control) - Processing/JavaScript examples
