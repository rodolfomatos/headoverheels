import 'dart:convert';
import 'dart:math' as math;
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

/// Which screen the player is looking at. The state machine lives in the game
/// so it can be tested without a widget tree.
enum GameScreen { title, playing, paused, status, victory, defeat }

/// The playable game. All rules live in [RoomSession]; this class only turns
/// input into session calls, draws the room and runs the sundial.
class KnightLoreGame extends FlameGame {
  KnightLoreGame({
    this.config = const KnightLoreGameConfig(),
    AssetBundle? bundle,
    KnightLoreAudio? audio,
  })  : bundle = bundle ?? rootBundle,
        audio = audio ?? KnightLoreAudio();

  final KnightLoreGameConfig config;
  final AssetBundle bundle;

  /// The sounds. Silent unless a sink is given, so tests and the off-screen
  /// preview never touch an audio device.
  final KnightLoreAudio audio;

  RoomSession? session;
  RoomView? roomView;
  String message = 'Find the wizard. Six ingredients, forty days.';
  String? error;

  bool _loaded = false;

  /// How much of the screen is still black from the last room change, 1 to 0.
  ///
  /// The original cuts between rooms. A short fade is the polish, and it also
  /// hides the moment when the new room is drawn before the party is placed.
  double transition = 0;

  /// How long a room change takes to fade, in seconds.
  static const double transitionSeconds = 0.22;

  bool get isTransitioning => transition > 0;

  /// Trap cycles per second.
  static const double trapTicksPerSecond = 6;

  GameScreen screen = GameScreen.title;
  double _dayProgress = 0;
  double _trapAccumulator = 0;
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

  /// True once the six ingredients are in the cauldron.
  bool get isWon => session?.isWon ?? false;

  /// True when the forty days are up.
  bool get isOutOfTime => (session?.curse.daysLeft ?? 1) <= 0;

  bool get isPlaying => screen == GameScreen.playing;

  /// The status the title screen advertises.
  String get objective {
    final session = this.session;
    if (session == null) return 'Find the wizard and break the curse.';
    final wanted = session.curse.demandedIngredient;
    return 'The cauldron wants ${wanted ?? KlItems.ingredients.first}.';
  }

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

  /// How many images are decoded at once.
  ///
  /// The art is forty-nine images, and it was decoded one at a time: the browser
  /// fetched the first fifty assets in five seconds and then the load crawled,
  /// two images every thirty seconds, and the screen said "Loading the castle"
  /// the whole while. Decoding is the work, and doing forty-nine of them in a
  /// row is a queue with nothing in it. Eight at a time uses the browser's own
  /// concurrency without asking it for fifty decoded bitmaps at once.
  static const int artDecodeBatch = 8;

  /// The images the game needs, by the key it looks them up under.
  Map<String, String> _artToLoad() {
    final wanted = <String, String>{};
    for (final area in KlAreas.all) {
      wanted['tileset_$area'] = '${config.tilesBasePath}/$area.png';
      for (final prop in KnightLoreManifest.propTypes) {
        wanted['${prop}_$area'] =
            '${config.spritesBasePath}/props/${prop}_$area.png';
      }
    }
    for (final knight in KnightClass.values) {
      wanted['character_${knight.id}'] = '${config.spritesBasePath}/knights/'
          '${knight.id}_${knight == KnightClass.sabreman ? 'idle' : 'walk'}.png';
    }
    return wanted;
  }

