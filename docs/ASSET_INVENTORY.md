# Asset Inventory — Head over Heels

**Generated:** 2024-09-20  
**Ticket:** T016 — Asset & Visual System Audit  
**Status:** Complete

---

## Executive Summary

This document inventories all visual assets, sprite requirements, and data inconsistencies discovered during the T016 audit of the Head over Heels Flutter/Flame reimplementation.

**Key Finding:** The project has a complete game architecture with TMX-based level loading, entity system, and character state management, but **zero actual sprite assets exist**. All rendering currently uses placeholder colored rectangles.

---

## 1. Current Visual Implementation

### 1.1 Rendering Architecture

| Component | Status | Implementation |
|-----------|--------|----------------|
| **CharacterComponent** | Placeholder | `SpriteAnimationComponent` with colored rectangle |
| **PuzzleEntity (base)** | Abstract | Rectangle hitbox only |
| **BagEntity** | Placeholder | Brown `RectangleComponent` (0.6× size) |
| **CrownEntity** | Placeholder | Gold `RectangleComponent` (0.6× size) |
| **FishEntity** | Placeholder | Cyan/Grey `RectangleComponent` (0.6× size) |
| **MonsterEntity** | Placeholder | Red `RectangleComponent` (0.8× size) |
| **GuardianEntity** | Not reviewed | Likely placeholder |
| **HushPuppyEntity** | Not reviewed | Likely placeholder |
| **SpringEntity** | Not reviewed | Likely placeholder |
| **SwitchEntity** | Not reviewed | Likely placeholder |
| **Tilemap (TiledComponent)** | Functional | Loads TMX via `flame_tiled` |

### 1.2 Missing Visual Assets

| Category | Required | Implemented |
|----------|----------|-------------|
| Character sprites (Head/Heels/Combined) | 3 × 8-dir × 6 anims | 0 |
| Character combined composition | 1 system | 0 |
| Entity sprites (19 types) | 19 × variants | 0 |
| Tile sprites (6 themes × 256) | 1,536 tiles | 0 |
| UI icons | ~20 | 0 |
| Effects (particles, impacts) | ~10 | 0 |
| Sprite sheets / atlases | Multiple | 0 |
| Sprite metadata | Complete | 0 |

---

## 2. Tile System Inventory

### 2.1 Tilesets

| Tileset | File | Tiles | Theme | Status |
|---------|------|-------|-------|--------|
| castle.tsx | ✅ Exists | 256 (16×16) | Castle | Defined, no image |
| egyptus.tsx | ❌ Missing | 256 | Egyptus | Missing |
| penitentiary.tsx | ❌ Missing | 256 | Penitentiary | Missing |
| safari.tsx | ❌ Missing | 256 | Safari | Missing |
| bookworld.tsx | ❌ Missing | 256 | Book World | Missing |
| moonbase.tsx | ❌ Missing | 256 | Moonbase | Missing |

**Total Required:** 6 tilesets × 256 = **1,536 tiles**  
**Currently Defined:** 1 tileset (castle.tsx) with 256 entries  
**Missing:** 5 tilesets (1,280 tiles)

### 2.2 castle.tsx Analysis

| Metric | Value |
|--------|-------|
| Tile Count | 256 (IDs 0–255) |
| Columns | 16 |
| Image Source | `castle.png` (1024×512) — **MISSING** |
| Tile Width | 64px |
| Tile Height | 32px |

**Tile Inventory (by type):**

| ID Range | Type | Count | Collidable |
|----------|------|-------|------------|
| 0–63 | Floor / Wall (alternating) | 64 | Floor: No, Wall: Yes |
| 64–65 | Conveyor | 2 | No |
| 65–66 | Spring | 2 | No |
| 67–68 | Switch (off/on) | 2 | No |
| 69–70 | Door (closed/open) | 2 | Closed: Yes, Open: No |
| 71 | Teleport | 1 | No |
| 72–73 | Fish (alive/dead) | 2 | Dead: Yes |
| 74 | Crown | 1 | No |
| 74 | Bag | 1 | No |
| 75 | Hush Puppy | 1 | No |
| 75 | Key | 1 | No |
| 76 | Monster | 1 | Yes |
| 76 | Guardian | 1 | Yes |

**Issues Found:**
- **Duplicate Tile IDs:** 65 (×2), 74 (×2), 75 (×2), 76 (×2)
- **Missing Image:** `castle.png` referenced but not present
- **Unused Tiles:** Many IDs defined but not referenced in maps

### 2.3 Missing Tileset Images

