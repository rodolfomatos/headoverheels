# Head over Heels — Visual Style Guide

**Version:** 1.0  
**Status:** Authoritative  
**Project:** `rodolfomatos/headoverheels`  
**Purpose:** Single source of truth for all visual decisions.

---

## 1. Core Aesthetic Principles

### 1.1 Pixel Art — Hard Edges Only

**DO:**
- Hard-edged pixels
- Clean silhouettes
- Limited palette
- Selective dithering only
- Controlled highlights
- Deliberate pixels

**DO NOT:**
- Anti-aliasing (smooth edges)
- Blur effects
- Photographic gradients
- Photorealistic textures
- Subpixel rendering
- Automatic smoothing

### 1.2 Geometry

- **Projection:** 2:1 dimetric isometric (64×32 logical tiles)
- **Grid:** Strict 64×32 tile geometry
- **Anchor points:** Bottom-center for characters, center for tiles
- **Baseline:** Consistent across all animation frames

### 1.3 Lighting

**Global light source:** Top-left (315° / -45°)

**Rules:**
- Highlights on top and left faces
- Shadows on bottom and right faces
- Subtle ambient occlusion in corners
- Ground contact shadows
- No arbitrary shadow direction changes between sprites

---

## 2. Palette — "Spectrum+"

**File:** `style/palette.json`

**Base principle:** Expand the original ZX Spectrum 8 colors to a controlled 16–24 color palette that maintains the Spectrum feel but allows modern expressiveness.

### 2.1 Core Colors (16 base)

| Name | Hex | Usage |
|------|-----|-------|
| black | #000000 | Outlines, deepest shadows |
| dark_blue | #0000D8 | Deep shadows, dark materials |
| blue | #3030FF | Accent, magical effects |
| dark_red | #D00000 | Shadows on red objects |
| red | #FF2020 | Heels body, warnings |
| dark_green | #008000 | Shadows on green |
| green | #20C020 | Head body, vegetation |
| dark_cyan | #008080 | Shadows on cyan |
| cyan | #20D8D8 | Water, magical |
| dark_yellow | #C0A000 | Gold shadows |
| yellow | #FFD820 | Highlights, gold, doughnuts |
| dark_magenta | #A000A0 | Magic shadows |
| magenta | #E020E0 | Magical effects |
| grey | #808080 | Stone, metal midtones |
| light_grey | #C0C0C0 | Highlights on grey |
| white | #FFFFFF | Brightest highlights |

### 2.2 Theme Extensions (per-theme 8-color additions)

Each theme adds 8 colors to the base 16:

| Theme | Extension Colors |
|-------|-----------------|
| castle | Stone variants, torch orange, banner red, iron grey, moss green |
| egyptus | Sand tones, hieroglyph blue/green, gold |
| penitentiary | Concrete greys, metal blues, warning red/yellow |
| safari | Jungle greens, wood browns, flower colors |
| bookworld | Shelf wood, paper cream, ink colors, leather, gold leaf |
| moonbase | Metal greys, panel blues/cyans, glow colors |

---

## 3. Geometry Standards

**File:** `style/geometry.json`

### 3.1 Tile Geometry

```json
{
  "tile_width": 64,
  "tile_height": 32,
  "projection": "dimetric_2_1",
  "iso_angle": 26.565,
  "grid_snap": true
}
```

### 3.2 Character Geometry

| Character | Width | Height | Anchor X | Anchor Y |
|-----------|-------|--------|----------|----------|
| Head | 48 | 48 | 24 | 43 |
| Heels | 48 | 56 | 24 | 51 |
| Combined | 56 | 64 | 28 | 59 |

### 3.3 Entity Geometry

| Entity Type | Width | Height |
|-------------|-------|--------|
| Small (fish, rabbit, crown) | 32 | 32 |
| Medium (bag, key, spring) | 48 | 48 |
| Large (monster, guardian) | 64 | 64 |

---

## 4. Proportions

**File:** `style/proportions.json`

### 4.1 Character Silhouettes

