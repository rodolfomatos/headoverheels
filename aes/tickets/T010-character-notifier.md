---
ticket: T010
title: Connect CharacterState notifier to CharacterComponent
sprint: sprint-05
priority: high
status: done
created: 2026-10-16
---

# T010 — Connect CharacterState Notifier to CharacterComponent

## Context
Currently CharacterComponent receives a static CharacterState. Need to connect it to Riverpod StateNotifier for reactive updates.

## Acceptance Criteria
- [ ] CharacterStateNotifier extends StateNotifier<CharacterState>
- [ ] CharacterComponent watches notifier and syncs position/animation
- [ ] Actions (move, jump, carry, fire, swop) call notifier methods
- [ ] Riverpod provider for each character (head, heels)
- [ ] Swop logic in notifier (handles combined/separate transitions)
- [ ] Physics updates in notifier (fixed timestep)

## Scope
**In scope:**
- CharacterStateNotifier implementation
- Riverpod providers (headProvider, heelsProvider)
- CharacterComponent ref.watch() integration
- Action methods (move, jump, carry, fire, swop)
- Physics step in notifier.update(dt)

**Out of scope:**
- Physics implementation (T003 has base physics)
- Input handling (T008 touch controls)

## Dependencies
- T003 (CharacterState, physics constants)
- T008 (InputController for actions)
- Riverpod + flutter_riverpod

## Known Risks
- State sync between Riverpod (authoritative) and Flame (render)
- Fixed timestep vs variable frame rate
- Swop transition edge cases

## Notes
Reference: `docs/ARCHITECTURE.md` - State Management Architecture
Reference: `lib/entities/character_state.dart` - CharacterState, CharacterStateExtension
Reference: `lib/features/gameplay/entities/character_component.dart` - CharacterComponent