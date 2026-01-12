# Creative Lighting Effects

> Ideas and patterns for interesting and creative light control

## Ambient Effects

### Sunrise Simulation
```python
def sunrise(bridge, group_id, duration_minutes=20):
    """Gradual warm wake-up light."""
    import time

    # Start: very dim, very warm (like candlelight)
    bridge.set_group(group_id, {
        'on': True,
        'bri': 1,
        'ct': 500,  # 2000K
        'transitiontime': 0
    })

    steps = [
        (10, 450, duration_minutes * 0.2),   # Dim orange
        (50, 400, duration_minutes * 0.2),   # Brighter orange
        (120, 350, duration_minutes * 0.2),  # Warm white
        (200, 300, duration_minutes * 0.2),  # Neutral
        (254, 250, duration_minutes * 0.2),  # Bright daylight
    ]

    for bri, ct, phase_mins in steps:
        bridge.set_group(group_id, {
            'bri': bri,
            'ct': ct,
            'transitiontime': int(phase_mins * 60 * 10)
        })
        time.sleep(phase_mins * 60)

sunrise(b, 1, 20)  # 20-minute wake up
```

### Sunset/Wind Down
```python
def sunset(bridge, group_id, duration_minutes=30):
    """Gradual evening dim-down."""
    bridge.set_group(group_id, {
        'bri': 50,
        'ct': 500,  # Very warm
        'transitiontime': duration_minutes * 60 * 10
    })
```

### Candlelight Flicker
```python
import random
import time

def candlelight(bridge, light_ids, duration_seconds=60):
    """Simulate flickering candle."""
    base_bri = 100
    base_ct = 500  # Very warm

    end_time = time.time() + duration_seconds
    while time.time() < end_time:
        for lid in light_ids:
            flicker = random.randint(-30, 30)
            bridge.set_light(lid, {
                'bri': max(1, min(254, base_bri + flicker)),
                'ct': base_ct + random.randint(-20, 20),
                'transitiontime': random.randint(1, 3)
            })
        time.sleep(0.1)

candlelight(b, [1, 2], 120)
```

### Breathing Effect
```python
import time
import math

def breathe(bridge, light_ids, min_bri=30, max_bri=254, period=4):
    """Slow pulsing like breathing."""
    while True:
        for t in range(0, 100):
            # Sine wave from min to max
            bri = min_bri + (max_bri - min_bri) * (math.sin(t * 0.0628) + 1) / 2
            bridge.set_light(light_ids, {'bri': int(bri), 'transitiontime': 2})
            time.sleep(period / 100)
```

## Party & Entertainment

### Color Wave
```python
import time

def color_wave(bridge, light_ids, speed=0.5):
    """Wave of color across lights."""
    hue_offset = 65535 // len(light_ids)

    while True:
        base_hue = int(time.time() * 10000) % 65535
        for i, lid in enumerate(light_ids):
            hue = (base_hue + i * hue_offset) % 65535
            bridge.set_light(lid, {
                'hue': hue,
                'sat': 254,
                'bri': 254,
                'transitiontime': int(speed * 10)
            })
        time.sleep(speed)

color_wave(b, [1, 2, 3, 4], 0.5)
```

### Lightning Storm
```python
import random
import time

def lightning(bridge, light_ids, duration=30):
    """Random lightning flashes."""
    # Save current state
    original = {lid: bridge.get_light(lid, 'state') for lid in light_ids}

    # Set base storm ambiance
    bridge.set_light(light_ids, {'bri': 30, 'ct': 250, 'on': True})

    end_time = time.time() + duration
    while time.time() < end_time:
        # Wait for next strike
        time.sleep(random.uniform(0.5, 3))

        # Pick random lights for this strike
        strike_lights = random.sample(light_ids, random.randint(1, len(light_ids)))

        # Flash sequence
        for _ in range(random.randint(1, 3)):
            bridge.set_light(strike_lights, {'bri': 254, 'ct': 153, 'transitiontime': 0})
            time.sleep(random.uniform(0.05, 0.15))
            bridge.set_light(strike_lights, {'bri': 30, 'transitiontime': 0})
            time.sleep(random.uniform(0.05, 0.2))

    # Restore
    for lid, state in original.items():
        bridge.set_light(lid, {k: v for k, v in state.items()
                               if k in ['on', 'bri', 'hue', 'sat', 'ct']})
```

