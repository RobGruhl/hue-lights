#!/bin/bash
# Morning Sunrise - Gentle wake-up scene for dining room
# Colors flow E→W (opposite of sunset) - deep coral → peach → soft gold → warm white

source "$(dirname "$0")/../.env"

# Main floor Signes (E→W order for sunrise direction)
SIGNES=(
    "457a3777-b619-4765-92a0-7292cbbaab7b"   # E (Signe main floor front)
    "ca82265e-1ee9-4337-a0d4-e44b46b21b1d"   # ME (Signe kitchen)
    "d1a940ac-c385-4857-88dc-bb89ff5ddfc4"   # M (Signe kitchen table)
    "03e56936-b959-4687-b2de-5f2f670c8674"   # MW (Signe couch corner)
    "fa08b99f-aa8a-4683-af76-c0e3fd566217"   # W (Signe dining table)
)

# Kitchen pendants
KITCHEN_EAST=("dd90028e-5494-4585-9a75-cb593d1275ec" "7fabbbed-4222-4bf4-baee-64977ebc5dde" "f95f8da4-3dd0-4f80-91a5-ca8ad1a7ff22")
KITCHEN_WEST=("ca9107e3-4f2c-4383-bf1a-67ae0765bbdf" "52e22f83-a8c0-4ede-9a5e-68801c8c69f7" "bd5ef4f9-7258-4ee8-af97-851b9713c147")

# Sunrise palette - warm coral → peach → gold → warm white (with brightness compensation)
# Yellows dimmed slightly, corals boosted for perceptual balance
declare -a CX=(0.58 0.55 0.52 0.50 0.48 0.45 0.42 0.40 0.42 0.45 0.50 0.54)
declare -a CY=(0.35 0.38 0.40 0.42 0.43 0.43 0.42 0.40 0.38 0.36 0.34 0.33)
declare -a CB=(100  95   90   85   85   85   90   95   100  100  100  100)

PALETTE_LEN=${#CX[@]}

# Position offsets for E→W scroll (proportional to physical spacing)
# E→ME=9', ME→M=7', M→MW=4', MW→W=11.5' (reversed from W→E)
POS_OFFSETS=(0 2 4 5 7)

set_gradient_light() {
    local id=$1
    local phase=$2
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
      ]},\"dynamics\":{\"duration\":8000},\"dimming\":{\"brightness\":100}}" > /dev/null 2>&1
}

set_solid_light() {
    local id=$1
    local phase=$2
    local p=$(( phase % PALETTE_LEN ))
    curl -sk -X PUT "https://$HUE_BRIDGE/clip/v2/resource/light/$id" \
      -H "hue-application-key: $HUE_USER" \
      -H "Content-Type: application/json" \
      -d "{\"color\":{\"xy\":{\"x\":${CX[$p]},\"y\":${CY[$p]}}},\"dimming\":{\"brightness\":${CB[$p]}},\"dynamics\":{\"duration\":8000}}" > /dev/null 2>&1
}

echo "MORNING SUNRISE: Gentle wake-up (E→W flow)"
echo "Press Ctrl+C to stop"

phase=0
while true; do
    # Signes with position-based offsets (E→W direction)
    for i in 0 1 2 3 4; do
        signe_phase=$(( (phase + ${POS_OFFSETS[$i]}) % PALETTE_LEN ))
        set_gradient_light "${SIGNES[$i]}" "$signe_phase" &
    done

    # Kitchen - East gets coral tones, West gets gold tones
    for id in "${KITCHEN_EAST[@]}"; do
        set_solid_light "$id" $(( (phase + 1) % PALETTE_LEN )) &
    done
    for id in "${KITCHEN_WEST[@]}"; do
        set_solid_light "$id" $(( (phase + 6) % PALETTE_LEN )) &
    done

    wait
    phase=$(( (phase + 1) % PALETTE_LEN ))
    sleep 10
done
