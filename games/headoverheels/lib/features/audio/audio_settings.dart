// Audio settings for Head over Heels - persistent user preferences.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Audio settings stored in SharedPreferences.
class AudioSettings {
  final bool musicEnabled;
  final bool sfxEnabled;
  final double musicVolume;
  final double sfxVolume;

  const AudioSettings({
    this.musicEnabled = true,
    this.sfxEnabled = true,
    this.musicVolume = 0.7,
    this.sfxVolume = 0.8,
  });

  AudioSettings copyWith({
    bool? musicEnabled,
    bool? sfxEnabled,
    double? musicVolume,
    double? sfxVolume,
  }) {
    return AudioSettings(
      musicEnabled: musicEnabled ?? this.musicEnabled,
      sfxEnabled: sfxEnabled ?? this.sfxEnabled,
      musicVolume: musicVolume ?? this.musicVolume,
      sfxVolume: sfxVolume ?? this.sfxVolume,
    );
  }

  static const _keyMusicEnabled = 'audio_music_enabled';
  static const _keySfxEnabled = 'audio_sfx_enabled';
  static const _keyMusicVolume = 'audio_music_volume';
  static const _keySfxVolume = 'audio_sfx_volume';

  /// Load settings from SharedPreferences.
  static Future<AudioSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AudioSettings(
      musicEnabled: prefs.getBool(_keyMusicEnabled) ?? true,
      sfxEnabled: prefs.getBool(_keySfxEnabled) ?? true,
      musicVolume: prefs.getDouble(_keyMusicVolume) ?? 0.7,
      sfxVolume: prefs.getDouble(_keySfxVolume) ?? 0.8,
    );
  }

  /// Save settings to SharedPreferences.
  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyMusicEnabled, musicEnabled);
    await prefs.setBool(_keySfxEnabled, sfxEnabled);
    await prefs.setDouble(_keyMusicVolume, musicVolume);
    await prefs.setDouble(_keySfxVolume, sfxVolume);
  }
}

/// Provider for AudioSettings loaded from preferences.
final audioSettingsProvider = FutureProvider<AudioSettings>((ref) async {
  return AudioSettings.load();
});

/// Notifier for managing audio settings with persistence.
class AudioSettingsNotifier extends StateNotifier<AudioSettings> {
  AudioSettingsNotifier() : super(const AudioSettings()) {
    _load();
  }

  Future<void> _load() async {
    state = await AudioSettings.load();
  }

  Future<void> setMusicEnabled(bool enabled) async {
    state = state.copyWith(musicEnabled: enabled);
    await state.save();
  }

  Future<void> setSfxEnabled(bool enabled) async {
    state = state.copyWith(sfxEnabled: enabled);
    await state.save();
  }

  Future<void> setMusicVolume(double volume) async {
    state = state.copyWith(musicVolume: volume.clamp(0.0, 1.0));
    await state.save();
  }

  Future<void> setSfxVolume(double volume) async {
    state = state.copyWith(sfxVolume: volume.clamp(0.0, 1.0));
    await state.save();
  }
}

/// Provider for AudioSettingsNotifier.
final audioSettingsNotifierProvider =
    StateNotifierProvider<AudioSettingsNotifier, AudioSettings>((ref) {
      return AudioSettingsNotifier();
    });
