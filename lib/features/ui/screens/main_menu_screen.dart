// Main menu screen for Head over Heels.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:headoverheels/features/ui/theme/app_theme.dart';
import 'package:headoverheels/features/ui/widgets/virtual_joystick.dart';
import 'package:headoverheels/features/ui/widgets/action_buttons.dart';

class MainMenuScreen extends ConsumerWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.darkBackground,
              Color(0xFF1A1A1A),
              AppColors.darkBackground,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo / Title
                  _buildLogo(),
                  const SizedBox(height: AppSpacing.xxxl),

                  // Menu Buttons
                  _buildMenuButton(
                    context,
                    'New Game',
                    Icons.play_arrow_rounded,
                    onPressed: () => _navigateToGame(context),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _buildMenuButton(
                    context,
                    'Continue',
                    Icons.save_rounded,
                    onPressed: () => _continueGame(context),
                    isSecondary: true,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _buildMenuButton(
                    context,
                    'Settings',
                    Icons.settings_rounded,
                    onPressed: () => _openSettings(context),
                    isSecondary: true,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _buildMenuButton(
                    context,
                    'Credits',
                    Icons.info_outline_rounded,
                    onPressed: () => _showCredits(context),
                    isSecondary: true,
                  ),

                  const SizedBox(height: AppSpacing.xxxl),

                  // Version info
                  Text(
                    'Head over Heels v1.0.0',
                    style: AppTypography.small.copyWith(
                      color: AppColors.darkMuted,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'A Flutter port of the 1987 classic',
                    style: AppTypography.small.copyWith(
                      color: AppColors.darkMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        // Icon representation
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            gradient: const LinearGradient(
              colors: [AppColors.headColor, AppColors.heelsColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.headColor.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.videogame_asset_rounded,
              size: 60,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Head over Heels',
          style: AppTypography.display.copyWith(
            color: AppColors.darkText,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Remastered for Android',
          style: AppTypography.body.copyWith(
            color: AppColors.darkMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuButton(
    BuildContext context,
    String label,
    IconData icon, {
    required VoidCallback onPressed,
    bool isSecondary = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: isSecondary
          ? OutlinedButton.icon(
              icon: Icon(icon, size: 24),
              label: Text(label),
              onPressed: onPressed,
            )
          : ElevatedButton.icon(
              icon: Icon(icon, size: 24),
              label: Text(label),
              onPressed: onPressed,
            ),
    );
  }

  void _navigateToGame(BuildContext context) {
    // Navigate to game screen
    Navigator.of(context).pushReplacementNamed('/game');
  }

  void _continueGame(BuildContext context) {
    // Continue saved game
    Navigator.of(context).pushReplacementNamed('/game', arguments: {'continue': true});
  }

  void _openSettings(BuildContext context) {
    Navigator.of(context).pushNamed('/settings');
  }

  void _showCredits(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Credits', style: AppTypography.h2),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _creditsSection('Original Game (1987)', [
                'Jon Ritman - Design & Programming',
                'Bernie Drummond - Graphics & Design',
                'Guy Stevens - Music & Sound',
                'Published by Ocean Software',
              ]),
              _creditsSection('Flutter Port', [
                'Flutter Team - Framework',
                'Flame Engine - Game Engine',
                'Riverpod - State Management',
                'Community Contributors',
              ]),
              _creditsSection('Special Thanks', [
                'World of Spectrum - Game Preservation',
                'WebMSX - Online Playable Version',
                'Original Players & Fans',
              ]),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _creditsSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.h2),
        const SizedBox(height: AppSpacing.sm),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(left: AppSpacing.md, bottom: AppSpacing.xs),
          child: Text('• $item', style: AppTypography.body),
        )),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }
}