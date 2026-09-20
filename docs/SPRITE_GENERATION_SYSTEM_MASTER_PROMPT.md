# Head over Heels — Sprite Generation System

## Context

You are working on the repository `rodolfomatos/headoverheels`, a Flutter/Flame reimplementation of the ZX Spectrum game **Head over Heels**.

The objective is to build a completely new visual asset pipeline for the project.

This is **not simply a request to generate some PNG sprites**.

The goal is to establish a reproducible, deterministic and validated **Sprite Generation System** capable of producing:

* Head;
* Heels;
* Head + Heels combined;
* character animations;
* entities;
* environmental tiles;
* themed tilesets;
* effects;
* UI assets;
* sprite sheets / atlases;
* metadata;
* Flutter/Flame runtime assets.

The visual style should be a **modern pixel-art reinterpretation** of the original game, inspired by its visual language but using newly created artwork rather than extracted original assets.

---

# 1. CRITICAL FIRST RULE

## DO NOT START BY GENERATING SPRITES.

First inspect the repository thoroughly.

The repository is currently a partially implemented game engine/prototype.

The architecture documents describe a future sprite/atlas architecture, but much of that infrastructure does not yet exist.

You must therefore distinguish carefully between:

```text
DOCUMENTED ARCHITECTURE
IMPLEMENTED ARCHITECTURE
PLACEHOLDER IMPLEMENTATION
MISSING IMPLEMENTATION
```

Do not assume that something exists because `ARCHITECTURE.md` or `REQUIREMENTS.md` says it should exist.

Verify everything against the actual source tree.

---

# 2. First task: Repository Audit

Before changing code, inspect at minimum:

```text
docs/
lib/
assets/
test/
tool/
scripts/
pubspec.yaml
Makefile
```

Pay particular attention to:

```text
docs/ARCHITECTURE.md
docs/REQUIREMENTS.md

assets/levels/
assets/levels/rooms/
assets/levels/tilesets/

lib/entities/
lib/features/gameplay/
lib/core/
```

Inspect:

* all TMX files;
* all TSX files;
* `world.json`;
* character state definitions;
* animation state definitions;
* entity factories;
* entity components;
* room loading;
* rendering components;
* asset declarations;
* existing tests;
* existing validation commands.

Do not rely on previous analysis.

The current repository is the source of truth.

---

# 3. Audit the actual visual implementation

Determine exactly:

1. Which sprites currently exist?
2. Which sprite sheets currently exist?
3. Which atlases currently exist?
4. Which image assets currently exist?
5. Which assets are placeholders?
6. Which components currently render rectangles/circles instead of sprites?
7. How are characters rendered?
8. How are entities rendered?
9. How are tiles rendered?
10. How are animations represented?
11. How are assets declared in `pubspec.yaml`?
12. How does Flame currently load textures?
13. Is there already an atlas loader?
14. Is `flame_texturepacker` used?
15. Are there existing sprite metadata files?

Do not invent an answer.

---

# 4. Audit the tile system

Inspect every relevant `.tsx` and `.tmx`.

Determine:

```text
tile width
tile height
tile count
columns
image source
GIDs
tile properties
object properties
animations
collision metadata
```

For each tileset, build an inventory.

Especially inspect:

```text
assets/levels/tilesets/castle.tsx
```

and all maps referencing it.

Important:

A TSX declaring:

```text
tilecount = 256
columns = 16
```

does NOT automatically mean that all 256 tiles are actually defined, used or semantically distinct.

Determine:

* which tile IDs are defined;
* which are used;
* which are unused;
* which have properties;
* which are duplicated;
* which are referenced from maps;
* which have conflicting semantics;
* which are placeholders.

If duplicate or contradictory tile definitions exist, report them.

Do not silently "fix" them unless required for the current task.

---

# 5. Audit map usage

Parse all TMX files and determine which GIDs are actually used.

Produce a machine-readable and human-readable inventory.

At minimum:

```text
Tile ID
GID
Tileset
Used?
Rooms
Properties
Semantic type
Visual family
```

The final visual system must be based on actual usage, not assumptions.

---

# 6. Audit entities

Inspect the actual entity implementation.

Identify every logical entity type.

For each entity determine:

```text
entity type
source class
factory registration
gameplay state
visual implementation
placeholder implementation
possible visual states
```

Examples may include:

```text
fish
rabbit
crown
bag
key
hush puppy
monster
guardian
switch
door
spring
conveyor
teleport
etc.
```

Do not assume this list is complete.

Extract the real list from the repository.

