---
ticket: T003
title: Implement Head/Heels character controllers & physics
sprint: sprint-02
priority: high
status: done
created: 2026-09-18
---

# T003 — Implement Head/Heels Character Controllers & Physics

## Context
Based on T001 research and T002 architecture, implement the dual-character movement system with distinct physics for Head and Heels.

## Acceptance Criteria
- [ ] CharacterState freezed classes with all required fields
- [ ] MovementPhysics constants matching original game (head: 2x jump, heels: 2x speed)
- [ ] Grid-based movement with sub-tile interpolation for smooth rendering
- [ ] Jump arc physics: parabolic, character-specific height/duration
- [ ] Edge-hang detection (30% over tile edge before falling)
- [ ] Running jump bonus (extra distance when moving + jumping)
- [ ] Head mid-air control (0.5 steering), Heels limited (0.2)
- [ ] Ladder climbing state (Head only, essential skill)
- [ ] Carry state (Heels only, requires bag)
- [ ] Fire state (Head only, requires doughnuts + hooter)
- [ ] Swop logic: separate ↔ combined transitions
- [ ] Input abstraction: TouchVirtualStick, Gamepad, Keyboard
- [ ] Unit tests for physics calculations (≥80% coverage)
- [ ] Integration test: character moves in empty room

## Scope
**In scope:**
- Character state machine (Freezed + Riverpod notifier)
- Movement physics implementation
- Input controller implementations
- Basic collision with room bounds
- Swop key logic

**Out of scope:**
- Puzzle element interactions (T005)
- Room transitions/doors
- Sprite animations (placeholder colored rectangles OK)
- Audio
- Save/load

## Dependencies
- T001 (research complete)
- T002 (architecture complete, isometric.dart, providers structure)

## Rollback
Revert lib/entities/, lib/features/gameplay/character/

## Known Risks
- Touch controls for isometric 8-dir movement are non-trivial
- Jump physics must feel "right" - may need tuning
- State sync between Riverpod (authoritative) and Flame (render)

## Notes
Key physics values from research:
- Head walk: 2 tiles/sec, Jump: 2 tiles high, 30 frames
- Heels walk: 4 tiles/sec, Jump: 1 tile high, 20 frames
- Combined: 3 tiles/sec, Jump: 2 tiles high
- Edge hang: 30% of tile width
- Air control: Head 0.5, Heels 0.2

Reference: `lib/core/isometric.dart` for coordinate system