---
ticket: T007
title: Implement final puzzle mechanics (crown, bag, hush puppy, guardian) + InteractionSystem
sprint: sprint-04
priority: high
status: done
created: 2026-10-09
---

# T007 — Implement Final Puzzle Mechanics + InteractionSystem

## Context
Complete the puzzle mechanics with the final entities: Crown (win condition), Bag (Heels carry), HushPuppy (teleports from Head), Guardian (immune to doughnut). Also implement the InteractionSystem for character-entity collisions and create a test room TMX for integration testing.

## Acceptance Criteria
- [ ] CrownEntity: 5 crowns total, one per planet, win condition tracking
- [ ] Bag system: Heels only, pickup/carry one item, cannot drop in doorway
- [ ] HushPuppyEntity: sleeps, teleports away when Head approaches (3 tile radius)
- [ ] GuardianEntity: blocks throne room, immune to doughnut, defeated by 4 crowns
- [ ] InteractionSystem: central collision handling for character-entity interactions
- [ ] RoomState persistence: bag contents, crown collection, entity states
- [ ] Test room TMX: includes all entity types for integration testing
- [ ] Unit tests for each new entity
- [ ] Integration test: test room with all entities functional

## Scope
**In scope:**
- CrownEntity, Bag system, HushPuppyEntity, GuardianEntity
- InteractionSystem for collision dispatch
- Test room TMX with all entity types
- RoomState extensions for persistence

**Out of scope:**
- Complex animations (placeholder sprites OK)
- Audio (T010)
- UI/HUD (T008)
- Level design (T009)

## Dependencies
- T003 (character state, canCarry, canFire, doughnutCount)
- T004 (room system, entity factory)
- T005/T006 (puzzle entity framework, all other entities)

## Known Risks
- Bag + doorway validation (must prevent drop in doorway)
- Guardian immunity logic (special case in doughnut collision)
- HushPuppy teleport destination finding (safe tile search)
- Crown win condition (game state transition)

## Notes
Reference: `docs/RESEARCH/original-game-analysis.md`
Key mechanics:
- Crown: "5 total", "one per planet", "start revolution"
- Bag: "Heels only", "essential", "not in doorway"
- Hush Puppy: "teleport themselves away" when Head approaches
- Guardian: "doesn't like doughnuts", "only true hero may pass"