---

# 7. Audit character state

Inspect the real character model.

In particular inspect:

```text
CharacterType
FacingDirection
AnimationState
CharacterState
DualCharacterState
```

Determine all actual states supported by the game.

The current architecture includes concepts such as:

```text
idle
walk
jumpRise
jumpPeak
jumpFall
land
climb
carry
fire
swop
hurt
death
```

and eight directions.

However, verify the actual implementation before treating this list as authoritative.

---

# 8. Important architectural principle

The sprite system must be driven by the actual game state.

Do NOT start from:

```text
"I need 8 × 6 × 2 animations"
```

Instead derive:

```text
Game State Model
       ↓
Reachable Visual States
       ↓
Visually Distinct States
       ↓
Required Assets
```

For example:

```text
CharacterType
×
AnimationState
×
FacingDirection
×
CarriedItem
×
PowerUp
```

must be reduced to the actual reachable and visually distinct combinations.

Avoid generating unnecessary sprites.

---

# 9. Combined Head + Heels

Treat the combined state as a composition problem.

Do not automatically create an enormous independent sprite set for every combined animation.

Investigate whether the correct architecture is:

```text
Combined State
      |
      +-- Head visual
      |
      +-- Heels visual
      |
      +-- relative anchors
      |
      +-- shared animation timing
      |
      +-- shared shadow
```

Use a composite sprite where possible.

Only create dedicated combined artwork where the visual pose genuinely requires it.

---

# 10. Data consistency audit

Look for inconsistencies such as:

```text
TMX entity type != world.json entity type
TSX semantic type conflicts
duplicate tile IDs
missing asset references
incorrect asset names
unused definitions
```

Do not assume these are intentional.

Document them in the audit.

If an inconsistency affects the sprite architecture, resolve it before building the dependent asset.

---

# 11. Create the visual inventory

Create:

```text
docs/ASSET_INVENTORY.md
```

This document must contain the actual discovered inventory.

Sections:

```text
Characters
Character states
Character animations
Directions
Entities
Entity visual states
Tilesets
Tile families
Effects
UI
Missing assets
Placeholder assets
Data inconsistencies
```

Include tables wherever useful.

---

# 12. Create the new Sprite Generation System document

Create:

```text
docs/SPRITE_GENERATION_SYSTEM.md
```

This document becomes the authoritative specification for the visual asset pipeline.

It must describe the system below.

---

# 13. Core architecture

The final architecture should conceptually be:

```text
                    GAME MODEL
                        |
           +------------+------------+
           |            |            |
           v            v            v
      characters     entities      tiles
           |            |            |
           +------------+------------+
                        |
                        v
                 VISUAL INVENTORY
                        |
                        v
                  STYLE SYSTEM
                        |
              +---------+---------+
              |                   |
              v                   v
        MASTER ASSETS        THEME MASTERS
              |                   |
              +---------+---------+
                        |
                        v
                 AI GENERATION
                        |
                        v
                  NORMALIZATION
                        |
                        v
                   VALIDATION
                        |
                        v
                    ATLAS
                        |
                        v
                 VISUAL REGISTRY
                        |
                        v
                 FLAME COMPONENTS
```

---

# 14. Separation of responsibilities

Keep these layers separate:

## Game layer

Responsible for:

* game state;
* physics;
* interaction;
* entity behaviour;
* world state;
* room state.

## Visual layer

Responsible for:

* sprite selection;
* animation;
* frame timing;
* visual composition;
* rendering.

## Asset production layer

Responsible for:

* references;
* prompts;
* generation;
* normalization;
* validation;
* atlas creation.

The gameplay layer must not depend on filenames such as:

```text
head_walk_ne_03.png
```

---

# 15. Asset IDs

Use stable logical asset IDs.

For example:

```text
character.head.walk.ne
entity.fish.idle
entity.rabbit.walk
tile.castle.floor
tile.castle.wall
ui.crown
```

The game should resolve:

```text
logical state
    ↓
asset ID
    ↓
atlas frame
```

rather than hard-coding filenames throughout gameplay code.

---

# 16. Sprite Registry

Design a central:

```text
SpriteRegistry
```

or equivalent abstraction.

Conceptually:

```dart
SpriteAnimation getCharacterAnimation(
  String character,
  String animation,
  String direction,
);
```

Do not necessarily copy this exact API.

Adapt it to the existing architecture.

The important principle is centralised resolution.

---

# 17. Visual State Resolver

Introduce a resolver concept:

