# T010 — Solution Proposal: CharacterState Notifier

## CHOSEN APPROACH

### 1. CharacterStateNotifier (Riverpod StateNotifier)
```dart
class CharacterStateNotifier extends StateNotifier<CharacterState> {
  CharacterStateNotifier({required CharacterState initialState}) : super(initialState);

  // Movement
  void move(Direction8 direction) { ... }
  void stop() { ... }
  
  // Jumping
  void jump() { ... }
  void applyJumpBoost() { ... }
  
  // Actions
  void carry() { ... }
  void fire() { ... }
  void swop() { ... }
  
  // Physics
  void update(double dt) { ... } // Fixed timestep
  
  // Swop
  void combineWith(DualCharacterState dual) { ... }
  void separate(ControlledEntity controlled) { ... }
}
```

### 2. Riverpod Providers
```dart
final headProvider = StateNotifierProvider<CharacterStateNotifier, CharacterState>((ref) {
  return CharacterStateNotifier(initialState: CharacterState.initial(
    type: CharacterType.head,
    startPosition: Vector3(1, 1, 0),
  ));
});

final heelsProvider = StateNotifierProvider<CharacterStateNotifier, CharacterState>((ref) {
  return CharacterStateNotifier(initialState: CharacterState.initial(
    type: CharacterType.heels,
    startPosition: Vector3(2, 2, 0),
  ));
});

final dualCharacterProvider = StateNotifierProvider<DualCharacterNotifier, DualCharacterState>((ref) {
  return DualCharacterNotifier(
    head: ref.watch(headProvider.notifier),
    heels: ref.watch(heelsProvider.notifier),
  );
});
```

### 3. CharacterComponent Integration
```dart
class CharacterComponent extends PositionComponent with CollisionCallbacks {
  final CharacterType type;
  final WidgetRef ref; // Injected via constructor or ProviderScope
  
  late final CharacterStateNotifier _notifier;
  
  @override
  void onLoad() {
    _notifier = ref.read(type == CharacterType.head ? headProvider.notifier : heelsProvider.notifier);
    _notifier.addListener(_syncFromState);
    _syncFromState();
  }
  
  void _syncFromState() {
    final state = _notifier.state;
    position = IsometricCoordinates.gridToScreen(state.position);
    // Update animation, facing, etc.
  }
  
  @override
  void update(double dt) {
    _notifier.update(dt); // Fixed timestep physics
    super.update(dt);
  }
}
```

### 4. Swop Logic (DualCharacterNotifier)
```dart
class DualCharacterNotifier extends StateNotifier<DualCharacterState> {
  final CharacterStateNotifier head;
  final CharacterStateNotifier heels;
  
  void swop() {
    state = state.when(
      separate: (head, heels, controlled) => _handleSeparateSwop(controlled),
      combined: (combined, controlled) => _handleCombinedSwop(controlled),
    );
  }
  
  void combine() { ... } // Head on Heels
  void separate() { ... } // Separate them
}
```

### 5. Physics Update (Fixed Timestep)
```dart
void update(double dt) {
  _accumulator += dt;
  while (_accumulator >= _fixedTimestep) {
    _fixedUpdate(_fixedTimestep);
    _accumulator -= _fixedTimestep;
  }
}

void _fixedUpdate(double dt) {
  // Apply velocity, gravity, collision
  // Update position, jump phase, animation
  state = state.copyWith(
    position: newPosition,
    velocity: newVelocity,
    jumpPhase: newJumpPhase,
    isGrounded: newIsGrounded,
    animation: newAnimation,
    facing: newFacing,
  );
}
```

## WHAT WILL CHANGE

### New Files
```
lib/features/gameplay/state/
├── character_notifier.dart      # CharacterStateNotifier
├── dual_character_notifier.dart # DualCharacterNotifier
├── providers.dart               # Riverpod providers
```

### Modified Files
- `lib/entities/character_state.dart` — add notifier methods
- `lib/features/gameplay/entities/character_component.dart` — ref.watch integration
- `lib/features/gameplay/systems/input_system.dart` — connect input to notifier

## WHAT WILL NOT CHANGE
- CharacterState immutable structure (T003)
- Physics constants (T003)
- Flame game loop

## VERIFICATION CRITERIA

### Unit Tests
- [ ] Notifier.move() updates velocity correctly
- [ ] Notifier.jump() starts jump phase
- [ ] Notifier.swop() transitions separate ↔ combined
- [ ] Notifier.combine() merges inventories
- [ ] Notifier.separate() splits inventories
- [ ] Fixed timestep produces deterministic results

### Integration Tests
- [ ] CharacterComponent syncs position from notifier
- [ ] VirtualJoystick → notifier.move() works
- [ ] ActionButtons → notifier.jump/carry/fire/swop works
- [ ] Swop transitions work correctly
- [ ] Combined state merges abilities

### Quality Gates
- [ ] `flutter analyze` — no issues
- [ ] `flutter test` — all pass
- [ ] `dart format` — no changes