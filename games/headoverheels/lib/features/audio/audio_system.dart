// Audio system for Head over Heels.

import 'package:flutter/foundation.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/audio/hoh_cues.dart';

/// Audio system managing all game sounds and music.
///
/// The sounds themselves are not chosen here. Every path lives with the cue
/// that computes it, in `HohCue`, so a sound cannot be named in this class
/// without a file behind it: `test/audio_test.dart` checks the list below against
/// what `tool/generate_audio.dart` writes.
/// Where the sounds go.
///
/// A test has no audio device and no plugin, and audioplayers does not fail
/// politely in one: it throws out of an initialiser the game's load is waiting
/// on, so a test that wanted to draw a frame of the game could not finish
/// loading it. This is the seam Knight Lore already has, and the game that had
/// no way to prove anything on screen is the one that needed it.
abstract class AudioSink {
  /// Plays a sound once.
  Future<void> play(String asset, {double volume = 1});

  /// Starts a sound looping, replacing the loop already going.
  Future<void> startLoop(String asset, {double volume = 1});

  /// Stops the loop.
  Future<void> stopLoop();

  /// Preloads an asset, so the first play of it is not late.
  Future<void> preload(String asset);
}

/// The real sounds, through Flame's audio layer.
class FlameAudioSink implements AudioSink {
  AudioPlayer? _loop;

  @override
  Future<void> play(String asset, {double volume = 1}) async {
    await FlameAudio.play(asset, volume: volume);
  }

  @override
  Future<void> startLoop(String asset, {double volume = 1}) async {
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

  @override
  Future<void> preload(String asset) => FlameAudio.audioCache.load(asset);
}

/// A sink that hears nothing and says so, for a test and for a machine with no
/// audio.
class SilentAudioSink implements AudioSink {
  const SilentAudioSink();

  @override
  Future<void> play(String asset, {double volume = 1}) async {}

  @override
  Future<void> startLoop(String asset, {double volume = 1}) async {}

  @override
  Future<void> stopLoop() async {}

  @override
  Future<void> preload(String asset) async {}
}

class AudioSystem {
  /// Every sound the game can make, and nothing else.
  static List<String> get allAssets =>
      HohCue.values.map(assetFor).map(relativeAsset).toList(growable: false);

  /// The path the audio layer is given, from a cue's bundle path.
  ///
  /// FlameAudio prefixes `assets/audio/` itself, so handing it a path that
  /// already starts with `assets/` asks for a file that has never existed:
  /// `assets/audio/assets/audio/sfx/jump.wav`. The cue table names files from
  /// the bundle root because that is how a human reads them; this is where that
  /// becomes the path the loader wants.
  static String relativeAsset(String asset) =>
      asset.startsWith(audioRoot) ? asset.substring(audioRoot.length) : asset;

  /// Where the synthesiser writes, and where FlameAudio looks.
  static const String audioRoot = 'assets/audio/';

  /// Where the sounds go. A test passes a [SilentAudioSink].
  final AudioSink sink;

  AudioSystem({AudioSink? sink}) : sink = sink ?? FlameAudioSink();

  bool _musicEnabled = true;
  bool _sfxEnabled = true;
  double _musicVolume = 0.7;
  double _sfxVolume = 0.8;
  String? _currentMusic;
  HohCue? _currentMusicCue;

  /// Initialize audio system - preload all assets gracefully.
  Future<void> initialize() async {
    for (final asset in allAssets) {
      try {
        await sink.preload(asset);
      } catch (e) {
        // Log but don't crash - audio is optional
        debugPrint('Audio asset not found (non-fatal): $asset - $e');
      }
    }
  }

  /// Play background music for a specific planet/theme.
  void playMusic(String planetId, {bool loop = true, double? volume}) {
    if (!_musicEnabled) return;
    playLooping(musicForPlanet(planetId), volume: volume);
  }

  /// Starts a looping cue, unless it is already the one playing.
  void playLooping(HohCue cue, {double? volume}) {
    if (_currentMusicCue == cue) return;
    _currentMusicCue = cue;
    _currentMusic = relativeAsset(assetFor(cue));
    try {
      sink.startLoop(_currentMusic!, volume: volume ?? _musicVolume);
    } catch (e) {
      debugPrint('Failed to play music $_currentMusic: $e');
    }
  }