```text
Game State
    ↓
Visual State
    ↓
Asset ID
```

Example:

```text
CharacterType = head
Facing = southEast
Animation = walk
```

becomes:

```text
character.head.walk.southEast
```

Then the registry resolves that ID to atlas frames.

---

# 18. Style Guide

Create:

```text
tools/sprites/style/style-guide.md
```

or another appropriate location.

It must define:

* pixel-art rules;
* pixel scale;
* outline rules;
* silhouette rules;
* palette;
* lighting;
* shading;
* dithering;
* material treatment;
* character proportions;
* tile geometry;
* transparency;
* animation conventions.

---

# 19. Pixel-art direction

Use:

```text
hard-edged pixel art
limited palette
clean silhouettes
controlled shading
nearest-neighbour scaling
```

Avoid:

```text
traditional anti-aliasing
blur
photorealistic textures
soft gradients
subpixel rendering
excessive colour counts
```

The goal is a modern pixel-art reinterpretation, not a smooth retro illustration.

---

# 20. Palette

Use a controlled:

```text
Spectrum+
```

palette.

Start from the conceptual Spectrum palette but allow an expanded controlled palette.

Do not allow AI-generated sprites to introduce arbitrary hundreds of colours.

Create a machine-readable palette file:

```text
tools/sprites/style/palette.json
```

The exact colours should be selected after visual evaluation.

---

# 21. Lighting

Define a common light source:

```text
top-left
```

Use consistent:

* highlights;
* shadows;
* ambient occlusion;
* ground contact.

Create:

```text
lighting.json
```

if appropriate.

---

# 22. Geometry

Tiles remain:

```text
64 × 32
```

with the existing 2:1 dimetric/isometric geometry.

Do not change map geometry merely to accommodate the new artwork.

Character dimensions should be derived from actual gameplay scale.

Do not assume arbitrary 48×48 or 56×56 sizes until tested in a real room.

---

# 23. Master assets

Do not immediately generate hundreds of final sprites.

First create a small set of master assets.

Characters:

```text
Head
Heels
Head + Heels
```

Environment:

```text
floor
wall
wall corner
stairs
door
switch
conveyor
spring
teleport
hazard
prop
```

Entities:

a representative subset covering different visual behaviours.

These masters establish:

* outline;
* palette;
* proportions;
* shading;
* lighting;
* pixel density;
* silhouette language.

---

# 24. Vertical visual slice

The first real visual milestone is NOT:

```text
"all sprites generated"
```

It is:

```text
one complete playable room
```

containing as many relevant visual systems as possible.

Ideally:

```text
Head
Heels
combined
floor
wall
stairs
door
switch
conveyor
spring
teleport
fish
rabbit
crown
bag
key
monster
guardian
```

The visual slice must run in the actual Flutter/Flame game.

Do not validate only isolated PNGs.

---

# 25. Castle first

Use the Castle theme as the first complete theme.

Reason:

It exercises most of the asset system.

Complete:

```text
castle tiles
castle entities
characters
effects
```

before expanding to:

```text
Egyptus
Penitentiary
Safari
Book World
```

Do not hard-code assumptions about the exact number of themes; derive the final list from the repository.

---

# 26. Tile generation

Do not treat 256 tiles as 256 independent artistic problems.

Use:

```text
master tile
    ↓
tile family
    ↓
variants
    ↓
TSX slot
```

For example:

```text
floor
 ├── clean
 ├── worn
 ├── cracked
 └── decorated
```

and:

```text
wall
 ├── straight
 ├── corner
 ├── end
 ├── inner
 └── damaged
```

The actual families must be derived from the real TSX/TMX inventory.

---

# 27. TSX compatibility

Do not arbitrarily change:

```text
tile IDs
GIDs
firstgid
TMX topology
collision properties
object properties
```

unless explicitly required.

The first visual implementation should preserve gameplay compatibility.

Ideally:

```text
existing TMX
      ↓
same tile references
      ↓
new TSX
      ↓
new artwork
```

---

# 28. AI generation

AI generation is a candidate-generation mechanism.

Pipeline:

```text
Prompt
   ↓
Generation
   ↓
Candidate selection
   ↓
Human approval
   ↓
Normalization
   ↓
Validation
   ↓
Runtime
```

Do not automatically commit generated output as production artwork.

---

# 29. Prompt system

Create:

```text
tools/sprites/prompts/
```

with:

```text
system/
characters/
tiles/
entities/
effects/
ui/
```

Every prompt must inherit the common style guide.

Avoid repeating contradictory style definitions in individual prompts.

