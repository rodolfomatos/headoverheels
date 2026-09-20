# Architecture Decision Record — Head over Heels (Flutter Port)

**Ticket**: T002  
**Date**: 2026-09-18  
**Status**: In Progress

---

## 1. Rendering Engine Decision

### Options Evaluated

| Option | Pros | Cons | Verdict |
|--------|------|------|---------|
| **Flame Engine** | Built-in game loop, component system, isometric helpers, input handling, audio, particles, Tiled support, good Flutter integration | Extra dependency (~500KB), learning curve | ✅ **CHOSEN** |
| **CustomPainter + Custom Game Loop** | Full control, zero deps, minimal bundle | Reinvent wheel: game loop, input, collision, state sync, parallax, entity management | ❌ Rejected |
| **Flutter 3D (Impeller)** | Modern GPU rendering | Overkill for 2D isometric; no isometric helpers; experimental | ❌ Rejected |
| **Godot + Flutter bridge** | Mature 2D engine | Complex integration; two languages; not pure Flutter | ❌ Rejected |

### Flame Configuration
```yaml
dependencies:
  flame: ^1.17.0
  flame_tiled: ^1.0.0  # TMX map loading
  flame_audio: ^1.0.0  # Audio wrapper
```

### Isometric in Flame
- `IsometricTileMapComponent` for room rendering
- Custom `IsometricCoordinateSystem` for 2:1 dimetric projection
- Camera follows player with smooth interpolation
- Layers: Background → Floor → Objects → Characters → Effects → UI

---

## 2. Coordinate System

### Logical (Grid) Space
```
Tile: 64x32 logical pixels (2:1 dimetric)
Grid: Integer (x, y, z) where z = height level
Origin: Bottom-left of room
```

### Screen Space Projection
```dart
// 2:1 Dimetric (classic isometric)
Vector2 gridToScreen(Vector3 grid) {
  final x = (grid.x - grid.y) * tileWidth / 2;
  final y = (grid.x + grid.y) * tileHeight / 2 - grid.z * tileHeight;
  return Vector2(x, y) + screenOffset;
}

Vector3 screenToGrid(Vector2 screen) {
  // Inverse projection for input
}
```

### Room Coordinates
- Each room: 16×16 tiles (1024×512 logical)
- Room ID: `(worldX, worldY, worldZ)` for 3D room grid
- Door connections: `(roomId, direction, targetRoomId, targetEntrance)`

---

## 3. State Management Architecture

### Riverpod Providers Structure
```dart
// Core providers
final gameStateProvider = StateNotifierProvider<GameStateNotifier, GameState>((ref) => ...);
final currentRoomProvider = StateProvider<RoomId>((ref) => RoomId.start);
final playerControlProvider = StateProvider<ControlledEntity>((ref) => ControlledEntity.head);

// Entity providers (per character)
final headProvider = StateNotifierProvider<CharacterNotifier, CharacterState>((ref) => ...);
final heelsProvider = StateNotifierProvider<CharacterNotifier, CharacterState>((ref) => ...);

// Global systems
final inventoryProvider = StateNotifierProvider<InventoryNotifier, InventoryState>((ref) => ...);
final powerUpProvider = StateNotifierProvider<PowerUpNotifier, PowerUpState>((ref) => ...);
final saveSystemProvider = Provider<SaveSystem>((ref) => SaveSystem(ref));
```

### Immutable State (Freezed)
```dart
@freezed
class CharacterState with _$CharacterState {
  const factory CharacterState({
    required CharacterType type,        // head | heels | combined
    required Vector3 position,          // Grid coordinates
    required Vector2 velocity,          // Sub-tile interpolation
    required AnimationState animation,  // idle, walk, jump, climb, carry, fire
    required FacingDirection facing,    // 8-directional
    required bool isGrounded,
    required int jumpPhase,             // 0=ground, 1=rising, 2=falling
    required InventoryItem? carriedItem, // Heels only
    required int doughnutCount,         // Head only
    required List<PowerUp> activePowerUps,
    required bool isControllable,       // Player has control
  }) = _CharacterState;
}

@freezed
class GameState with _$GameState {
  const factory GameState({
    required GamePhase phase,           // menu, playing, paused, gameOver, won
    required RoomId currentRoom,
    required Map<RoomId, RoomState> rooms,
    required Set<CrownId> collectedCrowns,
    required Set<FishId> eatenFish,     // Checkpoints
    required int lives,
    required DifficultyMode difficulty,
    required ControlScheme controlScheme,
  }) = _GameState;
}
```

