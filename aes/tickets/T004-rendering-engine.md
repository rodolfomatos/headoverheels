---
ticket: T004
title: Build isometric level rendering engine with TMX
sprint: sprint-02
priority: high
status: done
created: 2026-09-18
---

# T004 — Build Isometric Level Rendering Engine with TMX

## Context
Based on T002 architecture decision (Flame engine with `flame_tiled` for TMX loading) and T003 character state, implement the room rendering system that loads TMX maps and renders them isometrically.

## Acceptance Criteria
- [ ] TMX map loads and renders correctly (floor, walls, objects layers)
- [ ] IsometricTileMapComponent configured for 2:1 dimetric (64x32 tiles)
- [ ] Camera follows player with smooth interpolation
- [ ] Room transitions via doors (trigger zone → load next room)
- [ ] Object layer parsing: switches, conveyors, teleports, springs, fish, items
- [ ] Collision detection with wall tiles
- [ ] Z-level rendering order (background → floor → objects → characters → effects)
- [ ] Asset pipeline: sprite atlases for tilesets
- [ ] Unit tests for TMX parsing and coordinate conversion
- [ ] Integration test: character moves through loaded room

## Scope
**In scope:**
- TMX loading with flame_tiled
- Isometric rendering of tile layers
- Object layer entity spawning
- Room graph navigation (doors, teleports)
- Camera system

**Out of scope:**
- Puzzle element behavior (T005)
- Character animations (placeholder rectangles OK)
- Save/load
- UI/HUD

## Dependencies
- T002 (architecture, coordinate system)
- T003 (character state, physics)

## Rollback
Revert lib/features/gameplay/room/, lib/features/gameplay/camera/

## Known Risks
- flame_tiled isometric support may have bugs
- TMX object parsing for custom properties
- Z-ordering with isometric projection
- Performance with large rooms

## Notes
Reference: `lib/core/isometric.dart` for coordinate conversion
TMX structure from architecture doc:
- Floor layer: base tiles
- Walls layer: collision tiles
- Objects layer: entities with type + properties
- Triggers layer: doors, zone transitions