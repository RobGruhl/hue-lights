# CLI Quick Reference

> Direct curl/httpie commands for controlling Hue from the terminal

## Setup

```bash
# Discover bridge IP
curl -s https://discovery.meethue.com | jq

# Set variables (add to ~/.zshrc or ~/.bashrc)
export HUE_BRIDGE="192.168.1.x"
export HUE_USER="your-api-key-here"
```

## Authentication (First Time)

```bash
# Press link button on bridge, then within 30 seconds:
curl -X POST "http://$HUE_BRIDGE/api" \
  -H "Content-Type: application/json" \
  -d '{"devicetype":"claude#terminal"}'

# Save the returned username to HUE_USER
```

## Light Control

### List All Lights
```bash
curl -s "http://$HUE_BRIDGE/api/$HUE_USER/lights" | jq
```

### Get Light Status
```bash
curl -s "http://$HUE_BRIDGE/api/$HUE_USER/lights/1" | jq
```

### Turn On/Off
```bash
# On
curl -X PUT "http://$HUE_BRIDGE/api/$HUE_USER/lights/1/state" \
  -H "Content-Type: application/json" \
  -d '{"on": true}'

# Off
curl -X PUT "http://$HUE_BRIDGE/api/$HUE_USER/lights/1/state" \
  -d '{"on": false}'
```

### Set Brightness
```bash
# 0-254 (1=dim, 254=max)
curl -X PUT "http://$HUE_BRIDGE/api/$HUE_USER/lights/1/state" \
  -d '{"bri": 200}'
```

### Set Color (Hue/Sat)
```bash
# Red
curl -X PUT "http://$HUE_BRIDGE/api/$HUE_USER/lights/1/state" \
  -d '{"hue": 0, "sat": 254}'

# Blue
curl -X PUT "http://$HUE_BRIDGE/api/$HUE_USER/lights/1/state" \
  -d '{"hue": 46920, "sat": 254}'
```

### Set Color Temperature
```bash
# Warm (2700K-ish)
curl -X PUT "http://$HUE_BRIDGE/api/$HUE_USER/lights/1/state" \
  -d '{"ct": 370}'

# Cool daylight
curl -X PUT "http://$HUE_BRIDGE/api/$HUE_USER/lights/1/state" \
  -d '{"ct": 154}'
```

### Transition Time
```bash
# Fade to brightness over 5 seconds (50 deciseconds)
curl -X PUT "http://$HUE_BRIDGE/api/$HUE_USER/lights/1/state" \
  -d '{"bri": 100, "transitiontime": 50}'
```

### Flash Light
```bash
# Single flash
curl -X PUT "http://$HUE_BRIDGE/api/$HUE_USER/lights/1/state" \
  -d '{"alert": "select"}'

# Flash for 10 seconds
curl -X PUT "http://$HUE_BRIDGE/api/$HUE_USER/lights/1/state" \
  -d '{"alert": "lselect"}'
```

### Color Loop Effect
```bash
# Start color cycling
curl -X PUT "http://$HUE_BRIDGE/api/$HUE_USER/lights/1/state" \
  -d '{"effect": "colorloop"}'

# Stop
curl -X PUT "http://$HUE_BRIDGE/api/$HUE_USER/lights/1/state" \
  -d '{"effect": "none"}'
```

## Group Control

### List All Groups
```bash
curl -s "http://$HUE_BRIDGE/api/$HUE_USER/groups" | jq
```

### Control Group
```bash
# Turn on living room (group 1)
curl -X PUT "http://$HUE_BRIDGE/api/$HUE_USER/groups/1/action" \
  -d '{"on": true, "bri": 254}'

# All lights off (group 0 = all)
curl -X PUT "http://$HUE_BRIDGE/api/$HUE_USER/groups/0/action" \
  -d '{"on": false}'
```

### Create Room
```bash
curl -X POST "http://$HUE_BRIDGE/api/$HUE_USER/groups" \
  -d '{
    "name": "Office",
    "type": "Room",
    "class": "Office",
    "lights": ["3", "4"]
  }'
```

### Create Zone
```bash
curl -X POST "http://$HUE_BRIDGE/api/$HUE_USER/groups" \
  -d '{
    "name": "Downstairs",
    "type": "Zone",
    "lights": ["1", "2", "3", "4", "5"]
  }'
```

### Rename Group
```bash
curl -X PUT "http://$HUE_BRIDGE/api/$HUE_USER/groups/2" \
  -d '{"name": "New Room Name"}'
```

### Delete Group
```bash
curl -X DELETE "http://$HUE_BRIDGE/api/$HUE_USER/groups/5"
```

## Scenes

### List Scenes
```bash
curl -s "http://$HUE_BRIDGE/api/$HUE_USER/scenes" | jq
```

### Activate Scene
```bash
# Activate scene "abc123" on group 1
curl -X PUT "http://$HUE_BRIDGE/api/$HUE_USER/groups/1/action" \
  -d '{"scene": "abc123"}'
```

### Create Scene
```bash
curl -X POST "http://$HUE_BRIDGE/api/$HUE_USER/scenes" \
  -d '{
    "name": "Movie Night",
    "type": "GroupScene",
    "group": "1",
    "recycle": false
  }'
```

## Schedules

### List Schedules
```bash
curl -s "http://$HUE_BRIDGE/api/$HUE_USER/schedules" | jq
```

### Create One-Time Schedule
```bash
curl -X POST "http://$HUE_BRIDGE/api/$HUE_USER/schedules" \
  -d '{
    "name": "Turn on at 7am",
    "command": {
      "address": "/api/'$HUE_USER'/groups/1/action",
      "method": "PUT",
      "body": {"on": true, "bri": 254}
    },
    "localtime": "2024-12-25T07:00:00"
  }'
```

