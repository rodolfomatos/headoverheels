// Game screen for Head over Heels.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:headoverheels/features/ui/theme/app_theme.dart';
import 'package:headoverheels/features/ui/widgets/virtual_joystick.dart';
import 'package:headoverheels/features/ui/widgets/action_buttons.dart';
import 'package:headoverheels/features/ui/widgets/hud.dart';
import 'package:headoverheels/features/gameplay/state/input_system.dart';
import 'package:headoverheels/features/audio/audio_system.dart';
import 'package:headoverheels/features/audio/audio_settings.dart';

class GameScreen extends ConsumerStatefulWidget {
  static const routeName = '/game';

  const GameScreen({super.key, this.continueGame = false});

  final bool continueGame;

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  bool _showPauseMenu = false;

  @override
  void initState() {
    super.initState();
    // Initialize audio system and play music
    _initAudio();
    // Initialize game state
    if (widget.continueGame) {
      // Load saved game
    } else {
      // Start new game
    }
  }

  Future<void> _initAudio() async {
    final audioSystem = ref.read(audioSystemProvider);
    final settings = await ref.read(audioSettingsProvider.future);

    await audioSystem.initialize();
    audioSystem.setMusicEnabled(settings.musicEnabled);
    audioSystem.setSfxEnabled(settings.sfxEnabled);
    audioSystem.setMusicVolume(settings.musicVolume);
    audioSystem.setSfxVolume(settings.sfxVolume);

    // Play main menu music initially
    audioSystem.playMusic('main_menu');
  }

  @override
  void dispose() {
    // Pause music when leaving game screen
    ref.read(audioSystemProvider).pauseMusic();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pauseOverlay = _showPauseMenu
        ? _buildPauseOverlay()
        : const SizedBox.shrink();

    final inputSystem = ref.watch(inputSystemProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          setState(() => _showPauseMenu = true);
          ref.read(audioSystemProvider).playPause();
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            // Game canvas (Flame game widget would go here)
            _buildGameCanvas(),

            // HUD
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(child: HUD()),
            ),

            // Touch controls
            Positioned(
              bottom: AppSpacing.lg,
              left: AppSpacing.md,
              child: VirtualJoystick(
                radius: 70,
                onDirectionChanged: (direction) {
                  inputSystem.onJoystickDirection(direction);
                },
                onTap: () {
                  // Handle tap (could be jump)
                  inputSystem.onJump();
                },
              ),
            ),

            Positioned(
              bottom: AppSpacing.lg,
              right: AppSpacing.md,
              child: ActionButtons(
                onJump: () => inputSystem.onJump(),
                onCarry: () => inputSystem.onCarry(),
                onFire: () => inputSystem.onFire(),
                onSwop: () => inputSystem.onSwop(),
                canJump: true,
                canCarry: true,
                canFire: true,
                canSwop: true,
                doughnutCount: 3,
              ),
            ),

            // Pause button
            Positioned(
              top: AppSpacing.md,
              right: AppSpacing.md,
              child: PauseButton(
                onPressed: () => setState(() => _showPauseMenu = true),
              ),
            ),

            // Pause menu overlay
            pauseOverlay,
          ],
        ),
      ),
    );
  }

  Widget _buildGameCanvas() {
    // Placeholder for Flame game widget
    return Container(
      color: AppColors.darkBackground,
      child: const Center(
        child: Text(
          'Game Canvas (Flame GameWidget goes here)',
          style: TextStyle(color: Colors.white54),
        ),
      ),
    );
  }

  Widget _buildPauseOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.7),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(AppSpacing.xl),
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: AppColors.darkSurface,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: AppColors.darkBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Paused', style: AppTypography.h1),
              const SizedBox(height: AppSpacing.xl),
              _buildPauseButton('Resume', Icons.play_arrow_rounded, () {
                setState(() => _showPauseMenu = false);
                ref.read(audioSystemProvider).resumeMusic();
              }),
              const SizedBox(height: AppSpacing.md),
              _buildPauseButton('Restart Room', Icons.refresh_rounded, () {
                setState(() => _showPauseMenu = false);
              }),
              const SizedBox(height: AppSpacing.md),
              _buildPauseButton('Settings', Icons.settings_rounded, () {
                setState(() => _showPauseMenu = false);
                Navigator.of(context).pushNamed('/settings');
              }),
              const SizedBox(height: AppSpacing.md),
              _buildPauseButton('Quit to Menu', Icons.exit_to_app_rounded, () {
                ref.read(audioSystemProvider).playMusic('main_menu');
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/main-menu', (route) => false);
              }, isDestructive: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPauseButton(
    String label,
    IconData icon,
    VoidCallback onPressed, {
    bool isDestructive = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: isDestructive
          ? OutlinedButton.icon(
              icon: Icon(icon),
              label: Text(label),
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.darkDestructive,
                side: BorderSide(color: AppColors.darkDestructive, width: 2),
              ),
            )
          : ElevatedButton.icon(
              icon: Icon(icon),
              label: Text(label),
              onPressed: onPressed,
            ),
    );
  }
}
