// The settings the main menu's Settings button opens.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:headoverheels/features/audio/audio_settings.dart';
import 'package:headoverheels/features/audio/audio_system.dart';

/// Music and effects, which is what the game has settings for.
///
/// The menu has had a Settings button that pushed a route nothing answered. It
/// answers now, and it answers with the settings the game actually reads, so the
/// switches change what a player hears rather than what a widget holds.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(audioSettingsNotifierProvider);
    final notifier = ref.read(audioSettingsNotifierProvider.notifier);
    final audio = ref.read(audioSystemProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text('Music'),
            value: settings.musicEnabled,
            onChanged: (value) {
              notifier.setMusicEnabled(value);
              audio.setMusicEnabled(value);
            },
          ),
          Slider(
            value: settings.musicVolume,
            label: 'Music volume',
            onChanged: settings.musicEnabled
                ? (value) {
                    notifier.setMusicVolume(value);
                    audio.setMusicVolume(value);
                  }
                : null,
          ),
          SwitchListTile(
            title: const Text('Sound effects'),
            value: settings.sfxEnabled,
            onChanged: (value) {
              notifier.setSfxEnabled(value);
              audio.setSfxEnabled(value);
            },
          ),
          Slider(
            value: settings.sfxVolume,
            label: 'Effects volume',
            onChanged: settings.sfxEnabled
                ? (value) {
                    notifier.setSfxVolume(value);
                    audio.setSfxVolume(value);
                  }
                : null,
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Back'),
          ),
        ],
      ),
    );
  }
}
