# T010 — Hostile Analysis: CharacterState Notifier

## INSIGHTS CONSULTED
- SD-T003-character-state (CharacterState, CharacterStateExtension, physics constants)
- SD-T002-architecture (Riverpod + Freezed, one-way sync Riverpod → Flame)
- SD-T008-ui (InputController, VirtualJoystick, ActionButtons)

## ASSUMPTIONS I'M MAKING (with uncertainty classification)

- [KNOWN] CharacterState is Freezed immutable with all physics params
- [KNOWN] Riverpod providers: headProvider, heelsProvider, dualCharacterProvider
- [KNOWN] CharacterComponent currently takes static CharacterState in constructor
- [KNOWN] Physics runs at fixed 60Hz timestep (16.67ms)
- [KNOWN] Swop logic: separate ↔ combined transitions with state merging
- [INFERRED] CharacterStateNotifier needs: move, jump, carry, fire, swop, update(dt)
- [INFERRED] Swop logic: separate→combined merges state, combined→separate splits state
- [ASSUMED] One-way sync: Riverpod state → Flame component (via ref.watch)
- [ASSUMED] Physics step in notifier.update(dt) with fixed timestep accumulator
- [UNKNOWN] Exact swop animation timing
- [UNKNOWN] Whether notifier handles input directly or receives commands

## WHAT WASN'T SPECIFIED (that matters)
- How input maps to notifier methods (direct call vs command queue)
- Swop mid-air behavior (allowed? blocked?)
- State persistence across room transitions
- Network sync for future multiplayer

## ALTERNATIVES I DIDN'T CHOOSE (and why)

- **CharacterComponent owns state**: Rejected — violates Riverpod authoritative state
- **Notifier in Flame component**: Rejected — breaks Riverpod testability
- **Two-way sync**: Rejected — single source of truth in Riverpod
- **Notifier per action**: Rejected — single notifier per character simpler

## INVITE CONTRADICTION
- What if Riverpod → Flame sync causes frame lag?
- What if fixed timestep in notifier conflicts with Flame's update loop?
- What if swop during jump creates invalid state?

## DISTINGUISH CLAIM TYPES
- **Empirical**: Riverpod + Freezed pattern from T002 ADR
- **Normative**: Fixed timestep, one-way sync, swop logic (design decisions)

## RISKS & SIDE EFFECTS
- State desync between Riverpod and Flame
- Swop mid-action edge cases
- Performance: ref.watch rebuilds CharacterComponent

## COST OF BEING WRONG: HIGH
- Core character control depends on this
- Swop is core mechanic

## REASONING SKELETON FOR KEY CLAIMS
[Riverpod authoritative] → ADR: "Riverpod → Flame (one-way sync)" → Notifier is source of truth
[Fixed timestep] → Physics determinism → Accumulator pattern in notifier.update(dt)
[Swop merges state] → Manual: "abilities merge when combined" → Notifier merges inventories/abilities

## SCOPE BOUNDARIES DECLARATION
This analysis covers: CharacterStateNotifier, Riverpod providers, CharacterComponent integration, swop logic, physics step.
Deliberately excludes: Input handling (T008), physics implementation details (T003), Flame game loop.