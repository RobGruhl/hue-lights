# Modular Scene System

Mix and match any palette with any animation on any room(s).

## Quick Start

```bash
./scripts/run-scene.sh <palette> <animation> <room> [room2] [room3] ...
```

## Examples

```bash
# Deep ocean breathing across the whole house
./scripts/run-scene.sh ocean breathing whole-house

# Vaporwave wave on dining room and Jamie's office
./scripts/run-scene.sh vaporwave wave dining jamies-office

# Candlelight flicker just on the Signes (no kitchen)
./scripts/run-scene.sh candle flicker dining-signes-only

# Nordic twilight drift in bedrooms
./scripts/run-scene.sh nordic drift master-bedroom jordans-room kestons-room

# Aurora northern lights pulse for a party
./scripts/run-scene.sh aurora pulse whole-house

# Static sunrise colors in dining room (no animation)
./scripts/run-scene.sh sunrise static dining
```

---

## Available Palettes

| Palette | Description | Best For |
|---------|-------------|----------|
| `sunflare` | Warm yellow → teal | Daytime, bright work |
| `vaporwave` | Pink → purple → cyan | Evening, 80s vibes |
| `toadstool` | Rust → amber → forest | Cozy evening |
| `romantic` | Pink → coral → orange | Date night |
| `midnight` | Hot pink ↔ magenta | Late night intensity |
| `sunrise` | Coral → peach → gold | Morning wake-up |
| `ocean` | Deep teal → seafoam → aqua | Calming, focus |
| `candle` | Warm amber variations | Dinner parties |
| `nordic` | Lavender → rose → cream | Hygge, relaxation |
| `aurora` | Green → purple → blue | Northern lights |
| `fire` | Deep reds → oranges | Fireplace warmth |

---

## Available Animations

| Animation | Speed | Description |
|-----------|-------|-------------|
| `wave` | 5s/step | Horizontal scroll across lights |
| `breathing` | 8s/step | Synchronized pulsing with subtle offsets |
| `flicker` | 1.2s/step | Randomized candle-like variations |
| `drift` | 15s/step | Very slow, almost imperceptible |
| `pulse` | 1.5s/step | Fast synchronized (parties) |
| `static` | One-time | Set colors once, no animation |

---

## Available Rooms

| Room | Lights | Description |
|------|--------|-------------|
| `dining` | 11 | Main floor Signes + kitchen pendants |
| `dining-signes-only` | 5 | Just the 5 Signe floor lamps |
| `kitchen` | 6 | Just the 6 kitchen pendants |
| `jamies-office` | 4 | 2 Signes + 2 Plays |
| `master-bedroom` | 8 | 4 Signes + 4 Twilights |
| `master-bath` | 1 | Master bathroom Signe |
| `jordans-room` | 3 | Signe + Back + Front |
| `kestons-room` | 3 | Signe + Back + Front |
| `tv-room` | 1 | TV lightstrip |
| `balcony` | 1 | Festavia globe lights |
| `whole-house` | 32 | All lights |
| `adults-only` | 23 | Dining + Jamie's + Master suite |
| `bedrooms` | 14 | All bedrooms |

---

## Combining Multiple Rooms

Just list them after the animation:

```bash
# Two rooms
./scripts/run-scene.sh vaporwave wave dining jamies-office

# Three rooms
./scripts/run-scene.sh romantic pulse master-bedroom jordans-room kestons-room

# Custom combo
./scripts/run-scene.sh ocean breathing dining master-bedroom balcony
```

---

## Listing Options

```bash
./scripts/run-scene.sh --list palettes
./scripts/run-scene.sh --list animations
./scripts/run-scene.sh --list rooms
./scripts/run-scene.sh --help
```

---

## File Structure

```
scripts/
├── run-scene.sh          # Main runner
├── lib/
│   ├── rooms.sh          # Room definitions (light UUIDs)
│   ├── palettes.sh       # Color palettes (11 palettes)
│   └── animations.sh     # Animation patterns (6 animations)
└── [legacy scripts]      # Original single-purpose scripts
```

---

## Adding New Palettes

Edit `scripts/lib/palettes.sh`:

```bash
# Add three parallel arrays for your palette
P_MYPALETTE_X=(0.50 0.45 0.40 ...)  # X coordinates
P_MYPALETTE_Y=(0.35 0.38 0.42 ...)  # Y coordinates
P_MYPALETTE_B=(100 95 90 ...)       # Brightness values
```

Then update the `list_palettes` function.

---

## Adding New Rooms

Edit `scripts/lib/rooms.sh`:

1. Define light arrays at the top
2. Add a case in `get_room_lights()` function
3. Update `list_rooms()` function

---

## Tips

- **Ctrl+C** stops any running animation
- Use `static` animation to set colors without continuous animation
- Combine `dining-signes-only` with separate kitchen control for more flexibility
- The `adults-only` room group excludes kids' rooms
- Gradient lights get full 5-point gradients; solid lights get single colors
