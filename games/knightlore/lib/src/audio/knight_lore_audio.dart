import 'package:flame_audio/flame_audio.dart';

import 'knight_lore_cues.dart';

/// Where the audio goes.
///
/// Kept behind an interface so the game, the widget tests and a headless render
/// can all run the same code: tests pass a [SilentAudioSink] and never touch an
/// audio device.
abstract class AudioSink {
  Future<void> play(String asset, {double volume = 1});
  Future<void> startLoop(String asset, {double volume = 1});
  Future<void> stopLoop();
}

/// Plays the WAV files in `assets/audio` through Flame's audio layer.
class FlameAudioSink implements AudioSink {
  AudioPlayer? _loop;

  @override
  Future<void> play(String asset, {double volume = 1}) async {
    await FlameAudio.play(asset, volume: volume);
  }

  @override
  Future<void> startLoop(String asset, {double volume = 1}) async {
    // One loop at a time: starting the next area's loop replaces the last.
    final current = _loop;
    _loop = null;
    if (current != null) await current.stop();
    _loop = await FlameAudio.loop(asset, volume: volume);
  }

  @override
  Future<void> stopLoop() async {
    final current = _loop;
    _loop = null;
    if (current != null) await current.stop();
  }
}

/// Drops every sound. Used by tests and by the off-screen preview render.
class SilentAudioSink implements AudioSink {
  const SilentAudioSink();

  @override
  Future<void> play(String asset, {double volume = 1}) async {}

  @override
  Future<void> startLoop(String asset, {double volume = 1}) async {}

  @override
  Future<void> stopLoop() async {}
}

/// Sounds for the game, with the cues it was last asked to play.
///
/// The service does not decide *what* a cue should be: the rules in
/// [RoomSession] do, through the `Cue` values they emit, so a test can read the
/// same decisions without an audio device.
class KnightLoreAudio {
  KnightLoreAudio({AudioSink sink = const SilentAudioSink()}) : _sink = sink;

  final AudioSink _sink;

  /// The asset path of every cue, so the manifest and the tests agree.
  static String assetFor(AudioCue cue) => 'assets/audio/${cue.name}.wav';

  /// Every cue that was asked for, in order. Only filled when [record] is on.
  final List<AudioCue> played = [];

  bool _record = false;
  String? _loop;

  /// Starts writing every cue to [played]. Tests use this instead of audio.
  void startRecording() => _record = true;

  Future<void> play(AudioCue cue) async {
    if (_record) played.add(cue);
    await _sink.play(assetFor(cue));
  }

  /// Starts the ambient loop of [area], or keeps the current one if it is the
  /// area the party is already in.
  Future<void> startAmbient(String area) async {
    final audio = AudioArea.values.firstWhere(
      (candidate) => candidate.name == area,
      orElse: () => AudioArea.castle,
    );
    final asset = 'assets/audio/${audio.asset}.wav';
    if (_loop == asset) return;
    _loop = asset;
    await _sink.startLoop(asset, volume: 0.5);
  }

  Future<void> stopAmbient() async {
    if (_loop == null) return;
    _loop = null;
    await _sink.stopLoop();
  }

  /// The ambient loop currently running, if any.
  String? get ambient => _loop;
}