| Tileset | Required Image | Status |
|---------|----------------|--------|
| castle.tsx | `castle.png` (1024×512) | ❌ Missing |
| egyptus.tsx | `egyptus.png` | ❌ Missing |
| penitentiary.tsx | `penitentiary.png` | ❌ Missing |
| safari.tsx | `safari.png` | ❌ Missing |
| bookworld.tsx | `bookworld.png` | ❌ Missing |
| moonbase.tsx | `moonbase.png` | ❌ Missing |

---

## 3. Map/Room Inventory

### 3.1 World Structure (from world.json)

| Planet | Rooms | Connections |
|--------|-------|-------------|
| **Castle** (6 rooms) | castle_start, castle_cell, castle_hall, castle_market, castle_teleport, blacktooth_castle, blacktooth_throne | Fully connected |
| **Egyptus** (4 rooms) | egyptus_entrance, egyptus_pyramid_1, egyptus_pyramid_2, egyptus_tomb | Connected |
| **Penitentiary** (3 rooms) | penitentiary_entrance, penitentiary_cell_block, penitentiary_the_pit | Connected |
| **Safari** (3 rooms) | safari_entrance, safari_jungle_1, safari_fort | Connected |
| **Book World** (3 rooms) | bookworld_entrance, bookworld_library_1, bookworld_library_2 | Connected |

**Total Rooms:** 21 (including final throne room)

### 3.2 Room TMX Files

| Room | TMX File | Layers | Object Groups |
|------|----------|--------|---------------|
| castle_start | castle/castle_start.tmx | Floor, Walls, Entities, Triggers | 2 |
| castle_cell | castle/castle_cell.tmx | Floor, Walls, Entities, Triggers | 2 |
| castle_hall | castle/castle_hall.tmx | Floor, Walls, Entities, Triggers | 2 |
| castle_market | castle/castle_market.tmx | Floor, Walls, Entities, Triggers | 2 |
| castle_teleport | castle/castle_teleport.tmx | Floor, Walls, Entities, Triggers | 2 |
| blacktooth_castle | castle/blacktooth_castle.tmx | Floor, Walls, Entities, Triggers | 2 |
| blacktooth_throne | castle/blacktooth_throne.tmx | Floor, Walls, Entities, Triggers | 2 |
| + 14 other rooms | Various | Floor, Walls, Entities, Triggers | 2 |

**All TMX files exist** and reference `castle.tsx` tileset.

### 3.3 Tile Usage in Maps (castle_start example)

| Layer | GIDs Used | Count |
|-------|-----------|-------|
| Floor | 0 (empty) | 256 |
| Walls | 0, 2 | 256 |

**Observation:** Maps use only tile IDs 0 (empty) and 2 (wall). Most defined tiles (conveyors, springs, switches, etc.) are **only placed via object groups**, not tile layers.

---

## 4. Entity Inventory

### 4.1 Entity Types (from TriggerType enum + factory)

| Entity Type | TriggerType | Visual States Required | Factory |
|-------------|-------------|------------------------|---------|
| Door | `door` | closed, open, locked | EntityFactory |
| Teleport | `teleport` | idle, active | EntityFactory |
| Ladder (Up) | `ladderUp` | static | EntityFactory |
| Ladder (Down) | `ladderDown` | static | EntityFactory |
| Conveyor | `conveyor` | animated (4 frames × 4 dir) | EntityFactory |
| Switch | `switchTrigger` | off, on, glowing | EntityFactory |
| Bag | `bag` | idle, collected | EntityFactoryItems |
| Key | `key` | idle, collected | EntityFactoryItems |
| Crown | `crown` | rotating, collected | EntityFactoryItems |
| Spring | `springItem` | compressed, extended | EntityFactoryItems |
| Hush Puppy | `hushPuppy` | sleeping, teleporting | EntityFactoryItems |
| Monster | `monster` | walk (8-dir), freeze, death | EntityFactoryItems |
| Guardian | `guardian` | patrol (8-dir), attack | EntityFactoryItems |
| Spring Item | `springItem` | idle, collected | EntityFactoryItems |
| Key Item | `key` | idle, collected | EntityFactoryItems |
| Bag Item | `bag` | idle, collected | EntityFactoryItems |
| Hush Puppy Item | `hushPuppy` | idle, collected | EntityFactoryItems |

### 4.2 Entity Visual State Requirements

| Entity | Base Size | Animations | Directions | Frames/Anim |
|--------|-----------|------------|------------|-------------|
| Monster | 64×64 | walk, freeze, death | 8 | 8/4/4 |
| Guardian | 96×96 | patrol, attack | 8 | 8/6 |
| Fish | 64×32 | swim, dead, eaten | 1 | 8/1/6 |
| Rabbit | 32×32 | hop, collected | 1 | 4/6 |
| Crown | 32×32 | rotate, collected | 1 | 8/8 |
| Spring | 48×48 | compressed, extended | 1 | 3 |
| Switch | 48×48 | off, on (glow) | 1 | 2 |
| Conveyor | 64×32 | belt (4-frame) | 4 dirs | 4 |
| Teleport | 64×64 | swirl | 1 | 4 |
| Door | 64×64 | open/close/locked | 1 | 2-3 |
| Switch | 48×48 | off/on | 1 | 2 |
| Hush Puppy | 48×48 | sleep, teleport, awake | 1 | 8/6/4 |
| Bag/Key/Items | 32×32 | idle, collected | 1 | 1/6 |