**Head:**
- Rounded head shape (~60% of height)
- Small wings (~20% of width)
- Large expressive eyes (~25% of face)
- Compact body (~40% of height)

**Heels:**
- No arms visible
- Oversized boots/legs (~50% of height)
- Confident wide stance
- Visible eyes high on face

**Combined (Duo):**
- Head sits on Heels' shoulders
- Head: ~35% of total height
- Heels: ~65% of total height
- Clear visual separation at shoulders

---

## 5. Animation Standards

### 5.1 Frame Timing

| Animation | Frames | Timing | Loop |
|-----------|--------|--------|------|
| idle | 4 | 200ms | yes |
| walk | 8 | 100ms | yes |
| run | 8 | 75ms | yes |
| jump | 4 | 150ms | no |
| climb | 4 | 200ms | yes |
| fire | 3 | 100ms | no |
| carry | 4 | 200ms | yes |
| combined | 6 | 200ms | yes |

### 5.2 Directional Requirements

| Animation | Directions Required |
|-----------|---------------------|
| idle | 4 (N, E, S, W) |
| walk | 8 (all) |
| run | 8 (all) |
| jump | 4 (N, E, S, W) |
| climb | 4 (N, E, S, W) |
| fire | 4 (N, E, S, W) |
| carry | 4 (N, E, S, W) |

**Note:** Not all animations need 8 directions if not justified by gameplay visibility.

---

## 6. Naming Convention

**File:** `style/naming.md`

### 6.1 Format

```
{category}_{asset}_{animation}_{direction}_{frame}.png
```

### 6.2 Categories

| Category | Prefix |
|----------|--------|
| Characters | `character_` |
| Entities | `entity_` |
| Tiles | `tile_{theme}_` |
| UI | `ui_` |
| Effects | `fx_` |

### 6.3 Direction Codes

| Direction | Code |
|-----------|------|
| North | `n` |
| Northeast | `ne` |
| East | `e` |
| Southeast | `se` |
| South | `s` |
| Southwest | `sw` |
| West | `w` |
| Northwest | `nw` |

### 6.4 Examples

```
character_head_idle_s_01.png
character_head_walk_ne_03.png
character_heels_walk_e_05.png
character_duo_idle_s_01.png

entity_fish_idle_e_01.png
entity_rabbit_hop_s_02.png

tile_castle_floor_01.png
tile_castle_wall_corner_03.png

ui_crown.png
ui_doughnut.png
```

---

## 7. Asset Metadata Schema

Every sprite must have embeddable metadata:

```json
{
  "id": "character_head_walk_ne_03",
  "category": "character",
  "character": "head",
  "animation": "walk",
  "direction": "ne",
  "frame": 3,
  "width": 48,
  "height": 48,
  "anchor": { "x": 24, "y": 43 },
  "palette": "spectrum_plus",
  "source": "generated",
  "master": "head",
  "approved": true,
  "version": 1
}
```

---

## 7. Quality Gates (Non-Negotiable)

Every asset must pass ALL gates before integration:

- [ ] Correct dimensions (exact match to spec)
- [ ] Correct alpha channel (full transparency where needed)
- [ ] Correct palette (no colors outside defined palette)
- [ ] Correct naming convention
- [ ] Correct anchor point (within 1px tolerance)
- [ ] Correct scale (within 1px of spec)
- [ ] Animation consistency (baseline, anchor, scale stable)
- [ ] Tile geometry (64×32, correct diamond geometry)
- [ ] No unintended artifacts (stray pixels, color bleeding)
- [ ] Human visual approval (explicit approval recorded)

---

## 8. Legal & Attribution

**Principle:** Original artwork inspired by, never derivative of Ocean/Atari IP.

- No extracted assets from original game
- Clean-room reimagining
- Attribution: "Inspired by Head over Heels (1987, Ocean Software)"
- License: MIT (same as project)

---

## 9. Change Control

Any modification to this style guide requires:
1. Visual regression test on all affected assets
2. Human visual approval
3. Version bump in `style/style-guide.md`
4. Regeneration of affected assets through pipeline

---

*This document is the single source of truth for all visual decisions. When in doubt, consult this guide.*