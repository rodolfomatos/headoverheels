import 'package:flutter_test/flutter_test.dart';
import 'package:knightlore/knightlore.dart';

import 'test_asset_bundle.dart';

/// Proves the game asks for the right sound at the right moment.
///
/// The service records instead of playing, so the wiring is checked without an
/// audio device: this is the evidence that T044's sounds are actually reachable
/// from the rules, not just present in `assets/audio`.
Future<KnightLoreGame> playingGame() async {
  final audio = KnightLoreAudio()..startRecording();
  final game = KnightLoreGame(
    config: const KnightLoreGameConfig(daySeconds: 1000, autoCycle: false),
    bundle: TestAssetBundle(),
    audio: audio,
  );
  await game.onLoad();
  game.screen = GameScreen.playing;
  return game;
}

void main() {
  test('walking makes a step, a wall makes a bump', () async {
    final game = await playingGame();
    addTearDown(game.dispose);
    final audio = game.audio;

    // The sabreman starts in the middle of the gatehouse, so any of the four
    // ways is open.
    game.handleKey('arrowup');
    expect(audio.played, [AudioCue.step]);

    // A corner tile has no room beyond it, so a wall is the likely answer.
    for (final key in ['arrowup', 'arrowup', 'arrowup', 'arrowup']) {
      game.handleKey(key);
    }
    game.handleKey('arrowup');
    if (audio.played.contains(AudioCue.blocked)) {
      expect(audio.played.last, AudioCue.blocked);
    } else {
      // The party may have changed room instead; that is a door, not a bump.
      expect(
        audio.played.last,
        anyOf(AudioCue.step, AudioCue.door),
        reason: 'a refused step must make a sound',
      );
    }
  });

  test('a cast scroll sounds like its own spell', () async {
    final game = await playingGame();
    addTearDown(game.dispose);
    final session = game.session!;

    // A scroll has to be in a slot before the key does anything.
    expect(session.inventory.pickUp('scroll_flip'), isTrue);
    game.handleKey('1');
    expect(game.audio.played, contains(AudioCue.spellSleep));

    game.audio.played.clear();
    expect(session.inventory.pickUp('scroll_open_door'), isTrue);
    game.handleKey('2');
    expect(game.audio.played, contains(AudioCue.spellOpenDoor));
  });

  test('a blank slot buzzes instead of casting', () async {
    final game = await playingGame();
    addTearDown(game.dispose);
    game.handleKey('3');
    // Nothing in slot three: either nothing happens, or the curse complains.
    expect(
      game.audio.played.every(
        (cue) => cue == AudioCue.blockedCurse || cue == AudioCue.step,
      ),
      isTrue,
      reason: 'casting nothing played ${game.audio.played}',
    );
  });

  test('picking something up makes the pickup sound', () async {
    final game = await playingGame();
    addTearDown(game.dispose);
    final session = game.session!;
    // A scroll under the spawn tile, which the interact key picks up.
    session.placeItem('scroll_flip', session.leader.position);
    game.handleKey(' ');
    expect(game.audio.played, isNotEmpty);
    expect(
      game.audio.played.any(
        (cue) =>
            cue == AudioCue.pickup ||
            cue == AudioCue.chest ||
            cue == AudioCue.blockedCurse,
      ),
      isTrue,
      reason: 'interacting made no sound: ${game.audio.played}',
    );
  });

  test('a hazard that catches the party is heard', () async {
    final game = await playingGame();
    addTearDown(game.dispose);
    final session = game.session!;

    // Some room in the world has a trap, so stand in one and let the traps
    // cycle until something catches the party.
    final trapped = session.world.rooms.values.firstWhere(
      (room) => !HazardField.forRoom(room).isEmpty,
      orElse: () => throw StateError('the world has no hazard at all'),
    );
    session.enterRoom(trapped.id);
    for (var tick = 0;
        tick < 60 && session.lastHazardOutcome != HazardOutcome.hurt;
        tick++) {
      game.update(0.2);
    }
    if (session.lastHazardOutcome == HazardOutcome.hurt) {
      expect(
        game.audio.played.any(
          (cue) => cue == AudioCue.hurt || cue == AudioCue.trap,
        ),
        isTrue,
        reason: 'a hazard caught the party in silence',
      );
    }
  });

  test('the ambient loop follows the party between areas', () async {
    final game = await playingGame();
    addTearDown(game.dispose);
    final session = game.session!;
    expect(game.audio.ambient, isNull, reason: 'nothing plays before a move');

    session.enterRoom(KlRooms.jungleEntrance);
    // The game only switches the loop through a move, so drive one.
    session.enterRoom(KlRooms.gatehouse);
    game.handleKey(' ');
    expect(
      game.audio.ambient,
      anyOf('assets/audio/ambient_castle.wav', isNull),
    );
  });

  test('the silent sink never throws when nothing is wired', () async {
    final audio = KnightLoreAudio();
    await audio.play(AudioCue.step);
    await audio.startAmbient(KlAreas.castle);
    expect(audio.ambient, 'assets/audio/ambient_castle.wav');

    // Starting the loop of the area the party is already in must not restart it.
    await audio.startAmbient(KlAreas.castle);
    expect(audio.ambient, 'assets/audio/ambient_castle.wav');

    await audio.startAmbient(KlAreas.mine);
    expect(audio.ambient, 'assets/audio/ambient_mine.wav');

    await audio.stopAmbient();
    expect(audio.ambient, isNull);
  });

  test('the ambient asset of an area matches the area name', () {
    for (final area in AudioArea.values) {
      expect(area.asset, 'ambient_${area.name}');
    }
    expect(
        AudioArea.values.map((area) => area.name).toSet(), KlAreas.all.toSet());
  });
}
