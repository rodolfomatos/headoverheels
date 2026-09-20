# Naming Convention — Head over Heels Sprites

**Version:** 1.0  
**Status:** Authoritative  
**Enforcement:** Automated via `scripts/validate_sprites.py`

---

## 1. Canonical Format

```
{category}_{asset}_{animation}_{direction}_{frame}.png
```

### Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| category | enum | Yes | Asset category |
| asset | string | Yes | Specific asset identifier |
| animation | string | Yes | Animation state |
| direction | enum | Conditional | 8-direction code (omitted for 1-dir) |
| frame | int | Yes | Zero-padded frame number (01, 02, ...) |

---

## 2. Category Prefixes

| Category | Prefix | Examples |
|----------|--------|----------|
| Characters | `character_` | `character_head_`, `character_heels_`, `character_duo_` |
| Entities | `entity_` | `entity_fish_`, `entity_rabbit_`, `entity_crown_` |
| Tiles | `tile_{theme}_` | `tile_castle_`, `tile_egyptus_` |
| UI | `ui_` | `ui_crown_`, `ui_doughnut_` |
| Effects | `fx_` | `fx_explosion_`, `fx_sparkle_` |

---

## 3. Asset Identifiers

### Characters
| Asset | Identifier |
|-------|------------|
| Head | `head` |
| Heels | `heels` |
| Combined (Duo) | `duo` |

### Entities
| Entity | Identifier |
|--------|------------|
| Reincarnation Fish | `fish` |
| Cuddly Rabbit | `rabbit` |
| Crown | `crown` |
| Spring | `spring` |
| Switch | `switch` |
| Conveyor | `conveyor` |
| Teleport | `teleport` |
| Door | `door` |
| Monster | `monster` |
| Guardian | `guardian` |
| Hush Puppy | `hush_puppy` |
| Bag | `bag` |
| Key | `key` |
| Doughnut | `doughnut` |
| Iron Pill | `iron_pill` |
| Speed Pill | `speed_pill` |
| Jump Pill | `jump_pill` |
| Life Pill | `life_pill` |

### Tiles (per theme)
| Theme | Prefix |
|-------|--------|
| Castle | `tile_castle_` |
| Egyptus | `tile_egyptus_` |
| Penitentiary | `tile_penitentiary_` |
| Safari | `tile_safari_` |
| Bookworld | `tile_bookworld_` |
| Moonbase | `tile_moonbase_` |

### UI
| Element | Identifier |
|---------|------------|
| Crown icon | `crown` |
| Doughnut counter | `doughnut` |
| Bag icon | `bag` |
| Key icon | `key` |
| Life icon | `life` |
| Pause button | `pause` |
| Menu icons | `menu_*` |

### Effects
| Effect | Identifier |
|--------|------------|
| Explosion | `explosion` |
| Sparkle | `sparkle` |
| Teleport | `teleport` |
| Hit | `hit` |
| Death | `death` |

---

## 4. Animation States

| State | Code | Notes |
|-------|------|-------|
| idle | `idle` | Looping |
| walk | `walk` | 8-frame loop |
| run | `run` | 8-frame loop (Heels) |
| jump | `jump` | Non-looping |
| climb | `climb` | Looping |
| fire | `fire` | Non-looping |
| carry | `carry` | Looping |
| combined | `combined` | Duo mode |
| idle (entity) | `idle` | Looping |
| active | `active` | Entity-specific |
| death | `death` | Non-looping |
| collected | `collected` | Non-looping |
| rotate | `rotate` | Looping (crown) |

---

## 5. Direction Codes

| Direction | Code | Angle |
|-----------|------|-------|
| North | `n` | 0° |
| Northeast | `ne` | 45° |
| East | `e` | 90° |
| Southeast | `se` | 135° |
| South | `s` | 180° |
| Southwest | `sw` | 225° |
| West | `w` | 270° |
| Northwest | `nw` | 315° |

**Omission rule:** For single-direction assets (entities, UI), omit direction entirely.

---

## 6. Frame Numbers

