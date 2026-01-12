#!/bin/bash
# Room definitions - light UUIDs organized by room
# Source this file to get room arrays

# =============================================================================
# MAIN FLOOR - DINING/KITCHEN/LIVING
# =============================================================================

# Main floor Signes (W→E order for wave animations)
DINING_SIGNES=(
    "fa08b99f-aa8a-4683-af76-c0e3fd566217"   # W (Signe dining table)
    "03e56936-b959-4687-b2de-5f2f670c8674"   # MW (Signe couch corner)
    "d1a940ac-c385-4857-88dc-bb89ff5ddfc4"   # M (Signe kitchen table)
    "ca82265e-1ee9-4337-a0d4-e44b46b21b1d"   # ME (Signe kitchen)
    "457a3777-b619-4765-92a0-7292cbbaab7b"   # E (Signe main floor front)
)

# Kitchen pendant clusters
KITCHEN_WEST=(
    "ca9107e3-4f2c-4383-bf1a-67ae0765bbdf"   # Kitchen 4
    "52e22f83-a8c0-4ede-9a5e-68801c8c69f7"   # Kitchen 5
    "bd5ef4f9-7258-4ee8-af97-851b9713c147"   # Kitchen 6
)
KITCHEN_EAST=(
    "dd90028e-5494-4585-9a75-cb593d1275ec"   # Kitchen 1
    "7fabbbed-4222-4bf4-baee-64977ebc5dde"   # Kitchen 2
    "f95f8da4-3dd0-4f80-91a5-ca8ad1a7ff22"   # Kitchen 3
)
KITCHEN_ALL=("${KITCHEN_WEST[@]}" "${KITCHEN_EAST[@]}")

# =============================================================================
# JAMIE'S OFFICE
# =============================================================================

JAMIE_SIGNES=(
    "7f91bd72-a9eb-4310-bf9a-461db7d8635c"   # Signe gradient couch corner
    "74d25075-110e-4db5-b0e0-f3e60addb10b"   # Signe gradient 4
)
JAMIE_PLAYS=(
    "d220cd0b-219f-4eae-8ea1-4fd20fa06275"   # Hue Play Right
    "e1e48801-86bd-4725-8098-c6249a8d8346"   # Hue Play Left
)

# =============================================================================
# MASTER BEDROOM
# =============================================================================

MASTER_SIGNES=(
    "dfcfd007-8106-435e-80d3-4dc09174b783"   # Signe Jamie
    "6ae37491-1a2f-470f-8204-9c0b7d01da8f"   # Signe Rob
    "52b7c364-3a09-4ada-9b7d-f1d687e4a6bf"   # Signe Rob Desk Left
    "a15aef77-0db6-4480-a0a5-2a5aa4d74dd4"   # Signe Rob Desk Right
)
TWILIGHT_BACKS=(
    "91b5c5db-296b-4491-b220-1cfa5231a875"   # Back 1
    "b703f623-4cd0-4325-9d93-660c48fb0199"   # Back 2
)
TWILIGHT_FRONTS=(
    "5396d289-b7e1-4bdb-90f6-2b57e0ad7fc5"   # Front 1
    "0d806f9b-0416-47bb-8583-e5461fecb669"   # Front 2
)

# =============================================================================
# MASTER BATHROOM
# =============================================================================

MASTER_BATH=(
    "e15184b3-d09a-4b0a-b8b1-fd8a16f69a0c"   # Signe Master Bathroom
)

# =============================================================================
# KIDS' ROOMS
# =============================================================================

# Note: Light IDs verified against bridge 2025-01-11
JORDAN_SIGNE=("9c26b749-70db-4492-996e-c0dad1e41cd1")
JORDAN_BACK=("a2a890cf-6d44-480d-887f-14c711ba4821")
JORDAN_FRONT=("c75776ff-d48f-4ec8-b8cc-5dd45e50e9d7")

KESTON_SIGNE=("2d2cc7f7-9987-44d6-be2c-86420050157c")
KESTON_BACK=("585292eb-f27d-432d-a82f-db450c8c9fb2")
KESTON_FRONT=("d3bbd5c5-585c-48b1-a01d-4eb5a4d7f4c6")