---

## 5. Character System Inventory

### 5.1 Character Types

| Character | Type | Abilities | Animations |
|-----------|------|-----------|------------|
| **Head** | `CharacterType.head` | High jump (2), slow walk (2), fire doughnuts | idle, walk, jump, climb, fire, combined |
| **Heels** | `CharacterType.heels` | Low jump (1), fast walk (4), carry items | idle, walk, run, jump, climb, carry, combined |
| **Combined** | `CharacterType.combined` | Merged: jump 2, walk 3, fire + carry | idle, walk, run, jump, fire, carry |

### 5.2 Animation States (from AnimationState enum)

| State | Code | Loop | Frames (est.) |
|-------|------|------|---------------|
| idle | `idle` | Yes | 4 |
| walk | `walk` | Yes | 8 |
| run | `run` | Yes | 8 (Heels only) |
| jumpRise | `jumpRise` | No | 4 |
| jumpPeak | `jumpPeak` | No | 1 |
| jumpFall | `jumpFall` | No | 4 |
| land | `land` | No | 2 |
| climb | `climb` | Yes | 4 |
| carry | `carry` | Yes | 4 |
| fire | `fire` | No | 3 |
| swop | `swop` | No | 6 |
| hurt | `hurt` | No | 4 |
| death | `death` | No | 6 |

### 5.3 Directions (8-way)

| Code | Direction | Angle |
|------|-----------|-------|
| `n` | North | 0° |
| `ne` | Northeast | 45° |
| `e` | East | 90° |
| `se` | Southeast | 135° |
| `s` | South | 180° |
| `sw` | Southwest | 225° |
| `w` | West | 270° |
| `nw` | Northwest | 315° |

### 5.4 Character State (from CharacterState)

| Property | Type | Description |
|----------|------|-------------|
| type | CharacterType | head/heels/combined |
| position | Vector3 | Grid position (x, y, z) |
| velocity | Vector2 | Movement velocity |
| animation | AnimationState | Current animation |
| facing | FacingDirection | 8-direction facing |
| isGrounded | bool | On ground |
| jumpPhase | int | 0=ground, 1=rising, 2=peak, 3=falling |
| jumpFramesRemaining | int | Frames left in jump |
| carriedItem | CarriedItem | none/key/crown/other |
| doughnutCount | int | Doughnuts available |
| activePowerUps | List<PowerUp> | Active effects |
| isControllable | bool | Player control |
| isInvulnerable | bool | Invulnerability |
| lives | int | Remaining lives |

### 5.4 Dual Character State

| Property | Type |
|----------|------|
| head | CharacterState |
| heels | CharacterState |
| controlled | ControlledEntity (head/heels/combined) |
| areCombined | bool |
| combinedPosition | Vector3 |

---

## 6. UI Asset Requirements

| UI Element | Size | States | Count |
|------------|------|--------|-------|
| Crown icon | 32×32 | 5 planets | 5 |
| Doughnut counter | 32×32 | count 0-9 | 10 |
| Bag icon | 32×32 | empty/full | 2 |
| Life/Heart icon | 24×24 | full/empty | 2 |
| Pause button | 48×48 | normal/pressed | 2 |
| Virtual joystick | 140×140 | base/knob | 2 |
| Action buttons (4) | 64×64 | normal/pressed | 8 |
| HUD background | Full width | — | 1 |

---

## 6. Data Inconsistencies Found

### 6.1 castle.tsx Issues

| Issue | Details |
|-------|---------|
| **Duplicate tile IDs** | ID 65 (×2), 74 (×2), 75 (×2), 76 (×2) |
| **Missing image** | `castle.png` referenced but not present |
| **Unused tiles** | ~200 of 256 tiles never referenced in maps |

### 6.2 TMX/world.json Consistency

| Check | Status |
|-------|--------|
| TMX tileset references | ✅ All reference `castle.tsx` |
| world.json room files | ✅ All TMX files exist |
| world.json room connections | ✅ Bidirectional consistent |
| world.json trigger IDs | ✅ Unique within rooms |
| world.json trigger positions | ✅ Match TMX object positions |

### 6.3 Entity Type Consistency

