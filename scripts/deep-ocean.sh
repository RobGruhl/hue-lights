#!/bin/bash
# Deep Ocean - Calming whole-house scene
# Breathing rhythm with deep teals, seafoam, and aqua
# All 32 lights included

source "$(dirname "$0")/../.env"

# === ALL LIGHTS BY ROOM ===

# Main Floor Signes (W→E)
MAIN_SIGNES=(
    "fa08b99f-aa8a-4683-af76-c0e3fd566217"   # W
    "03e56936-b959-4687-b2de-5f2f670c8674"   # MW
    "d1a940ac-c385-4857-88dc-bb89ff5ddfc4"   # M
    "ca82265e-1ee9-4337-a0d4-e44b46b21b1d"   # ME
    "457a3777-b619-4765-92a0-7292cbbaab7b"   # E
)

# Kitchen Pendants
KITCHEN=("dd90028e-5494-4585-9a75-cb593d1275ec" "7fabbbed-4222-4bf4-baee-64977ebc5dde" "f95f8da4-3dd0-4f80-91a5-ca8ad1a7ff22" "ca9107e3-4f2c-4383-bf1a-67ae0765bbdf" "52e22f83-a8c0-4ede-9a5e-68801c8c69f7" "bd5ef4f9-7258-4ee8-af97-851b9713c147")

# Jamie's Office
JAMIE_SIGNES=("7f91bd72-a9eb-4310-bf9a-461db7d8635c" "74d25075-110e-4db5-b0e0-f3e60addb10b")
JAMIE_PLAYS=("d220cd0b-219f-4eae-8ea1-4fd20fa06275" "e1e48801-86bd-4725-8098-c6249a8d8346")

# Master Bedroom
MASTER_SIGNES=("dfcfd007-8106-435e-80d3-4dc09174b783" "6ae37491-1a2f-470f-8204-9c0b7d01da8f" "52b7c364-3a09-4ada-9b7d-f1d687e4a6bf" "a15aef77-0db6-4480-a0a5-2a5aa4d74dd4")
TWILIGHT_BACKS=("91b5c5db-296b-4491-b220-1cfa5231a875" "b703f623-4cd0-4325-9d93-660c48fb0199")
TWILIGHT_FRONTS=("5396d289-b7e1-4bdb-90f6-2b57e0ad7fc5" "0d806f9b-0416-47bb-8583-e5461fecb669")

# Master Bathroom
MASTER_BATH=("e15184b3-d09a-4b0a-b8b1-fd8a16f69a0c")

# Jordan's Bedroom
JORDAN_SIGNE=("9c26b749-70db-4492-996e-c0dad1e41cd1")
JORDAN_BACK=("585292eb-f27d-432d-a82f-db450c8c9fb2")
JORDAN_FRONT=("c75776ff-d48f-4ec8-b8cc-5dd45e50e9d7")

# Keston's Bedroom
KESTON_SIGNE=("2d2cc7f7-9987-44d6-be2c-86420050157c")
KESTON_BACK=("a2a890cf-6d44-480d-887f-14c711ba4821")
KESTON_FRONT=("d3bbd5c5-585c-48b1-a01d-4eb5a4d7f4c6")

# TV Room
TV_STRIP=("aacd4d39-f3fa-42d4-9ac4-0abf1647854d")

# Balcony
FESTAVIA=("7b12ed85-aebe-4c3e-9471-ad8598443ef3")

# Deep Ocean palette - breathing through teal depths
# Deep teal → seafoam → pale aqua → soft white → back down
# Blues boosted for perceptual brightness
declare -a CX=(0.16 0.18 0.20 0.23 0.26 0.28 0.30 0.28 0.25 0.22 0.19 0.17)
declare -a CY=(0.32 0.34 0.36 0.37 0.38 0.37 0.36 0.35 0.34 0.33 0.32 0.31)
declare -a CB=(100  100  100  100  95   90   85   90   95   100  100  100)

PALETTE_LEN=${#CX[@]}

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
      ]},\"dynamics\":{\"duration\":6000},\"dimming\":{\"brightness\":100}}" > /dev/null 2>&1
}

set_solid_light() {
    local id=$1
    local phase=$2
    local p=$(( phase % PALETTE_LEN ))
    curl -sk -X PUT "https://$HUE_BRIDGE/clip/v2/resource/light/$id" \
      -H "hue-application-key: $HUE_USER" \
      -H "Content-Type: application/json" \
      -d "{\"color\":{\"xy\":{\"x\":${CX[$p]},\"y\":${CY[$p]}}},\"dimming\":{\"brightness\":${CB[$p]}},\"dynamics\":{\"duration\":6000}}" > /dev/null 2>&1
}

echo "DEEP OCEAN: Whole house breathing (32 lights)"
echo "Press Ctrl+C to stop"

phase=0
while true; do
    # Main floor Signes - wave across room
    for i in 0 1 2 3 4; do
        set_gradient_light "${MAIN_SIGNES[$i]}" $(( (phase + i * 2) % PALETTE_LEN )) &
    done

    # Kitchen - gentle offset from main floor
    for i in "${!KITCHEN[@]}"; do
        set_solid_light "${KITCHEN[$i]}" $(( (phase + 3) % PALETTE_LEN )) &
    done

    # Jamie's office - slight delay from main floor
    for i in 0 1; do
        set_gradient_light "${JAMIE_SIGNES[$i]}" $(( (phase + 4 + i * 2) % PALETTE_LEN )) &
        set_gradient_light "${JAMIE_PLAYS[$i]}" $(( (phase + 5 + i * 2) % PALETTE_LEN )) &
    done

    # Master bedroom - another wave
    for i in 0 1 2 3; do
        set_gradient_light "${MASTER_SIGNES[$i]}" $(( (phase + 6 + i * 2) % PALETTE_LEN )) &
    done
    for i in 0 1; do
        set_gradient_light "${TWILIGHT_BACKS[$i]}" $(( (phase + 8 + i * 2) % PALETTE_LEN )) &
        set_solid_light "${TWILIGHT_FRONTS[$i]}" $(( (phase + 7 + i * 2) % PALETTE_LEN )) &
    done

    # Master bathroom
    set_gradient_light "${MASTER_BATH[0]}" $(( (phase + 5) % PALETTE_LEN )) &

    # Jordan's room
    set_gradient_light "${JORDAN_SIGNE[0]}" $(( (phase + 2) % PALETTE_LEN )) &
    set_gradient_light "${JORDAN_BACK[0]}" $(( (phase + 3) % PALETTE_LEN )) &
    set_solid_light "${JORDAN_FRONT[0]}" $(( (phase + 4) % PALETTE_LEN )) &

    # Keston's room
    set_gradient_light "${KESTON_SIGNE[0]}" $(( (phase + 3) % PALETTE_LEN )) &
    set_gradient_light "${KESTON_BACK[0]}" $(( (phase + 4) % PALETTE_LEN )) &
    set_solid_light "${KESTON_FRONT[0]}" $(( (phase + 5) % PALETTE_LEN )) &

    # TV room
    set_gradient_light "${TV_STRIP[0]}" $(( (phase + 1) % PALETTE_LEN )) &

    # Balcony
    set_gradient_light "${FESTAVIA[0]}" $(( phase % PALETTE_LEN )) &

    wait
    phase=$(( (phase + 1) % PALETTE_LEN ))
    sleep 8
done
