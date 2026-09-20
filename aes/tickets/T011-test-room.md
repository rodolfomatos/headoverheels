---
ticket: T011
title: Create test room TMX with all entity types
sprint: sprint-05
priority: high
status: done
created: 2026-10-16
---

# T011 — Create Test Room TMX with All Entity Types

## Context
Create a comprehensive test room TMX file that includes all entity types for integration testing.

## Acceptance Criteria
- [ ] TMX file: `assets/levels/rooms/test_room.tmx`
- [ ] Tileset: castle theme (64x32 isometric)
- [ ] Layers:
  - Floor (walkable tiles)
  - Walls (collision tiles)
  - Objects (entities with custom properties)
  - Triggers (doors, teleports, ladders)
- [ ] Entities placed:
  - Switch + Door (linked)
  - Conveyor belt (horizontal)
  - Spring
  - Reincarnation Fish (alive)
  - Crown (planet: castle)
  - Bag pickup
  - Hush Puppy
  - Monster (2-point patrol)
  - Guardian (throne room blocker)
  - Teleport (to test_room_2)
- [ ] Room connections defined in world.json
- [ ] Spawn point for Head and Heels
- [ ] Room loads in RoomComponent without errors

## Scope
**In scope:**
- TMX file creation (use Tiled editor or manual XML)
- Tileset reference (castle.tsx)
- Object layer with all entity types
- Trigger zones with custom properties
- world.json entry

**Out of scope:**
- Multiple test rooms (start with one)
- Complex level design

## Dependencies
- T004 (RoomComponent, EntityFactory)
- T005/T006/T007 (all entity types implemented)
- Tileset assets (castle.tsx, castle.png)

## Known Risks
- TMX property parsing for custom properties
- Tileset alignment with isometric coordinates
- Entity spawn position accuracy

## Notes
Reference: `docs/ARCHITECTURE.md` - Level Format section
Tileset: 64x32 dimetric, castle theme
Use Tiled map editor (free) or manual TMX XML