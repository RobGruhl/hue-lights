#!/bin/bash
HUE_BRIDGE="192.168.1.209"
HUE_USER="afWtQvMRm2Chj0G8nU7NS9bkKBAEKXd0JNm2QafC"

# Signe v2 IDs (W→E order for scroll)
SIGNE_IDS=(
  "fa08b99f-aa8a-4683-af76-c0e3fd566217"   # W
  "03e56936-b959-4687-b2de-5f2f670c8674"   # MW
  "d1a940ac-c385-4857-88dc-bb89ff5ddfc4"   # M
  "ca82265e-1ee9-4337-a0d4-e44b46b21b1d"   # ME
  "457a3777-b619-4765-92a0-7292cbbaab7b"   # E
)

# Kitchen cluster v1 group IDs and positions
KITCHEN_W="102"  # 2' from W
KITCHEN_E="101"  # 5.5' from W

# Perceptually balanced color palette (xy coords + brightness)
# Warm orange → cream → cyan, wrapping back
declare -a COLORS_X=(0.52 0.47 0.42 0.36 0.30 0.24 0.18 0.20 0.26 0.32 0.38 0.45)
declare -a COLORS_Y=(0.41 0.41 0.40 0.39 0.37 0.36 0.37 0.37 0.38 0.39 0.40 0.41)
declare -a COLORS_BRI=(80 85 90 95 100 100 100 100 95 90 85 80)

PALETTE_LEN=${#COLORS_X[@]}

set_signe_gradient() {
    local id=$1
    local offset=$2
    
    # Build 5-point gradient from palette based on offset
    local p0=$(( offset % PALETTE_LEN ))
    local p1=$(( (offset + 2) % PALETTE_LEN ))
    local p2=$(( (offset + 4) % PALETTE_LEN ))
    local p3=$(( (offset + 6) % PALETTE_LEN ))
    local p4=$(( (offset + 8) % PALETTE_LEN ))
    
    local gradient="{
      \"gradient\": {
        \"points\": [
          {\"color\": {\"xy\": {\"x\": ${COLORS_X[$p0]}, \"y\": ${COLORS_Y[$p0]}}}, \"dimming\": {\"brightness\": ${COLORS_BRI[$p0]}}},
          {\"color\": {\"xy\": {\"x\": ${COLORS_X[$p1]}, \"y\": ${COLORS_Y[$p1]}}}, \"dimming\": {\"brightness\": ${COLORS_BRI[$p1]}}},
          {\"color\": {\"xy\": {\"x\": ${COLORS_X[$p2]}, \"y\": ${COLORS_Y[$p2]}}}, \"dimming\": {\"brightness\": ${COLORS_BRI[$p2]}}},
          {\"color\": {\"xy\": {\"x\": ${COLORS_X[$p3]}, \"y\": ${COLORS_Y[$p3]}}}, \"dimming\": {\"brightness\": ${COLORS_BRI[$p3]}}},
          {\"color\": {\"xy\": {\"x\": ${COLORS_X[$p4]}, \"y\": ${COLORS_Y[$p4]}}}, \"dimming\": {\"brightness\": ${COLORS_BRI[$p4]}}}
        ]
      },
      \"dynamics\": {\"duration\": 5000},
      \"dimming\": {\"brightness\": 100}
    }"
    
    curl -sk -X PUT "https://$HUE_BRIDGE/clip/v2/resource/light/$id" \
      -H "hue-application-key: $HUE_USER" \
      -H "Content-Type: application/json" \
      -d "$gradient" > /dev/null
}

set_kitchen() {
    local group_id=$1
    local offset=$2
    
    local p=$(( (offset + 4) % PALETTE_LEN ))  # middle of gradient range
    local hue_val=$(awk "BEGIN {print int((1 - ${COLORS_X[$p]}) * 65535 / 0.7)}")
    local sat_val=$(awk "BEGIN {print int(${COLORS_Y[$p]} * 254)}")
    local bri_val=$(awk "BEGIN {print int(${COLORS_BRI[$p]} * 2.54)}")
    
    curl -s -X PUT "http://$HUE_BRIDGE/api/$HUE_USER/groups/$group_id/action" \
      -d "{\"on\":true, \"bri\":$bri_val, \"sat\":180, \"transitiontime\":50}" > /dev/null
}

echo "Gradient scroll with perceptual balance (10s per step)..."
echo "Signes show bottom-to-top gradient, scrolling W→E"

# Position offsets proportional to physical spacing
POS_OFFSETS=(0 1 2 4 5 7 10)  # W, KitchenW, KitchenE, MW, M, ME, E

phase=0
while true; do
    # Set each Signe with offset gradient
    for i in 0 1 2 3 4; do
        offset=$(( (phase + POS_OFFSETS[$((i + 2))]) % PALETTE_LEN ))  # +2 to skip kitchen positions
        set_signe_gradient "${SIGNE_IDS[$i]}" "$offset" &
    done
    
    # Set kitchen clusters (solid colors from middle of gradient)
    set_kitchen "$KITCHEN_W" $(( (phase + 1) % PALETTE_LEN )) &
    set_kitchen "$KITCHEN_E" $(( (phase + 2) % PALETTE_LEN )) &
    
    wait
    phase=$(( (phase + 1) % PALETTE_LEN ))
    sleep 10  # Half speed = 10 seconds per step
done
