// HUD widget for Head over Heels.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:headoverheels/features/ui/theme/app_theme.dart';
import 'package:headoverheels/entities/character_state.dart';
import 'package:headoverheels/features/gameplay/state/dual_character_notifier.dart';
import 'package:headoverheels/features/gameplay/state/crowns_notifier.dart';
import 'package:headoverheels/features/gameplay/entities/guardian_entity.dart';

/// Heads-up display showing lives, crowns, character, doughnuts, and bag item.
class HUD extends ConsumerWidget {
  const HUD({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dualState = ref.watch(dualCharacterProvider);
    final headState = dualState.head;
    final heelsState = dualState.heels;

    // Get controlled character from dual state
    final controlledCharacter = dualState.controlled == ControlledEntity.heels
        ? CharacterType.heels
        : dualState.controlled == ControlledEntity.combined
        ? CharacterType.combined
        : CharacterType.head;

    // Use Head's state for lives and doughnuts (Head has doughnuts)
    final lives = headState.lives;
    final doughnutCount = headState.doughnutCount;
    final carriedItem = heelsState.carriedItem; // Heels carries items

    // The crowns of the planet the party is standing on, which is the number the
    // guardian of that planet's throne room asks for. This was a `2/5` written
    // into the widget: a number that never moved, for a total the game does not
    // use.
    final crowns = ref.watch(crownsProvider);
    final crownsCollected = crowns.planet == null
        ? 0
        : crowns.byPlanet[crowns.planet] ?? 0;
    const int totalCrowns = GuardianEntity.requiredCrowns;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left side: Lives and Crowns
          Row(
            children: [
              _buildStatIcon(
                Icons.favorite_rounded,
                '$lives',
                AppColors.darkDestructive,
              ),
              const SizedBox(width: AppSpacing.md),
              _buildStatIcon(
                Icons.emoji_events_rounded,
                crowns.planet == null
                    ? '--/$totalCrowns'
                    : '$crownsCollected/$totalCrowns',
                AppColors.crownColor,
              ),
            ],
          ),

          // Center: Active character indicator
          _buildCharacterIndicator(controlledCharacter),

          // Right side: Doughnuts and Bag
          Row(
            children: [
              _buildStatIcon(
                Icons.local_fire_department_rounded,
                doughnutCount > 0 ? '$doughnutCount' : '0',
                AppColors.doughnutColor,
              ),
              const SizedBox(width: AppSpacing.md),
              _buildBagIcon(carriedItem),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatIcon(IconData icon, String count, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: AppSpacing.xs),
        Text(
          count,
          style: AppTypography.body.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildCharacterIndicator(CharacterType character) {
    final (color, icon, label) = switch (character) {
      CharacterType.head => (AppColors.headColor, Icons.face_rounded, 'HEAD'),
      CharacterType.heels => (
        AppColors.heelsColor,
        Icons.directions_run_rounded,
        'HEELS',
      ),
      CharacterType.combined => (
        AppColors.combinedColor,
        Icons.group_rounded,
        'HEAD+HEELS',
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: color, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: AppTypography.small.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBagIcon(CarriedItem item) {
    return item.when(
      none: () =>
          _buildBagIconContent(Icons.backpack_outlined, AppColors.darkMuted),
      key: (keyId) =>
          _buildBagIconContent(Icons.key_rounded, AppColors.crownColor),
      crown: () => _buildBagIconContent(
        Icons.emoji_events_rounded,
        AppColors.crownColor,
      ),
      other: (itemId) =>
          _buildBagIconContent(Icons.backpack_rounded, AppColors.heelsColor),
    );
  }

  Widget _buildBagIconContent(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }
}