# =============================================================================
# OTHER ROOMS
# =============================================================================

TV_ROOM=("aacd4d39-f3fa-42d4-9ac4-0abf1647854d")   # TV lightstrip
BALCONY=("7b12ed85-aebe-4c3e-9471-ad8598443ef3")   # Festavia globe string lights

# =============================================================================
# COMPOSITE ROOM GROUPS
# =============================================================================

# Get lights for a named room - returns space-separated list of gradient:uuid or solid:uuid
get_room_lights() {
    local room=$1
    case "$room" in
        dining)
            for id in "${DINING_SIGNES[@]}"; do echo "gradient:$id"; done
            for id in "${KITCHEN_ALL[@]}"; do echo "solid:$id"; done
            ;;
        dining-signes-only)
            for id in "${DINING_SIGNES[@]}"; do echo "gradient:$id"; done
            ;;
        kitchen)
            for id in "${KITCHEN_ALL[@]}"; do echo "solid:$id"; done
            ;;
        jamies-office)
            for id in "${JAMIE_SIGNES[@]}"; do echo "gradient:$id"; done
            for id in "${JAMIE_PLAYS[@]}"; do echo "gradient:$id"; done
            ;;
        master-bedroom)
            for id in "${MASTER_SIGNES[@]}"; do echo "gradient:$id"; done
            for id in "${TWILIGHT_BACKS[@]}"; do echo "gradient:$id"; done
            for id in "${TWILIGHT_FRONTS[@]}"; do echo "solid:$id"; done
            ;;
        master-bath)
            for id in "${MASTER_BATH[@]}"; do echo "gradient:$id"; done
            ;;
        jordans-room)
            for id in "${JORDAN_SIGNE[@]}"; do echo "gradient:$id"; done
            for id in "${JORDAN_BACK[@]}"; do echo "gradient:$id"; done
            for id in "${JORDAN_FRONT[@]}"; do echo "solid:$id"; done
            ;;
        kestons-room)
            for id in "${KESTON_SIGNE[@]}"; do echo "gradient:$id"; done
            for id in "${KESTON_BACK[@]}"; do echo "gradient:$id"; done
            for id in "${KESTON_FRONT[@]}"; do echo "solid:$id"; done
            ;;
        tv-room)
            for id in "${TV_ROOM[@]}"; do echo "gradient:$id"; done
            ;;
        balcony)
            for id in "${BALCONY[@]}"; do echo "gradient:$id"; done
            ;;
        whole-house)
            get_room_lights dining
            get_room_lights jamies-office
            get_room_lights master-bedroom
            get_room_lights master-bath
            get_room_lights jordans-room
            get_room_lights kestons-room
            get_room_lights tv-room
            get_room_lights balcony
            ;;
        adults-only)
            get_room_lights dining
            get_room_lights jamies-office
            get_room_lights master-bedroom
            get_room_lights master-bath
            ;;
        bedrooms)
            get_room_lights master-bedroom
            get_room_lights jordans-room
            get_room_lights kestons-room
            ;;
        *)
            echo "Unknown room: $room" >&2
            return 1
            ;;
    esac
}

# List available rooms
list_rooms() {
    echo "Available rooms:"
    echo "  dining            - Main floor Signes + kitchen pendants"
    echo "  dining-signes-only - Just the 5 Signe floor lamps"
    echo "  kitchen           - Just the 6 kitchen pendants"
    echo "  jamies-office     - Jamie's office (2 Signes + 2 Plays)"
    echo "  master-bedroom    - Master bedroom (4 Signes + 4 Twilights)"
    echo "  master-bath       - Master bathroom Signe"
    echo "  jordans-room      - Jordan's bedroom"
    echo "  kestons-room      - Keston's bedroom"
    echo "  tv-room           - TV room lightstrip"
    echo "  balcony           - Balcony Festavia lights"
    echo "  whole-house       - All 32 lights"
    echo "  adults-only       - Dining + Jamie's office + Master suite"
    echo "  bedrooms          - All bedrooms"
}
