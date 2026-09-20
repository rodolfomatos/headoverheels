# T007 — Solution Proposal: Final Puzzle Mechanics + InteractionSystem

## CHOSEN APPROACH

### 1. Entity Implementations

#### CrownEntity
```dart
class CrownEntity extends PuzzleEntity {
  final String planetId; // egyptus, penitentiary, safari, bookworld, blacktooth
  
  @override
  void onInteract(CharacterComponent character) {
    // Any character can collect
    _collectCrown(character);
  }
  
  void _collectCrown(CharacterComponent character) {
    // Add to game state
    gameRef.collectCrown(planetId);
    removeFromParent();
  }
}
```

#### Bag System (extends CharacterState)
- Already in CharacterState: `carriedItem` (CarriedItem enum)
- Heels only: `canCarry` getter
- Pickup: onInteract with item entity → `carriedItem = item`
- Drop: onInteract (when carrying) → spawn item entity at position
- Validation: cannot drop in doorway (check adjacent tiles for door triggers)

#### HushPuppyEntity
```dart
class HushPuppyEntity extends PuzzleEntity {
  static const double detectionRadius = 3.0; // tiles
  bool _isAwake;
  Timer _returnTimer;
  
  @override
  void updatePuzzle(double dt) {
    if (!_isAwake) {
      _checkHeadProximity();
    } else {
      _returnTimer -= dt;
      if (_returnTimer <= 0) _goToSleep();
    }
  }
  
  void _checkHeadProximity() {
    final head = _findHead();
    if (head != null && head.position.distanceTo(position) < detectionRadius * tileWidth) {
      _teleportAway();
    }
  }
  
  void _teleportAway() {
    final safeTile = _findSafeTile();
    if (safeTile != null) {
      position = IsometricCoordinates.gridToScreen(safeTile);
      _isAwake = true;
      _returnTimer = 5.0; // seconds
    }
  }
  
  void _goToSleep() {
    _isAwake = false;
    // Return to original position or stay?
  }
}
```

#### GuardianEntity (extends MonsterEntity)
```dart
class GuardianEntity extends MonsterEntity {
  @override
  void freeze(int frames) {
    // Immune to doughnut freeze
    // Visual: flash red instead of blue
  }
  
  @override
  void onInteract(CharacterComponent character) {
    // Check if player has 4 crowns
    final crownCount = gameRef.getCrownCount();
    if (crownCount >= 4) {
      _defeatGuardian();
    } else {
      // Block passage
    }
  }
}
```

### 2. InteractionSystem
Central collision dispatch:
```dart
class InteractionSystem {
  void update(List<CharacterComponent> characters, List<PuzzleEntity> entities) {
    for (final character in characters) {
      for (final entity in entities) {
        if (character.hitboxes.any((h) => entity.hitboxes.any((e) => h.collidesWith(e)))) {
          if (!entity._wasColliding) {
            entity.onEnter(character);
            entity._wasColliding = true;
          }
        } else if (entity._wasColliding) {
          entity.onExit(character);
          entity._wasColliding = false;
        }
      }
    }
  }
}
```
Called from RoomComponent.update() or Game.update().

### 3. RoomState Extensions
```dart
@freezed
abstract class RoomState with _$RoomState {
  const factory RoomState({
    ...
    required Map<String, dynamic> entityStates, // frozen timers, etc.
    required bool crownCollected,
    required String? hushPuppyState, // sleeping/awake
  }) = _RoomState;
}
```

### 4. EntityFactory Extensions
Add to EntityFactory.create():
```dart
case TriggerType.crown:
  return _createCrown(trigger, roomId);
case TriggerType.bag:
  return _createBag(trigger, roomId);
case TriggerType.hushPuppy:
  return _createHushPuppy(trigger, roomId);
case TriggerType.guardian:
  return _createGuardian(trigger, roomId);
```

### 5. Test Room TMX
Create `assets/levels/rooms/test_room.tmx` with:
- Floor + Walls layers
- Objects layer with one of each entity type:
  - Switch + Door
  - Conveyor belt
  - Spring
  - Fish (alive)
  - Crown
  - Bag pickup
  - Hush Puppy
  - Monster (patrol)
  - Guardian
  - Teleport

### 6. CharacterComponent Integration
Add doughnut firing:
```dart
void fireDoughnut() {
  if (canFire && state.doughnutCount > 0) {
    final doughnut = DoughnutProjectile(startPosition: state.position);
    gameRef.add(doughnut);
    notifier.updateDoughnutCount(state.doughnutCount - 1);
  }
}
```

## WHAT WILL CHANGE

### New Files
```
lib/features/gameplay/entities/
├── crown_entity.dart
├── bag_system.dart (or extend character_state.dart)
├── hush_puppy_entity.dart
├── guardian_entity.dart

lib/features/gameplay/systems/
├── interaction_system.dart

lib/features/gameplay/room/
├── room_state_extensions.dart (or update room_graph.dart)

assets/levels/rooms/
├── test_room.tmx
```

### Modified Files
- `lib/features/gameplay/entities/entity_factory.dart` — add new types
- `lib/features/gameplay/room/room_component.dart` — add InteractionSystem
- `lib/features/gameplay/room/room_graph.dart` — RoomState extensions
- `lib/entities/character_state.dart` — add fireDoughnut(), bag validation
- `lib/features/gameplay/entities/entity_factory.dart` — new entity types

## VERIFICATION CRITERIA

### Unit Tests
- [ ] Crown increments collection, triggers win at 5
- [ ] Bag picks up/drops items, prevents doorway drop
- [ ] Hush Puppy teleports when Head approaches
- [ ] Guardian immune to doughnut, defeated at 4 crowns
- [ ] InteractionSystem dispatches onEnter/onExit/onInteract

### Integration Tests
- [ ] Test room loads all entities correctly
- [ ] Crown collection increments GameState
- [ ] Bag item carries across room transitions
- [ ] Hush Puppy teleports away from Head
- [ ] Guardian blocks until 4 crowns collected
- [ ] Doughnut freezes monsters but not Guardian

### Quality Gates
- [ ] `flutter analyze` — no issues
- [ ] `flutter test` — all pass
- [ ] `dart format` — no changes