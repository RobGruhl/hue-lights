# Technical Learnings

## V2 API Gradient Control

Signe gradient lights support bottom-to-top gradients via the v2 API.

### Capabilities
- **Points:** Up to 5 gradient points per light
- **Pixels:** 10 pixels total (interpolated between points)
- **Modes:** `interpolated_palette`, `interpolated_palette_mirrored`, `random_pixelated`, `segmented_palette`

### Setting a Gradient
```bash
curl -sk -X PUT "https://{bridge}/clip/v2/resource/light/{uuid}" \
  -H "hue-application-key: {api_key}" \
  -H "Content-Type: application/json" \
  -d '{
    "gradient": {
      "points": [
        {"color": {"xy": {"x": 0.55, "y": 0.42}}, "dimming": {"brightness": 80}},
        {"color": {"xy": {"x": 0.40, "y": 0.40}}, "dimming": {"brightness": 95}},
        {"color": {"xy": {"x": 0.28, "y": 0.35}}, "dimming": {"brightness": 100}}
      ]
    },
    "dynamics": {"duration": 3000},
    "dimming": {"brightness": 100}
  }'
```

### Key Fields
- `gradient.points[]` - Array of color points (bottom to top)
- `gradient.points[].color.xy` - CIE xy coordinates
- `gradient.points[].dimming.brightness` - Per-point brightness (0-100)
- `dynamics.duration` - Transition time in milliseconds
- `dimming.brightness` - Overall light brightness

---

## Perceptual Brightness Compensation

Different colors appear different brightnesses at the same power level.

### The Science
- **Luminous efficiency:** Human eyes most sensitive to green-yellow (~555nm)
- **Yellow/green appears brightest**, blue appears dimmest at same setting
- **Helmholtz-Kohlrausch effect:** Saturated colors appear brighter

### Compensation Strategy
To balance perceived brightness:
- **Blues/teals:** Boost brightness 20-30%
- **Yellows/oranges:** Reduce brightness 10-20%
- **Shift teal toward cyan** (more green = more luminous)

### Example Balanced Gradient
```json
{
  "points": [
    {"color": {"xy": {"x": 0.52, "y": 0.41}}, "dimming": {"brightness": 80}},  // orange (dimmed)
    {"color": {"xy": {"x": 0.42, "y": 0.40}}, "dimming": {"brightness": 95}},  // cream
    {"color": {"xy": {"x": 0.33, "y": 0.38}}, "dimming": {"brightness": 100}}, // warm white
    {"color": {"xy": {"x": 0.22, "y": 0.35}}, "dimming": {"brightness": 100}}, // cyan (boosted)
    {"color": {"xy": {"x": 0.18, "y": 0.37}}, "dimming": {"brightness": 100}}  // aqua
  ]
}
```

---

## Animation Techniques

### Vertical Wave (Bottom-to-Top on Signes)
Colors cycle through gradient points, creating upward motion:
```bash
# Cycle through palette, offsetting each point
p0=$(( phase % PALETTE_LEN ))
p1=$(( (phase + 2) % PALETTE_LEN ))
# ... etc for p2, p3, p4
```

### Horizontal Wave (Across Room)
Stagger phase offset per light based on position:
```bash
for i in 0 1 2 3 4; do
    signe_phase=$(( (phase + i * 2) % PALETTE_LEN ))
    set_gradient_light "${SIGNES[$i]}" "$signe_phase"
done
```

### Spacing-Proportional Timing
For natural-looking waves across unevenly-spaced lights:
```bash
# Physical distances: W-MW=11.5', MW-M=4', M-ME=7', ME-E=9'
# Scale to palette offsets proportionally
POS_OFFSETS=(0 1 2 4 5 7 10)  # ~proportional to 0, 2, 5.5, 11.5, 15.5, 22.5, 31.5
```

### Transition Timing
- `transitiontime` in v1 API: **deciseconds** (10 = 1 second)
- `dynamics.duration` in v2 API: **milliseconds** (3000 = 3 seconds)
- For smooth animation: transition ≈ 70-80% of step interval

---

## Color Reference (XY Coordinates)

