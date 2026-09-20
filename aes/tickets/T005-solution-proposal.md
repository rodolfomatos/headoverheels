# T005 — Solution Proposal: Puzzle Mechanics

## CHOSEN APPROACH

### 1. Entity Component Architecture (Flame)
Each puzzle element = `EntityComponent` with:
- `HitboxComponent` for collision
- `PositionComponent` for grid position
- Custom logic in `update(dt)` or event handlers
- State persisted in `RoomState` (switches, fish, items)

### 2. Entity Factory (from TMX Objects)
```dart
// TMX object properties → Entity
{
  "type": "switch",
  "targetId": "door_1",
  "initialState": "off"
}
```
Factory parses `type` + custom properties → spawns correct entity.

### 3. Character Interaction System
Central `InteractionSystem` handles:
- `onActionPressed()` → check overlapping trigger → dispatch
- Character abilities gate interactions (canFire, canCarry, canClimb)

### 4. Puzzle Element Implementations

#### Switch
- `SwitchEntity`: `bool isOn`, `String targetId`
- On activate: toggle → send event to target
- Visual: pressed/unpressed sprite

#### ConveyorBelt
- `ConveyorEntity`: `ExitDirection direction`, `double speed`
- In `update`: apply velocity to overlapping characters
- Character can jump to move opposite

#### Spring
- `SpringEntity`: `double boostMultiplier` (default 1.5)
- On jump from: multiply jump velocity
- Can be carried (Heels) and placed

#### ReincarnationFish
- `FishEntity`: `bool isAlive`, `Vector3 checkpointPos`
- On interact (eat): if alive → save checkpoint, mark eaten
- If dead: damage character
- State in `RoomState.eatenFish`

#### Doughnut System
- Head only: `doughnutCount` (0-6)
- On fire: spawn `DoughnutProjectile` → seeks nearest monster
- On hit: `MonsterEntity.freeze(180 frames)`
- Projectile: homing, expires if no target

#### Bag System
- Heels only: `carriedItem` (nullable)
- On action + overlapping item: pickup
- On action (no item): drop (not in doorway)
- Item displayed in HUD

#### Crown
- `CrownEntity`: `String planetId`
- On collect: add to `GameState.collectedCrowns`
- Check win: all 5 collected

#### HushPuppy
- `HushPuppyEntity`: `bool isSleeping`
- On Head approach (radius): teleport to random safe spot
- Returns after delay

#### Monster
- `MonsterEntity`: `List<Vector3> patrolPoints`, `int currentPoint`
- Patrol: move to next point, wait, reverse
- On touch character: kill (unless invulnerable)
- On doughnut hit: freeze (timer), unfreeze → resume patrol

#### Guardian (Blacktooth)
- Special monster: immune to doughnut
- Blocks door until all 4 crowns collected

### 5. RoomState Persistence
```dart
@freezed
abstract class RoomState {
  Set<String> activatedSwitches;
  Set<String> eatenFish;
  Set<String> collectedItems;
  Map<String, dynamic> customFlags;
}
```
Saved on room transition, restored on enter.

### 6. Collision System
- Grid-based AABB (tile coordinates)
- Character hitbox: 0.8x0.8 tiles (centered)
- Entity hitbox: full tile or custom
- Separate layers: solid (walls), trigger (switches), damage (monsters)

## WHAT WILL CHANGE

### New Files
```
lib/features/gameplay/entities/
├── switch_entity.dart
├── conveyor_entity.dart
├── spring_entity.dart
├── fish_entity.dart
├── doughnut_projectile.dart
├── bag_item.dart
├── crown_entity.dart
├── hush_puppy_entity.dart
├── monster_entity.dart
├── guardian_entity.dart
└── entity_factory.dart

lib/features/gameplay/systems/
├── interaction_system.dart
├── puzzle_system.dart
├── monster_ai_system.dart
└── conveyor_system.dart

lib/features/gameplay/room/
├── room_state.dart (extend with puzzle state)

test/
├── switch_entity_test.dart
├── conveyor_entity_test.dart
├── doughnut_system_test.dart
├── monster_ai_test.dart
└── integration_puzzle_test.dart
```

### Modified Files
- `lib/features/gameplay/room/room_component.dart` — spawn entities
- `lib/features/gameplay/room/entity_factory.dart` — parse TMX objects
- `lib/entities/character_state.dart` — add interaction helpers

## WHAT WILL NOT CHANGE
- Core character physics (T003)
- Room loading/rendering (T004)
- Coordinate system

## VERIFICATION CRITERIA

### Unit Tests
- [ ] Switch toggles target on/off
- [ ] Conveyor applies correct velocity
- [ ] Spring boosts jump height
- [ ] Fish saves checkpoint / damages when dead
- [ ] Doughnut freezes monster for 180 frames
- [ ] Bag picks up/drops items correctly
- [ ] Crown increments collection
- [ ] Hush puppy teleports on approach
- [ ] Monster patrols and kills on touch

### Integration Tests
- [ ] Character activates switch → door opens
- [ ] Character rides conveyor → moves with belt
- [ ] Character jumps on spring → reaches higher platform
- [ ] Character eats live fish → checkpoint saved
- [ ] Head fires doughnut → monster freezes
- [ ] Heels picks up key → carries to door
- [ ] Collect all 5 crowns → win condition

### Visual Verification
- [ ] Switch visual state changes
- [ ] Conveyor animates
- [ ] Doughnut projectile visible
- [ ] Monster patrol visible

### Quality Gates
- [ ] `flutter analyze` — no issues
- [ ] `flutter test` — all pass
- [ ] `dart format` — no changes