import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/services.dart' show AssetBundle, rootBundle;
import 'package:iso_core/iso_core.dart';
import 'package:knightlore/knightlore.dart';

/// How the game is driven. Kept as data so the day length, the starting area
/// and the auto cycle can be changed without touching the loop.
class KnightLoreGameConfig {
  const KnightLoreGameConfig({
    this.daySeconds = 24,
    this.autoCycle = true,
    this.worldKey = KnightLoreWorld.worldKey,
    this.roomsBasePath = RoomMapBuilder.roomsBasePath,
    this.tilesBasePath = KnightLoreManifest.tilesBasePath,
    this.spritesBasePath = KnightLoreManifest.spritesBasePath,
  });

  /// Seconds of real time per in-game day.
  final double daySeconds;
  final bool autoCycle;
  final String worldKey;
  final String roomsBasePath;
  final String tilesBasePath;
  final String spritesBasePath;
}

/// The playable game. All rules live in [RoomSession]; this class only turns
/// input into session calls, draws the room and runs the sundial.
class KnightLoreGame extends FlameGame {
  KnightLoreGame({
    this.config = const KnightLoreGameConfig(),
    AssetBundle? bundle,
  }) : bundle = bundle ?? rootBundle;

  final KnightLoreGameConfig config;
  final AssetBundle bundle;

  RoomSession? session;
  RoomView? roomView;
  String message = 'Find the wizard. Six ingredients, forty days.';
  String? error;

  bool _loaded = false;

  double _dayProgress = 0;
  bool _nightHandled = false;
  final Map<String, ui.Image> _tilesets = {};
  final Map<String, ui.Image> _sprites = {};
  final Map<String, RoomMap> _maps = {};

  /// Night is a clock state, not a curse state: after the split the four
  /// knights are still walking at night, they are just no longer a wolf.
  bool get isNight => _dayProgress >= 0.5 && _dayProgress < 1.0;

  /// True while the sabreman is the werewolf.
  bool get isWerewolf => session?.curse.phase == CursePhase.werewolf;

  /// True while the four knights are the party.
  bool get isSplit => session?.party.length == 4;

  /// True once the world, the maps and the art are loaded.
  bool get assetsReady => _loaded;

  double get dayProgress => _dayProgress;

  @override
  Future<void> onLoad() async {
    try {
      await _loadWorld();
      await _loadArt();
      _loaded = true;
    } catch (failure) {
      error = '$failure';
    }
  }

  Future<void> _loadWorld() async {
    final source = await bundle.loadString(config.worldKey);
    final world = WorldGraph.fromJson(
      jsonDecode(source) as Map<String, dynamic>,
    );
    final terrain = <String, RoomTerrain>{};
    for (final room in world.rooms.values) {
      final tmx = await bundle.loadString(
        '${config.roomsBasePath}/${room.theme}/${room.id}.tmx',
      );
      final map = parseRoomMap(tmx, room.id, room);
      _maps[room.id] = map;
      terrain[room.id] = map.terrain;
    }
    session = RoomSession(world: world, terrain: terrain);
  }

  Future<void> _loadArt() async {
    for (final area in KlAreas.all) {
      _tilesets[area] = await _image(
        '${config.tilesBasePath}/$area.png',
      );
      for (final prop in KnightLoreManifest.propTypes) {
        final key = '${prop}_$area';
        _sprites[key] = await _image(
          '${config.spritesBasePath}/props/${prop}_$area.png',
        );
      }
    }
    for (final knight in KnightClass.values) {
      _sprites['character_${knight.id}'] = await _image(
        '${config.spritesBasePath}/knights/'
        '${knight.id}_${knight == KnightClass.sabreman ? 'idle' : 'walk'}.png',
      );
    }
  }

