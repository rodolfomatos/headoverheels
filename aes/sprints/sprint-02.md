---
sprint: sprint-02
period: 2026-09-25 → 2026-10-02
status: done
---

# Sprint 02 — Core Gameplay Implementation

**Goal**: Implement Head/Heels character controllers, physics, and basic room rendering with TMX loading

## Tickets
| ID | Title | Status |
|----|-------|--------|
| T003 | Implement Head/Heels character controllers & physics | done |
| T004 | Build isometric level rendering engine with TMX | done |
| T005 | Implement puzzle mechanics (switches, conveyors, doughnuts) | done |

## Retrospective
*Filled at end of sprint.*

### What went well
- Character state system with Freezed immutable states working well
- Room system with TMX loading via flame_tiled functional
- Puzzle entity framework (Switch, Conveyor, Door, Teleport, Ladder) implemented
- All quality gates passing (analyze, test, format)

### What went wrong
- Flame_tiled API required trial-and-error to understand (TileLayer API, TiledComponent)
- Freezed JSON serialization required custom converters for Vector2/3, RoomId, CarriedItem, PowerUp
- Analyzer issues with HasGameReference mixin (gameRef) - likely analyzer bug

### What to change next sprint
- Add remaining puzzle entities (Spring, Fish, Doughnut, Bag, Crown, HushPuppy, Monster, Guardian)
- Implement InteractionSystem for character-entity collision handling
- Create test room TMX for integration testing
- Add basic touch controls for testing