#!/bin/bash
# Animation patterns - timing and movement functions
# Source this file along with rooms.sh and palettes.sh

# Requires: HUE_BRIDGE, HUE_USER, and palette loaded (CX, CY, CB, PALETTE_LEN)

# =============================================================================
# CORE API FUNCTIONS
# =============================================================================

# Set a gradient light (5 points, bottom to top)
set_gradient() {
    local id=$1
    local phase=$2
    local duration=${3:-3000}
    local brightness=${4:-100}

    local p0=$(( phase % PALETTE_LEN ))
    local p1=$(( (phase + 2) % PALETTE_LEN ))
    local p2=$(( (phase + 4) % PALETTE_LEN ))
    local p3=$(( (phase + 6) % PALETTE_LEN ))
    local p4=$(( (phase + 8) % PALETTE_LEN ))

    curl -sk -X PUT "https://$HUE_BRIDGE/clip/v2/resource/light/$id" \
      -H "hue-application-key: $HUE_USER" \
      -H "Content-Type: application/json" \
      -d "{\"gradient\":{\"points\":[
        {\"color\":{\"xy\":{\"x\":${CX[$p0]},\"y\":${CY[$p0]}}},\"dimming\":{\"brightness\":${CB[$p0]}}},
        {\"color\":{\"xy\":{\"x\":${CX[$p1]},\"y\":${CY[$p1]}}},\"dimming\":{\"brightness\":${CB[$p1]}}},
        {\"color\":{\"xy\":{\"x\":${CX[$p2]},\"y\":${CY[$p2]}}},\"dimming\":{\"brightness\":${CB[$p2]}}},
        {\"color\":{\"xy\":{\"x\":${CX[$p3]},\"y\":${CY[$p3]}}},\"dimming\":{\"brightness\":${CB[$p3]}}},
        {\"color\":{\"xy\":{\"x\":${CX[$p4]},\"y\":${CY[$p4]}}},\"dimming\":{\"brightness\":${CB[$p4]}}}
      ]},\"dynamics\":{\"duration\":$duration},\"dimming\":{\"brightness\":$brightness}}" > /dev/null 2>&1
}

# Set a solid color light
set_solid() {
    local id=$1
    local phase=$2
    local duration=${3:-3000}
    local brightness_override=$4

    local p=$(( phase % PALETTE_LEN ))
    local bri=${brightness_override:-${CB[$p]}}

    curl -sk -X PUT "https://$HUE_BRIDGE/clip/v2/resource/light/$id" \
      -H "hue-application-key: $HUE_USER" \
      -H "Content-Type: application/json" \
      -d "{\"color\":{\"xy\":{\"x\":${CX[$p]},\"y\":${CY[$p]}}},\"dimming\":{\"brightness\":$bri},\"dynamics\":{\"duration\":$duration}}" > /dev/null 2>&1
}

# =============================================================================
# ANIMATION: WAVE
# Horizontal scroll across lights (W→E or E→W)
# =============================================================================

# Animation config
WAVE_STEP_TIME=5          # Seconds per animation step
WAVE_TRANSITION=3000      # Transition duration in ms

run_wave() {
    local lights=("$@")
    local phase=0
    local light_count=${#lights[@]}

    echo "Running WAVE animation on $light_count lights"
    echo "Press Ctrl+C to stop"

    while true; do
        local idx=0
        for light in "${lights[@]}"; do
            local type="${light%%:*}"
            local id="${light#*:}"
            local light_phase=$(( (phase + idx * 2) % PALETTE_LEN ))

            if [[ "$type" == "gradient" ]]; then
                set_gradient "$id" "$light_phase" "$WAVE_TRANSITION" &
            else
                set_solid "$id" "$light_phase" "$WAVE_TRANSITION" &
            fi
            ((idx++))
        done
        wait
        phase=$(( (phase + 1) % PALETTE_LEN ))
        sleep "$WAVE_STEP_TIME"
    done
}

# =============================================================================
# ANIMATION: BREATHING
# Synchronized pulsing with subtle phase offsets per room
# =============================================================================

BREATHING_STEP_TIME=8     # Seconds per breath cycle step
BREATHING_TRANSITION=6000

run_breathing() {
    local lights=("$@")
    local phase=0
    local light_count=${#lights[@]}

    echo "Running BREATHING animation on $light_count lights"
    echo "Press Ctrl+C to stop"

    while true; do
        local idx=0
        for light in "${lights[@]}"; do
            local type="${light%%:*}"
            local id="${light#*:}"
            # Subtle offset based on position (creates gentle wave effect)
            local light_phase=$(( (phase + idx / 3) % PALETTE_LEN ))

            if [[ "$type" == "gradient" ]]; then
                set_gradient "$id" "$light_phase" "$BREATHING_TRANSITION" &
            else
                set_solid "$id" "$light_phase" "$BREATHING_TRANSITION" &
            fi
            ((idx++))
        done
        wait
        phase=$(( (phase + 1) % PALETTE_LEN ))
        sleep "$BREATHING_STEP_TIME"
    done
}

# =============================================================================
# ANIMATION: FLICKER
# Randomized candle-like variations
# =============================================================================

FLICKER_STEP_TIME=1.2
FLICKER_TRANSITION=800

run_flicker() {
    local lights=("$@")
    local phase=0
    local light_count=${#lights[@]}

    echo "Running FLICKER animation on $light_count lights"
    echo "Press Ctrl+C to stop"

    while true; do
        for light in "${lights[@]}"; do
            local type="${light%%:*}"
            local id="${light#*:}"
            # Random offset for organic flicker
            local offset=$(( RANDOM % 4 ))
            local light_phase=$(( (phase + offset) % PALETTE_LEN ))

            if [[ "$type" == "gradient" ]]; then
                set_gradient "$id" "$light_phase" "$FLICKER_TRANSITION" 80 &
            else
                # Solid lights flicker more dramatically
                local bri=$(( 60 + RANDOM % 35 ))
                set_solid "$id" "$light_phase" "$FLICKER_TRANSITION" "$bri" &
            fi
        done
        wait
        phase=$(( (phase + 1) % PALETTE_LEN ))
        sleep "$FLICKER_STEP_TIME"
    done
}

# =============================================================================
# ANIMATION: DRIFT
# Very slow, almost imperceptible movement (hygge/relaxation)
# =============================================================================

DRIFT_STEP_TIME=15
DRIFT_TRANSITION=12000

run_drift() {
    local lights=("$@")
    local phase=0
    local light_count=${#lights[@]}

    echo "Running DRIFT animation on $light_count lights (very slow)"
    echo "Press Ctrl+C to stop"

    while true; do
        local idx=0
        for light in "${lights[@]}"; do
            local type="${light%%:*}"
            local id="${light#*:}"
            local light_phase=$(( (phase + idx) % PALETTE_LEN ))

            if [[ "$type" == "gradient" ]]; then
                set_gradient "$id" "$light_phase" "$DRIFT_TRANSITION" 75 &
            else
                set_solid "$id" "$light_phase" "$DRIFT_TRANSITION" &
            fi
            ((idx++))
        done
        wait
        phase=$(( (phase + 1) % PALETTE_LEN ))
        sleep "$DRIFT_STEP_TIME"
    done
}

# =============================================================================
# ANIMATION: PULSE
# Fast synchronized pulse (good for parties)
# =============================================================================

PULSE_STEP_TIME=1.5
PULSE_TRANSITION=1200

run_pulse() {
    local lights=("$@")
    local phase=0
    local light_count=${#lights[@]}

    echo "Running PULSE animation on $light_count lights (fast)"
    echo "Press Ctrl+C to stop"

    while true; do
        for light in "${lights[@]}"; do
            local type="${light%%:*}"
            local id="${light#*:}"

            if [[ "$type" == "gradient" ]]; then
                set_gradient "$id" "$phase" "$PULSE_TRANSITION" &
            else
                set_solid "$id" "$phase" "$PULSE_TRANSITION" &
            fi
        done
        wait
        phase=$(( (phase + 1) % PALETTE_LEN ))
        sleep "$PULSE_STEP_TIME"
    done
}

# =============================================================================
# ANIMATION: STATIC
# No movement - just set all lights to a fixed palette position
# =============================================================================

run_static() {
    local lights=("$@")
    local light_count=${#lights[@]}

    echo "Setting STATIC colors on $light_count lights"

    local idx=0
    for light in "${lights[@]}"; do
        local type="${light%%:*}"
        local id="${light#*:}"
        # Spread colors evenly across lights
        local light_phase=$(( idx * PALETTE_LEN / light_count ))

        if [[ "$type" == "gradient" ]]; then
            set_gradient "$id" "$light_phase" 2000 &
        else
            set_solid "$id" "$light_phase" 2000 &
        fi
        ((idx++))
    done
    wait
    echo "Done. Lights set to static colors."
}

# =============================================================================
# HELPER: Run an animation by name
# =============================================================================

run_animation() {
    local animation=$1
    shift
    local lights=("$@")

    case "$animation" in
        wave)      run_wave "${lights[@]}" ;;
        breathing) run_breathing "${lights[@]}" ;;
        flicker)   run_flicker "${lights[@]}" ;;
        drift)     run_drift "${lights[@]}" ;;
        pulse)     run_pulse "${lights[@]}" ;;
        static)    run_static "${lights[@]}" ;;
        *)
            echo "Unknown animation: $animation" >&2
            echo "Available: wave, breathing, flicker, drift, pulse, static" >&2
            return 1
            ;;
    esac
}

# List available animations
list_animations() {
    echo "Available animations:"
    echo "  wave      - Horizontal scroll across lights (5s/step)"
    echo "  breathing - Synchronized pulsing with subtle offsets (8s/step)"
    echo "  flicker   - Randomized candle-like variations (1.2s/step)"
    echo "  drift     - Very slow, almost imperceptible (15s/step)"
    echo "  pulse     - Fast synchronized pulse for parties (1.5s/step)"
    echo "  static    - Set colors once, no animation"
}
