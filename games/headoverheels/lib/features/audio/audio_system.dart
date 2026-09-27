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
class AudioSystem {
  /// Every sound the game can make, and nothing else.
  static List<String> get allAssets =>
      HohCue.values.map(assetFor).map(relativeAsset).toList(growable: false);

  /// FlameAudio resolves assets from the bundle root, so a path loses its
  /// `assets/` prefix.
  static String relativeAsset(String asset) =>
      asset.startsWith('assets/') ? asset.substring('assets/'.length) : asset;

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
        await FlameAudio.audioCache.load(asset);
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
      FlameAudio.bgm.play(_currentMusic!, volume: (volume ?? _musicVolume));
    } catch (e) {
      debugPrint('Failed to play music $_currentMusic: $e');
    }
  }

  /// Stop background music.
  void stopMusic() {
    FlameAudio.bgm.stop();
    _currentMusic = null;
    _currentMusicCue = null;
  }

  /// Pause background music.
  void pauseMusic() {
    FlameAudio.bgm.pause();
  }

  /// Resume background music.
  void resumeMusic() {
    FlameAudio.bgm.resume();
  }

  /// Play a sound effect.
  void playSfx(HohCue cue, {double? volume}) {
    if (!_sfxEnabled) return;
    final asset = relativeAsset(assetFor(cue));
    try {
      FlameAudio.play(asset, volume: (volume ?? _sfxVolume));
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
