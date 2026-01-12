#!/bin/bash
HUE_BRIDGE="192.168.1.209"
HUE_USER="afWtQvMRm2Chj0G8nU7NS9bkKBAEKXd0JNm2QafC"

# Signe v2 IDs (W→E)
SIGNE_IDS=(
  "fa08b99f-aa8a-4683-af76-c0e3fd566217"   # W
  "03e56936-b959-4687-b2de-5f2f670c8674"   # MW
  "d1a940ac-c385-4857-88dc-bb89ff5ddfc4"   # M
  "ca82265e-1ee9-4337-a0d4-e44b46b21b1d"   # ME
  "457a3777-b619-4765-92a0-7292cbbaab7b"   # E
)

# Vaporwave colors (xy coords) - pink to purple to cyan
# We'll cycle through these vertically
declare -a CX=(0.45 0.38 0.32 0.25 0.20 0.16 0.15 0.16 0.20 0.28 0.36 0.42)
declare -a CY=(0.22 0.18 0.15 0.13 0.14 0.20 0.28 0.32 0.30 0.22 0.18 0.20)
declare -a CB=(85 88 90 93 96 100 100 96 93 90 88 85)

PALETTE_LEN=${#CX[@]}

set_signe() {
    local id=$1
    local phase=$2  # 0-11, determines where in the color cycle we are
    
    # 5 points spread across the palette, offset by phase
    local p0=$(( phase % PALETTE_LEN ))
    local p1=$(( (phase + 2) % PALETTE_LEN ))
    local p2=$(( (phase + 4) % PALETTE_LEN ))
    local p3=$(( (phase + 6) % PALETTE_LEN ))
    local p4=$(( (phase + 8) % PALETTE_LEN ))
    
    curl -sk -X PUT "https://$HUE_BRIDGE/clip/v2/resource/light/$id" \
      -H "hue-application-key: $HUE_USER" \
      -H "Content-Type: application/json" \
      -d "{
        \"gradient\": {
          \"points\": [
            {\"color\": {\"xy\": {\"x\": ${CX[$p0]}, \"y\": ${CY[$p0]}}}, \"dimming\": {\"brightness\": ${CB[$p0]}}},
            {\"color\": {\"xy\": {\"x\": ${CX[$p1]}, \"y\": ${CY[$p1]}}}, \"dimming\": {\"brightness\": ${CB[$p1]}}},
            {\"color\": {\"xy\": {\"x\": ${CX[$p2]}, \"y\": ${CY[$p2]}}}, \"dimming\": {\"brightness\": ${CB[$p2]}}},
            {\"color\": {\"xy\": {\"x\": ${CX[$p3]}, \"y\": ${CY[$p3]}}}, \"dimming\": {\"brightness\": ${CB[$p3]}}},
            {\"color\": {\"xy\": {\"x\": ${CX[$p4]}, \"y\": ${CY[$p4]}}}, \"dimming\": {\"brightness\": ${CB[$p4]}}}
          ]
        },
        \"dynamics\": {\"duration\": 3000}
      }" > /dev/null
}

echo "Vaporwave vertical wave - colors rippling bottom→top across room..."

phase=0
while true; do
    # Each Signe gets same animation but slightly offset in time (wave across room)
    for i in 0 1 2 3 4; do
        signe_phase=$(( (phase + i * 2) % PALETTE_LEN ))
        set_signe "${SIGNE_IDS[$i]}" "$signe_phase" &
    done
    wait
    
    phase=$(( (phase + 1) % PALETTE_LEN ))
    sleep 3
done

# Kitchen clusters - set once at start (pink west, cyan east)
curl -s -X PUT "http://$HUE_BRIDGE/api/$HUE_USER/groups/102/action" \
  -d '{"on":true, "hue":56000, "sat":240, "bri":220}' > /dev/null &
curl -s -X PUT "http://$HUE_BRIDGE/api/$HUE_USER/groups/101/action" \
  -d '{"on":true, "hue":40000, "sat":220, "bri":254}' > /dev/null &
