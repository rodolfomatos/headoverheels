---
ticket: T009
title: Implement Bag system (Heels carry items)
sprint: sprint-05
priority: high
status: done
created: 2026-10-16
---

# T009 — Implement Bag System (Heels Carry Items)

## Context
Implement the bag system for Heels character: pickup, carry, and drop items. The bag is essential for progression.

## Acceptance Criteria
- [ ] Bag pickup: Heels touches bag entity → gains bag ability
- [ ] Item pickup: Heels + action key on item → item in bag (CarriedItem enum)
- [ ] Item drop: Heels + action key (no item in bag) → spawn item at position
- [ ] Doorway validation: cannot drop item in doorway (check adjacent tiles for door triggers)
- [ ] Bag persistence: carried item persists across room transitions
- [ ] HUD display: show carried item icon in HUD
- [ ] Only Heels/Combined can carry (canCarry getter)

## Scope
**In scope:**
- Bag entity (pickup once per game)
- CarriedItem state in CharacterState
- Pickup/drop logic in CharacterComponent
- Doorway drop prevention
- HUD integration

**Out of scope:**
- Multiple item slots (original has 1 slot)
- Item combining/crafting

## Dependencies
- T003 (CharacterState.carriedItem, canCarry)
- T008 (HUD display)
- T004 (room transitions for persistence)

## Known Risks
- Doorway detection accuracy
- Item spawn position on drop
- Multi-room persistence

## Notes
Reference: `docs/RESEARCH/original-game-analysis.md` - Bag section
- "Essential for Heels to find and get the bag as it is impossible to get far without it"
- "Not possible to drop an object in a doorway"
- "Only Heels may carry anything"