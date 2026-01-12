#!/bin/bash
# Create all 11 palettes as scenes in every room
# This populates "My scenes" in the Hue app

source "$(dirname "$0")/../.env"
source "$(dirname "$0")/lib/palettes.sh"

# Get human-readable name for palette
get_palette_name() {
    case "$1" in
        SUNFLARE)  echo "Warm Sunflare" ;;
        VAPORWAVE) echo "Vaporwave" ;;
        TOADSTOOL) echo "Woodland Toadstool" ;;
        ROMANTIC)  echo "Romantic Pink" ;;
        MIDNIGHT)  echo "Midnight Pinks" ;;
        SUNRISE)   echo "Morning Sunrise" ;;
        OCEAN)     echo "Deep Ocean" ;;
        CANDLE)    echo "Candlelight" ;;
        NORDIC)    echo "Nordic Twilight" ;;
        AURORA)    echo "Aurora" ;;
        FIRE)      echo "Fireplace" ;;
        *)         echo "$1" ;;
    esac
}

create_scene() {
    local name=$1
    local group_id=$2
    local group_type=$3
    local palette=$4
    local lights_csv=$5

    # Load the palette
    load_palette "$palette"

    # Convert CSV to array
    IFS=',' read -ra lights <<< "$lights_csv"
    local light_count=${#lights[@]}

    # Build actions JSON
    local actions="["
    local first=true
    local idx=0

    for light in "${lights[@]}"; do
        local phase=$(( idx * PALETTE_LEN / light_count ))
        local p=$(( phase % PALETTE_LEN ))

        if [[ "$first" != "true" ]]; then
            actions+=","
        fi
        first=false

        actions+="{\"target\":{\"rid\":\"$light\",\"rtype\":\"light\"},\"action\":{\"on\":{\"on\":true},\"dimming\":{\"brightness\":${CB[$p]}},\"color\":{\"xy\":{\"x\":${CX[$p]},\"y\":${CY[$p]}}}}}"
        ((idx++))
    done
    actions+="]"

    # Create the scene
    local response=$(curl -sk -X POST "https://$HUE_BRIDGE/clip/v2/resource/scene" \
      -H "hue-application-key: $HUE_USER" \
      -H "Content-Type: application/json" \
      -d "{\"type\":\"scene\",\"metadata\":{\"name\":\"$name\"},\"group\":{\"rid\":\"$group_id\",\"rtype\":\"$group_type\"},\"actions\":$actions}" 2>/dev/null)

    if echo "$response" | grep -q '"errors":\[\]'; then
        echo "  + $name"
    else
        echo "  ! $name (error)"
    fi
}

# All palettes
PALETTES="SUNFLARE VAPORWAVE TOADSTOOL ROMANTIC MIDNIGHT SUNRISE OCEAN CANDLE NORDIC AURORA FIRE"

echo "========================================"
echo "Creating All Scenes in All Rooms"
echo "========================================"
echo ""

total=0

# Dining Floor
echo "--- Dining Floor ---"
DINING_LIGHTS="fa08b99f-aa8a-4683-af76-c0e3fd566217,03e56936-b959-4687-b2de-5f2f670c8674,d1a940ac-c385-4857-88dc-bb89ff5ddfc4,ca82265e-1ee9-4337-a0d4-e44b46b21b1d,457a3777-b619-4765-92a0-7292cbbaab7b,ca9107e3-4f2c-4383-bf1a-67ae0765bbdf,52e22f83-a8c0-4ede-9a5e-68801c8c69f7,bd5ef4f9-7258-4ee8-af97-851b9713c147,dd90028e-5494-4585-9a75-cb593d1275ec,7fabbbed-4222-4bf4-baee-64977ebc5dde,f95f8da4-3dd0-4f80-91a5-ca8ad1a7ff22"
for p in $PALETTES; do
    create_scene "$(get_palette_name $p)" "1047b6a7-aa13-4f8d-8d09-22422b6042a3" "room" "$p" "$DINING_LIGHTS"
    ((total++))
    sleep 0.1
done
echo ""

# Jamie's Office
echo "--- Jamie's Office ---"
JAMIE_LIGHTS="7f91bd72-a9eb-4310-bf9a-461db7d8635c,74d25075-110e-4db5-b0e0-f3e60addb10b,d220cd0b-219f-4eae-8ea1-4fd20fa06275,e1e48801-86bd-4725-8098-c6249a8d8346"
for p in $PALETTES; do
    create_scene "$(get_palette_name $p)" "3ce30afb-b56f-4cad-968b-c3d58637ae1d" "room" "$p" "$JAMIE_LIGHTS"
    ((total++))
    sleep 0.1
done
echo ""

# Master Bedroom
echo "--- Master Bedroom ---"
MASTER_LIGHTS="dfcfd007-8106-435e-80d3-4dc09174b783,6ae37491-1a2f-470f-8204-9c0b7d01da8f,52b7c364-3a09-4ada-9b7d-f1d687e4a6bf,a15aef77-0db6-4480-a0a5-2a5aa4d74dd4,91b5c5db-296b-4491-b220-1cfa5231a875,b703f623-4cd0-4325-9d93-660c48fb0199,5396d289-b7e1-4bdb-90f6-2b57e0ad7fc5,0d806f9b-0416-47bb-8583-e5461fecb669"
for p in $PALETTES; do
    create_scene "$(get_palette_name $p)" "43dc92f9-2587-42e3-912c-311f00585c1d" "room" "$p" "$MASTER_LIGHTS"
    ((total++))
    sleep 0.1
done
echo ""

# Master Bathroom
echo "--- Master Bathroom ---"
BATH_LIGHTS="e15184b3-d09a-4b0a-b8b1-fd8a16f69a0c"
for p in $PALETTES; do
    create_scene "$(get_palette_name $p)" "210dbc01-2eb7-4498-ac02-8872785b9f27" "room" "$p" "$BATH_LIGHTS"
    ((total++))
    sleep 0.1
done
echo ""

# Jordan's Bedroom
echo "--- Jordan's Bedroom ---"
JORDAN_LIGHTS="9c26b749-70db-4492-996e-c0dad1e41cd1,585292eb-f27d-432d-a82f-db450c8c9fb2,c75776ff-d48f-4ec8-b8cc-5dd45e50e9d7"
for p in $PALETTES; do
    create_scene "$(get_palette_name $p)" "4ed09bbf-cb61-4253-be91-142ac2343418" "room" "$p" "$JORDAN_LIGHTS"
    ((total++))
    sleep 0.1
done
echo ""

# Keston's Bedroom
echo "--- Keston's Bedroom ---"
KESTON_LIGHTS="2d2cc7f7-9987-44d6-be2c-86420050157c,a2a890cf-6d44-480d-887f-14c711ba4821,d3bbd5c5-585c-48b1-a01d-4eb5a4d7f4c6"
for p in $PALETTES; do
    create_scene "$(get_palette_name $p)" "3c6349bd-8582-47e3-8258-d05136e41eaa" "room" "$p" "$KESTON_LIGHTS"
    ((total++))
    sleep 0.1
done
echo ""

# TV Room
echo "--- TV Room ---"
TV_LIGHTS="aacd4d39-f3fa-42d4-9ac4-0abf1647854d"
for p in $PALETTES; do
    create_scene "$(get_palette_name $p)" "21ad19a1-63ae-4d07-8d8f-ff0e59f63941" "room" "$p" "$TV_LIGHTS"
    ((total++))
    sleep 0.1
done
echo ""

# Balcony
echo "--- Balcony ---"
BALCONY_LIGHTS="7b12ed85-aebe-4c3e-9471-ad8598443ef3"
for p in $PALETTES; do
    create_scene "$(get_palette_name $p)" "c5ce9b56-fbb3-47b2-ae6f-7e0eb120c6c6" "room" "$p" "$BALCONY_LIGHTS"
    ((total++))
    sleep 0.1
done
echo ""

# Whole Home Zone
echo "--- Whole Home Zone ---"
ALL_LIGHTS="fa08b99f-aa8a-4683-af76-c0e3fd566217,03e56936-b959-4687-b2de-5f2f670c8674,d1a940ac-c385-4857-88dc-bb89ff5ddfc4,ca82265e-1ee9-4337-a0d4-e44b46b21b1d,457a3777-b619-4765-92a0-7292cbbaab7b,ca9107e3-4f2c-4383-bf1a-67ae0765bbdf,52e22f83-a8c0-4ede-9a5e-68801c8c69f7,bd5ef4f9-7258-4ee8-af97-851b9713c147,dd90028e-5494-4585-9a75-cb593d1275ec,7fabbbed-4222-4bf4-baee-64977ebc5dde,f95f8da4-3dd0-4f80-91a5-ca8ad1a7ff22,7f91bd72-a9eb-4310-bf9a-461db7d8635c,74d25075-110e-4db5-b0e0-f3e60addb10b,d220cd0b-219f-4eae-8ea1-4fd20fa06275,e1e48801-86bd-4725-8098-c6249a8d8346,dfcfd007-8106-435e-80d3-4dc09174b783,6ae37491-1a2f-470f-8204-9c0b7d01da8f,52b7c364-3a09-4ada-9b7d-f1d687e4a6bf,a15aef77-0db6-4480-a0a5-2a5aa4d74dd4,91b5c5db-296b-4491-b220-1cfa5231a875,b703f623-4cd0-4325-9d93-660c48fb0199,5396d289-b7e1-4bdb-90f6-2b57e0ad7fc5,0d806f9b-0416-47bb-8583-e5461fecb669,e15184b3-d09a-4b0a-b8b1-fd8a16f69a0c,9c26b749-70db-4492-996e-c0dad1e41cd1,585292eb-f27d-432d-a82f-db450c8c9fb2,c75776ff-d48f-4ec8-b8cc-5dd45e50e9d7,2d2cc7f7-9987-44d6-be2c-86420050157c,a2a890cf-6d44-480d-887f-14c711ba4821,d3bbd5c5-585c-48b1-a01d-4eb5a4d7f4c6,aacd4d39-f3fa-42d4-9ac4-0abf1647854d,7b12ed85-aebe-4c3e-9471-ad8598443ef3"
for p in $PALETTES; do
    create_scene "$(get_palette_name $p)" "377e0c96-5613-4219-ae1c-4ce7ffe17e42" "zone" "$p" "$ALL_LIGHTS"
    ((total++))
    sleep 0.1
done
echo ""

echo "========================================"
echo "Created $total scenes!"
echo "Check the Hue app for new scenes"
echo "========================================"
