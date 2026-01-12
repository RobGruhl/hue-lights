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

# Toadstool colors (xy coords) - rust to amber to forest green, cycling
declare -a CX=(0.60 0.58 0.55 0.50 0.45 0.40 0.35 0.32 0.35 0.42 0.50 0.56)
declare -a CY=(0.35 0.38 0.40 0.42 0.45 0.50 0.53 0.55 0.50 0.44 0.40 0.37)
declare -a CB=(75 80 85 90 95 95 90 85 90 95 90 80)

PALETTE_LEN=${#CX[@]}

# Kitchen clusters - set once (warm amber tones)
curl -s -X PUT "http://$HUE_BRIDGE/api/$HUE_USER/groups/102/action" \
  -d '{"on":true, "hue":5000, "sat":220, "bri":230}' > /dev/null &
curl -s -X PUT "http://$HUE_BRIDGE/api/$HUE_USER/groups/101/action" \
  -d '{"on":true, "hue":8000, "sat":200, "bri":240}' > /dev/null &

set_signe() {
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

echo "Woodland Toadstool vertical wave - colors rippling bottom→top..."

phase=0
while true; do
    for i in 0 1 2 3 4; do
        signe_phase=$(( (phase + i * 2) % PALETTE_LEN ))
        set_signe "${SIGNE_IDS[$i]}" "$signe_phase" &
    done
    wait
    
    phase=$(( (phase + 1) % PALETTE_LEN ))
    sleep 3
done