### Music Reactive (BPM-based)
```python
import time

def pulse_to_bpm(bridge, light_ids, bpm=120, color={'hue': 46920, 'sat': 254}):
    """Pulse lights to a beat."""
    interval = 60 / bpm

    while True:
        bridge.set_light(light_ids, {
            **color,
            'bri': 254,
            'transitiontime': 0
        })
        time.sleep(0.1)
        bridge.set_light(light_ids, {
            **color,
            'bri': 80,
            'transitiontime': int((interval - 0.1) * 10)
        })
        time.sleep(interval - 0.1)
```

## Productivity & Focus

### Pomodoro Timer
```python
import time

def pomodoro(bridge, light_id, work_mins=25, break_mins=5):
    """Visual pomodoro timer."""
    # Work mode: cool, focused light
    bridge.set_light(light_id, {
        'on': True,
        'bri': 254,
        'ct': 200,  # Cool daylight
        'transitiontime': 10
    })

    # Gradual warmup as work period ends
    time.sleep((work_mins - 2) * 60)
    bridge.set_light(light_id, {
        'ct': 350,
        'transitiontime': 1200  # 2-minute transition
    })
    time.sleep(2 * 60)

    # Break time: warm, relaxed
    bridge.set_light(light_id, 'alert', 'select')  # Flash
    bridge.set_light(light_id, {
        'bri': 150,
        'ct': 450,
        'transitiontime': 20
    })

    time.sleep(break_mins * 60)
    bridge.set_light(light_id, 'alert', 'select')
```

### Deep Focus Mode
```python
def deep_focus(bridge, room_group, accent_light=None):
    """Low distraction lighting for concentration."""
    bridge.set_group(room_group, {
        'on': True,
        'bri': 180,
        'ct': 220,  # Neutral-cool
        'transitiontime': 30
    })

    if accent_light:
        bridge.set_light(accent_light, {
            'on': True,
            'bri': 100,
            'ct': 350,
            'transitiontime': 30
        })
```

## Time-of-Day Automation

### Circadian Rhythm
```python
from datetime import datetime

def circadian_light(bridge, group_id):
    """Set light based on time of day."""
    hour = datetime.now().hour

    if 6 <= hour < 9:  # Morning
        ct, bri = 300, 200  # Warm, medium
    elif 9 <= hour < 17:  # Day
        ct, bri = 200, 254  # Cool, bright
    elif 17 <= hour < 20:  # Evening
        ct, bri = 400, 180  # Warm, medium
    elif 20 <= hour < 23:  # Night
        ct, bri = 500, 100  # Very warm, dim
    else:  # Late night
        ct, bri = 500, 30   # Warmest, very dim

    bridge.set_group(group_id, {
        'on': True,
        'ct': ct,
        'bri': bri,
        'transitiontime': 100  # 10-second transition
    })
```

### Movie Mode
```python
def movie_mode(bridge, main_group, bias_lights=None):
    """Dim main lights, set bias lighting behind TV."""
    # Dim or off main lights
    bridge.set_group(main_group, {
        'on': True,
        'bri': 20,
        'ct': 400,
        'transitiontime': 30
    })

    # Bias lights behind TV (reduces eye strain)
    if bias_lights:
        bridge.set_light(bias_lights, {
            'on': True,
            'bri': 60,
            'ct': 250,  # Match typical TV color temp
            'transitiontime': 30
        })
```

## Room-Specific Scenes

### Kitchen Task Lighting
```python
def kitchen_cooking(bridge, group_id):
    """Bright, clear light for food prep."""
    bridge.set_group(group_id, {
        'on': True,
        'bri': 254,
        'ct': 180,  # Daylight for accurate color
        'transitiontime': 10
    })

def kitchen_dining(bridge, group_id):
    """Warm, inviting for meals."""
    bridge.set_group(group_id, {
        'on': True,
        'bri': 180,
        'ct': 370,
        'transitiontime': 30
    })
```