  Future<ui.Image> _image(String key) async {
    final data = await bundle.load(key);
    final bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  /// Adds the room view once the world and the art are ready.
  void attachView() {
    final current = session;
    if (current == null || roomView != null) return;
    final view = RoomView(
      session: current,
      tileset: _tilesets[current.room.theme],
      sprites: _normalisedSprites(),
    );
    roomView = view;
    world.add(view);
    _syncRoom();
  }

  Map<String, ui.Image> _normalisedSprites() {
    // The renderer looks sprites up by trigger type, with the area folded in.
    final current = session;
    final area = current?.room.theme ?? KlAreas.all.first;
    return {
      for (final prop in KnightLoreManifest.propTypes)
        if (_sprites['${prop}_$area'] != null) prop: _sprites['${prop}_$area']!,
      for (final entry in _sprites.entries)
        if (entry.key.startsWith('character_')) entry.key: entry.value,
    };
  }

  void _syncRoom() {
    final current = session;
    final view = roomView;
    if (current == null || view == null) return;
    final map = _maps[current.roomId];
    if (map == null) return;
    view.setRoom(map, _tilesets[map.room.theme]!);
  }

  @override
  void update(double dt) {
    super.update(dt);
    roomView?.tick();
    final current = session;
    if (current == null || !_loaded) return;

    if (config.autoCycle) {
      _dayProgress += dt / config.daySeconds;
      if (_dayProgress >= 0.5 && !_nightHandled) {
        _nightHandled = true;
        current.nightFalls();
        current.splitParty();
        message = isSplit
            ? 'The curse splits: four knights, one creature.'
            : 'Night falls. The sabreman turns into a wolf.';
      } else if (_dayProgress >= 1.0) {
        _dayProgress = 0;
        _nightHandled = false;
        current.dawnBreaks();
        final event = current.advanceDay();
        message = switch (event) {
          CurseEvent.outOfTime => 'The forty days are over.',
          null => 'Dawn. ${current.curse.daysLeft} days left.',
          _ => 'Dawn.',
        };
      }
    }
  }

  /// Called by the keyboard layer.
  void handleKey(String key) {
    final current = session;
    if (current == null) return;
    final facing = _facingFor(key);
    if (facing != null) {
      _applyStep(current.step(facing));
      return;
    }
    final slot = _slotFor(key);
    if (slot != null) {
      _applyCast(current.castAtSlot(slot));
      return;
    }
    switch (key) {
      case ' ':
      case 'enter':
        _applyInteract(current.interact());
      case 'f':
        if (isNight) {
          _dayProgress = 0;
          _nightHandled = false;
          current.dawnBreaks();
          current.rejoinParty();
        } else {
          _dayProgress = 0.5;
          _nightHandled = false;
        }
    }
  }

  String? _facingChest() {
    final session = this.session;
    if (session == null) return null;
    return session.chestInFront;
  }

  Facing? _facingFor(String key) => switch (key) {
        'arrowUp' => Facing.north,
        'arrowRight' => Facing.east,
        'arrowDown' => Facing.south,
        'arrowLeft' => Facing.west,
        'w' => Facing.north,
        'd' => Facing.east,
        's' => Facing.south,
        'a' => Facing.west,
        'q' => Facing.northWest,
        'e' => Facing.northEast,
        'z' => Facing.northWest,
        'x' => Facing.northEast,
        _ => null,
      };

  /// Digits one to nine cast the scroll in that inventory slot.
  int? _slotFor(String key) {
    if (key.length != 1) return null;
    final digit = int.tryParse(key);
    if (digit == null || digit < 1 || digit > 9) return null;
    return digit - 1;
  }

  void _applyCast(CastOutcome outcome) {
    message = switch (outcome) {
      CastOutcome.cast => 'The spell takes hold.',
      CastOutcome.notAScroll => 'That is not a scroll.',
      CastOutcome.noSpell => 'The scroll is blank.',
      CastOutcome.nothing => '',
    };
  }

  void _applyStep(MoveOutcome outcome) {
    switch (outcome) {
      case MoveOutcome.moved:
        message = '';
      case MoveOutcome.blocked:
        message = 'A wall.';
      case MoveOutcome.noExit:
        message = 'No way out that way.';
      case MoveOutcome.refused:
        message = isWerewolf
            ? 'The wolf cannot use a doorway.'
            : 'That door is locked.';
      case MoveOutcome.changedRoom:
      case MoveOutcome.flipped:
        message = '';
        _syncRoom();
    }
  }

  String? _lastChestItem;

  void _applyInteract(InteractOutcome outcome) {
    if (outcome == InteractOutcome.chestOpened) {
      final chest = _facingChest();
      _lastChestItem = chest == null ? null : session?.chestContents(chest);
    }
    message = switch (outcome) {
      InteractOutcome.pickedUp => 'Picked up.',
      InteractOutcome.chestOpened =>
        'A chest: ${KlItems.nameOf(_lastChestItem ?? 'something')}.',
      InteractOutcome.chestEmpty => 'An empty chest.',
      InteractOutcome.ingredientAccepted => 'The cauldron takes it.',
      InteractOutcome.ingredientRefused => 'The cauldron refuses that.',
      InteractOutcome.wizardSpoke => 'Melkhior names what the cauldron wants.',
      InteractOutcome.wizardRefused =>
        'The wizard will not see a wolf or a knight.',
      InteractOutcome.dropped => 'An empty chest.',
      InteractOutcome.nothing => '',
    };
  }
}