- Zero-padded two digits: `01`, `02`, `03`, ..., `08`
- Start at `01` (not `00`)
- Sequential within animation

---

## 7. Complete Examples

### Characters
```
character_head_idle_s_01.png
character_head_walk_ne_03.png
character_heels_walk_e_05.png
character_heels_run_n_08.png
character_duo_idle_s_01.png
character_duo_jump_ne_02.png
character_duo_fire_s_01.png
```

### Entities
```
entity_fish_idle_01.png
entity_fish_dead.png
entity_fish_eaten_01.png
entity_rabbit_life_hop_01.png
entity_rabbit_shield_collected_03.png
entity_crown_castle_rotate_04.png
entity_crown_egyptus_collected_02.png
entity_spring_idle_e_01.png
entity_spring_compressed.png
entity_switch_off.png
entity_switch_on.png
entity_conveyor_e_01.png
entity_teleport_idle_03.png
entity_door_castle_locked.png
entity_door_egyptus_open.png
entity_monster_walk_s_04.png
entity_monster_freeze_ne_01.png
entity_guardian_patrol_w_06.png
entity_hush_puppy_sleep_02.png
entity_bag_idle.png
entity_key_castle.png
entity_doughnut.png
```

### Tiles
```
tile_castle_floor_01.png
tile_castle_floor_cracked_03.png
tile_castle_wall_straight_01.png
tile_castle_wall_corner_02.png
tile_castle_conveyor_e_02.png
tile_castle_spring_01.png
tile_castle_switch_off.png
tile_castle_switch_on.png
tile_castle_door_locked.png
tile_castle_teleport_01.png

tile_egyptus_floor_01.png
tile_egyptus_wall_hieroglyph_02.png
...
```

### UI
```
ui_crown.png
ui_crown_egyptus.png
ui_doughnut.png
ui_bag.png
ui_key_castle.png
ui_life.png
ui_pause.png
ui_menu_play.png
ui_menu_settings.png
```

### Effects
```
fx_explosion_01.png
fx_sparkle_03.png
fx_teleport_in_02.png
fx_hit_01.png
fx_death_04.png
fx_sparkle_burst_01.png
```

---

## 8. Tileset Image Naming

### Master Tileset Images
```
tileset_castle.png
tileset_egyptus.png
tileset_penitentiary.png
tileset_safari.png
tileset_bookworld.png
tileset_moonbase.png
```

### Manifest JSON (per tileset)
```
tileset_castle.json
tileset_egyptus.json
...
```

### Manifest Structure
```json
{
  "tileset": "castle",
  "version": "1.0",
  "tile_width": 64,
  "tile_height": 32,
  "tiles": [
    { "id": 0, "name": "floor_clean", "x": 0, "y": 0, "type": "floor" },
    { "id": 1, "name": "floor_cracked", "x": 64, "y": 0, "type": "floor" },
    ...
  ]
}
```

---

## 9. Manifest Files

### Sprite Manifest
```
assets/sprites/manifest.json
```

### Atlas Manifests
```
assets/atlases/characters.json
assets/atlases/entities.json
assets/atlases/castle.json
...
```

---

## 10. Validation Rules

The `scripts/validate_sprites.py` enforces:

1. **Format match**: Regex `^[a-z]+_[a-z0-9_]+(?:_[a-z]+)?(?:_[nsew]{1,2})?_\d{2}\.png$`
2. **Category validity**: Must match known category
3. **Asset validity**: Must match known asset for category
4. **Direction validity**: Must be valid 8-direction code
5. **Frame format**: Two digits, 01-99
7. **No spaces/special chars**: Only lowercase, digits, underscore, hyphen
8. **Extension**: Must be `.png`

---

## 11. Anti-Patterns (Forbidden)

```
character_head_idle.png           (no frame number)
character_head_IDLE.png           (uppercase)
character_head_walk_N_1.png       (single digit frame)
character-head-walk-n-01.png      (hyphens)
character_head_walk_north_01.png  (full direction name)
Character_Head_Walk_N_01.png      (mixed case)
character_head_walk_n_01.jpg      (wrong extension)
```