#!/bin/bash
# Color palettes - XY coordinates and brightness values
# Source this file to get palette arrays

# Palettes are defined as parallel arrays:
#   P_<name>_X  - X coordinates
#   P_<name>_Y  - Y coordinates
#   P_<name>_B  - Brightness values (0-100)

# =============================================================================
# WARM SUNFLARE - Daytime brightness, warm yellow to teal
# =============================================================================
P_SUNFLARE_X=(0.52 0.50 0.47 0.44 0.40 0.36 0.32 0.28 0.24 0.20 0.18 0.20)
P_SUNFLARE_Y=(0.41 0.42 0.42 0.41 0.40 0.39 0.38 0.37 0.36 0.35 0.37 0.36)
P_SUNFLARE_B=(80   85   88   90   92   95   98   100  100  100  100  100)

# =============================================================================
# VAPORWAVE - 80s aesthetic pink/purple/cyan
# =============================================================================
P_VAPORWAVE_X=(0.45 0.42 0.38 0.34 0.30 0.25 0.20 0.16 0.15 0.18 0.25 0.35)
P_VAPORWAVE_Y=(0.22 0.20 0.17 0.15 0.14 0.13 0.14 0.20 0.28 0.32 0.25 0.20)
P_VAPORWAVE_B=(100  100  100  100  100  100  100  100  100  100  100  100)

# =============================================================================
# WOODLAND TOADSTOOL - Cozy rust/amber/forest green
# =============================================================================
P_TOADSTOOL_X=(0.60 0.58 0.55 0.52 0.48 0.45 0.42 0.38 0.35 0.33 0.36 0.45)
P_TOADSTOOL_Y=(0.35 0.38 0.40 0.42 0.44 0.47 0.50 0.52 0.54 0.52 0.45 0.40)
P_TOADSTOOL_B=(100  100  95   90   90   90   95   100  100  100  100  100)

# =============================================================================
# ROMANTIC - Intense pink/coral/orange
# =============================================================================
P_ROMANTIC_X=(0.50 0.52 0.54 0.56 0.57 0.58 0.57 0.56 0.54 0.52 0.50 0.48)
P_ROMANTIC_Y=(0.25 0.28 0.30 0.32 0.34 0.36 0.38 0.40 0.38 0.35 0.30 0.26)
P_ROMANTIC_B=(100  100  100  100  100  95   90   85   90   95   100  100)

# =============================================================================
# MIDNIGHT PINK - Intense magenta/hot pink (for late night)
# =============================================================================
P_MIDNIGHT_X=(0.45 0.42 0.38 0.35 0.32 0.30 0.32 0.36 0.40 0.44 0.46 0.45)
P_MIDNIGHT_Y=(0.20 0.17 0.15 0.14 0.15 0.18 0.20 0.18 0.16 0.17 0.19 0.20)
P_MIDNIGHT_B=(100  100  100  100  100  100  100  100  100  100  100  100)

# =============================================================================
# MORNING SUNRISE - Gentle coral/peach/gold for waking up
# =============================================================================
P_SUNRISE_X=(0.58 0.55 0.52 0.50 0.48 0.45 0.42 0.40 0.42 0.45 0.50 0.54)
P_SUNRISE_Y=(0.35 0.38 0.40 0.42 0.43 0.43 0.42 0.40 0.38 0.36 0.34 0.33)
P_SUNRISE_B=(100  95   90   85   85   85   90   95   100  100  100  100)

# =============================================================================
# DEEP OCEAN - Calming teals and aquas
# =============================================================================
P_OCEAN_X=(0.16 0.18 0.20 0.23 0.26 0.28 0.30 0.28 0.25 0.22 0.19 0.17)
P_OCEAN_Y=(0.32 0.34 0.36 0.37 0.38 0.37 0.36 0.35 0.34 0.33 0.32 0.31)
P_OCEAN_B=(100  100  100  100  95   90   85   90   95   100  100  100)

# =============================================================================
# CANDLELIGHT - Warm amber flicker tones
# =============================================================================
P_CANDLE_X=(0.54 0.52 0.55 0.53 0.51 0.54 0.52 0.55 0.53 0.50 0.54 0.52)
P_CANDLE_Y=(0.41 0.42 0.40 0.43 0.42 0.41 0.43 0.42 0.41 0.44 0.40 0.43)
P_CANDLE_B=(75   85   70   90   80   75   85   70   80   90   75   85)

# =============================================================================
# NORDIC TWILIGHT - Cozy lavender/rose/cream
# =============================================================================
P_NORDIC_X=(0.34 0.38 0.42 0.44 0.46 0.48 0.46 0.44 0.42 0.40 0.38 0.36)
P_NORDIC_Y=(0.28 0.30 0.34 0.36 0.38 0.40 0.41 0.39 0.36 0.33 0.30 0.28)
P_NORDIC_B=(70   75   80   85   85   85   85   80   75   70   70   70)

# =============================================================================
# AURORA - Northern lights inspired (green/purple/blue)
# =============================================================================
P_AURORA_X=(0.30 0.28 0.25 0.22 0.20 0.22 0.28 0.32 0.35 0.32 0.28 0.25)
P_AURORA_Y=(0.55 0.50 0.40 0.30 0.20 0.15 0.18 0.22 0.30 0.40 0.48 0.52)
P_AURORA_B=(100  100  100  100  100  100  100  100  100  100  100  100)

# =============================================================================
# FIREPLACE - Deep reds and oranges
# =============================================================================
P_FIRE_X=(0.65 0.62 0.60 0.58 0.55 0.58 0.62 0.65 0.63 0.60 0.57 0.60)
P_FIRE_Y=(0.33 0.35 0.38 0.40 0.42 0.40 0.36 0.33 0.32 0.35 0.38 0.36)
P_FIRE_B=(80   90   100  90   80   70   85   95   90   85   75   80)

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

# Load a palette into the active arrays (CX, CY, CB)
load_palette() {
    local palette=$1

    # Use eval for shell compatibility (bash and zsh)
    eval "CX=(\"\${P_${palette}_X[@]}\")"
    eval "CY=(\"\${P_${palette}_Y[@]}\")"
    eval "CB=(\"\${P_${palette}_B[@]}\")"
    PALETTE_LEN=${#CX[@]}

    if [[ $PALETTE_LEN -eq 0 ]]; then
        echo "Unknown palette: $palette" >&2
        return 1
    fi
}

# Get a color at a specific phase
get_color() {
    local phase=$1
    local idx=$(( phase % PALETTE_LEN ))
    echo "${CX[$idx]} ${CY[$idx]} ${CB[$idx]}"
}

# List available palettes
list_palettes() {
    echo "Available palettes:"
    echo "  SUNFLARE   - Warm yellow to teal (daytime)"
    echo "  VAPORWAVE  - Pink/purple/cyan (80s evening)"
    echo "  TOADSTOOL  - Rust/amber/forest (cozy evening)"
    echo "  ROMANTIC   - Pink/coral/orange (intense romantic)"
    echo "  MIDNIGHT   - Hot pink/magenta (late night)"
    echo "  SUNRISE    - Coral/peach/gold (morning wake-up)"
    echo "  OCEAN      - Deep teal/seafoam/aqua (calming)"
    echo "  CANDLE     - Warm amber variations (dinner)"
    echo "  NORDIC     - Lavender/rose/cream (hygge)"
    echo "  AURORA     - Green/purple/blue (northern lights)"
    echo "  FIRE       - Deep reds/oranges (fireplace)"
}
