# Visual Design System — Head over Heels 2026

**Version:** 1.0  
**Status:** Active  
**Based on:** REIMAGINING.md specification  
**Authority:** This document is the single source of truth for all visual decisions.

---

## 1. Visual Philosophy — "Head over Heels, if made in 2026"

> **Core Question:** *How would Head over Heels look if its creators designed it in 2026, preserving its identity but without 1987 technical constraints?*

### Guiding Principles

| Principle | Description |
|-----------|-------------|
| **Identity First** | Must be instantly recognisable as Head over Heels |
| **No Artificial Limits** | No 8/16 colour limits, no attribute clash, no hardware constraints |
| **Pixel Art Integrity** | Hard edges, deliberate pixels, clean silhouettes, intentional clusters |
| **Modern Capabilities** | Alpha, lighting, materials, particles, shaders, high-res masters |
| **Isometric Purity** | 2:1 dimetric (64×32), consistent lighting, coherent depth |
| **Scale Freedom** | Masters at high res, runtime scaling via nearest-neighbour |

> **Not:** NES/SNES aesthetics, generic pixel art, AI gloss, vector art, photorealism  
> **Is:** *Head over Heels, if made in 2026*

---

## 2. Colour System — "Spectrum DNA → 2026 Master Palette"

### 2.1 Spectrum DNA (Identity Anchors)

These 8 colours are **identity references**, not limits:

| Name | Hex | Role |
|------|-----|------|
| Spectrum Black | `#000000` | Deep shadows, outlines |
| Spectrum Blue | `#0000D8` | Cold tech, magic |
| Spectrum Red | `#D00000` | Danger, heat, Heels accent |
| Spectrum Magenta | `#A000A0` | Magic, otherworldly |
| Spectrum Green | `#008000` | Life, nature, Head accent |
| Spectrum Cyan | `#008080` | Water, ice, tech |
| Spectrum Yellow | `#C0A000` | Gold, wealth, highlights |
| Spectrum White | `#FFFFFF` | Pure highlights |

> **These are chromatic anchors, not limits.** They define the "Spectrum DNA" that must be perceptible in the final palette.

---

### 2.2 2026 Master Palette Structure

```
Spectrum DNA (8)
    ↓
Shadow Ramps (3 steps per base)
    ↓
Highlight Ramps (3 steps per base)
    ↓
Material Ramps (stone, metal, wood, fabric, organic, magic, tech)
    ↓
Environment Colours (per theme)
    ↓
Effect Colours (fire, water, magic, poison, electric, holy, poison)
```

**Target:** ~120–180 colours total, organised as ramps, not a flat list.

### 2.3 Shadow Ramp Convention

For each base colour, generate 3 shadow steps:

| Step | Luminosity Shift | Use Case |
|------|------------------|----------|
| Shadow 1 | -25% L | Surface facing away from light |
| Shadow 2 | -45% L | Deep crevices, undersides |
| Shadow 3 | -65% L | Deep cavities, contact shadows |

### 2.4 Highlight Ramp Convention

| Step | Luminosity Shift | Use Case |
|------|------------------|----------|
| Highlight 1 | +20% L | Top-left faces (key light) |
| Highlight 2 | +40% L | Sharp edges, ridges |
| Highlight 3 | +60% L | Specular points, glints |

### 2.4 Material Ramps (Examples)

| Material | Base | Shadows | Highlights | Special |
|----------|------|---------|------------|---------|
| **Stone** | Grey ramp | Cool shadows | Warm highlights | Subtle texture noise |
| **Metal** | Grey-blue ramp | High contrast | Sharp white glints | Anisotropic streaks |
| **Wood** | Brown ramp | Warm shadows | Golden highlights | Grain clusters |
| **Metal (Gold)** | Yellow ramp | Orange shadows | White-yellow glints | Reflective |
| **Water** | Cyan-blue ramp | Deep blue | White caustics | Animated caustics |
| **Lava** | Red-orange ramp | Dark red | Bright yellow-white | Animated glow |
| **Fabric** | Hue ramp | Soft shadows | Subtle highlights | Weave pattern |
| **Skin** | Peach/pink ramp | Reddish shadows | Warm highlights | Subsurface scatter hint |

---

## 3. Lighting System

### 3.1 Global Light Source

