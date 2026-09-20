// Action buttons widget for touch controls.

import 'package:flutter/material.dart';
import 'package:headoverheels/features/ui/theme/app_theme.dart';

/// Action buttons for right side of screen (Jump, Carry, Fire, Swop).
class ActionButtons extends StatelessWidget {
  final VoidCallback? onJump;
  final VoidCallback? onCarry;
  final VoidCallback? onFire;
  final VoidCallback? onSwop;
  final bool canJump;
  final bool canCarry;
  final bool canFire;
  final bool canSwop;
  final int doughnutCount;

  const ActionButtons({
    super.key,
    this.onJump,
    this.onCarry,
    this.onFire,
    this.onSwop,
    this.canJump = true,
    this.canCarry = true,
    this.canFire = true,
    this.canSwop = true,
    this.doughnutCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Top row: Jump (left) / Fire (right)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _ActionButton(
              icon: Icons.keyboard_arrow_up_rounded,
              label: 'Jump',
              onPressed: canJump ? onJump : null,
              enabled: canJump,
              color: AppColors.headColor,
            ),
            _ActionButton(
              icon: Icons.sports_handball_rounded,
              label: doughnutCount > 0 ? '$doughnutCount' : 'Fire',
              onPressed: canFire && doughnutCount > 0 ? onFire : null,
              enabled: canFire && doughnutCount > 0,
              color: AppColors.doughnutColor,
              showCount: doughnutCount > 0,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        // Bottom row: Carry (left) / Swop (right)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _ActionButton(
              icon: Icons.backpack_rounded,
              label: 'Carry',
              onPressed: canCarry ? onCarry : null,
              enabled: canCarry,
              color: AppColors.heelsColor,
            ),
            _ActionButton(
              icon: Icons.swap_horiz_rounded,
              label: 'Swop',
              onPressed: canSwop ? onSwop : null,
              enabled: canSwop,
              color: AppColors.combinedColor,
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool enabled;
  final Color color;
  final bool showCount;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.enabled,
    required this.color,
    this.showCount = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        splashColor: color.withOpacity(0.3),
        highlightColor: color.withOpacity(0.1),
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: enabled ? color : AppColors.darkMuted.withOpacity(0.3),
            border: Border.all(
              color: enabled ? color.withOpacity(0.5) : AppColors.darkBorder,
              width: 2,
            ),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: () {
              final children = <Widget>[
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      color: enabled ? AppColors.darkBackground : AppColors.darkMuted,
                      size: 28,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: AppTypography.small.copyWith(
                        color: enabled ? AppColors.darkBackground : AppColors.darkMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ];
              if (showCount) {
                children.add(
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: AppColors.darkDestructive,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Center(
                        child: Text(
                          // Count would be passed in real implementation
                          '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }
              return children;
            }(),
          ),
        ),
      ),
    );
  }
}

/// Pause button for top-right corner.
class PauseButton extends StatelessWidget {
  final VoidCallback onPressed;

  const PauseButton({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadius.full),
        splashColor: AppColors.darkAccent.withOpacity(0.3),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.darkSurface,
            border: Border.all(
              color: AppColors.darkBorder,
              width: 1.5,
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.pause_rounded,
              color: AppColors.darkText,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}