---

# 30. Normalization

Create a deterministic normalization tool.

Possible:

```text
tools/sprites/scripts/normalize_sprites.py
```

It should handle:

* transparency;
* dimensions;
* scaling;
* pixel alignment;
* palette conversion;
* artifact cleanup;
* anchor metadata;
* output naming.

Do not silently modify source/generated artwork.

Keep:

```text
generated/
```

separate from:

```text
normalized/
```

---

# 31. Validation

Implement validators for:

```text
dimensions
alpha
palette
naming
anchors
animation consistency
tile geometry
atlas metadata
manifest references
```

A production build should reject invalid assets.

---

# 32. Animation validation

Check:

* baseline;
* bounding box;
* anchor;
* scale;
* frame-to-frame displacement;
* unexpected jumps;
* inconsistent silhouette;
* empty frames;
* duplicated frames.

Do not require every animation to have the same number of frames.

Frame counts should be determined by the actual visual behaviour.

---

# 33. Atlas architecture

The repository documentation expects atlas-based sprite loading.

Inspect the actual Flame dependencies before choosing the implementation.

Determine whether the project should use:

```text
TexturePacker
flame_texturepacker
custom JSON atlas
```

Do not add a dependency merely because it was proposed in an earlier plan.

Choose the simplest approach compatible with the current project.

Possible atlas grouping:

```text
characters
entities
castle
egyptus
penitentiary
safari
bookworld
ui
effects
```

---

# 34. Runtime assets

The generated production assets should ultimately become:

```text
assets/sprites/
```

The generation tooling should remain outside runtime assets.

Suggested conceptual separation:

```text
tools/sprites/
    source/generation system

assets/sprites/
    runtime output
```

---

# 35. Flutter integration

Inspect the current `pubspec.yaml`.

Add only the asset paths actually required.

Do not assume `assets/sprites/` is already declared.

Implement the minimum necessary runtime changes.

Do not rewrite gameplay architecture.

---

# 36. CharacterComponent

Replace placeholder visual rendering with actual sprite rendering.

However:

`CharacterComponent` must remain a renderer.

It should not become responsible for gameplay state transitions.

Conceptually:

```text
CharacterState
      ↓
VisualStateResolver
      ↓
SpriteRegistry
      ↓
SpriteAnimationComponent
```

---

# 37. Entity visuals

Replace placeholder geometric rendering progressively.

Do not rewrite entity gameplay logic merely to support sprites.

Prefer:

```text
Entity gameplay
+
Entity visual component
```

or an equivalent architecture consistent with the existing codebase.

---

# 38. Asset Manifest

Create a machine-readable manifest.

It should associate:

```text
asset ID
category
source
dimensions
anchor
frames
animation
direction
theme
palette
atlas
```

Example:

```json
{
  "id": "character.head.walk.ne",
  "category": "character",
  "frames": 8,
  "direction": "ne",
  "atlas": "characters"
}
```

Adapt the exact schema to the implementation.

---

# 39. Repository changes

Do not create an entirely parallel architecture if the repository already has appropriate locations.

Before creating directories:

```text
inspect existing structure
```

Reuse existing conventions wherever possible.

The final changes should be minimal and coherent.

Expected areas may include:

```text
docs/
tools/
assets/
lib/
pubspec.yaml
Makefile
test/
```

but only modify files where necessary.

---

# 40. Makefile integration

Add appropriate commands such as:

```bash
make sprites-check
make sprites-build
make sprites-pack
make assets-check
```

But inspect the existing Makefile first and follow its conventions.

The main project quality gate must remain intact.

Run:

```bash
make check
```

or the actual repository-equivalent quality gate.

---

# 41. Testing

Add tests for:

* asset manifest;
* asset IDs;
* visual state resolution;
* animation lookup;
* missing assets;
* invalid references;
* tile inventory;
* sprite validation.

Do not write tests that merely verify that a PNG exists.

Test the relationship between game state and visual asset resolution.

---

# 42. Documentation

The following documents should exist after the initial implementation:

```text
docs/ASSET_INVENTORY.md
docs/SPRITE_GENERATION_SYSTEM.md
```

The latter must document:

* architecture;
* style;
* palette;
* generation pipeline;
* normalization;
* validation;
* atlas;
* runtime integration;
* naming;
* asset IDs;
* production workflow;
* quality gates;
* future expansion.

---

# 43. Important: update the document with discovered facts

Do not blindly copy assumptions into:

```text
docs/SPRITE_GENERATION_SYSTEM.md
```