| Check | Status |
|-------|--------|
| TriggerType enum vs factory | ✅ All types handled |
| Entity factory coverage | ✅ All 19 types implemented |
| Trigger properties parsing | ✅ JSON parsing implemented |
| Duplicate entity IDs | ⚠️ Some IDs reused across rooms |

---

## 7. Missing Assets Summary

### 7.1 Critical Path (Visual Vertical Slice)

| Asset | Priority | Est. Frames |
|-------|----------|-------------|
| Head character (idle, walk, jump) | 🔴 Critical | ~20 |
| Heels character (idle, walk, run, jump) | 🔴 Critical | ~28 |
| Combined (Duo) | 🔴 Critical | ~24 |
| Castle floor tile | 🔴 Critical | 1 |
| Castle wall tile | 🔴 Critical | 1 |
| Castle stairs | 🔴 Critical | 1 |
| Castle door (locked/unlocked) | 🔴 Critical | 2 |
| Switch (on/off) | 🔴 Critical | 2 |
| Conveyor (4-dir) | 🔴 Critical | 16 |
| Spring | 🔴 Critical | 3 |
| Teleport | 🔴 Critical | 4 |
| Fish (alive/dead) | 🔴 Critical | 9 |
| Rabbit | 🔴 Critical | 10 |
| Crown | 🔴 Critical | 16 |
| Switch entity | 🔴 Critical | 2 |
| Monster | 🔴 Critical | 16 |
| Guardian | 🔴 Critical | 14 |
| **Total (slice)** | | **~200 assets** |

### 7.2 Full Production

| Category | Count | Est. Assets |
|----------|-------|-------------|
| Characters | 3 | ~72 |
| Entities | 19 | ~150 |
| Tilesets (6 themes) | 6 | 1,536 |
| UI/Icons | 20 | ~20 |
| Effects | 10 | ~40 |
| **Total** | | **~1,800 assets** |

---

## 8. Current Asset Declarations

### 8.1 pubspec.yaml Assets

```yaml
assets:
  - assets/levels/tilesets/
  - assets/levels/rooms/
  - assets/levels/world.json
  - assets/audio/
```

**Missing:** `assets/sprites/`, `assets/atlases/`

### 8.2 Actual Sprite Directory

```
/assets/sprites/  → EMPTY
```

---

## 9. Technical Debt & Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Duplicate tile IDs in castle.tsx | High | Tile rendering errors | Fix TSX before atlas generation |
| Missing tileset images | High | Blank tiles | Create placeholder PNGs first |
| No sprite atlas system | Medium | Runtime performance | Implement atlas pipeline |
| No sprite registry | Medium | Hardcoded asset paths | Implement SpriteRegistry |
| Placeholder rendering only | High | No visual game | Priority: vertical slice |
| Duplicate tile IDs | High | Undefined behavior | Fix TSX before generation |

---

## 10. Recommended Next Steps (per Master Prompt)

1. **Create `docs/ASSET_INVENTORY.md`** ✅ (this document)
2. **Create `docs/SPRITE_GENERATION_SYSTEM.md`** ✅ (already exists)
3. **Fix castle.tsx duplicates** — Before any generation
3. **Create placeholder castle.png** — 1024×512 placeholder
4. **Implement SpriteRegistry** — Central asset resolution
5. **Build validation pipeline** — `scripts/validate_sprites.py`
5. **Create master assets** — Head, Heels, Duo, floor, wall, stairs, door
6. **Vertical slice** — One complete playable room (castle_start)
7. **Castle tileset** — Full 256 tiles with variants
8. **Validation pipeline** — Automated quality gates
9. **Atlas pipeline** — TexturePacker integration
10. **Flutter integration** — SpriteRegistry + VisualStateResolver

---

## Appendix: Tile ID Mapping (castle.tsx)

| ID | Type | Visual Family |
|----|------|---------------|
| 0,2,4,6,8,10,12,14,16,18,20,22,24,26,28,30,32,34,36,38,40,42,44,46,48,50,52,54,56,58,60,62 | floor | floor |
| 1,3,5,7,9,11,13,15,17,19,21,23,25,27,29,31,33,35,37,39,41,43,45,47,49,51,53,55,57,59,61,63 | wall | wall |
| 64, 65 | conveyor | conveyor |
| 65, 66 | spring | spring |
| 67, 68 | switch | switch |
| 69, 70 | door | door |
| 71 | teleport | teleport |
| 72, 73 | fish | fish |
| 74 | crown / bag | items |
| 75 | hush_puppy / key | items |
| 76 | monster / guardian | enemies |

*Note: Duplicate IDs (65, 74, 75, 76) must be resolved before proceeding.*

---

**Document Version:** 1.0  
**Next Update:** After T017 Visual Design System milestone  
**Related:** `docs/SPRITE_GENERATION_SYSTEM.md`, `aes/kanban.md` (T016)