  /// Stop background music.
  void stopMusic() {
    sink.stopLoop();
    _currentMusic = null;
    _currentMusicCue = null;
  }

  /// Pause background music.
  void pauseMusic() {
    _pausedMusic = true;
  }

  /// Resume background music.
  void resumeMusic() {
    if (!_pausedMusic) return;
    _pausedMusic = false;
    final cue = _currentMusicCue;
    if (cue != null) playLooping(cue);
  }

  bool _pausedMusic = false;

  /// Play a sound effect.
  void playSfx(HohCue cue, {double? volume}) {
    if (!_sfxEnabled) return;
    final asset = relativeAsset(assetFor(cue));
    try {
      sink.play(asset, volume: volume ?? _sfxVolume);
    } catch (e) {
      debugPrint('Failed to play SFX $asset: $e');
    }
  }

  // Convenience methods for common sound effects

  void playJump() => playSfx(HohCue.jump);
  void playLand() => playSfx(HohCue.land, volume: _sfxVolume * 0.7);
  void playPickup() => playSfx(HohCue.pickup);
  void playSwitch() => playSfx(HohCue.toggleSwitch);
  void playDoor() => playSfx(HohCue.door);
  void playTeleport() => playSfx(HohCue.teleport);
  void playSpring() => playSfx(HohCue.spring);
  void playConveyor() => playSfx(HohCue.conveyor, volume: _sfxVolume * 0.3);
  void playFire() => playSfx(HohCue.fire);
  void playDoughnutHit() => playSfx(HohCue.doughnutHit);
  void playEnemyHit() => playSfx(HohCue.enemyHit);
  void playPlayerHit() => playSfx(HohCue.playerHit);
  void playPlayerDeath() => playSfx(HohCue.playerDeath);
  void playFishEat() => playSfx(HohCue.fishEat);
  void playFishPoison() => playSfx(HohCue.fishPoison);
  void playCrown() => playSfx(HohCue.crown);
  void playBag() => playSfx(HohCue.bag);
  void playHushPuppy() => playSfx(HohCue.hushPuppy);
  void playSwop() => playSfx(HohCue.swop);
  void playPause() => playSfx(HohCue.pause);
  void playMenuSelect() => playSfx(HohCue.menuSelect);
  void playMenuNavigate() =>
      playSfx(HohCue.menuNavigate, volume: _sfxVolume * 0.5);

  /// The cue whose loop is playing, if any.
  HohCue? get currentMusic => _currentMusicCue;

  /// Set music enabled state.
  void setMusicEnabled(bool enabled) {
    _musicEnabled = enabled;
    if (!enabled) {
      stopMusic();
    }
  }

  /// Set SFX enabled state.
  void setSfxEnabled(bool enabled) {
    _sfxEnabled = enabled;
  }

  /// Set music volume (0.0 to 1.0).
  void setMusicVolume(double volume) {
    _musicVolume = volume.clamp(0.0, 1.0);
    // Bgm has no setVolume, the volume is set on play, so the track has to
    // start again to hear the new one.
    final cue = _currentMusicCue;
    if (cue != null) {
      _currentMusicCue = null;
      playLooping(cue);
    }
  }

  /// Set SFX volume (0.0 to 1.0).
  void setSfxVolume(double volume) {
    _sfxVolume = volume.clamp(0.0, 1.0);
  }

  /// Get current music volume.
  double get musicVolume => _musicVolume;

  /// Get current SFX volume.
  double get sfxVolume => _sfxVolume;

  /// Check if music is enabled.
  bool get musicEnabled => _musicEnabled;

  /// Check if SFX is enabled.
  bool get sfxEnabled => _sfxEnabled;

  /// Dispose audio resources.
  void dispose() {
    FlameAudio.bgm.stop();
    FlameAudio.audioCache.clearAll();
  }
}

/// Provider for AudioSystem.
final audioSystemProvider = Provider<AudioSystem>((ref) {
  return AudioSystem();
});
