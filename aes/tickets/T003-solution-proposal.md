# T003 — Solution Proposal: Character Controllers & Physics

## CHOSEN APPROACH

### 1. Character State Machine (Freezed)
Immutable state classes with explicit states for each character mode:
- `CharacterState` base with common fields
- Subtypes: `HeadState`, `HeelsState`, `CombinedState`
- Riverpod `StateNotifier` for authoritative state management

### 2. Physics Engine (Custom, Deterministic)
Single `MovementPhysics` class parameterized by `CharacterType`:
- Fixed timestep (1/60s) for determinism
- Grid-based collision (tile coordinates)
- Sub-tile position for visual interpolation
- Parabolic jump arcs with character-specific parameters

### 3. Input Abstraction Layer
`InputController` interface with three implementations:
- `KeyboardController` (testing/desktop)
- `GamepadController` (Bluetooth/USB)
- `TouchVirtualStickController` (mobile primary)

### 4. Flame Integration
- `CharacterComponent` renders state from Riverpod
- One-way sync: Riverpod → Flame (authoritative state in Riverpod)
- Interpolation alpha for smooth rendering between physics ticks

## WHAT WILL CHANGE

### New Files
```
lib/entities/
├── character_state.dart          # Freezed state classes
├── character_physics.dart        # MovementPhysics, jump calculations
├── input_controller.dart         # Input abstraction
├── character_notifier.dart       # Riverpod StateNotifier
└── character_component.dart      # Flame component

lib/features/gameplay/
├── character_controller.dart     # High-level controller coordinating physics + input
└── movement_system.dart          # System for updating all characters

test/
├── character_physics_test.dart   # Unit tests for physics
├── character_state_test.dart     # State machine tests
└── input_controller_test.dart    # Input tests
```

### Modified Files
- `lib/core/isometric.dart` — add helper for collision bounds
- `pubspec.yaml` — ensure all deps present

## WHAT WILL NOT CHANGE
- Existing `IsometricCoordinates` (proven working)
- Riverpod provider structure from T002
- Flame game loop structure
- Level format (TMX) — handled in T004

## VERIFICATION CRITERIA

### Unit Tests (≥80% coverage)
- [ ] `MovementPhysics.calculateJumpArc()` matches expected heights/durations
- [ ] `MovementPhysics.resolveCollision()` prevents wall penetration
- [ ] `MovementPhysics.edgeHangCheck()` triggers at 30% threshold
- [ ] `CharacterNotifier.swop()` transitions correctly between all states
- [ ] `InputController` implementations return correct vectors

### Integration Tests
- [ ] Head moves 2 tiles/sec, jumps 2 tiles high in empty room
- [ ] Heels moves 4 tiles/sec, jumps 1 tile high in empty room
- [ ] Combined moves 3 tiles/sec, jumps 2 tiles high
- [ ] Swop key cycles: Head→Heels (separate), Head→Combined→Heels→Combined (joined)
- [ ] Touch virtual stick produces 8-directional input

### Visual Verification
- [ ] Character moves smoothly at 60fps (interpolation working)
- [ ] No jitter at tile boundaries
- [ ] Jump arc looks parabolic

### Quality Gates
- [ ] `flutter analyze` — no issues
- [ ] `flutter test` — all pass
- [ ] `dart format` — no changes needed