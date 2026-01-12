#!/bin/bash
# Create Hue scenes on the bridge that appear in the app's "My scenes"
# Each scene is a static snapshot representing the palette

source "$(dirname "$0")/../.env"
source "$(dirname "$0")/lib/palettes.sh"
source "$(dirname "$0")/lib/rooms.sh"

# Room/Zone UUIDs
DINING_ROOM="1047b6a7-aa13-4f8d-8d09-22422b6042a3"
JAMIE_OFFICE="3ce30afb-b56f-4cad-968b-c3d58637ae1d"
MASTER_BEDROOM="43dc92f9-2587-42e3-912c-311f00585c1d"
WHOLE_HOME_ZONE="377e0c96-5613-4219-ae1c-4ce7ffe17e42"

# Create a scene on the bridge
# Args: scene_name, group_id, group_type (room/zone), light_uuids[], palette_name
create_scene() {
    local name=$1
    local group_id=$2
    local group_type=$3
    local palette=$4
    shift 4
    local lights=("$@")

    echo "Creating scene: $name"

    # Load the palette
    load_palette "$palette"

    # Build actions JSON
    local actions="["
    local first=true
    local idx=0

    for light in "${lights[@]}"; do
        local phase=$(( idx * PALETTE_LEN / ${#lights[@]} ))
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
      -d "{\"type\":\"scene\",\"metadata\":{\"name\":\"$name\"},\"group\":{\"rid\":\"$group_id\",\"rtype\":\"$group_type\"},\"actions\":$actions}")

    if echo "$response" | grep -q '"errors":\[\]'; then
        local scene_id=$(echo "$response" | grep -o '"rid":"[^"]*"' | head -1 | cut -d'"' -f4)
        echo "  Created: $scene_id"
    else
        echo "  Error: $response"
    fi
}

# Get lights for a room from the bridge
get_room_light_ids() {
    local room_id=$1
    curl -sk "https://$HUE_BRIDGE/clip/v2/resource/room/$room_id" \
      -H "hue-application-key: $HUE_USER" | \
      grep -o '"rid":"[^"]*","rtype":"device"' | \
      cut -d'"' -f4
}

# Get light IDs from device IDs
get_light_from_device() {
    local device_id=$1
    curl -sk "https://$HUE_BRIDGE/clip/v2/resource/device/$device_id" \
      -H "hue-application-key: $HUE_USER" | \
      grep -o '"rid":"[^"]*","rtype":"light"' | head -1 | \
      cut -d'"' -f4
}

echo "========================================"
echo "Creating Hue Scenes on Bridge"
echo "========================================"
echo ""

# === DINING FLOOR SCENES ===
echo "--- Dining Floor ---"
DINING_LIGHTS=(
    "fa08b99f-aa8a-4683-af76-c0e3fd566217"   # Signe W
    "03e56936-b959-4687-b2de-5f2f670c8674"   # Signe MW
    "d1a940ac-c385-4857-88dc-bb89ff5ddfc4"   # Signe M
    "ca82265e-1ee9-4337-a0d4-e44b46b21b1d"   # Signe ME
    "457a3777-b619-4765-92a0-7292cbbaab7b"   # Signe E
    "ca9107e3-4f2c-4383-bf1a-67ae0765bbdf"   # Kitchen W1
    "52e22f83-a8c0-4ede-9a5e-68801c8c69f7"   # Kitchen W2
    "bd5ef4f9-7258-4ee8-af97-851b9713c147"   # Kitchen W3
    "dd90028e-5494-4585-9a75-cb593d1275ec"   # Kitchen E1
    "7fabbbed-4222-4bf4-baee-64977ebc5dde"   # Kitchen E2
    "f95f8da4-3dd0-4f80-91a5-ca8ad1a7ff22"   # Kitchen E3
)

create_scene "Warm Sunflare" "$DINING_ROOM" "room" "SUNFLARE" "${DINING_LIGHTS[@]}"
create_scene "Morning Sunrise" "$DINING_ROOM" "room" "SUNRISE" "${DINING_LIGHTS[@]}"
create_scene "Candlelight Dinner" "$DINING_ROOM" "room" "CANDLE" "${DINING_LIGHTS[@]}"
create_scene "Nordic Twilight" "$DINING_ROOM" "room" "NORDIC" "${DINING_LIGHTS[@]}"
create_scene "Vaporwave" "$DINING_ROOM" "room" "VAPORWAVE" "${DINING_LIGHTS[@]}"
create_scene "Woodland Toadstool" "$DINING_ROOM" "room" "TOADSTOOL" "${DINING_LIGHTS[@]}"

echo ""

# === JAMIE'S OFFICE SCENES ===
echo "--- Jamie's Office ---"
JAMIE_LIGHTS=(
    "7f91bd72-a9eb-4310-bf9a-461db7d8635c"   # Signe 1
    "74d25075-110e-4db5-b0e0-f3e60addb10b"   # Signe 2
    "d220cd0b-219f-4eae-8ea1-4fd20fa06275"   # Play Right
    "e1e48801-86bd-4725-8098-c6249a8d8346"   # Play Left
)

create_scene "Vaporwave" "$JAMIE_OFFICE" "room" "VAPORWAVE" "${JAMIE_LIGHTS[@]}"
create_scene "Romantic Pink" "$JAMIE_OFFICE" "room" "ROMANTIC" "${JAMIE_LIGHTS[@]}"
create_scene "Midnight Pinks" "$JAMIE_OFFICE" "room" "MIDNIGHT" "${JAMIE_LIGHTS[@]}"

echo ""

# === MASTER BEDROOM SCENES ===
echo "--- Master Bedroom ---"
MASTER_LIGHTS=(
    "dfcfd007-8106-435e-80d3-4dc09174b783"   # Signe Jamie
    "6ae37491-1a2f-470f-8204-9c0b7d01da8f"   # Signe Rob
    "52b7c364-3a09-4ada-9b7d-f1d687e4a6bf"   # Signe Rob Desk L
    "a15aef77-0db6-4480-a0a5-2a5aa4d74dd4"   # Signe Rob Desk R
    "91b5c5db-296b-4491-b220-1cfa5231a875"   # Twilight Back 1
    "b703f623-4cd0-4325-9d93-660c48fb0199"   # Twilight Back 2
    "5396d289-b7e1-4bdb-90f6-2b57e0ad7fc5"   # Twilight Front 1
    "0d806f9b-0416-47bb-8583-e5461fecb669"   # Twilight Front 2
)

create_scene "Romantic Pink" "$MASTER_BEDROOM" "room" "ROMANTIC" "${MASTER_LIGHTS[@]}"
create_scene "Midnight Pinks" "$MASTER_BEDROOM" "room" "MIDNIGHT" "${MASTER_LIGHTS[@]}"
create_scene "Nordic Twilight" "$MASTER_BEDROOM" "room" "NORDIC" "${MASTER_LIGHTS[@]}"

echo ""

# === WHOLE HOME ZONE SCENE ===
echo "--- Whole Home Zone ---"
# All 32 lights
ALL_LIGHTS=(
    # Dining Signes
    "fa08b99f-aa8a-4683-af76-c0e3fd566217"
    "03e56936-b959-4687-b2de-5f2f670c8674"
    "d1a940ac-c385-4857-88dc-bb89ff5ddfc4"
    "ca82265e-1ee9-4337-a0d4-e44b46b21b1d"
    "457a3777-b619-4765-92a0-7292cbbaab7b"
    # Kitchen
    "ca9107e3-4f2c-4383-bf1a-67ae0765bbdf"
    "52e22f83-a8c0-4ede-9a5e-68801c8c69f7"
    "bd5ef4f9-7258-4ee8-af97-851b9713c147"
    "dd90028e-5494-4585-9a75-cb593d1275ec"
    "7fabbbed-4222-4bf4-baee-64977ebc5dde"
    "f95f8da4-3dd0-4f80-91a5-ca8ad1a7ff22"
    # Jamie's Office
    "7f91bd72-a9eb-4310-bf9a-461db7d8635c"
    "74d25075-110e-4db5-b0e0-f3e60addb10b"
    "d220cd0b-219f-4eae-8ea1-4fd20fa06275"
    "e1e48801-86bd-4725-8098-c6249a8d8346"
    # Master Bedroom
    "dfcfd007-8106-435e-80d3-4dc09174b783"
    "6ae37491-1a2f-470f-8204-9c0b7d01da8f"
    "52b7c364-3a09-4ada-9b7d-f1d687e4a6bf"
    "a15aef77-0db6-4480-a0a5-2a5aa4d74dd4"
    "91b5c5db-296b-4491-b220-1cfa5231a875"
    "b703f623-4cd0-4325-9d93-660c48fb0199"
    "5396d289-b7e1-4bdb-90f6-2b57e0ad7fc5"
    "0d806f9b-0416-47bb-8583-e5461fecb669"
    # Master Bath
    "e15184b3-d09a-4b0a-b8b1-fd8a16f69a0c"
    # Jordan's Room
    "9c26b749-70db-4492-996e-c0dad1e41cd1"
    "585292eb-f27d-432d-a82f-db450c8c9fb2"
    "c75776ff-d48f-4ec8-b8cc-5dd45e50e9d7"
    # Keston's Room
    "2d2cc7f7-9987-44d6-be2c-86420050157c"
    "a2a890cf-6d44-480d-887f-14c711ba4821"
    "d3bbd5c5-585c-48b1-a01d-4eb5a4d7f4c6"
    # TV Room
    "aacd4d39-f3fa-42d4-9ac4-0abf1647854d"
    # Balcony
    "7b12ed85-aebe-4c3e-9471-ad8598443ef3"
)

create_scene "Deep Ocean" "$WHOLE_HOME_ZONE" "zone" "OCEAN" "${ALL_LIGHTS[@]}"

echo ""
echo "========================================"
echo "Done! Check the Hue app for new scenes"
echo "========================================"
