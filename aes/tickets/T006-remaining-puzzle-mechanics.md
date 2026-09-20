---
ticket: T006
title: Implement remaining puzzle mechanics (spring, fish, doughnut, bag, crown, hush puppy, monster, guardian)
sprint: sprint-03
priority: high
status: in-progress
created: 2026-10-02
---

# T006 — Implement Remaining Puzzle Mechanics

## Context
Based on T001 research (original game mechanics) and T005 puzzle framework, implement the remaining puzzle elements that define Head over Heels gameplay.

## Acceptance Criteria
- [ ] Spring entity: boosts jump height when jumped from (1.5x multiplier)
- [ ] Reincarnation fish entity: alive = checkpoint, dead = poison
- [ ] Doughnut firing (Head only): 6 per tray, seeks nearest monster, freezes 3s
- [ ] Bag system (Heels only): pickup/carry one item, cannot drop in doorway
- [ ] Crown collection: 5 total, one per planet, win condition
- [ ] Hush puppy entity: sleeps, teleports away when Head approaches
- [ ] Monster entity: patrols, kills on touch, freezable by doughnuts
- [ ] Guardian entity: blocks throne room, immune to doughnuts
- [ ] InteractionSystem: handles character-entity collisions
- [ ] Unit tests for each puzzle element
- [ ] Integration test: test room with all elements

## Scope
**In scope:**
- All remaining puzzle entities
- InteractionSystem for collision handling
- State persistence in RoomState
- TMX object property parsing

**Out of scope:**
- Complex monster AI (basic patrol only)
- Particle effects (placeholder only)
- Audio (T009)
- UI feedback (T007)

## Dependencies
- T003 (character state, physics)
- T004 (room system, entity factory)
- T005 (puzzle entity framework, switch, conveyor)

## Known Risks
- Doughnut homing projectile physics
- Fish alive/dead state persistence across room transitions
- Monster patrol synchronization
- Guardian immunity logic

## Notes
Reference: `docs/RESEARCH/original-game-analysis.md` for exact behaviors
Key mechanics from original:
- Spring: "extra height to your jump"
- Fish: "alive = checkpoint", "dead = poison"
- Doughnut: "6 per tray", "Head only", "freeze monsters 3s"
- Bag: "Heels only", "one item", "not in doorway"
- Crown: "5 total", "one per planet"
- Hush puppy: "teleport away when Head approaches"
- Guardian: "immune to doughnuts", "blocks throne room"