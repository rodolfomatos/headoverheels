# T006 — Solution Proposal: Remaining Puzzle Mechanics

## CHOSEN APPROACH

### 1. Entity Implementations (extends PuzzleEntity)

#### SpringEntity
- Boosts jump velocity by 1.5x when character jumps from it
- Visual: compressed/extended sprite states
- TMX properties: none (standard)

#### FishEntity
- `isAlive` state (persisted in RoomState.eatenFish)
- On interact (eat): if alive → save checkpoint, mark eaten
- If dead: damage character (invulnerability check)
- State in `RoomState.eatenFish` (Set<String>)
- Visual: wiggling (alive) vs static (dead)

#### Doughnut System
- Head only: `doughnutCount` (0-6)
- On fire: spawn `DoughnutProjectile` → seeks nearest monster
- Projectile: homing, 3s lifetime, expires if no target
- On hit: `MonsterEntity.freeze(180 frames)`
- Visual: doughnut sprite, trail effect

#### Bag System
- Heels only: `carriedItem` (nullable)
- On action + overlapping item: pickup (if canCarry)
- On action (carrying): drop (validate not in doorway)
- Item displayed in HUD via `CharacterState.carriedItem`

#### CrownEntity
- `planetId` property (egyptus, penitentiary, safari, bookworld, blacktooth)
- On collect: add to `GameState.collectedCrowns`
- Check win: all 5 collected → victory screen
- Visual: glowing crown, particle effect

#### HushPuppyEntity
- Sleeping state, `isAwake` flag
- Detection radius: 3 tiles (Head only)
- On Head approach: teleport to random safe tile in room
- Returns after 5s delay
- Visual: sleeping (ZZZ) vs awake (eyes open)

#### MonsterEntity
- `patrolPoints: List<Vector3>` from TMX
- `currentPointIndex`, `direction` (forward/backward)
- `isFrozen` timer (frames remaining)
- Patrol: move to next point, wait 0.5s, reverse at ends
- On touch character: kill (unless invulnerable)
- On doughnut hit: freeze (180 frames), timer counts down
- Visual: patrol animation, frozen (blue tint)

#### GuardianEntity (extends MonsterEntity)
- Special: immune to doughnut (override freeze)
- Blocks throne room door
- Defeated when all 4 slave planet crowns collected
- Visual: larger, distinct appearance

### 2. InteractionSystem
Central system for character-entity collisions:
```dart
class InteractionSystem {
  void update(Set<CharacterComponent> characters, List<PuzzleEntity> entities) {
    for (final character in characters) {
      for (final entity in entities) {
        if (collides(character, entity)) {
          entity.onEnter(character);
        } else if (wasColliding(character, entity)) {
          entity.onExit(character);
        }
      }
    }
  }
}
```

### 3. RoomState Extensions
```dart
@freezed
abstract class RoomState with _$RoomState {
  const factory RoomState({
    ...
    required Set<String> eatenFish,
    required Map<String, dynamic> entityStates, // frozen monsters, etc.
  }) = _RoomState;
}
```

### 4. TMX Object Properties
Each entity reads custom properties:
```xml
<object name="spring_1" type="spring" x="320" y="160" gid="45"/>
<object name="fish_1" type="fish" x="640" y="320" properties="isAlive:true"/>
<object name="monster_1" type="monster" x="0" y="0" width="64" height="32" 
        properties="patrolPoints:[(10,5),(15,5)];waitTime:0.5"/>
```

### 5. DoughnutProjectile
- Homing: seeks nearest unfrozen monster within 8 tiles
- Speed: 8 tiles/sec
- Lifetime: 3s (180 frames)
- On hit: `monster.freeze(180)`, destroy projectile

## WHAT WILL CHANGE

### New Files
```
lib/features/gameplay/entities/
├── spring_entity.dart
├── fish_entity.dart
├── doughnut_projectile.dart
├── crown_entity.dart
├── hush_puppy_entity.dart
├── monster_entity.dart
├── guardian_entity.dart

lib/features/gameplay/systems/
├── interaction_system.dart
├── doughnut_system.dart
├── monster_ai_system.dart

test/
├── spring_entity_test.dart
├── fish_entity_test.dart
├── doughnut_system_test.dart
├── monster_ai_test.dart
└── integration_puzzle_test.dart
```

### Modified Files
- `lib/features/gameplay/entities/entity_factory.dart` — add new entity types
- `lib/features/gameplay/room/room_graph.dart` — add entity state fields
- `lib/features/gameplay/room/room_component.dart` — spawn new entities

## VERIFICATION CRITERIA

### Unit Tests
- [ ] Spring boosts jump height by 1.5x
- [ ] Fish saves checkpoint / damages when dead
- [ ] Doughnut freezes monster for 180 frames
- [ ] Bag picks up/drops items correctly
- [ ] Crown increments collection
- [ ] Hush puppy teleports on Head approach
- [ ] Monster patrols and kills on touch
- [ ] Guardian immune to doughnut

### Integration Tests
- [ ] Character jumps on spring → reaches higher platform
- [ ] Character eats live fish → checkpoint saved
- [ ] Head fires doughnut → monster freezes
- [ ] Heels picks up key → carries to door
- [ ] Collect all 5 crowns → win condition
- [ ] Head approaches hush puppy → teleports away
- [ ] Monster touches character → death
- [ ] Guardian blocks door until 4 crowns

### Quality Gates
- [ ] `flutter analyze` — no issues
- [ ] `flutter test` — all pass
- [ ] `dart format` — no changes