  Future<void> _loadArt() async {
    final wanted = _artToLoad();
    final keys = wanted.keys.toList(growable: false);

    for (var start = 0; start < keys.length; start += artDecodeBatch) {
      final batch = keys.skip(start).take(artDecodeBatch);
      final images = await Future.wait(
        batch.map((key) => _image(wanted[key]!)),
      );
      for (var i = 0; i < batch.length; i++) {
        final key = batch.elementAt(i);
        if (key.startsWith('tileset_')) {
          _tilesets[key.substring('tileset_'.length)] = images[i];
        } else {
          _sprites[key] = images[i];
        }
      }
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

  /// Builds a room view for the current room without attaching it, which is
  /// what the visual preview test renders.
  RoomView? createView() {
    final current = session;
    if (current == null) return null;
    final view = RoomView(
      session: current,
      tileset: _tilesets[current.room.theme],
      sprites: _normalisedSprites(),
    );
    final map = _maps[current.roomId];
    if (map != null) view.setRoom(map, _tilesets[map.room.theme]!);
    return view;
  }

  /// Adds the room view once the world and the art are ready.
  void attachView() {
    final current = session;
    if (current == null || roomView != null) return;
    final view = createView();
    if (view == null) return;
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
    // The traps keep their own time so a party standing still still gets
    // caught, and so the renderer can draw a spike that is currently out.
    _stepTransition(dt);

    final session = this.session;
    if (session != null && _loaded) {
      _trapAccumulator += dt * trapTicksPerSecond;
      while (_trapAccumulator >= 1) {
        _trapAccumulator -= 1;
        session.advanceTick();
        _reportHazard();
      }
    }
    final current = session;
    if (current == null || !_loaded) return;

    if (config.autoCycle) {
      _dayProgress += dt / config.daySeconds;
      if (_dayProgress >= 0.5 && !_nightHandled) {
        _nightHandled = true;
        current.nightFalls();
        current.splitParty();
        _cue(AudioCue.night);
        message = isSplit
            ? 'The curse splits: four knights, one creature.'
            : 'Night falls. The sabreman turns into a wolf.';
      } else if (_dayProgress >= 1.0) {
        _dayProgress = 0;
        _nightHandled = false;
        current.dawnBreaks();
        final event = current.advanceDay();
        _cue(AudioCue.dawn);
        _cue(AudioCue.dayTick);
        message = switch (event) {
          CurseEvent.outOfTime => 'The forty days are over.',
          null => 'Dawn. ${current.curse.daysLeft} days left.',
          _ => 'Dawn.',
        };
      }
    }
    _checkEnd();
  }

  /// Called by the keyboard layer.
  void handleKey(String key) {
    final current = session;
    if (current == null) return;
    if (_handleUiKey(key)) return;
    if (screen != GameScreen.playing) return;
    final facing = _facingFor(key);
    if (facing != null) {
      _applyStep(current.step(facing));
      return;
    }
    final slot = _slotFor(key);
    if (slot != null) {
      final items = current.inventory.items;
      _lastCastItem = slot < items.length ? items[slot] : null;
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

  Facing? _facingFor(String key) => switch (key.toLowerCase()) {
        'arrowup' => Facing.north,
        'arrowright' => Facing.east,
        'arrowdown' => Facing.south,
        'arrowleft' => Facing.west,
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
  /// Screen keys first: they work whatever screen is open. Keys are matched
  /// case insensitively, because a keyboard may report a capital letter.
  bool _handleUiKey(String key) {
    switch (key.toLowerCase()) {
      case 'escape':
        screen = switch (screen) {
          GameScreen.playing => GameScreen.paused,
          GameScreen.paused => GameScreen.playing,
          GameScreen.status => GameScreen.playing,
          _ => screen,
        };
        return true;
      case 'p':
        if (screen == GameScreen.playing) {
          screen = GameScreen.paused;
        } else if (screen == GameScreen.paused) {
          screen = GameScreen.playing;
        }
        return true;
      case 'i':
        if (screen == GameScreen.playing) {
          screen = GameScreen.status;
        } else if (screen == GameScreen.status) {
          screen = GameScreen.playing;
        }
        return true;
      case ' ':
      case 'enter':
        switch (screen) {
          case GameScreen.title:
            screen = GameScreen.playing;
          case GameScreen.paused:
            screen = GameScreen.playing;
          case GameScreen.victory:
          case GameScreen.defeat:
            screen = GameScreen.title;
            _reset();
          default:
            return false;
        }
        return true;
    }
    return false;
  }

  void _reset() {
    _dayProgress = 0;
    _nightHandled = false;
    _won = false;
    _lastChestItem = null;
    message = 'Find the wizard. Six ingredients, forty days.';
    session = newKnightLoreSession();
    roomView = null;
  }

  int? _slotFor(String key) {
    if (key.length != 1) return null;
    key = key.toLowerCase();
    final digit = int.tryParse(key);
    if (digit == null || digit < 1 || digit > 9) return null;
    return digit - 1;
  }

  /// The game ends when the curse is broken or the days run out.
  /// Fades the room change out. A party that changes rooms twice in one frame
  /// restarts the fade instead of stacking it.
  void _stepTransition(double dt) {
    if (transition > 0) {
      transition = math.max(0, transition - dt / transitionSeconds);
    }
    final view = roomView;
    if (view == null) return;
    view.fade = transition;
    // The wash comes back as the fade clears. Driving both from the same value
    // is what stops a room staying unlit forever after a change.
    view.ambienceStrength = 1 - transition;
    // The canvas size is only known once the game is on screen. Reading it
    // before layout asserts, and the game does update before the widget puts it
    // on the display.
    if (transition > 0 && hasLayout) {
      final canvas = camera.viewport.size;
      view.canvasSize = ui.Size(canvas.x, canvas.y);
    }
  }

  /// Starts the fade for a room change. Public because a screen that swaps
  /// rooms itself has to start the same fade.
  void beginTransition() {
    transition = 1;
    final view = roomView;
    if (view != null) {
      view.ambienceStrength = 0;
      view.fade = 1;
    }
  }

  /// Where [Sundial] reads the day from: the dial counts the days that have
  /// passed, the HUD counts the ones that are left.
  int get daysOn =>
      CurseState.totalDays -
      (session?.curse.daysLeft ?? CurseState.totalDays) +
      1;

  /// Queues a sound. Deliberately not awaited: a cue must never delay a move.
  void _cue(AudioCue cue) {
    audio.play(cue);
  }

  void _checkEnd() {
    final current = session;
    if (current == null) return;
    if (isWon && screen != GameScreen.victory) {
      screen = GameScreen.victory;
      message = 'The curse is broken. You ride out of the castle a man again.';
      _cue(AudioCue.victory);
      audio.stopAmbient();
      return;
    }
    if (isOutOfTime && screen != GameScreen.defeat) {
      screen = GameScreen.defeat;
      message = 'The forty days are over and the wolf keeps you.';
      _cue(AudioCue.defeat);
      audio.stopAmbient();
    }
  }

  void _applyCast(CastOutcome outcome) {
    message = switch (outcome) {
      CastOutcome.cast => 'The spell takes hold.',
      CastOutcome.notAScroll => 'That is not a scroll.',
      CastOutcome.noSpell => 'The scroll is blank.',
      CastOutcome.nothing => '',
    };
    if (outcome == CastOutcome.cast) {
      // The scroll that was cast decides the sound, so casting the same spell
      // twice sounds the same twice.
      final cue = cueForSpellItem(_lastCastItem);
      if (cue != null) _cue(cue);
    } else if (outcome == CastOutcome.noSpell) {
      _cue(AudioCue.blockedCurse);
    }
  }

  /// A trap that caught the party costs a day; say so.
  void _reportHazard() {
    final session = this.session;
    if (session == null || session.lastHazardOutcome != HazardOutcome.hurt) {
      return;
    }
    final hazard = session.hazards.byId(session.lastHazardId ?? '');
    _cue(hazard?.kind == HazardKind.ball ? AudioCue.trap : AudioCue.hurt);
    message = switch (hazard?.kind) {
      HazardKind.spikes => 'The spikes catch you. A day is gone.',
      HazardKind.demon => 'The demon surfaces on you. A day is gone.',
      HazardKind.fallingBlock => 'The block lands on you. A day is gone.',
      HazardKind.bouncingBlock => 'The block bounces into you. A day is gone.',
      HazardKind.ball => '',
      null => 'Something catches you. A day is gone.',
    };
  }

  void _applyStep(MoveOutcome outcome) {
    if (session?.lastHazardOutcome == HazardOutcome.hurt) {
      _reportHazard();
    }
    switch (outcome) {
      case MoveOutcome.moved:
        message = '';
        _cue(AudioCue.step);
      case MoveOutcome.blocked:
        message =
            session?.lastHazardId != null ? 'A ball is in the way.' : 'A wall.';
        _cue(AudioCue.blocked);
      case MoveOutcome.noExit:
        message = 'No way out that way.';
        _cue(AudioCue.blocked);
      case MoveOutcome.refused:
        message = isWerewolf
            ? 'The wolf cannot use a doorway.'
            : 'That door is locked.';
        _cue(AudioCue.blockedCurse);
      case MoveOutcome.changedRoom:
      case MoveOutcome.flipped:
        message = '';
        _syncRoom();
        if (outcome == MoveOutcome.changedRoom) {
          beginTransition();
          _cue(AudioCue.door);
          final current = session;
          if (current != null) audio.startAmbient(current.room.theme);
        }
    }
  }

  String? _lastCastItem;
  String? _lastChestItem;
  bool _won = false;

  void _applyInteract(InteractOutcome outcome) {
    if (isWon && !_won) {
      _won = true;
      message = 'The curse is broken. You ride out of the castle a man again.';
    }
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
    _cue(switch (outcome) {
      InteractOutcome.pickedUp => AudioCue.pickup,
      InteractOutcome.chestOpened => AudioCue.chest,
      InteractOutcome.ingredientAccepted => AudioCue.chest,
      InteractOutcome.ingredientRefused => AudioCue.blockedCurse,
      InteractOutcome.dropped => AudioCue.drop,
      _ => AudioCue.menuMove,
    });
    // The end of the game has the last word on the message.
    _checkEnd();
  }
}
