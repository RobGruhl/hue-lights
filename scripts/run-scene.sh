#!/bin/bash
# run-scene.sh - Modular scene runner
# Usage: ./run-scene.sh <palette> <animation> <room> [room2] [room3] ...
#
# Examples:
#   ./run-scene.sh ocean breathing whole-house
#   ./run-scene.sh vaporwave wave dining
#   ./run-scene.sh nordic drift master-bedroom jamies-office
#   ./run-scene.sh candle flicker dining
#
# Use --list to see available options:
#   ./run-scene.sh --list palettes
#   ./run-scene.sh --list animations
#   ./run-scene.sh --list rooms

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Load environment
if [[ -f "$SCRIPT_DIR/../.env" ]]; then
    source "$SCRIPT_DIR/../.env"
elif [[ -f "$SCRIPT_DIR/.env" ]]; then
    source "$SCRIPT_DIR/.env"
else
    echo "Error: .env file not found" >&2
    exit 1
fi

# Load libraries
source "$SCRIPT_DIR/lib/rooms.sh"
source "$SCRIPT_DIR/lib/palettes.sh"
source "$SCRIPT_DIR/lib/animations.sh"

# =============================================================================
# HELP / LIST
# =============================================================================

show_help() {
    cat <<EOF
Usage: $(basename "$0") <palette> <animation> <room> [room2] [room3] ...

Run a lighting scene by combining a color palette, animation style, and rooms.

Arguments:
  palette    - Color palette to use (e.g., ocean, vaporwave, nordic)
  animation  - Animation pattern (e.g., wave, breathing, drift)
  room       - One or more rooms to apply the scene to

Options:
  --list palettes    Show available color palettes
  --list animations  Show available animation patterns
  --list rooms       Show available rooms
  --help, -h         Show this help message

Examples:
  $(basename "$0") ocean breathing whole-house
  $(basename "$0") vaporwave wave dining jamies-office
  $(basename "$0") candle flicker dining
  $(basename "$0") nordic drift master-bedroom

Tips:
  - Combine multiple rooms: just list them after the animation
  - Use 'static' animation for no movement
  - Use Ctrl+C to stop running animations
EOF
}

# Handle --list and --help
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    show_help
    exit 0
fi

if [[ "$1" == "--list" ]]; then
    case "$2" in
        palettes|palette|p)
            list_palettes
            ;;
        animations|animation|a)
            list_animations
            ;;
        rooms|room|r)
            list_rooms
            ;;
        *)
            echo "Usage: $(basename "$0") --list [palettes|animations|rooms]"
            exit 1
            ;;
    esac
    exit 0
fi

# =============================================================================
# PARSE ARGUMENTS
# =============================================================================

if [[ $# -lt 3 ]]; then
    echo "Error: Missing arguments" >&2
    echo "Usage: $(basename "$0") <palette> <animation> <room> [room2] ..." >&2
    echo "Use --help for more information" >&2
    exit 1
fi

PALETTE=$(echo "$1" | tr '[:lower:]' '[:upper:]')  # Uppercase for palette lookup
ANIMATION="$2"
shift 2
ROOMS=("$@")

# =============================================================================
# LOAD PALETTE
# =============================================================================

echo "Loading palette: $PALETTE"
if ! load_palette "$PALETTE"; then
    echo "" >&2
    list_palettes >&2
    exit 1
fi
echo "  Loaded $PALETTE_LEN colors"

# =============================================================================
# COLLECT LIGHTS FROM ALL ROOMS
# =============================================================================

echo "Collecting lights from rooms: ${ROOMS[*]}"
ALL_LIGHTS=()

for room in "${ROOMS[@]}"; do
    room_lights=$(get_room_lights "$room")
    if [[ $? -ne 0 ]]; then
        echo "" >&2
        list_rooms >&2
        exit 1
    fi
    while IFS= read -r light; do
        [[ -n "$light" ]] && ALL_LIGHTS+=("$light")
    done <<< "$room_lights"
done

LIGHT_COUNT=${#ALL_LIGHTS[@]}
if [[ $LIGHT_COUNT -eq 0 ]]; then
    echo "Error: No lights found in specified rooms" >&2
    exit 1
fi

echo "  Found $LIGHT_COUNT lights"

# Count gradient vs solid
GRADIENT_COUNT=0
SOLID_COUNT=0
for light in "${ALL_LIGHTS[@]}"; do
    if [[ "${light%%:*}" == "gradient" ]]; then
        ((GRADIENT_COUNT++))
    else
        ((SOLID_COUNT++))
    fi
done
echo "  Gradient: $GRADIENT_COUNT, Solid: $SOLID_COUNT"

# =============================================================================
# RUN ANIMATION
# =============================================================================

echo ""
echo "Starting: $PALETTE + $ANIMATION on ${ROOMS[*]}"
echo "================================================"
echo ""

run_animation "$ANIMATION" "${ALL_LIGHTS[@]}"