| Property | Value |
|----------|-------|
| **Key Light** | Top-left (315° / -45°) |
| **Elevation** | 45° |
| **Intensity** | 1.0 (normalised) |
| **Colour** | Warm white (`#FFF8E7`) |

### 3.2 Secondary Lighting

| Component | Specification |
|-----------|---------------|
| **Ambient Fill** | Cool, 15% intensity, from bottom-right |
| **Ambient Occlusion** | Subtle, in crevices and contact points |
| **Contact Shadows** | Strong, under objects, 2px offset down-right |

### 3.3 Per-Object Lighting Rules

| Object Type | Highlight | Shadow | Special |
|-------------|-----------|--------|---------|
| **Floor** | Top edge | None | Subtle AO at wall junctions |
| **Walls** | Top-left edge | Bottom-right | Top bevel highlight |
| **Characters** | Top-left | Soft ground shadow (ellipse) | Rim light on silhouette |
| **Objects** | Top-left face | Contact + cast | Cast shadow when floating |
| **Water** | Specular glints | — | Animated caustics |
| **Magic/Effects** | Self-illuminated | — | Additive glow |

### 3.4 Contact Shadow Rules

```
Object
   ████████
    ██████
     ████
      ↓
   contact shadow (2px offset, 40% opacity, blurred 1px)
```

---

## 4. Geometry Standards

### 4.1 Tile Geometry

| Property | Value |
|----------|-------|
| Logical Tile | 64 × 32 px (2:1 dimetric) |
| Diamond Points | Top(32,0), Right(64,16), Bottom(32,32), Left(0,16) |
| Grid Snap | 1px tolerance |
| Height Levels | 32px per level |

### 4.2 Character Geometry

| Character | Width | Height | Anchor | Silhouette Ratio |
|-----------|-------|--------|--------|------------------|
| Head | 48px | 48px | (24, 43) | 0.75 |
| Heels | 48px | 56px | (24, 51) | 0.85 |
| Combined | 56px | 64px | (28, 59) | 0.95 |

**Anchor = bottom-center of visual bounds**

### 4.3 Entity Geometry

| Class | Width | Height | Anchor |
|-------|-------|--------|--------|
| Small (fish, rabbit, crown, key) | 32–48px | 32–48px | Center-bottom |
| Medium (spring, switch, bag, key) | 48×48 | 48×48 | Center-bottom |
| Large (monster, guardian, door) | 64–96px | 64–96px | Center-bottom |
| Conveyor | 64×32 | tile-aligned | Tile-aligned |

---

## 5. Pixel Art Rules — "Hard Edges Only"

### DO

- ✅ Hard-edged pixels
- ✅ Clean, readable silhouettes at 1×
- ✅ Deliberate pixel placement
- ✅ Selective dithering (ordered, 2×2 Bayer)
- ✅ Controlled highlights (max 3 per ramp)
- ✅ Hard edges on material boundaries
- ✅ Cluster-based shading
- ✅ Nearest-neighbour scaling only

### DO NOT

- ❌ Anti-aliasing (no smooth edges)
- ❌ Blur / Gaussian blur
- ❌ Photographic textures
- ❌ Photorealistic gradients
- ❌ Subpixel rendering
- ❌ Soft brushes / airbrush
- ❌ Lens flare / bloom / bloom
- ❌ "AI gloss" / plastic shine
- ❌ Subpixel positioning

### Cluster Rules

- Minimum cluster: 2×2 pixels
- Maximum single-pixel noise: 0 (none)
- Edges: 1px hard transition
- Corners: 2×2 minimum radius

---

## 6. Character Visual Rules

### 6.1 Head (Headus Mouthion)

| Aspect | Specification |
|--------|---------------|
| **Silhouette** | Rounded head, small wings, compact body |
| **Colours** | Green body (`#43A047`), Yellow wings (`#FDD835`) |
| **Eyes** | Expressive, 6×6px min, distinct pupils |
| **Wings** | Semi-transparent, subtle flutter in idle |
| **Silhouette Ratio** | 0.75 (width/height) |
| **Animations** | idle(4), walk(8), jump(4), climb(4), fire(3), combined(6) |

### 6.2 Heels (Footus Underium)