### Create Daily Schedule
```bash
# W127 = every day, W124 = weekdays, W003 = weekends
curl -X POST "http://$HUE_BRIDGE/api/$HUE_USER/schedules" \
  -d '{
    "name": "Evening lights",
    "command": {
      "address": "/api/'$HUE_USER'/groups/1/action",
      "method": "PUT",
      "body": {"on": true, "bri": 180, "ct": 400}
    },
    "localtime": "W127/T18:00:00"
  }'
```

### Delete Schedule
```bash
curl -X DELETE "http://$HUE_BRIDGE/api/$HUE_USER/schedules/1"
```

## System Info

### Bridge Configuration
```bash
curl -s "http://$HUE_BRIDGE/api/$HUE_USER/config" | jq
```

### Full State Dump
```bash
curl -s "http://$HUE_BRIDGE/api/$HUE_USER" | jq
```

### List Sensors
```bash
curl -s "http://$HUE_BRIDGE/api/$HUE_USER/sensors" | jq
```

## Shell Helper Functions

Add to `~/.zshrc` or `~/.bashrc`:

```bash
# Prerequisites
export HUE_BRIDGE="192.168.1.x"
export HUE_USER="your-api-key"

# Quick commands
hue-on() { curl -s -X PUT "http://$HUE_BRIDGE/api/$HUE_USER/lights/$1/state" -d '{"on":true}' > /dev/null; }
hue-off() { curl -s -X PUT "http://$HUE_BRIDGE/api/$HUE_USER/lights/$1/state" -d '{"on":false}' > /dev/null; }
hue-bri() { curl -s -X PUT "http://$HUE_BRIDGE/api/$HUE_USER/lights/$1/state" -d "{\"bri\":$2}" > /dev/null; }
hue-ct() { curl -s -X PUT "http://$HUE_BRIDGE/api/$HUE_USER/lights/$1/state" -d "{\"ct\":$2}" > /dev/null; }
hue-color() { curl -s -X PUT "http://$HUE_BRIDGE/api/$HUE_USER/lights/$1/state" -d "{\"hue\":$2,\"sat\":254}" > /dev/null; }

# Group commands
hue-group-on() { curl -s -X PUT "http://$HUE_BRIDGE/api/$HUE_USER/groups/$1/action" -d '{"on":true}' > /dev/null; }
hue-group-off() { curl -s -X PUT "http://$HUE_BRIDGE/api/$HUE_USER/groups/$1/action" -d '{"on":false}' > /dev/null; }
hue-all-off() { curl -s -X PUT "http://$HUE_BRIDGE/api/$HUE_USER/groups/0/action" -d '{"on":false}' > /dev/null; }

# List resources
hue-lights() { curl -s "http://$HUE_BRIDGE/api/$HUE_USER/lights" | jq -r 'to_entries[] | "\(.key): \(.value.name) [\(if .value.state.on then "ON" else "OFF" end)]"'; }
hue-groups() { curl -s "http://$HUE_BRIDGE/api/$HUE_USER/groups" | jq -r 'to_entries[] | "\(.key): \(.value.name) (\(.value.type))"'; }
hue-scenes() { curl -s "http://$HUE_BRIDGE/api/$HUE_USER/scenes" | jq -r 'to_entries[] | "\(.key): \(.value.name)"'; }

# Usage examples:
# hue-on 1          # Turn on light 1
# hue-bri 1 200     # Set light 1 to brightness 200
# hue-ct 1 370      # Set light 1 to warm white
# hue-color 1 46920 # Set light 1 to blue
# hue-all-off       # Turn off all lights
# hue-lights        # List all lights with status
```

## v2 API (HTTPS)

```bash
# v2 uses HTTPS with self-signed cert (-k to skip verification)
# and sends username as header

# List lights (v2)
curl -k -s "https://$HUE_BRIDGE/clip/v2/resource/light" \
  -H "hue-application-key: $HUE_USER" | jq

# List rooms (v2)
curl -k -s "https://$HUE_BRIDGE/clip/v2/resource/room" \
  -H "hue-application-key: $HUE_USER" | jq

# List zones (v2)
curl -k -s "https://$HUE_BRIDGE/clip/v2/resource/zone" \
  -H "hue-application-key: $HUE_USER" | jq

# Activate scene (v2) - uses UUID
curl -k -X PUT "https://$HUE_BRIDGE/clip/v2/resource/scene/{scene-uuid}" \
  -H "hue-application-key: $HUE_USER" \
  -H "Content-Type: application/json" \
  -d '{"recall": {"action": "active"}}'

# Subscribe to events (v2)
curl -k -N "https://$HUE_BRIDGE/eventstream/clip/v2" \
  -H "hue-application-key: $HUE_USER" \
  -H "Accept: text/event-stream"
```

## Useful One-Liners

```bash
# Find light by name
curl -s "http://$HUE_BRIDGE/api/$HUE_USER/lights" | \
  jq -r 'to_entries[] | select(.value.name | test("living"; "i")) | .key'

# Check which lights are on
curl -s "http://$HUE_BRIDGE/api/$HUE_USER/lights" | \
  jq -r 'to_entries[] | select(.value.state.on) | "\(.key): \(.value.name)"'

# Get room's lights
curl -s "http://$HUE_BRIDGE/api/$HUE_USER/groups/1" | jq '.lights'

# Scene lookup by name
curl -s "http://$HUE_BRIDGE/api/$HUE_USER/scenes" | \
  jq -r 'to_entries[] | select(.value.name | test("relax"; "i")) | .key'
```
