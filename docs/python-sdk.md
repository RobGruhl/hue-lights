# Python SDK Guide (phue)

> Using phue for direct light control via Claude Code

## Installation

```bash
# Using pipx for CLI tools
pipx install phue

# Or in a project with poetry
poetry add phue
```

## First-Time Setup

```python
from phue import Bridge

# First run: press link button on bridge, then run this
b = Bridge('192.168.1.x')  # Replace with your bridge IP
b.connect()

# Credentials saved to ~/.python_hue
```

## Quick Reference

```python
from phue import Bridge

b = Bridge('192.168.1.x')

# Get all lights
lights = b.get_light_objects('list')
for light in lights:
    print(f"{light.light_id}: {light.name} - {'On' if light.on else 'Off'}")

# Control by ID
b.set_light(1, 'on', True)
b.set_light(1, 'bri', 254)  # Max brightness

# Control by name
b.set_light('Living Room Lamp', 'on', True)

# Multiple attributes at once
b.set_light(1, {'on': True, 'bri': 254, 'hue': 10000, 'sat': 200})

# Control multiple lights
b.set_light([1, 2, 3], 'on', False)
```

## Light Object API

```python
# Get light objects for easier manipulation
lights = b.get_light_objects('id')    # Dict by ID: {1: Light, 2: Light}
lights = b.get_light_objects('name')  # Dict by name: {"Lamp": Light}
lights = b.get_light_objects('list')  # List: [Light, Light, Light]

# Direct property access
light = lights[1]
light.on = True
light.brightness = 200
light.hue = 10000
light.saturation = 254

# Transition time (in deciseconds, 10 = 1 second)
light.transitiontime = 20  # 2 second transition
light.brightness = 50      # Will take 2 seconds
```

## Color Control

### Hue/Saturation (HSB)
```python
# Hue: 0-65535 (color wheel)
# Saturation: 0-254 (0=white, 254=vivid)
b.set_light(1, {'hue': 10000, 'sat': 254, 'bri': 254})

# Common colors
RED = {'hue': 0, 'sat': 254}
ORANGE = {'hue': 5000, 'sat': 254}
YELLOW = {'hue': 12750, 'sat': 254}
GREEN = {'hue': 25500, 'sat': 254}
CYAN = {'hue': 36210, 'sat': 254}
BLUE = {'hue': 46920, 'sat': 254}
PURPLE = {'hue': 50000, 'sat': 254}
PINK = {'hue': 56100, 'sat': 254}
```

### Color Temperature
```python
# Mireds: 153 (cold/6500K) to 500 (warm/2000K)
b.set_light(1, 'ct', 370)  # Warm white (~2700K)
b.set_light(1, 'ct', 250)  # Neutral (~4000K)
b.set_light(1, 'ct', 154)  # Cool daylight (~6500K)

def kelvin_to_mired(k):
    return int(1000000 / k)

b.set_light(1, 'ct', kelvin_to_mired(3000))  # 3000K
```

### XY Color (CIE 1931)
```python
# For precise color matching
b.set_light(1, 'xy', [0.675, 0.322])  # Red
b.set_light(1, 'xy', [0.409, 0.518])  # Green
b.set_light(1, 'xy', [0.167, 0.040])  # Blue
```

### RGB to Hue Conversion
```python
import colorsys

def rgb_to_hue(r, g, b):
    """Convert RGB (0-255) to Hue values."""
    h, s, v = colorsys.rgb_to_hsv(r/255, g/255, b/255)
    return {
        'hue': int(h * 65535),
        'sat': int(s * 254),
        'bri': int(v * 254)
    }

b.set_light(1, rgb_to_hue(255, 128, 0))  # Orange
```

## Groups

```python
# List all groups
groups = b.get_group()
for gid, group in groups.items():
    print(f"{gid}: {group['name']} ({group['type']})")

# Get specific group
living_room = b.get_group(1)
print(living_room['lights'])  # ['1', '2', '3']

# Control entire group
b.set_group(1, 'on', True)
b.set_group(1, {'on': True, 'bri': 200, 'ct': 350})

# Create a group
b.create_group('Reading Corner', [1, 4])

# Delete a group
b.delete_group(5)
```

## Scenes

```python
# List scenes
scenes = b.get_scene()
for sid, scene in scenes.items():
    print(f"{sid}: {scene['name']} (group: {scene.get('group', 'N/A')})")

# Activate a scene (via group action)
b.set_group(1, {'scene': 'abc123'})  # Use scene ID

# Run a scene by name (helper)
def activate_scene_by_name(bridge, scene_name, group_id=None):
    scenes = bridge.get_scene()
    for sid, scene in scenes.items():
        if scene['name'].lower() == scene_name.lower():
            if group_id:
                bridge.set_group(group_id, {'scene': sid})
            elif 'group' in scene:
                bridge.set_group(int(scene['group']), {'scene': sid})
            return True
    return False

activate_scene_by_name(b, 'Relax')
```

