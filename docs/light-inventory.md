# Light Inventory & Mappings

## Main Floor (Dining/Kitchen/Living)

### Signe Floor Lamps (North Wall, E→W)
| Position | v1 ID | Name | v2 UUID | Gradient |
|----------|-------|------|---------|----------|
| E (east) | 17 | Signe main floor E | 457a3777-b619-4765-92a0-7292cbbaab7b | Yes (5pt, 10px) |
| ME | 22 | Signe main floor ME | ca82265e-1ee9-4337-a0d4-e44b46b21b1d | Yes |
| M (middle) | 32 | Signe main floor M | d1a940ac-c385-4857-88dc-bb89ff5ddfc4 | Yes |
| MW | 31 | Signe main floor MW | 03e56936-b959-4687-b2de-5f2f670c8674 | Yes |
| W (west) | 18 | Signe main floor W | fa08b99f-aa8a-4683-af76-c0e3fd566217 | Yes |

**Physical spacing (for animations):**
- W → MW: 11.5'
- MW → M: 4'
- M → ME: 7'
- ME → E: 9'
- Total span: 31.5'

### Kitchen Pendant Clusters
| Cluster | v1 IDs | Names | Zone ID | Position |
|---------|--------|-------|---------|----------|
| East | 24, 25, 29 | Kitchen E1, E2, E3 | 101 | 5.5' from W Signe |
| West | 26, 27, 28 | Kitchen W1, W2, W3 | 102 | 2' from W Signe |

**Notes:**
- 6" frosted globe bulbs, 3 per cluster
- Best when each cluster is uniform color (avoids "party balloon" effect)

---

## Jamie's Office

| v1 ID | Name | v2 UUID | Type | Gradient |
|-------|------|---------|------|----------|
| 30 | Signe gradient couch corner | 7f91bd72-a9eb-4310-bf9a-461db7d8635c | Signe | Yes |
| 23 | Signe gradient 4 | 74d25075-110e-4db5-b0e0-f3e60addb10b | Signe | Yes |
| 19 | Hue Play Right | d220cd0b-219f-4eae-8ea1-4fd20fa06275 | Play | No |
| 20 | Hue Play Left | e1e48801-86bd-4725-8098-c6249a8d8346 | Play | No |

**Room ID:** 97

---

## Master Bedroom

### Signe Lamps
| v1 ID | Name | v2 UUID | Gradient |
|-------|------|---------|----------|
| 2 | Signe Jamie | dfcfd007-8106-435e-80d3-4dc09174b783 | Yes |
| 9 | Signe Rob | 6ae37491-1a2f-470f-8204-9c0b7d01da8f | Yes |
| 3 | Signe Rob Desk Left | 52b7c364-3a09-4ada-9b7d-f1d687e4a6bf | Yes |
| 15 | Signe Rob Desk Right | a15aef77-0db6-4480-a0a5-2a5aa4d74dd4 | Yes |

### Twilight Lights
| v1 ID | Name | v2 UUID | Gradient |
|-------|------|---------|----------|
| 10 | Back | 91b5c5db-296b-4491-b220-1cfa5231a875 | Yes |
| 12 | Back | b703f623-4cd0-4325-9d93-660c48fb0199 | Yes |
| 11 | Front | 5396d289-b7e1-4bdb-90f6-2b57e0ad7fc5 | No |
| 13 | Front | 0d806f9b-0416-47bb-8583-e5461fecb669 | No |

**Room ID:** 84
**Zone (with bathroom):** 87

---

## Other Rooms

### Jordan's Bedroom (Room 85)
- Lights: 4 (Back), 5 (Front), 1 (Signe Jordan)

### Keston's Bedroom (Room 86)
- Lights: 6 (Signe Keston), 7 (Back), 8 (Front)

### TV Room (Room 94)
- Light 16: TV lightstrip (gradient capable)

### Balcony (Room 98)
- Light 21: Festavia globe string lights (gradient capable)

---

## Zones

| Zone ID | Name | Lights |
|---------|------|--------|
| 87 | Master Bedroom & Bathroom | 14, 10, 11, 2, 3, 15, 9, 12, 13 |
| 88 | Whole Home | All 32 lights |
| 89 | Jamie's Bedside | 9, 10, 11, 2 |
| 90 | Rob's Bedside | 3, 15, 12, 13 |
| 96 | House Minus Kids | Most lights except kids' rooms |
| 99 | Kitchen | 24, 29, 25, 27, 26, 28 |
| 101 | Kitchen East | 24, 25, 29 |
| 102 | Kitchen West | 26, 27, 28 |
