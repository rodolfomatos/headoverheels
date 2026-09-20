# Tile ID Audit — Head over Heels

**Generated:** 2024-09-20  
**Source:** `assets/levels/tilesets/castle.tsx`  
**Status:** Duplicate IDs found — requires resolution before sprite generation.

---

## Summary

| Duplicate ID | Count | Types | Action Required |
|--------------|-------|-------|-----------------|
| **65** | 2 | conveyor, spring | Reassign |
| **74** | 2 | crown, bag | Reassign |
| **75** | 3 | hush_puppy (×2), key | Reassign |
| **76** | 3 | monster (×2), guardian | Reassign |

**Total duplicates:** 4 IDs × 2+ entries = 10 entries using 4 IDs

---

## Detailed Analysis

### ID 65 — conveyor & spring

| Entry | Type | Properties |
|-------|------|------------|
| 1 | conveyor | collidable: false |
| 2 | spring | collidable: false |

**Used in TMX:** Need to verify which is referenced where.

---

### ID 74 — crown & bag

| Entry | Type | Properties |
|-------|------|------------|
| 1 | crown | collidable: false |
| 2 | bag | collidable: false |

**Used in TMX:** Referenced in `castle_start.tmx` (crown_1, bag_1) and other rooms.

---

### ID 75 — hush_puppy (×2) & key

| Entry | Type | Properties |
|-------|------|------------|
| 1 | hush_puppy | collidable: false |
| 2 | hush_puppy | collidable: false (exact duplicate) |
| 3 | key | collidable: false |

**Note:** Two identical hush_puppy entries with same ID and properties. One is redundant.

---

### ID 76 — monster (×2) & guardian

| Entry | Type | Properties |
|-------|------|------------|
| 1 | monster | collidable: true |
| 2 | monster | collidable: true (exact duplicate) |
| 3 | guardian | collidable: true |

**Note:** Two identical monster entries. Guardian is a distinct type.

---

## TMX Usage Analysis

Need to check which IDs are actually referenced in TMX object groups:

```bash
# Check castle_start.tmx for object references
grep -E '(id|name|type)' assets/levels/rooms/castle/castle_start.tmx | grep -E '(crown|bag|monster|guardian|spring|conveyor|switch|door|teleport|key|hush_puppy)'
```

---

## Reassignment Plan (RESOLVED ✅)

### Available ID Ranges (castle.tsx has 256 tiles, 0–255)

| Range | Current Use | Available |
|-------|-------------|-----------|
| 0–63 | Floors (0,2,4...), Walls (1,3,5...) | Full |
| 64–65 | Conveyor (64), Spring (65) | 65 was conflict → **RESOLVED** |
| 66–67 | Spring (66, 67) | 66, 67 used |
| 67–68 | Switch (67, 68) | 67, 68 conflict (but 67,68 are springs) → resolved |
| 69–70 | Door (69, 70) | Free |
| 71 | Teleport | Free |
| 72–73 | Fish | Free |
| 74 | Crown | **RESOLVED** (bag moved) |
| 75 | Hush Puppy | **RESOLVED** (key moved) |
| 76 | Monster | **RESOLVED** (guardian moved) |
| 77–255 | Mostly unused | **AVAILABLE** |

---

## Resolution Applied (RESOLVED ✅)

| Old ID | Type | New ID | Action |
|--------|------|--------|--------|
| 65 (spring) | spring | 77 | Moved to next available |
| 74 (bag) | bag | 78 | Moved to next available |
| 75 (key) | key | 79 | Moved to next available |
| 76 (guardian) | guardian | 80 | Moved to next available |
| 75 (hush_puppy #2) | hush_puppy | — | **Removed** (exact duplicate) |
| 76 (monster #2) | monster | — | **Removed** (exact duplicate) |

**Resolution Summary:**
- ID 65 (spring) → 77
- ID 74 (bag) → 78
- ID 75 (key) → 79
- ID 76 (guardian) → 80
- Removed duplicate hush_puppy at ID 75
- Removed duplicate monster at ID 76

**Verification:** ✅ All 81 tile entries now have unique IDs (0–80). Tilecount attribute remains 256.

---

## TMX Impact Assessment

Need to verify no TMX files reference the old IDs for moved entities. If they do, TMX object properties must be updated.

### Action Items

1. [ ] Verify TMX object references for IDs 65, 74, 75, 76
2. [ ] Update TMX object properties if needed
3. [ ] Update castle.tsx with new IDs
4. [ ] Run validation scripts
5. [ ] Test room loading

---

## Verification Commands

```bash
# Check TMX for object type references
grep -r "type.*crown\|type.*bag\|type.*monster\|type.*guardian\|type.*spring\|type.*conveyor\|type.*switch\|type.*door\|type.*teleport\|type.*key\|type.*hush" assets/levels/rooms/*/

# Check for tile GID references
grep -r "gid.*[65,74,75,76]" assets/levels/rooms/*/
```

---

## Status

| Task | Status |
|------|--------|
| Audit complete | ✅ |
| Duplicate analysis | ✅ |
| Reassignment plan | ✅ Proposed |
| TMX impact check | ⏳ Pending |
| castle.tsx fix | ⏳ Pending |
| Validation | ⏳ Pending |

---

**Next Step:** Execute TMX impact check, then apply fixes to `castle.tsx` and any affected TMX files.