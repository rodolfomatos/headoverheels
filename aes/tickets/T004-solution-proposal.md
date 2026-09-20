# T004 — Solution Proposal: Isometric Level Rendering Engine with TMX

## CHOSEN APPROACH

### 1. TMX Map Structure
Each room = 1 TMX file with layers:
- `Floor` (TileLayer): Base floor tiles
- `Walls` (TileLayer): Collision tiles (impassable)
- `Objects` (ObjectGroup): Entities with `type` + custom properties
- `Triggers` (ObjectGroup): Doors, teleports, zone transitions

### 2. Flame Components
```dart
// RoomComponent: Manages one room's tilemap + entities
class RoomComponent extends PositionComponent {
  final RoomId roomId;
  late IsometricTileMapComponent tileMap;
  late List<EntityComponent> entities;
  late List<TriggerComponent> triggers;
}

// IsometricTileMapComponent from flame_tiled
// Camera: follows player with lerp
```

### 3. Coordinate System Alignment
- TMX: Top-left origin, row/col indices
- Our grid: Bottom-left origin, (x, y, z) coordinates
- Conversion in `IsometricCoordinates.tmxToGrid()`

### 4. Room Graph & Transitions
- `WorldGraph` loads `world.json` with room connections
- Door trigger → `RoomTransitionSystem` loads target room
- Async loading with loading screen

### 5. Asset Pipeline
```
assets/levels/
├── tilesets/
│   ├── castle.tsx      # Tileset definition
│   ├── castle.png      # Sprite sheet
│   ├── egyptus.tsx
│   └── ...
├── rooms/
│   ├── castle_start.tmx
│   ├── castle_hall.tmx
│   └── ...
└── world.json          # Room graph + connections
```

## WHAT WILL CHANGE

### New Files
```
lib/features/gameplay/
├── room/
│   ├── room_component.dart       # RoomComponent
│   ├── room_loader.dart          # TMX loading + parsing
│   ├── room_graph.dart           # WorldGraph, RoomId, connections
│   ├── tilemap_component.dart    # IsometricTileMapComponent wrapper
│   └── triggers/
│       ├── trigger_component.dart
│       ├── door_trigger.dart
│       ├── teleport_trigger.dart
│       └── zone_trigger.dart
├── camera/
│   └── game_camera.dart          # CameraComponent with lerp
├── entities/
│   ├── entity_factory.dart       # Spawn entities from TMX objects
│   ├── switch_entity.dart
│   ├── conveyor_entity.dart
│   ├── teleport_entity.dart
│   ├── spring_entity.dart
│   ├── fish_entity.dart
│   └── item_entity.dart
└── systems/
    ├── room_transition_system.dart
    └── collision_system.dart

test/
├── room_loader_test.dart
├── room_graph_test.dart
└── coordinate_conversion_test.dart
```

### Modified Files
- `pubspec.yaml` — add `flame_tiled`
- `lib/core/isometric.dart` — add `tmxToGrid()` helper

## WHAT WILL NOT CHANGE
- Character state/physics (T003)
- Input system
- Core coordinate system

## VERIFICATION CRITERIA

### Unit Tests
- [ ] `RoomLoader` parses TMX → RoomComponent correctly
- [ ] `WorldGraph` finds paths between rooms
- [ ] `tmxToGrid()` converts TMX coordinates to our grid
- [ ] Object factory spawns correct entity types

### Integration Tests
- [ ] Load `castle_start.tmx` → renders floor + walls
- [ ] Character walks on floor, collides with walls
- [ ] Door trigger → loads adjacent room
- [ ] Camera follows character smoothly

### Visual Verification
- [ ] No Z-fighting at tile edges
- [ ] Isometric projection looks correct (2:1 dimetric)
- [ ] 60fps on mid-range device

### Quality Gates
- [ ] `flutter analyze` — no issues
- [ ] `flutter test` — all pass
- [ ] `dart format` — no changes