---

## 4. Game Loop & Fixed Timestep

### Flame Game Loop (built-in)
```dart
class HeadOverHeelsGame extends FlameGame with HasKeyboardHandlerComponents, HasGameRef<HeadOverHeelsGame> {
  @override
  Future<void> onLoad() async {
    // Fixed timestep via Flame's update loop
    // 60Hz target, variable render interpolation
  }
  
  @override
  void update(double dt) {
    // dt is variable; use fixed timestep internally
    _accumulator += dt;
    while (_accumulator >= _fixedTimestep) {
      _fixedUpdate(_fixedTimestep);
      _accumulator -= _fixedTimestep;
    }
    _interpolationAlpha = _accumulator / _fixedTimestep;
  }
  
  void _fixedUpdate(double dt) {
    // Physics, AI, state machines - deterministic
  }
}
```

### Timestep Constants
- **Fixed timestep**: 1/60s (16.67ms)
- **Max frame skip**: 5 (prevent spiral of death)
- **Interpolation**: Linear between physics states for render

---

## 5. Character Controller Design

### State Machine (per character)
```
IDLE → WALK → (JUMP_RISE → JUMP_PEAK → JUMP_FALL) → LAND → IDLE
                    ↘ CLIMB (on ladder)
                    ↘ CARRY (pickup/drop)
                    ↘ FIRE (Head only)
                    ↘ SWOP (transition to combined/separate)
```

### Movement Physics (Grid-Based)
```dart
class MovementPhysics {
  // Walk speed (tiles/sec)
  static const double headWalkSpeed = 2.0;
  static const double heelsWalkSpeed = 4.0;  // 2x faster
  static const double combinedWalkSpeed = 3.0;
  
  // Jump (tiles)
  static const double headJumpHeight = 2.0;   // 2x height
  static const double heelsJumpHeight = 1.0;
  static const double combinedJumpHeight = 2.0;
  
  // Jump duration (frames @ 60Hz)
  static const int headJumpFrames = 30;       // ~0.5s
  static const int heelsJumpFrames = 20;      // ~0.33s
  
  // Air control
  static const double headAirControl = 0.5;   // Can steer mid-air
  static const double heelsAirControl = 0.2;
  
  // Edge hang (how far past tile edge before falling)
  static const double edgeHangThreshold = 0.3; // 30% of tile
}
```

### Input Abstraction
```dart
abstract class InputController {
  Vector2 get moveVector;      // -1..1 normalized
  bool get jumpPressed;
  bool get carryPressed;
  bool get firePressed;
  bool get swopPressed;
  bool get pausePressed;
}

// Implementations:
// - TouchVirtualStickController (mobile)
// - GamepadController (Bluetooth/USB)
// - KeyboardController (desktop/test)
```

---

## 6. Level Format

### TMX (Tiled) for Room Layout
```xml
<!-- Room.tmx -->
<map version="1.2" tiledversion="1.10.0" orientation="isometric" 
     renderorder="right-down" width="16" height="16" tilewidth="64" tileheight="32">
  <tileset firstgid="1" source="tilesets/castle.tsx"/>
  <layer name="Floor" id="1">...</layer>
  <layer name="Walls" id="2">...</layer>
  <objectgroup name="Entities" id="3">
    <object name="fish_1" type="ReincarnationFish" x="320" y="160" gid="45"/>
    <object name="switch_1" type="Switch" x="640" y="320" properties="target:door_1"/>
    <object name="conveyor_1" type="ConveyorBelt" x="0" y="0" width="640" height="32" properties="direction:right"/>
  </objectgroup>
  <objectgroup name="Triggers" id="4">
    <object name="door_north" type="Door" x="480" y="0" width="64" height="32" 
            properties="targetRoom:castle_2, targetEntrance:south"/>
  </objectgroup>
</map>
```

