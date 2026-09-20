# T009 — Solution Proposal: Bag System

## CHOSEN APPROACH

### 1. BagEntity
```dart
class BagEntity extends PuzzleEntity {
  bool _isCollected;
  
  @override
  void onInteract(CharacterComponent character) {
    if (!character.canCarry) return;
    if (_isCollected) return;
    
    _collectBag(character);
  }
  
  void _collectBag(CharacterComponent character) {
    _isCollected = true;
    character.state = character.state.copyWith(hasBag: true);
    removeFromParent();
  }
}
```

### 2. CharacterState Extensions
```dart
extension BagSystem on CharacterStateNotifier {
  void pickupItem(CarriedItem item) {
    if (!state.canCarry) return;
    if (state.carriedItem != CarriedItem.none()) return;
    
    state = state.copyWith(carriedItem: item);
  }
  
  void dropItem() {
    if (state.carriedItem == CarriedItem.none()) return;
    if (!_canDropHere()) return;
    
    final droppedItem = state.carriedItem;
    state = state.copyWith(carriedItem: CarriedItem.none());
    _spawnDroppedItem(droppedItem);
  }
  
  bool _canDropHere() {
    // Check 4 adjacent tiles for door triggers
    // If any adjacent tile has DoorEntity, return false
  }
}
```

### 3. Doorway Detection
```dart
bool _isInDoorway(Vector3 position) {
  final directions = [Offset(1,0), Offset(-1,0), Offset(0,1), Offset(0,-1)];
  for (final dir in directions) {
    final checkPos = position + Vector3(dir.dx, dir.dy, 0);
    if (_room.getEntityAt(checkPos) is DoorEntity) return true;
  }
  return false;
}
```

### 4. Item Entity (for dropped items)
```dart
class DroppedItemEntity extends PuzzleEntity {
  final CarriedItem item;
  
  @override
  void onInteract(CharacterComponent character) {
    character.state.pickupItem(item);
    removeFromParent();
  }
}
```

### 5. EntityFactory Integration
```dart
case TriggerType.bag:
  return BagEntity(...);
case TriggerType.item:
  return ItemEntity(...); // keys, crowns, springs, etc.
```

### 6. HUD Update
- Already shows carried item in `_buildBagIcon()`
- Updates reactively via Riverpod

## WHAT WILL CHANGE

### New Files
```
lib/features/gameplay/entities/
├── bag_entity.dart
├── dropped_item_entity.dart
```

### Modified Files
- `lib/entities/character_state.dart` — add bag methods
- `lib/features/gameplay/entities/entity_factory.dart` — add bag/item types
- `lib/features/gameplay/room/room_component.dart` — spawn items
- `lib/features/ui/widgets/hud.dart` — already supports bag icon

## WHAT WILL NOT CHANGE
- Core character physics
- Room loading system
- Other puzzle entities

## VERIFICATION CRITERIA

### Unit Tests
- [ ] Heels picks up bag → gains carry ability
- [ ] Heels picks up key → key in bag
- [ ] Heels drops key → key spawns at position
- [ ] Drop in doorway → prevented
- [ ] Bag persists across room transitions
- [ ] Head cannot pick up bag

### Integration Tests
- [ ] Heels picks up bag → can carry key to door
- [ ] Drop key in doorway → rejected
- [ ] Drop key in valid spot → key spawns
- [ ] Swop to Head → bag disabled
- [ ] Room transition → bag item persists

### Quality Gates
- [ ] `flutter analyze` — no issues
- [ ] `flutter test` — all pass
- [ ] `dart format` — no changes