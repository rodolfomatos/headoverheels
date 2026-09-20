---
ticket: T005
title: Implement puzzle mechanics (switches, conveyors, doughnuts)
sprint: sprint-02
priority: high
status: done
created: 2026-09-18
---

# T005 — Implement Puzzle Mechanics (Switches, Conveyors, Doughnuts)

## Context
Based on T001 research (original game mechanics) and T004 room system (entity spawning from TMX), implement the core puzzle elements that define Head over Heels gameplay.

## Acceptance Criteria
- [ ] Switch entity: toggles target (door, conveyor, monster) on/off
- [ ] Conveyor belt entity: pushes characters in direction, jump to oppose
- [ ] Spring entity: boosts jump height when jumped from
- [ ] Reincarnation fish entity: checkpoint (alive) / poison (dead)
- [ ] Doughnut firing (Head only): freezes monsters temporarily
- [ ] Bag system (Heels only): pickup/carry one item
- [ ] Crown collection: win condition tracking
- [ ] Hush puppy entity: teleports away when approached
- [ ] Monster entity: patrols, kills on touch, freezable by doughnuts
- [ ] Unit tests for each puzzle element behavior
- [ ] Integration test: character interacts with all elements in test room

## Scope
**In scope:**
- Puzzle element entities with physics/collision
- Character interaction logic (switch press, conveyor push, spring boost, etc.)
- State persistence in RoomState
- TMX object property parsing for each element

**Out of scope:**
- Complex monster AI (basic patrol only)
- Particle effects (placeholder only)
- Audio (T008)
- UI feedback (T006)

## Dependencies
- T003 (character state, physics, input)
- T004 (room system, entity factory, TMX parsing)

## Rollback
Revert lib/features/gameplay/entities/, lib/features/gameplay/systems/

## Known Risks
- Conveyor + jump interaction edge cases
- Switch synchronization with target entities
- Doughnut freeze duration balancing
- Fish alive/dead state persistence across room transitions

## Notes
Reference: `docs/RESEARCH/original-game-analysis.md` for exact behaviors
Key mechanics from original:
- Switch: "push to toggle", "monster off still deadly"
- Conveyor: "push along", "jump to go opposite"
- Spring: "extra height"
- Fish: "alive = checkpoint", "dead = poison"
- Doughnut: "6 per tray", "Head only", "freeze monsters"
- Bag: "Heels only", "one item", "not in doorway"
- Crown: "one per planet", "5 total"
- Hush puppy: "teleport away when Head approaches"
- Guardian: "immune to doughnuts"