### Custom JSON for World Graph
```json
{
  "rooms": {
    "castle_start": {
      "file": "rooms/castle_start.tmx",
      "theme": "castle",
      "exits": {
        "north": { "room": "castle_hall", "entrance": "south" },
        "east": { "room": "castle_cell_2", "entrance": "west" }
      },
      "checkpoints": ["fish_1"],
      "requiredItems": []
    }
  },
  "worldGraph": {
    "planets": ["blacktooth", "egyptus", "penitentiary", "safari", "bookworld"],
    "teleports": {
      "castle_teleport_1": { "target": "moonbase_hq", "oneWay": false },
      "moonbase_teleport_egyptus": { "target": "egyptus_entrance", "oneWay": true }
    }
  }
}
```

### Asset Pipeline
```
assets/
├── sprites/
│   ├── characters/head.atlas
│   ├── characters/heels.atlas
│   ├── tilesets/castle.atlas
│   ├── tilesets/egyptus.atlas
│   ├── items/
│   └── ui/
├── audio/
│   ├── music/ (OGG, 3 quality levels)
│   └── sfx/ (WAV/OGG)
├── levels/
│   ├── rooms/*.tmx
│   └── world.json
└── fonts/
```

---

## 7. Entity-Component Architecture (Flame)

### Core Components
```dart
// Base character component
class CharacterComponent extends PositionComponent 
    with CollisionCallbacks, HasGameRef<HeadOverHeelsGame> {
  
  final CharacterType type;
  late CharacterStateNotifier notifier;
  late AnimationComponent animation;
  late HitboxComponent hitbox;
  
  // State sync from Riverpod
  @override
  void update(double dt) {
    final state = notifier.currentState;
    position = gridToScreen(state.position);
    animation.current = state.animation;
    // ... interpolate velocity for smooth render
  }
}

// Room component
class RoomComponent extends PositionComponent with HasGameRef {
  final RoomId roomId;
  late IsometricTileMapComponent tileMap;
  late List<EntityComponent> entities;
  late List<DoorComponent> doors;
  late List<TriggerComponent> triggers;
  
  void onEnter(CharacterComponent character) { ... }
  void onExit(CharacterComponent character) { ... }
}

// Puzzle elements as components
class SwitchComponent extends EntityComponent { ... }
class ConveyorBeltComponent extends EntityComponent { ... }
class TeleportComponent extends EntityComponent { ... }
class SpringComponent extends EntityComponent { ... }
class ReincarnationFishComponent extends EntityComponent { ... }
```

---

## 8. Save/Load System

### Save Data Structure
```dart
@freezed
class SaveData with _$SaveData {
  const factory SaveData({
    required int version,
    required DateTime timestamp,
    required GameState gameState,
    required CharacterState headState,
    required CharacterState heelsState,
    required InventoryState inventory,
    required PowerUpState powerUps,
    required Map<RoomId, RoomState> roomStates,
  }) = _SaveData;
```

### Storage
- **Primary**: `shared_preferences` (small, fast)
- **Backup**: JSON file in app documents (full state)
- **Auto-save**: On room transition, checkpoint (fish), crown collection
- **Slots**: 3 manual + 1 auto

---

## 9. Audio Architecture

### Flame Audio + just_audio
```dart
class AudioSystem {
  final AudioPlayer bgmPlayer = AudioPlayer();
  final AudioPool sfxPool = AudioPool(); // For overlapping SFX
  
  // 3 sound levels from original
  enum SoundLevel { full, effectsOnly, none }
  
  void playMusic(String track, {bool loop = true}) { ... }
  void playSfx(String name, {double volume = 1.0}) { ... }
  void setSoundLevel(SoundLevel level) { ... }
}
```