| Aspect | Specification |
|--------|---------------|
| **Silhouette** | No arms, oversized boots, confident stance |
| **Colours** | Orange-red body (`#E53935`), Yellow accents (`#FDD835`) |
| **Legs** | Oversized, expressive |
| **Eyes** | High on face, very visible |
| **Silhouette Ratio** | 0.85 |
| **Animations** | idle(4), walk(8), run(8), jump(4), carry(4), combined(6) |

### 6.3 Combined (Duo)

| Aspect | Specification |
|--------|---------------|
| **Composition** | Head sits on Heels' shoulders (offset: 0, -8) |
| **Anchor Points** | Head anchor: (24, 43), Heels anchor: (24, 51) |
| **Relative Offset** | Head: (0, -8) from Heels anchor |
| **Silhouette Ratio** | 0.95 |
| **Animations** | idle(4), walk(8), run(8), jump(4), fire(3), carry(4) |
| **Synchronization** | Shared timing, Heels leads movement |

> **Composition over Duplication:** Only create dedicated Duo frames where composition fails (e.g., combined jump peak).

---

## 8. Animation System

### 8.1 Frame Timing Standards

| Animation | Frames | Timing | Loop |
|-----------|--------|--------|------|
| idle | 4 | 200ms/frame | Yes |
| walk | 8 | 100ms/frame | Yes |
| run (Heels) | 8 | 75ms/frame | Yes |
| jump | 4 | 150ms/frame | No |
| climb | 4 | 200ms/frame | Yes |
| fire | 3 | 100ms/frame | No |
| carry | 4 | 200ms/frame | Yes |
| combined | 6 | 200ms/frame | Yes |

### 8.2 Directional Requirements

| Animation | Directions |
|-----------|------------|
| idle | 4 (N, E, S, W) |
| walk | 8 (all) |
| run | 8 (all) |
| jump | 4 (N, E, S, W) |
| climb | 4 (N, E, S, W) |
| fire | 4 (N, E, S, W) |
| carry | 4 (N, E, S, W) |

> Not all animations need 8 directions. Use 4-dir where gameplay doesn't require diagonal.

### 8.3 Animation Validation Rules

| Check | Tolerance |
|-------|-----------|
| Baseline consistency | ±1px |
| Anchor stability | ±1px |
| Scale consistency | ±1px |
| Loop seamlessness | Seamless |
| Frame timing | ±5ms |
| Silhouette stability | ≥0.95 similarity |

---

## 10. Duo Composition System

```
DUO COMPOSITION
        │
    ┌───┴────────┐
    ↓            ↓
  HEELS        HEAD
    │            │
  animation    animation
    │            │
    └─────┬──────┘
          ↓
    COMPOSITOR
        │
    ┌───┴───┐
    │offsets│
    │z-order│
    │shadow │
    │sync   │
```

### Composition Rules

| Element | Specification |
|---------|---------------|
| **Head Anchor** | (24, 43) from Head sprite origin |
| **Heels Anchor** | (24, 51) from Heels sprite origin |
| **Relative Offset** | Head at (0, -8) from Heels anchor |
| **Z-Order** | Heels (back), Head (front) |
| **Shadow** | Single shared ellipse under Heels |
| **Animation Sync** | Shared timer, Heels leads |

> **Only create dedicated Duo frames where composition fails** (e.g., combined jump peak where Head leans back).

---

## 11. Tile System — Master → Family → Variant

### Tile Generation Hierarchy

```
Master Tile (e.g., stone_floor_master)
    ├── clean
    ├── worn
    ├── cracked
    ├── moss
    ├── illuminated
    └── edge
```

### Tile Family Structure (per theme)

| Family | Members | Variants |
|--------|---------|----------|
| Floor | clean, worn, cracked, moss, decorated | 5–8 |
| Wall | straight, corner, end-cap, inner, damaged | 6–10 |
| Conveyor | 4 directions × 4 frames | 16 |
| Springs | compressed, extended, mid | 3 |
| Switches | off, on (glow) | 2 |
| Doors | locked, unlocked, secret | 3 |
| Teleports | inactive, active (4-frame) | 5 |
| Props | crates, torches, banners, chains | 8–12 |
| Stairs | up, down, corners | 4–8 |
| Hazards | water, lava, pits | 4–6 |
| Decals | blood, cracks, moss, arrows | 8–16 |

### Tile Naming

```
tile_{theme}_{family}_{variant}_{id:03d}.png
```