## Schedules

```python
from datetime import datetime, timedelta

# List schedules
schedules = b.get_schedule()

# Create a schedule (turn on in 1 hour)
future_time = datetime.now() + timedelta(hours=1)
b.create_schedule(
    'Wake up',
    future_time.strftime('%Y-%m-%dT%H:%M:%S'),
    1,  # light ID
    {'on': True, 'bri': 254},
    'Morning light'
)

# Create group schedule
b.create_group_schedule(
    'Movie time',
    '2024-12-25T20:00:00',
    1,  # group ID
    {'on': True, 'bri': 50, 'ct': 450}
)

# Delete schedule
b.delete_schedule(1)
```

## Effects & Alerts

```python
# Color loop effect (cycles through colors)
b.set_light(1, 'effect', 'colorloop')

# Stop effect
b.set_light(1, 'effect', 'none')

# Alert (flash)
b.set_light(1, 'alert', 'select')    # Flash once
b.set_light(1, 'alert', 'lselect')   # Flash for 10 seconds
b.set_light(1, 'alert', 'none')      # Stop
```

## Transitions

```python
# Transition time in deciseconds (1 = 0.1s)
b.set_light(1, 'bri', 254, transitiontime=30)  # 3 second fade

# With multiple attributes
b.set_light(1, {
    'on': True,
    'bri': 254,
    'ct': 350,
    'transitiontime': 100  # 10 second transition
})

# Per-light persistent transition time
light = b.get_light_objects('id')[1]
light.transitiontime = 20  # All changes take 2 seconds
light.brightness = 100
light.brightness = 200  # Both take 2 seconds
```

## Full Bridge State

```python
# Get everything
api = b.get_api()

# Structure:
# api['lights']     - all lights
# api['groups']     - all groups
# api['config']     - bridge config
# api['schedules']  - all schedules
# api['scenes']     - all scenes
# api['sensors']    - all sensors
# api['rules']      - all rules

# Check bridge info
config = api['config']
print(f"Bridge: {config['name']}")
print(f"Model: {config['modelid']}")
print(f"API version: {config['apiversion']}")
print(f"Zigbee channel: {config['zigbeechannel']}")
```

## Useful Patterns

### Sunset Transition
```python
def sunset_mode(bridge, group_id, duration_minutes=30):
    """Gradually dim lights to warm, low setting."""
    transition = duration_minutes * 60 * 10  # to deciseconds
    bridge.set_group(group_id, {
        'on': True,
        'bri': 50,
        'ct': 500,  # Very warm
        'transitiontime': transition
    })

sunset_mode(b, 1, 30)  # 30-minute fade
```

### Notification Flash
```python
def notify(bridge, light_ids, color=None, count=3):
    """Flash lights for notification."""
    import time
    original_states = {}

    for lid in light_ids:
        original_states[lid] = bridge.get_light(lid, 'state')

    for _ in range(count):
        if color:
            bridge.set_light(light_ids, {**color, 'on': True, 'transitiontime': 0})
        else:
            bridge.set_light(light_ids, 'alert', 'select')
        time.sleep(0.5)

    # Restore
    for lid, state in original_states.items():
        restore = {k: v for k, v in state.items()
                   if k in ['on', 'bri', 'hue', 'sat', 'ct', 'xy']}
        bridge.set_light(lid, restore)

notify(b, [1, 2], color={'hue': 0, 'sat': 254})  # Red flash
```

### Find Lights by Name Pattern
```python
def find_lights(bridge, pattern):
    """Find lights matching a pattern (case-insensitive)."""
    import re
    lights = bridge.get_light_objects('name')
    return {name: light for name, light in lights.items()
            if re.search(pattern, name, re.IGNORECASE)}

bedroom_lights = find_lights(b, r'bedroom')
for name, light in bedroom_lights.items():
    light.on = True
```

### Cycle Through Colors
```python
import time

def color_cycle(bridge, light_id, duration_per_color=2):
    """Cycle through rainbow colors."""
    colors = [0, 10000, 25000, 36000, 46000, 56000]

    for hue in colors:
        bridge.set_light(light_id, {
            'hue': hue,
            'sat': 254,
            'bri': 254,
            'transitiontime': duration_per_color * 10
        })
        time.sleep(duration_per_color)

color_cycle(b, 1)
```

## Error Handling

```python
from phue import PhueException, PhueRegistrationException

try:
    b = Bridge('192.168.1.x')
    b.connect()
except PhueRegistrationException:
    print("Press the link button on your bridge and try again")
except PhueException as e:
    print(f"Hue error: {e}")

# Check if light is reachable
light_state = b.get_light(1, 'state')
if not light_state['reachable']:
    print("Light 1 is not reachable (off at switch?)")
```

## Configuration File

phue stores credentials in `~/.python_hue`:
```json
{
    "192.168.1.x": {
        "username": "aBcD1234...your-api-key..."
    }
}
```

You can use this to pre-configure bridges or back up credentials.