### Tracks Needed
- Main theme (title)
- Castle theme
- Egyptus theme
- Penitentiary theme
- Safari theme
- Book World theme
- Moonbase theme
- Tension/danger
- Victory
- Game over

---

## 10. Accessibility Architecture

### Settings Provider
```dart
@freezed
class AccessibilitySettings with _$AccessibilitySettings {
  const factory AccessibilitySettings({
    @Default(false) bool colorBlindMode,
    @Default(ColorBlindType.protanopia) ColorBlindType colorBlindType,
    @Default(false) bool highContrast,
    @Default(false) bool reducedMotion,
    @Default(false) bool autoJumpAssist,
    @Default(false) bool holdToMove,
    @Default(1.0) double uiScale,
    @Default(1.0) double gameSpeed,
    @Default(ControlScheme.touch) ControlScheme preferredControls,
  }) = _AccessibilitySettings;
}
```

### Implementation
- **Color blind**: Shader-based palette swap (fragment shader)
- **High contrast**: Alternative tile/character sprites
- **Motor**: Input buffering, auto-jump, reduced precision zones
- **Screen reader**: Semantics labels on all UI, live region for game state

---

## 11. Testing Strategy

### Unit Tests (80% coverage target)
- Coordinate conversion (grid↔screen)
- Movement physics (jump arcs, walk speeds)
- State machine transitions
- Inventory logic
- Save/load serialization
- Room graph navigation

### Widget/Integration Tests (70% coverage)
- Menu navigation flows
- Room transitions
- Character switching
- Puzzle element interactions
- Accessibility features

### Golden Image Tests
- Room rendering at different zoom levels
- Character animations
- UI states

---

## 12. Dependencies Summary

```yaml
dependencies:
  flutter:
    sdk: flutter
  flame: ^1.17.0
  flame_tiled: ^1.0.0
  flame_audio: ^1.0.0
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.0
  freezed_annotation: ^2.4.4
  json_annotation: ^4.9.0
  just_audio: ^0.9.36
  shared_preferences: ^2.2.0
  path_provider: ^2.1.0
  vector_math: ^2.1.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
  freezed: ^2.5.2
  build_runner: ^2.4.11
  json_serializable: ^6.8.0
  riverpod_generator: ^2.4.0
  riverpod_lint: ^2.3.10
  custom_lint: ^0.6.4
  golden_toolkit: ^0.15.0
```

---

## 13. Remaining Decisions (Out of Scope for T002)

| Decision | Ticket | Notes |
|----------|--------|-------|
| Touch control layout details | T006 | Prototype in T003 |
| Asset style (vector vs pixel art) | T006 | Art direction needed |
| Level editor vs hand-authored TMX | T007 | Start hand-authored |
| Procedural room generation | Backlog | Maybe post-launch |
| Multiplayer/co-op | Non-goal | v1 single-player only |

---

## 14. Validation Criteria for T002

- [ ] ADR documented in this file
- [ ] Flame + dependencies in pubspec.yaml
- [ ] Coordinate system implemented + tested
- [ ] Character state machine skeleton (Freezed)
- [ ] Riverpod provider structure created
- [ ] Game loop with fixed timestep
- [ ] One room TMX loads and renders
- [ ] Head/Heels movement prototype (no art)
- [ ] Swop key logic implemented
- [ ] `make check` passes (analyze, test, format)

---

## 15. Risks & Mitigations

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Flame isometric bugs | Medium | High | Prototype early; file issues upstream |
| 60fps on low-end Android | Medium | High | Profile on real device; optimize draw calls |
| Touch control precision | High | High | Multiple control schemes; assist modes |
| State sync (Riverpod ↔ Flame) | Medium | Medium | Unidirectional: Riverpod → Flame only |
| Save data migration | Low | Medium | Versioned saves; migration functions |

---

*End of Architecture Decision Record*