Examples:
- `tile_castle_floor_clean_01.png`
- `tile_castle_wall_corner_02.png`
- `tile_egyptus_conveyor_e_03.png`

---

## 12. Entity Visual Specifications

| Entity | Size | Animations | Frames |
|--------|------|------------|--------|
| **Fish** | 64×32 | alive(8), dead(1), eaten(6) | 15 |
| **Rabbit** | 32×32 | hop(4), collected(6) | 10×4 types |
| **Crown** | 32×32 | rotate(8), collected(8) | 16×5 planets |
| **Spring** | 48×48 | compressed(1), extended(1), bounce(3) | 5 |
| **Switch** | 48×48 | off(1), on-glow(2) | 3 |
| **Conveyor** | 64×32 | 4-dir × 4 frames | 16 |
| **Teleport** | 64×64 | swirl(4), idle(1) | 5 |
| **Door** | 64×64 | closed, open, locked | 3 |
| **Monster** | 64×64 | walk(8), freeze(4), death(4) | 16 |
| **Guardian** | 96×96 | patrol(8), attack(6) | 14 |
| **Hush Puppy** | 48×48 | sleep(8), teleport(6), alert(4) | 18 |
| **Bag/Key** | 32×32 | idle(1), collected(6) | 7 |
| **Crown** | 32×32 | rotate(8), collected(8) | 16 |
| **Doughnut** | 16×16 | idle(1), throw(3) | 4 |

---

## 13. UI Visual Language

| Element | Size | States | Style |
|---------|------|--------|-------|
| Crown icon | 32×32 | 5 planets | Gold + planet gem |
| Doughnut counter | 32×32 | 0–9 | Glowing count |
| Bag icon | 32×32 | empty/full | Brown leather |
| Life/Heart | 24×24 | full/empty | Red heart |
| Pause button | 48×48 | normal/pressed | Rounded |
| Virtual joystick | 140×140 | base/knob | Semi-transparent |
| Action buttons | 64×64 | 4 states | Distinct shapes |
| HUD background | Full width | semi-transparent | Dark glass |

---

## 18. Asset Naming Convention

```
{category}_{asset}_{animation}_{direction}_{frame:02d}.png
```

| Category | Prefix | Examples |
|----------|--------|----------|
| Characters | `character_` | `character_head_walk_ne_03.png` |
| Entities | `entity_` | `entity_fish_swim_01.png` |
| Tiles | `tile_{theme}_` | `tile_castle_floor_01.png` |
| UI | `ui_` | `ui_crown_castle.png` |
| Effects | `fx_` | `fx_sparkle_01.png` |

### Direction Codes

| Dir | Code | Angle |
|-----|------|-------|
| N | `n` | 0° |
| NE | `ne` | 45° |
| E | `e` | 90° |
| SE | `se` | 135° |
| S | `s` | 180° |
| SW | `sw` | 225° |
| W | `w` | 270° |
| NW | `nw` | 315° |

**Omit direction for 1-dir assets (entities, UI).**

---

## 18. Sprite Registry Architecture

```
Game State
    ↓
Visual State Resolver
    ↓
Asset ID (e.g., "character.head.walk.ne")
    ↓
Sprite Registry
    ↓
Atlas Frame
    ↓
Flame SpriteAnimationComponent
```

### Asset ID Format

```
character.head.walk.ne
entity.fish.swim.01
tile.castle.floor.01
ui.crown.castle
fx.explosion.03
```

### Registry API (Conceptual)

```dart
class SpriteRegistry {
  final Map<String, SpriteAnimation> _animations;
  
  SpriteAnimation getCharacterAnimation(
    String character,  // head, heels, duo
    String animation,  // idle, walk, jump, etc.
    String direction,  // n, ne, e, se, s, sw, w, nw
  );
}
```

---

## 20. First Vertical Slice — Asset List

### Characters
- Head: front, side, back (idle, walk, jump)
- Heels: front, side, back (idle, walk, run, jump)
- Duo: combined composition

### Environment
- Floor, wall, corner, edge, stairs, door, switch, conveyor, spring, teleport

### Entities
- Fish, Rabbit, Crown, Item, Switch, Conveyor, Spring, Teleport, Monster, Guardian

### Effects
- Sparkle, teleport, hit, death

### UI
- HUD: lives, crowns, active character, doughnuts, bag item
- Pause menu, action buttons

