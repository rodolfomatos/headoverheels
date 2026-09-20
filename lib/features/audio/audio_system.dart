// Audio system for Head over Heels.

import 'package:flame_audio/flame_audio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Audio system managing all game sounds and music.
class AudioSystem {
  static const String _musicPrefix = 'music/';
  static const String _sfxPrefix = 'sfx/';

  // Music tracks
  static const String _musicMainMenu = '${_musicPrefix}main_menu.ogg';
  static const String _musicCastle = '${_musicPrefix}castle.ogg';
  static const String _musicEgyptus = '${_musicPrefix}egyptus.ogg';
  static const String _musicPenitentiary = '${_musicPrefix}penitentiary.ogg';
  static const String _musicSafari = '${_musicPrefix}safari.ogg';
  static const String _musicBookworld = '${_musicPrefix}bookworld.ogg';
  static const String _musicBoss = '${_musicPrefix}boss.ogg';
  static const String _musicGameOver = '${_musicPrefix}game_over.ogg';

  // Sound effects
  static const String _sfxJump = '${_sfxPrefix}jump.ogg';
  static const String _sfxLand = '${_sfxPrefix}land.ogg';
  static const String _sfxPickup = '${_sfxPrefix}pickup.ogg';
  static const String _sfxSwitch = '${_sfxPrefix}switch.ogg';
  static const String _sfxDoor = '${_sfxPrefix}door.ogg';
  static const String _sfxTeleport = '${_sfxPrefix}teleport.ogg';
  static const String _sfxSpring = '${_sfxPrefix}spring.ogg';
  static const String _sfxConveyor = '${_sfxPrefix}conveyor.ogg';
  static const String _sfxFire = '${_sfxPrefix}fire.ogg';
  static const String _sfxDoughnutHit = '${_sfxPrefix}doughnut_hit.ogg';
  static const String _sfxEnemyHit = '${_sfxPrefix}enemy_hit.ogg';
  static const String _sfxPlayerHit = '${_sfxPrefix}player_hit.ogg';
  static const String _sfxPlayerDeath = '${_sfxPrefix}player_death.ogg';
  static const String _sfxFishEat = '${_sfxPrefix}fish_eat.ogg';
  static const String _sfxFishPoison = '${_sfxPrefix}fish_poison.ogg';
  static const String _sfxCrown = '${_sfxPrefix}crown.ogg';
  static const String _sfxBag = '${_sfxPrefix}bag.ogg';
  static const String _sfxHushPuppy = '${_sfxPrefix}hush_puppy.ogg';
  static const String _sfxSwop = '${_sfxPrefix}swop.ogg';
  static const String _sfxPause = '${_sfxPrefix}pause.ogg';
  static const String _sfxMenuSelect = '${_sfxPrefix}menu_select.ogg';
  static const String _sfxMenuNavigate = '${_sfxPrefix}menu_navigate.ogg';

  bool _musicEnabled = true;
  bool _sfxEnabled = true;
  double _musicVolume = 0.7;
  double _sfxVolume = 0.8;
  String? _currentMusic;

  /// Initialize audio system - preload all assets.
  Future<void> initialize() async {
    await FlameAudio.audioCache.loadAll([
      _musicMainMenu, _musicCastle, _musicEgyptus, _musicPenitentiary,
      _musicSafari, _musicBookworld, _musicBoss, _musicGameOver,
      _sfxJump, _sfxLand, _sfxPickup, _sfxSwitch, _sfxDoor, _sfxTeleport,
      _sfxSpring, _sfxConveyor, _sfxFire, _sfxDoughnutHit, _sfxEnemyHit,
      _sfxPlayerHit, _sfxPlayerDeath, _sfxFishEat, _sfxFishPoison,
      _sfxCrown, _sfxBag, _sfxHushPuppy, _sfxSwop, _sfxPause,
      _sfxMenuSelect, _sfxMenuNavigate,
    ]);
  }

  /// Play background music for a specific planet/theme.
  void playMusic(String planetId, {bool loop = true, double? volume}) {
    if (!_musicEnabled) return;

    String musicFile;
    switch (planetId) {
      case 'castle':
        musicFile = _musicCastle;
        break;
      case 'egyptus':
        musicFile = _musicEgyptus;
        break;
      case 'penitentiary':
        musicFile = _musicPenitentiary;
        break;
      case 'safari':
        musicFile = _musicSafari;
        break;
      case 'bookworld':
        musicFile = _musicBookworld;
        break;
      case 'boss':
        musicFile = _musicBoss;
        break;
      default:
        musicFile = _musicMainMenu;
    }

    if (_currentMusic == musicFile) return;
    _currentMusic = musicFile;

    FlameAudio.bgm.play(musicFile, volume: (volume ?? _musicVolume));
  }

  /// Stop background music.
  void stopMusic() {
    FlameAudio.bgm.stop();
    _currentMusic = null;
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
  void playSfx(String sfxFile, {double? volume}) {
    if (!_sfxEnabled) return;
    FlameAudio.play(sfxFile, volume: (volume ?? _sfxVolume));
  }

  // Convenience methods for common sound effects

  void playJump() => playSfx(_sfxJump);
  void playLand() => playSfx(_sfxLand, volume: _sfxVolume * 0.7);
  void playPickup() => playSfx(_sfxPickup);
  void playSwitch() => playSfx(_sfxSwitch);
  void playDoor() => playSfx(_sfxDoor);
  void playTeleport() => playSfx(_sfxTeleport);
  void playSpring() => playSfx(_sfxSpring);
  void playConveyor() => playSfx(_sfxConveyor, volume: _sfxVolume * 0.3);
  void playFire() => playSfx(_sfxFire);
  void playDoughnutHit() => playSfx(_sfxDoughnutHit);
  void playEnemyHit() => playSfx(_sfxEnemyHit);
  void playPlayerHit() => playSfx(_sfxPlayerHit);
  void playPlayerDeath() => playSfx(_sfxPlayerDeath);
  void playFishEat() => playSfx(_sfxFishEat);
  void playFishPoison() => playSfx(_sfxFishPoison);
  void playCrown() => playSfx(_sfxCrown);
  void playBag() => playSfx(_sfxBag);
  void playHushPuppy() => playSfx(_sfxHushPuppy);
  void playSwop() => playSfx(_sfxSwop);
  void playPause() => playSfx(_sfxPause);
  void playMenuSelect() => playSfx(_sfxMenuSelect);
  void playMenuNavigate() => playSfx(_sfxMenuNavigate, volume: _sfxVolume * 0.5);

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
    // Note: FlameAudio Bgm doesn't have setVolume, volume is set on play
    // Replay current music with new volume
    if (_currentMusic != null) {
      playMusic(_currentMusic!.replaceFirst(_musicPrefix, '').replaceFirst('.ogg', ''));
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