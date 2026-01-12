#!/bin/bash
# Warm Sunflare Scroll Animation
# Scrolls warm color bands W→E across Signes + Kitchen clusters
# Both warm yellow and teal always visible in room

HUE_BRIDGE="192.168.1.209"
HUE_USER="afWtQvMRm2Chj0G8nU7NS9bkKBAEKXd0JNm2QafC"

# All lights W→E with positions:
# Signe W (18): 0'
# Kitchen W (zone 102): 2'
# Kitchen E (zone 101): 5.5'
# Signe MW (31): 11.5'
# Signe M (32): 15.5'
# Signe ME (22): 22.5'
# Signe E (17): 31.5'

LIGHT_IDS=("18" "102" "101" "31" "32" "22" "17")
LIGHT_TYPES=("light" "group" "group" "light" "light" "light" "light")
POS_OFFSETS=(0 1 2 4 5 7 10)  # proportional to physical positions

# Warm palette - orange/yellow through warm teal and back
PALETTE=(
    "8000,230"    # warm orange-yellow
    "10000,200"   # gold
    "14000,140"   # warm cream
    "22000,120"   # warm green
    "30000,140"   # warm teal
    "34000,160"   # teal-blue
    "30000,140"   # warm teal
    "22000,120"   # warm green
    "14000,140"   # warm cream
    "10000,200"   # gold
)

PALETTE_LEN=${#PALETTE[@]}

# Configurable speed (seconds per step)
STEP_DELAY=${1:-5}  # default 5 seconds, pass arg to change
TRANSITION=$((STEP_DELAY * 7))  # transition time in deciseconds

set_light() {
    local id=$1
    local type=$2
    local hue=$3
    local sat=$4

    if [ "$type" = "group" ]; then
        curl -s -X PUT "http://$HUE_BRIDGE/api/$HUE_USER/groups/$id/action" \
            -d "{\"on\":true, \"hue\":$hue, \"sat\":$sat, \"bri\":254, \"transitiontime\":$TRANSITION}" > /dev/null
    else
        curl -s -X PUT "http://$HUE_BRIDGE/api/$HUE_USER/lights/$id/state" \
            -d "{\"on\":true, \"hue\":$hue, \"sat\":$sat, \"bri\":254, \"transitiontime\":$TRANSITION}" > /dev/null
    fi
}

echo "Warm Sunflare Scroll - W→E (${STEP_DELAY}s per step)"
echo "Ctrl+C to stop"

offset=0
while true; do
    for i in 0 1 2 3 4 5 6; do
        palette_idx=$(( (offset + POS_OFFSETS[$i]) % PALETTE_LEN ))
        IFS=',' read -r hue sat <<< "${PALETTE[$palette_idx]}"
        set_light "${LIGHT_IDS[$i]}" "${LIGHT_TYPES[$i]}" "$hue" "$sat" &
    done
    wait

    offset=$(( (offset + 1) % PALETTE_LEN ))
    sleep "$STEP_DELAY"
done
