// Main game class for Head over Heels using Flame.

import '../../core/audio/hoh_cues.dart';
import 'package:flame/game.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:headoverheels/features/gameplay/state/input_system.dart';
import 'package:headoverheels/features/gameplay/systems/interaction_system.dart';
import 'package:headoverheels/features/gameplay/entities/character_component.dart';
import 'package:headoverheels/features/gameplay/room/room_component.dart';
import 'package:headoverheels/features/gameplay/room/room_graph.dart';
import 'package:headoverheels/features/gameplay/room/world_loader.dart';
import 'package:headoverheels/features/gameplay/state/character_notifier.dart';
import 'package:headoverheels/features/audio/audio_system.dart';
import 'package:headoverheels/entities/character_state.dart';
import 'package:headoverheels/features/gameplay/entities/bag_entity.dart';
import 'package:headoverheels/features/gameplay/entities/crown_entity.dart';
import 'package:headoverheels/features/gameplay/entities/dropped_item_entity.dart';
import 'package:headoverheels/features/gameplay/entities/guardian_entity.dart';

/// Main game class that manages the game world and loop.
class HeadOverHeelsGame extends FlameGame
    implements
        BagCollector,
        CrownCollector,
        ItemPicker,
        GuardianDefeatedNotifier {
  final Ref ref;

  /// Crowns collected, per planet. The throne room wants four of them.
  final Map<String, int> crownsByPlanet = {};

  /// Set once the guardian is beaten, which is what opens the throne room.
  bool guardianDefeated = false;
  final WorldGraph _worldGraph;
  final InteractionSystem _interactionSystem = InteractionSystem();
  late final InputSystem _inputSystem;

  RoomComponent? _currentRoom;
  late RoomId _currentRoomId;
  String? _lastPlanetId;

  HeadOverHeelsGame(this.ref, this._worldGraph);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // The same input system the touch controls write to. Building a second one
    // here would mean the joystick talking to an object the game never reads.
    _inputSystem = ref.read(inputSystemProvider);

    // Load initial room from world graph
    _currentRoomId = _worldGraph.startRoom;
    await _loadRoom(_currentRoomId);

    // Add characters
    await _addCharacters();

    // Set up camera
    camera.moveTo(Vector2.zero());
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Update physics for both characters (fixed timestep handled internally)
    _inputSystem.updatePhysics(dt);

    // Update interactions
    _interactionSystem.update(dt);

    // Update current room entities
    _currentRoom?.update(dt);
  }

  /// Current room ID.
  RoomId get currentRoomId => _currentRoomId;

  /// Current room component.
  RoomComponent? get currentRoom => _currentRoom;

  /// Load a room by ID.
  Future<void> _loadRoom(RoomId roomId) async {
    final definition = _worldGraph.getRoom(roomId);
    if (definition == null) {
      throw StateError('Room not found: $roomId');
    }

    // Remove current room if exists
    if (_currentRoom != null) {
      _unloadCurrentRoom();
    }

    // Create and load new room
    final room = RoomComponent(roomId: roomId, definition: definition);
    await add(room);
    _currentRoom = room;
    _currentRoomId = roomId;

    // Play music for the room's planet/theme
    _playRoomMusic(definition.theme);

    // Add characters to new room
    _moveCharactersToRoom(room);
  }

  /// Play background music appropriate for the room theme.
  void _playRoomMusic(String theme) {
    final audioSystem = ref.read(audioSystemProvider);
    if (_lastPlanetId != theme) {
      _lastPlanetId = theme;
      audioSystem.playMusic(theme);
    }
  }

  /// Transition to a new room via an exit.
  Future<void> transitionTo(RoomId targetRoomId, String targetEntrance) async {
    final audioSystem = ref.read(audioSystemProvider);
    audioSystem.playTeleport();

    await _loadRoom(targetRoomId);

    // Position characters at entrance
    final entrance = _findEntrance(targetEntrance);
    if (entrance != null) {
      _positionCharactersAt(entrance);
    }
  }

  /// Move both characters to the current room.
  void _moveCharactersToRoom(RoomComponent room) {
    CharacterComponent? head;
    CharacterComponent? heels;

    for (final character in children.whereType<CharacterComponent>()) {
      if (character.type == CharacterType.head) {
        head = character;
      } else if (character.type == CharacterType.heels) {
        heels = character;
      }
    }

    if (head != null) room.addCharacter(head);
    if (heels != null) room.addCharacter(heels);
  }

  /// Position characters at a specific entrance point.
  void _positionCharactersAt(Vector3 gridPosition) {
    final headNotifier = ref.read(headProvider.notifier);
    final heelsNotifier = ref.read(heelsProvider.notifier);

    // Set positions directly (for room transitions)
    headNotifier.setPosition(gridPosition);
    heelsNotifier.setPosition(gridPosition + Vector3(1, 0, 0));
  }

  /// Find entrance position by name in current room.
  Vector3? _findEntrance(String entranceName) {
    // For now, use spawn point
    final definition = _worldGraph.getRoom(_currentRoomId);
    return definition?.spawnPoint;
  }

  /// Unload the current room.
  void _unloadCurrentRoom() {
    if (_currentRoom == null) return;

    // Remove characters from room (they stay in game)
    for (final character in _currentRoom!.characters) {
      _currentRoom!.removeCharacter(character);
    }

    // Remove room entities
    for (final entity in _currentRoom!.entities) {
      entity.removeFromParent();
    }

    _currentRoom?.removeFromParent();
    _currentRoom = null;
  }

  /// The notifier behind a character, so a pickup can reach its state.
  CharacterStateNotifier? _notifierFor(CharacterComponent character) {
    final provider = character.type == CharacterType.head
        ? headProvider
        : heelsProvider;
    return ref.read(provider.notifier);
  }

  @override
  void onBagCollected(CharacterComponent character) {
    // The bag changes nothing yet, which is T056. Recording it means the item
    // is not lost, and a character has a slot to hold it in.
    _notifierFor(character)?.pickUp(const CarriedItem.other('bag'));
  }

  @override
  void collectCrown(String planetId) {
    crownsByPlanet.update(planetId, (count) => count + 1, ifAbsent: () => 1);
  }

  @override
  void onItemPickedUp(CharacterComponent character, CarriedItem item) {
    _notifierFor(character)?.pickUp(item);
  }

  /// How many crowns a planet has collected.
  int crownsFor(String planetId) => crownsByPlanet[planetId] ?? 0;

  /// Every crown collected so far. The world's guardian trigger does not say
  /// which planet its throne room belongs to, so the guardian counts them all:
  /// see T057 for the data that would fix it properly.

  /// Every crown collected, across the planets.
  int get crownsCollected =>
      crownsByPlanet.values.fold(0, (total, count) => total + count);

  @override
  void onGuardianDefeated() {
    guardianDefeated = true;
  }

  /// Add characters to the game world.
  Future<void> _addCharacters() async {
    // Head character
    final head = CharacterComponent(type: CharacterType.head, ref: ref);
    await add(head);
    _interactionSystem.registerCharacter(head);

    // Heels character
    final heels = CharacterComponent(type: CharacterType.heels, ref: ref);
    await add(heels);
    _interactionSystem.registerCharacter(heels);
  }

  /// Play a sound effect through the audio system.
  void playSfx(HohCue cue, {double? volume}) {
    ref.read(audioSystemProvider).playSfx(cue, volume: volume);
  }

  /// Convenience methods for common game sound effects.
  void playJump() => ref.read(audioSystemProvider).playJump();
  void playLand() => ref.read(audioSystemProvider).playLand();
  void playPickup() => ref.read(audioSystemProvider).playPickup();
  void playSwitch() => ref.read(audioSystemProvider).playSwitch();
  void playDoor() => ref.read(audioSystemProvider).playDoor();
  void playSpring() => ref.read(audioSystemProvider).playSpring();
  void playFire() => ref.read(audioSystemProvider).playFire();
  void playDoughnutHit() => ref.read(audioSystemProvider).playDoughnutHit();
  void playEnemyHit() => ref.read(audioSystemProvider).playEnemyHit();
  void playPlayerHit() => ref.read(audioSystemProvider).playPlayerHit();
  void playPlayerDeath() => ref.read(audioSystemProvider).playPlayerDeath();
  void playFishEat() => ref.read(audioSystemProvider).playFishEat();
  void playFishPoison() => ref.read(audioSystemProvider).playFishPoison();
  void playCrown() => ref.read(audioSystemProvider).playCrown();
  void playBag() => ref.read(audioSystemProvider).playBag();
  void playHushPuppy() => ref.read(audioSystemProvider).playHushPuppy();
  void playSwop() => ref.read(audioSystemProvider).playSwop();
}

/// Provider for WorldGraph loaded from JSON.
final worldGraphProvider = FutureProvider<WorldGraph>((ref) async {
  return loadWorldGraph();
});

/// The container's [Ref], for the widget layer to pass to the game.
///
/// A [WidgetRef] is a different type and does not fit where the game needs a
/// [Ref], so the screen reads this instead of trying to pass its own.
final gameRefProvider = Provider<Ref>((ref) => ref);

/// Builds the game over a world that is already loaded.
///
/// A provider for the game itself was a trap: the world arrives asynchronously,
/// so reading the provider before it resolved threw. The screen waits for
/// [worldGraphProvider] and calls this, which is the one way a game gets made.
HeadOverHeelsGame createHeadOverHeelsGame(Ref ref, WorldGraph worldGraph) =>
    HeadOverHeelsGame(ref, worldGraph);