### Warm Sunflare Palette
| Color | X | Y | Brightness |
|-------|---|---|------------|
| Warm orange | 0.52 | 0.41 | 80% |
| Gold | 0.47 | 0.41 | 85% |
| Cream | 0.42 | 0.40 | 90% |
| Warm white | 0.36 | 0.39 | 95% |
| Warm teal | 0.30 | 0.37 | 100% |
| Cyan | 0.24 | 0.36 | 100% |
| Aqua | 0.18 | 0.37 | 100% |

### Vaporwave Palette
| Color | X | Y |
|-------|---|---|
| Hot pink | 0.45 | 0.22 |
| Magenta | 0.38 | 0.18 |
| Purple | 0.32 | 0.15 |
| Deep purple | 0.25 | 0.13 |
| Blue-purple | 0.20 | 0.14 |
| Cyan | 0.16 | 0.20 |
| Teal | 0.15 | 0.30 |

### Woodland Toadstool Palette
| Color | X | Y |
|-------|---|---|
| Deep rust | 0.60 | 0.35 |
| Rust | 0.58 | 0.38 |
| Amber | 0.55 | 0.40 |
| Gold | 0.50 | 0.42 |
| Yellow-green | 0.45 | 0.45 |
| Warm green | 0.40 | 0.50 |
| Forest | 0.35 | 0.53 |
| Deep forest | 0.32 | 0.55 |

### Romantic Pink/Orange Palette
| Color | X | Y |
|-------|---|---|
| Deep pink | 0.50 | 0.25 |
| Pink | 0.52 | 0.28 |
| Coral | 0.55 | 0.30 |
| Salmon | 0.57 | 0.33 |
| Light coral | 0.58 | 0.35 |
| Peach | 0.57 | 0.38 |
| Warm orange | 0.55 | 0.40 |

### Morning Sunrise Palette
| Color | X | Y | Brightness |
|-------|---|---|------------|
| Deep coral | 0.58 | 0.35 | 100% |
| Coral | 0.55 | 0.38 | 95% |
| Peach | 0.52 | 0.40 | 90% |
| Soft gold | 0.50 | 0.42 | 85% |
| Gold | 0.48 | 0.43 | 85% |
| Warm white | 0.45 | 0.43 | 85% |
| Cream | 0.42 | 0.42 | 90% |
| Pale cream | 0.40 | 0.40 | 95% |

### Deep Ocean Palette
| Color | X | Y | Brightness |
|-------|---|---|------------|
| Deep teal | 0.16 | 0.32 | 100% |
| Teal | 0.18 | 0.34 | 100% |
| Sea green | 0.20 | 0.36 | 100% |
| Seafoam | 0.23 | 0.37 | 100% |
| Pale aqua | 0.26 | 0.38 | 95% |
| Light aqua | 0.28 | 0.37 | 90% |
| Soft white | 0.30 | 0.36 | 85% |

### Candlelight Palette
| Color | X | Y | Brightness |
|-------|---|---|------------|
| Warm amber | 0.54 | 0.41 | 75% |
| Amber | 0.52 | 0.42 | 85% |
| Deep amber | 0.55 | 0.40 | 70% |
| Gold | 0.53 | 0.43 | 90% |
| Soft amber | 0.51 | 0.42 | 80% |

### Nordic Twilight Palette
| Color | X | Y | Brightness |
|-------|---|---|------------|
| Soft lavender | 0.34 | 0.28 | 70% |
| Lavender | 0.38 | 0.30 | 75% |
| Dusty rose | 0.42 | 0.34 | 80% |
| Blush | 0.44 | 0.36 | 85% |
| Warm cream | 0.46 | 0.38 | 85% |
| Pale amber | 0.48 | 0.40 | 85% |

---

## API Rate Limits

| Scope | Limit |
|-------|-------|
| Light state changes | 10/second per light |
| Group actions | 1/second per group |
| Overall API | ~10-12 requests/second |

For animations with many lights, use parallel curl calls with `&` and `wait`.

---

## Bridge Connection

### Discovery
```bash
curl -s https://discovery.meethue.com
```

### Authentication
1. Press link button on bridge
2. POST to create user:
```bash
curl -X POST "http://{bridge}/api" -d '{"devicetype":"app_name#device"}'
```

### V2 API Authentication
Send API key as header:
```bash
curl -sk "https://{bridge}/clip/v2/resource/light" \
  -H "hue-application-key: {api_key}"
```

Note: V2 uses HTTPS with self-signed cert (`-k` to skip verification)
