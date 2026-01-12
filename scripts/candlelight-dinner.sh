#!/bin/bash
# Candlelight Dinner - Sophisticated entertaining scene
# Warm amber tones with subtle flicker effect mimicking candles
# Kitchen lights very low to let Signes be the stars

source "$(dirname "$0")/../.env"

# Main floor Signes (W→E)
SIGNES=(
    "fa08b99f-aa8a-4683-af76-c0e3fd566217"   # W
    "03e56936-b959-4687-b2de-5f2f670c8674"   # MW
    "d1a940ac-c385-4857-88dc-bb89ff5ddfc4"   # M
    "ca82265e-1ee9-4337-a0d4-e44b46b21b1d"   # ME
    "457a3777-b619-4765-92a0-7292cbbaab7b"   # E
)

# Kitchen pendants (very dim)
KITCHEN=("dd90028e-5494-4585-9a75-cb593d1275ec" "7fabbbed-4222-4bf4-baee-64977ebc5dde" "f95f8da4-3dd0-4f80-91a5-ca8ad1a7ff22" "ca9107e3-4f2c-4383-bf1a-67ae0765bbdf" "52e22f83-a8c0-4ede-9a5e-68801c8c69f7" "bd5ef4f9-7258-4ee8-af97-851b9713c147")

# Candlelight palette - narrow warm amber range with brightness variations
# Simulates flickering by varying brightness and subtle color shifts
declare -a CX=(0.54 0.52 0.55 0.53 0.51 0.54 0.52 0.55 0.53 0.50 0.54 0.52)
declare -a CY=(0.41 0.42 0.40 0.43 0.42 0.41 0.43 0.42 0.41 0.44 0.40 0.43)
declare -a CB=(75   85   70   90   80   75   85   70   80   90   75   85)

PALETTE_LEN=${#CX[@]}

set_gradient_light() {
    local id=$1
    local phase=$2
    # Each light gets slightly different phase for organic flicker
    local offset=$(( RANDOM % 3 ))
    local p0=$(( (phase + offset) % PALETTE_LEN ))
    local p1=$(( (phase + offset + 2) % PALETTE_LEN ))
    local p2=$(( (phase + offset + 4) % PALETTE_LEN ))
    local p3=$(( (phase + offset + 6) % PALETTE_LEN ))
    local p4=$(( (phase + offset + 8) % PALETTE_LEN ))

    curl -sk -X PUT "https://$HUE_BRIDGE/clip/v2/resource/light/$id" \
      -H "hue-application-key: $HUE_USER" \
      -H "Content-Type: application/json" \
      -d "{\"gradient\":{\"points\":[
        {\"color\":{\"xy\":{\"x\":${CX[$p0]},\"y\":${CY[$p0]}}},\"dimming\":{\"brightness\":${CB[$p0]}}},
        {\"color\":{\"xy\":{\"x\":${CX[$p1]},\"y\":${CY[$p1]}}},\"dimming\":{\"brightness\":${CB[$p1]}}},
        {\"color\":{\"xy\":{\"x\":${CX[$p2]},\"y\":${CY[$p2]}}},\"dimming\":{\"brightness\":${CB[$p2]}}},
        {\"color\":{\"xy\":{\"x\":${CX[$p3]},\"y\":${CY[$p3]}}},\"dimming\":{\"brightness\":${CB[$p3]}}},
        {\"color\":{\"xy\":{\"x\":${CX[$p4]},\"y\":${CY[$p4]}}},\"dimming\":{\"brightness\":${CB[$p4]}}}
      ]},\"dynamics\":{\"duration\":800},\"dimming\":{\"brightness\":80}}" > /dev/null 2>&1
}

set_kitchen_dim() {
    local id=$1
    # Kitchen stays very dim warm amber - subtle presence
    local bri=$(( 15 + RANDOM % 10 ))  # 15-25% brightness
    curl -sk -X PUT "https://$HUE_BRIDGE/clip/v2/resource/light/$id" \
      -H "hue-application-key: $HUE_USER" \
      -H "Content-Type: application/json" \
      -d "{\"color\":{\"xy\":{\"x\":0.52,\"y\":0.42}},\"dimming\":{\"brightness\":$bri},\"dynamics\":{\"duration\":2000}}" > /dev/null 2>&1
}

echo "CANDLELIGHT DINNER: Sophisticated ambiance with flicker"
echo "Press Ctrl+C to stop"

# Set kitchen lights dim initially
for id in "${KITCHEN[@]}"; do
    set_kitchen_dim "$id" &
done
wait

phase=0
while true; do
    # Signes flicker independently
    for id in "${SIGNES[@]}"; do
        set_gradient_light "$id" "$phase" &
    done

    # Kitchen gets occasional subtle brightness adjustment
    if (( phase % 4 == 0 )); then
        for id in "${KITCHEN[@]}"; do
            set_kitchen_dim "$id" &
        done
    fi

    wait
    phase=$(( (phase + 1) % PALETTE_LEN ))
    sleep 1.2  # Fast-ish for flicker effect
done
