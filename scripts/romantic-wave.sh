#!/bin/bash
HUE_BRIDGE="192.168.1.209"
HUE_USER="afWtQvMRm2Chj0G8nU7NS9bkKBAEKXd0JNm2QafC"

# Main floor Signes (W→E)
MAIN_SIGNES=(
  "fa08b99f-aa8a-4683-af76-c0e3fd566217"   # W
  "03e56936-b959-4687-b2de-5f2f670c8674"   # MW
  "d1a940ac-c385-4857-88dc-bb89ff5ddfc4"   # M
  "ca82265e-1ee9-4337-a0d4-e44b46b21b1d"   # ME
  "457a3777-b619-4765-92a0-7292cbbaab7b"   # E
)

# Jamie's office
JAMIE_SIGNES=("7f91bd72-a9eb-4310-bf9a-461db7d8635c" "74d25075-110e-4db5-b0e0-f3e60addb10b")
JAMIE_PLAYS=("d220cd0b-219f-4eae-8ea1-4fd20fa06275" "e1e48801-86bd-4725-8098-c6249a8d8346")

# Master bedroom Signes
MASTER_SIGNES=("dfcfd007-8106-435e-80d3-4dc09174b783" "6ae37491-1a2f-470f-8204-9c0b7d01da8f" "52b7c364-3a09-4ada-9b7d-f1d687e4a6bf" "a15aef77-0db6-4480-a0a5-2a5aa4d74dd4")

# Master bedroom Twilight Backs (gradient capable)
TWILIGHT_BACKS=("91b5c5db-296b-4491-b220-1cfa5231a875" "b703f623-4cd0-4325-9d93-660c48fb0199")

# Master bedroom Twilight Fronts (solid color)
TWILIGHT_FRONTS=("5396d289-b7e1-4bdb-90f6-2b57e0ad7fc5" "0d806f9b-0416-47bb-8583-e5461fecb669")

# Romantic colors - pink to coral to orange
declare -a CX=(0.50 0.52 0.55 0.57 0.58 0.57 0.55 0.52 0.50 0.48 0.47 0.48)
declare -a CY=(0.25 0.28 0.30 0.33 0.35 0.38 0.40 0.38 0.35 0.30 0.27 0.25)
declare -a CB=(85 88 90 93 95 95 93 90 88 86 85 85)

PALETTE_LEN=${#CX[@]}

# Kitchen clusters
curl -s -X PUT "http://$HUE_BRIDGE/api/$HUE_USER/groups/102/action" -d '{"on":true, "hue":58000, "sat":230, "bri":220}' > /dev/null &
curl -s -X PUT "http://$HUE_BRIDGE/api/$HUE_USER/groups/101/action" -d '{"on":true, "hue":3000, "sat":240, "bri":240}' > /dev/null &

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
      ]},\"dynamics\":{\"duration\":3000}}" > /dev/null 2>&1
}

set_solid_light() {
    local id=$1
    local phase=$2
    local p=$(( (phase + 4) % PALETTE_LEN ))
    curl -sk -X PUT "https://$HUE_BRIDGE/clip/v2/resource/light/$id" \
      -H "hue-application-key: $HUE_USER" \
      -H "Content-Type: application/json" \
      -d "{\"color\":{\"xy\":{\"x\":${CX[$p]},\"y\":${CY[$p]}}},\"dimming\":{\"brightness\":${CB[$p]}},\"dynamics\":{\"duration\":3000}}" > /dev/null 2>&1
}

echo "Romantic wave: Main floor + Jamie's office + Master bedroom (with Twilight backs)"

phase=0
while true; do
    # Main floor Signes
    for i in 0 1 2 3 4; do
        set_gradient_light "${MAIN_SIGNES[$i]}" $(( (phase + i * 2) % PALETTE_LEN )) &
    done
    
    # Jamie's office
    for i in 0 1; do
        set_gradient_light "${JAMIE_SIGNES[$i]}" $(( (phase + i * 3) % PALETTE_LEN )) &
        set_solid_light "${JAMIE_PLAYS[$i]}" $(( (phase + i * 2) % PALETTE_LEN )) &
    done
    
    # Master bedroom Signes
    for i in 0 1 2 3; do
        set_gradient_light "${MASTER_SIGNES[$i]}" $(( (phase + i * 2) % PALETTE_LEN )) &
    done
    
    # Master bedroom Twilight Backs (gradient)
    for i in 0 1; do
        set_gradient_light "${TWILIGHT_BACKS[$i]}" $(( (phase + i * 4) % PALETTE_LEN )) &
    done
    
    # Master bedroom Twilight Fronts (solid)
    for i in 0 1; do
        set_solid_light "${TWILIGHT_FRONTS[$i]}" $(( (phase + i * 3) % PALETTE_LEN )) &
    done
    
    wait
    phase=$(( (phase + 1) % PALETTE_LEN ))
    sleep 3
done