The document must distinguish:

```text
CURRENT STATE
TARGET STATE
IMPLEMENTATION PLAN
```

For example:

```markdown
## Current state

Character rendering currently uses placeholder components.

## Target state

Characters are rendered through SpriteRegistry.

## Migration

Replace placeholder rendering after the first visual vertical slice is approved.
```

---

# 44. Do not over-engineer

Do not introduce:

* a database;
* a complex build server;
* an external asset-management system;
* unnecessary dependencies;
* a separate microservice;
* an AI API integration;

unless the existing project clearly requires it.

The first implementation should be local, reproducible and scriptable.

---

# 45. Human approval gates

Introduce explicit visual gates:

```text
Gate 1 — Style
Gate 2 — Characters
Gate 3 — First room
Gate 4 — Castle
Gate 5 — Remaining themes
```

Do not proceed from one major visual stage to the next without producing preview material that can be inspected.

---

# 46. Do not destroy existing work

Before modifying:

```text
TMX
TSX
world.json
gameplay components
```

understand their role.

Do not rewrite them merely to make the sprite system easier.

Preserve gameplay behaviour.

---

# 47. First implementation milestone

Your first implementation milestone should be:

```text
T016 — Asset & Visual System Audit
```

Deliver:

```text
docs/ASSET_INVENTORY.md
docs/SPRITE_GENERATION_SYSTEM.md
```

plus any small scripts needed to generate the inventory.

At this stage, DO NOT generate the complete sprite set.

---

# 48. Second milestone

```text
T017 — Visual Design System
```

Deliver:

```text
tools/sprites/style/style-guide.md
tools/sprites/style/palette.json
tools/sprites/style/lighting.json
```

and a small concept/master asset set.

---

# 49. Third milestone

```text
T018 — Character Visual System
```

Implement:

```text
SpriteRegistry
VisualStateResolver
Head
Heels
Combined
```

with enough animations to demonstrate the system.

---

# 50. Fourth milestone

```text
T019 — Visual Vertical Slice
```

Render one real playable room using the new assets.

Only after this succeeds should full production begin.

---

# 51. Final production roadmap

```text
T016  Asset & Visual System Audit
  ↓
T017  Visual Design System
  ↓
T018  Character Visual System
  ↓
T019  Visual Vertical Slice
  ↓
T020  Castle Tileset
  ↓
T021  Entity Visual System
  ↓
T022  Castle Complete
  ↓
T023  Sprite Validation Pipeline
  ↓
T024  Atlas Pipeline
  ↓
T025  Remaining Themes
  ↓
T026  UI / Effects
  ↓
T027  Full Gameplay Integration
  ↓
T028  Visual QA
  ↓
T029  Final Asset Migration
```

Adjust ticket numbering if the repository already has conflicting AES ticket IDs.

---

# 52. Quality gate

Before declaring the work complete:

```bash
flutter analyze
flutter test
make check
```

plus the sprite-specific validation commands.

The final state must have:

```text
0 invalid asset references
0 missing required sprites
0 invalid palette violations
0 invalid atlas references
0 invalid animation references
0 broken TSX/TMX references
```

unless explicitly documented as an intentional limitation.

---

# 53. Final principle

The central design principle is:

> Generate freely. Normalize aggressively. Validate automatically. Approve visually. Integrate deterministically.

The AI is not the asset authority.

The generated image is not the production asset.

The production asset is the result of:

```text
reference
→ style
→ master
→ generation
→ normalization
→ validation
→ approval
→ atlas
→ runtime
```

---

# 54. Execution instructions

Proceed in this order:

1. Inspect the repository.
2. Inspect the current branch/status.
3. Inspect the relevant documentation.
4. Inspect all relevant source files.
5. Inspect TSX/TMX/world data.
6. Build the actual visual inventory.
7. Identify inconsistencies.
8. Create `docs/ASSET_INVENTORY.md`.
9. Create `docs/SPRITE_GENERATION_SYSTEM.md`.
10. Show the resulting architecture and inventory.
11. Only then begin implementing the first tooling.
12. Run tests and quality gates after each significant change.
13. Do not generate the complete artwork set until the visual system and vertical slice are validated.

If the repository state contradicts any assumption in this prompt, **the repository wins**.

Do not invent missing functionality.

Do not silently repair unrelated gameplay issues.

Do not replace existing architecture merely because a different architecture would be easier.

The objective is to add a robust visual asset system to the existing game, while preserving its gameplay architecture and making the new visual pipeline independently reproducible.