### Bathroom Night Mode
```python
def bathroom_night(bridge, light_ids):
    """Very dim, warm - won't destroy night vision."""
    bridge.set_light(light_ids, {
        'on': True,
        'bri': 5,
        'ct': 500,
        'transitiontime': 0
    })
```

### Reading Light
```python
def reading_mode(bridge, light_id):
    """Optimal reading light - bright but warm enough."""
    bridge.set_light(light_id, {
        'on': True,
        'bri': 254,
        'ct': 280,  # Warm white
        'transitiontime': 10
    })
```

## Notification & Alert Patterns

### Doorbell Flash
```python
def doorbell_alert(bridge, light_ids, color={'hue': 10000, 'sat': 200}):
    """Flash lights for doorbell (good for hearing impaired)."""
    import time
    original = {lid: bridge.get_light(lid, 'state') for lid in light_ids}

    for _ in range(3):
        bridge.set_light(light_ids, {
            **color,
            'bri': 254,
            'transitiontime': 0
        })
        time.sleep(0.3)
        bridge.set_light(light_ids, {'bri': 50, 'transitiontime': 0})
        time.sleep(0.3)

    # Restore
    for lid, state in original.items():
        bridge.set_light(lid, {k: v for k, v in state.items()
                               if k in ['on', 'bri', 'hue', 'sat', 'ct']})
```

### Status Indicator
```python
def status_light(bridge, light_id, status):
    """Use a light as a status indicator."""
    colors = {
        'ok': {'hue': 25500, 'sat': 254},      # Green
        'warning': {'hue': 10000, 'sat': 254}, # Orange
        'error': {'hue': 0, 'sat': 254},       # Red
        'busy': {'hue': 46920, 'sat': 254},    # Blue
        'away': {'hue': 50000, 'sat': 254},    # Purple
    }

    if status in colors:
        bridge.set_light(light_id, {
            'on': True,
            **colors[status],
            'bri': 150,
            'transitiontime': 5
        })
    elif status == 'off':
        bridge.set_light(light_id, {'on': False})
```

## Seasonal & Holiday

### Cozy Winter
```python
def cozy_winter(bridge, group_id):
    """Warm, fire-like ambiance."""
    bridge.set_group(group_id, {
        'on': True,
        'bri': 150,
        'ct': 500,  # Warmest
        'transitiontime': 50
    })
```

### Holiday Colors (rotating)
```python
import time

def holiday_rotation(bridge, light_ids, colors, interval=5):
    """Rotate through holiday colors."""
    while True:
        for color in colors:
            bridge.set_light(light_ids, {
                **color,
                'bri': 254,
                'transitiontime': 20
            })
            time.sleep(interval)

# Christmas
xmas_colors = [
    {'hue': 0, 'sat': 254},      # Red
    {'hue': 25500, 'sat': 254},  # Green
]

# Hanukkah
hanukkah_colors = [
    {'hue': 46920, 'sat': 254},  # Blue
    {'ct': 200},                  # White
]

# Halloween
halloween_colors = [
    {'hue': 6000, 'sat': 254},   # Orange
    {'hue': 50000, 'sat': 254},  # Purple
]
```

## Utility Functions

### Random Relaxation
```python
import random

def random_relax(bridge, light_ids):
    """Set each light to a random relaxing state."""
    for lid in light_ids:
        bridge.set_light(lid, {
            'on': True,
            'bri': random.randint(80, 180),
            'ct': random.randint(350, 500),
            'transitiontime': random.randint(20, 50)
        })
```

### Gradual All-Off
```python
def gradual_off(bridge, group_id=0, minutes=10):
    """Slowly dim to off over time."""
    bridge.set_group(group_id, {
        'bri': 1,
        'transitiontime': minutes * 60 * 10
    })
    # Schedule actual off after transition
    import time
    time.sleep(minutes * 60 + 1)
    bridge.set_group(group_id, {'on': False})
```

### Room Tour (sequential activation)
```python
import time

def room_tour(bridge, groups, duration_each=5):
    """Light up rooms in sequence."""
    for group_id in groups:
        bridge.set_group(group_id, {'on': True, 'bri': 254, 'transitiontime': 10})
        time.sleep(duration_each)
        bridge.set_group(group_id, {'on': False, 'transitiontime': 10})
        time.sleep(1)
```
