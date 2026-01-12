# Scene Preferences & Notes

## Modular Scene System

**New!** Mix and match any palette + animation + room(s):

```bash
./scripts/run-scene.sh <palette> <animation> <room> [room2] ...

# Examples:
./scripts/run-scene.sh ocean breathing whole-house
./scripts/run-scene.sh vaporwave wave dining jamies-office
./scripts/run-scene.sh candle flicker dining-signes-only
```

See [modular-scenes.md](modular-scenes.md) for full documentation.

---

## Household Preferences

### Rob
- Likes **Sunflare** (bright yellow to sky blue) for daytime - wants to see clearly, feels like daytime
- Likes **Vaporwave** in the evening
- Interested in **slow animations** that add subtle interest without being distracting
- Likes **intense pink/orange romantic** look

### Jamie
- Finds original Sunflare **too cold** - prefers warmer tones
- Likes **Vaporwave** in the evening
- Fond of **Woodland Toadstool** - warmer, fun look
- Likes **intense pink/orange romantic** look

### Compromise: Warm Sunflare
- Middle ground: warm yellow → soft gold → warm white → warm turquoise → soft teal
- Keeps brightness high for daytime visibility
- Replaces cold blue with warmer teal tones
- Animation: gentle wave flowing W→E with bottom-to-top gradients on Signes

---

## Dining Floor Light Layout

### Signe Floor Lamps (North Wall, E→W)
| Position | v1 ID | Name | v2 UUID |
|----------|-------|------|---------|
| E (east) | 17 | Signe main floor E | 457a3777-b619-4765-92a0-7292cbbaab7b |
| ME | 22 | Signe main floor ME | ca82265e-1ee9-4337-a0d4-e44b46b21b1d |
| M (middle) | 32 | Signe main floor M | d1a940ac-c385-4857-88dc-bb89ff5ddfc4 |
| MW | 31 | Signe main floor MW | 03e56936-b959-4687-b2de-5f2f670c8674 |
| W (west) | 18 | Signe main floor W | fa08b99f-aa8a-4683-af76-c0e3fd566217 |

- All are **Signe gradient floor** lights with 10 pixels, 5 gradient points capable
- Support gradient modes: interpolated_palette, interpolated_palette_mirrored, random_pixelated, segmented_palette

### Kitchen Pendant Clusters (Above Counter)
| Cluster | IDs | Zone |
|---------|-----|------|
| East | 24, 25, 29 | Kitchen East (zone 101) |
| West | 26, 27, 28 | Kitchen West (zone 102) |

- 6" frosted globe bulbs, 3 per cluster
- Look best when each cluster is uniform color (avoids "party balloon" effect)

---

## Scene Ideas to Build

### 1. Warm Sunflare (Daytime)
- **Colors**: Warm yellow → gold → warm white → warm turquoise → soft teal
- **Animation**: Slow wave W→E (30-60 sec per phase)
- **Signes**: Bottom-to-top gradient on each (warm bottom, cooler top)
- **Kitchen clusters**: Match nearby Signes

### 2. Vaporwave (Evening) ✓
- **Colors**: Hot pink → purple → cyan
- **Animation**: Vertical sine wave - colors ripple bottom→top, wave travels W→E
- **Kitchen**: Pink (west cluster), Cyan (east cluster) - static
- **Script**: `scripts/vaporwave-wave.sh`
- **Status**: Complete

### 3. Woodland Toadstool (Evening/Fun) ✓
- **Colors**: Deep rust → Amber → Forest green
- **Animation**: Vertical sine wave - colors ripple bottom→top, wave travels W→E
- **Kitchen**: Warm amber tones - static
- **Script**: `scripts/woodland-toadstool-wave.sh`
- **Status**: Complete

### 4. Romantic Pink/Orange ✓
- **Colors**: Deep pink → Coral → Warm orange
- **Animation**: Vertical sine wave across whole house
- **Rooms**: Main floor + Jamie's office + Master bedroom (incl. Twilight backs)
- **Kitchen**: Pink (west) / Orange (east) - static
- **Script**: `scripts/romantic-wave.sh`
- **Status**: Complete

### 5. Middle of the Night Pinks ✓
- **Colors**: Intense hot pink ↔ magenta (full saturation)
- **Animation**: Fast vertical wave (1.5s per phase)
- **Rooms**: Jamie's office + Master bedroom only
- **Script**: `scripts/middle-of-the-night-pinks.sh`
- **Status**: Complete

### 6. Morning Sunrise ✓
- **Colors**: Deep coral → peach → soft gold → warm white
- **Animation**: Slow wave E→W (opposite of sunset, 10s per phase)
- **Rooms**: Dining room only
- **Kitchen**: Coral (east) / Gold (west)
- **Script**: `scripts/morning-sunrise.sh`
- **Purpose**: Gentle, energizing wake-up scene
- **Status**: Complete

### 7. Deep Ocean ✓
- **Colors**: Deep teal → seafoam → pale aqua → soft white
- **Animation**: Breathing rhythm - all rooms with subtle phase offsets (8s per phase)
- **Rooms**: WHOLE HOUSE (all 32 lights)
- **Script**: `scripts/deep-ocean.sh`
- **Purpose**: Calming, meditative - focus work or relaxation
- **Status**: Complete

### 8. Candlelight Dinner ✓
- **Colors**: Warm amber → soft gold → cream (narrow warm range)
- **Animation**: Subtle flicker effect mimicking candles (1.2s per phase)
- **Rooms**: Dining room only
- **Kitchen**: Very dim (15-25%) warm amber - accent only
- **Script**: `scripts/candlelight-dinner.sh`
- **Purpose**: Sophisticated entertaining, romantic dinners
- **Status**: Complete

### 9. Nordic Twilight ✓
- **Colors**: Soft lavender → dusty rose → warm cream → pale amber
- **Animation**: Very slow drift, almost imperceptible (15s per phase)
- **Rooms**: Dining room only
- **Kitchen**: Lavender (west) / Warm cream (east)
- **Script**: `scripts/nordic-twilight.sh`
- **Purpose**: Cozy hygge-style relaxation before bed
- **Status**: Complete

---

## Animation Techniques

### Wave Effect (W→E across Signes)
- Phase offset for each light creates traveling wave
- Each Signe shows bottom-to-top gradient
- Colors shift together but staggered in time
- Speed: Demo at 1.5s, production at 5-10s per phase

### v2 API Gradient Control
```json
{
  "gradient": {
    "points": [
      {"color": {"xy": {"x": 0.5, "y": 0.45}}},   // bottom
      {"color": {"xy": {"x": 0.4, "y": 0.38}}},   // middle
      {"color": {"xy": {"x": 0.22, "y": 0.32}}}   // top
    ]
  },
  "dynamics": {"duration": 2000}
}
```

---

## Next Steps
- [ ] Finalize Warm Sunflare animation speed
- [ ] Test Vaporwave look
- [ ] Test Woodland Toadstool look
- [ ] Test Romantic Pink/Orange look
- [ ] Create saved scenes for each
- [ ] Set up automation schedules