---

## 22. Approval Gate — Style Board

**Required for Gate 1 approval:**

| Asset | Status |
|-------|--------|
| Head (idle, walk, jump) | ⬜ |
| Heels (idle, walk, run, jump) | ⬜ |
| Duo (combined idle) | ⬜ |
| Castle floor | ⬜ |
| Castle wall | ⬜ |
| Castle stairs | ⬜ |
| Castle door | ⬜ |
| Castle switch | ⬜ |
| Castle conveyor | ⬜ |
| Castle spring | ⬜ |
| Castle teleport | ⬜ |
| Fish (alive/dead) | ⬜ |
| Rabbit | ⬜ |
| Crown | ⬜ |
| Item (bag/key) | ⬜ |
| Monster | ⬜ |
| Guardian | ⬜ |
| Shadows | ⬜ |
| Animation | ⬜ |
| Atlas integration | ⬜ |
| Flutter integration | ⬜ |

**Gate 1 Pass Criteria:** All above assets visually cohere in a single test room at 1×, 2×, 4× scale.

---

## 25. Asset Naming Reference

```
characters/head/
  idle_n_01.png ... idle_w_04.png
  walk_n_01.png ... walk_nw_08.png
  jump_n_01.png ... jump_w_04.png
  climb_n_01.png ... climb_w_04.png
  fire_n_01.png ... fire_w_03.png
  combined_idle_s_01.png ...

characters/heels/
  idle_n_01.png ... idle_w_04.png
  walk_n_01.png ... walk_nw_08.png
  run_n_01.png ... run_nw_08.png
  jump_n_01.png ... jump_w_04.png
  climb_n_01.png ... climb_w_04.png
  carry_n_01.png ... carry_w_04.png
  combined_idle_s_01.png ...

characters/duo/
  idle_s_01.png ... combined_walk_nw_08.png

entities/fish/
  swim_01.png ... swim_08.png
  dead.png
  eaten_01.png ... eaten_06.png

entities/rabbit/
  life_hop_01.png ... speed_collected_06.png

entities/crown/
  castle_rotate_01.png ... bookworld_collected_08.png

tiles/castle/
  floor_01.png ... wall_corner_03.png
  conveyor_e_01.png ... conveyor_w_04.png
  spring_01.png ... spring_03.png
  switch_off.png, switch_on.png
  door_locked.png, door_open.png, door_secret.png
  teleport_01.png ... teleport_04.png

ui/
  crown_castle.png, crown_egyptus.png...
  doughnut_0.png ... doughnut_9.png
  bag_empty.png, bag_full.png
  life_full.png, life_empty.png
  pause.png, btn_jump.png, btn_carry.png, btn_fire.png, btn_swop.png

fx/
  sparkle_01.png ... sparkle_06.png
  teleport_in_01.png ... teleport_out_04.png
  hit_01.png ... death_04.png
```

---

## 28. Documentation Maintenance

| Document | Responsibility | Update Trigger |
|----------|----------------|----------------|
| `docs/VISUAL_DESIGN_SYSTEM.md` | Lead Artist | Every visual milestone |
| `docs/SPRITE_GENERATION_SYSTEM.md` | Tech Lead | Pipeline changes |
| `docs/ASSET_INVENTORY.md` | Asset Lead | Each milestone |
| `docs/TILE_ID_AUDIT.md` | Tech Lead | Tile changes |
| `docs/SPRITE_GENERATION_SYSTEM.md` | Tech Lead | Pipeline updates |
| `docs/ASSET_PIPELINE.md` | DevOps | Pipeline changes |

---

## 30. Quality Checklist (Per Asset)

- [ ] Correct dimensions (per spec)
- [ ] Correct alpha (binary: 0 or 255)
- [ ] Correct palette (no off-palette colours)
- [ ] Correct naming convention
- [ ] Correct anchor point (±1px)
- [ ] Correct scale (±1px)
- [ ] Animation consistency (baseline, anchor, scale)
- [ ] Tile geometry (64×32, diamond)
- [ ] No unintended artifacts
- [ ] Human visual approval ✅

---

**Document Version:** 1.0  
**Last Updated:** 2026-09-20  
**Authority:** This document supersedes all previous visual specifications.  
**Next Review:** After Gate 1 (Style Board) approval.