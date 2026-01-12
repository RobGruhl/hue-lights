#!/bin/bash
# ROLLER DISCO - Supa crazy disco mode for dining room
# Usage: ./roller-disco.sh
# Press Ctrl+C to stop

source "$(dirname "$0")/../.env"

LIGHTS=(
    "fa08b99f-aa8a-4683-af76-c0e3fd566217"   # Signe dining table
    "03e56936-b959-4687-b2de-5f2f670c8674"   # Signe couch corner
    "d1a940ac-c385-4857-88dc-bb89ff5ddfc4"   # Signe kitchen table
    "ca82265e-1ee9-4337-a0d4-e44b46b21b1d"   # Signe kitchen
    "457a3777-b619-4765-92a0-7292cbbaab7b"   # Signe main floor front
    "ca9107e3-4f2c-4383-bf1a-67ae0765bbdf"   # Kitchen 4
    "52e22f83-a8c0-4ede-9a5e-68801c8c69f7"   # Kitchen 5
    "bd5ef4f9-7258-4ee8-af97-851b9713c147"   # Kitchen 6
    "dd90028e-5494-4585-9a75-cb593d1275ec"   # Kitchen 1
    "7fabbbed-4222-4bf4-baee-64977ebc5dde"   # Kitchen 2
    "f95f8da4-3dd0-4f80-91a5-ca8ad1a7ff22"   # Kitchen 3
)

# Crazy disco colors - hot pink, electric blue, lime green, purple, orange, red, cyan, coral
COLORS=(
    "0.45 0.15"   # Hot pink
    "0.15 0.25"   # Electric blue
    "0.25 0.65"   # Lime green
    "0.32 0.12"   # Purple
    "0.60 0.38"   # Orange
    "0.68 0.31"   # Red
    "0.20 0.15"   # Cyan
    "0.55 0.25"   # Coral
)

echo "🪩 ROLLER DISCO MODE ACTIVATED 🪩"
echo "Press Ctrl+C to stop"

cleanup() {
    echo ""
    echo "Disco over! Setting lights to calm..."
    for light in "${LIGHTS[@]}"; do
        curl -sk -X PUT "https://$HUE_BRIDGE/clip/v2/resource/light/$light" \
            -H "hue-application-key: $HUE_USER" \
            -H "Content-Type: application/json" \
            -d '{"dimming":{"brightness":50},"color":{"xy":{"x":0.45,"y":0.41}},"dynamics":{"duration":2000}}' &
    done
    wait
    exit 0
}

trap cleanup SIGINT SIGTERM

while true; do
    for light in "${LIGHTS[@]}"; do
        # Random color for each light
        color=(${COLORS[$((RANDOM % ${#COLORS[@]}))]})
        brightness=$((70 + RANDOM % 31))  # 70-100

        curl -sk -X PUT "https://$HUE_BRIDGE/clip/v2/resource/light/$light" \
            -H "hue-application-key: $HUE_USER" \
            -H "Content-Type: application/json" \
            -d "{\"on\":{\"on\":true},\"dimming\":{\"brightness\":$brightness},\"color\":{\"xy\":{\"x\":${color[0]},\"y\":${color[1]}}},\"dynamics\":{\"duration\":200}}" &
    done
    wait
    sleep 0.3
done
