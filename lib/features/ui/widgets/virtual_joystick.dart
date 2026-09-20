// Virtual joystick widget for touch controls.

import 'package:flutter/material.dart';
import 'package:headoverheels/features/ui/theme/app_theme.dart';

/// Virtual joystick for 8-directional movement.
class VirtualJoystick extends StatefulWidget {
  final ValueChanged<Offset>? onDirectionChanged;
  final VoidCallback? onTap;
  final double radius;
  final Color? baseColor;
  final Color? knobColor;

  const VirtualJoystick({
    super.key,
    this.onDirectionChanged,
    this.onTap,
    this.radius = 80,
    this.baseColor,
    this.knobColor,
  });

  @override
  State<VirtualJoystick> createState() => _VirtualJoystickState();
}

class _VirtualJoystickState extends State<VirtualJoystick> {
  Offset _knobPosition = Offset.zero;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.baseColor ?? AppColors.darkSurface;
    final knobColor = widget.knobColor ?? AppColors.darkAccent;
    final borderColor = AppColors.darkBorder;

    return GestureDetector(
      onTapDown: (_) {
        if (widget.onTap != null) widget.onTap!();
      },
      onPanStart: (details) {
        setState(() {
          _isDragging = true;
          _updateKnobPosition(details.localPosition);
        });
      },
      onPanUpdate: (details) {
        _updateKnobPosition(details.localPosition);
      },
      onPanEnd: (_) {
        setState(() {
          _isDragging = false;
          _knobPosition = Offset.zero;
        });
        if (widget.onDirectionChanged != null) {
          widget.onDirectionChanged!(Offset.zero);
        }
      },
      child: SizedBox(
        width: widget.radius * 2,
        height: widget.radius * 2,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Base
            Container(
              width: widget.radius * 2,
              height: widget.radius * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.baseColor ?? AppColors.darkSurface,
                border: Border.all(
                  color: AppColors.darkBorder,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
            ),
            // Direction indicators
            _buildDirectionIndicators(),
            // Knob
            AnimatedPositioned(
              duration: const Duration(milliseconds: 50),
              curve: Curves.easeOut,
              left: widget.radius + _knobPosition.dx - widget.radius * 0.6,
              top: widget.radius + _knobPosition.dy - widget.radius * 0.6,
              child: Container(
                width: widget.radius * 1.2,
                height: widget.radius * 1.2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.knobColor ?? AppColors.darkAccent,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                    BoxShadow(
                      color: (widget.knobColor ?? AppColors.darkAccent).withOpacity(0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.arrow_upward_rounded,
                    color: AppColors.darkBackground,
                    size: widget.radius * 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDirectionIndicators() {
    final directions = <_DirectionIndicator>[
      _DirectionIndicator(Offset(0, -1), Icons.arrow_upward_rounded), // N
      _DirectionIndicator(Offset(1, -1), Icons.arrow_upward_rounded), // NE
      _DirectionIndicator(Offset(1, 0), Icons.arrow_forward_rounded), // E
      _DirectionIndicator(Offset(1, 1), Icons.arrow_downward_rounded), // SE
      _DirectionIndicator(Offset(0, 1), Icons.arrow_downward_rounded), // S
      _DirectionIndicator(Offset(-1, 1), Icons.arrow_downward_rounded), // SW
      _DirectionIndicator(Offset(-1, 0), Icons.arrow_back_rounded), // W
      _DirectionIndicator(Offset(-1, -1), Icons.arrow_upward_rounded), // NW
    ];

    return Stack(
      alignment: Alignment.center,
      children: directions.map((dir) {
        final angle = _getAngle(dir.offset);
        final distance = widget.radius * 0.75;
        return Positioned(
          left: widget.radius + angle.dx * distance - 12,
          top: widget.radius + angle.dy * distance - 12,
          child: Opacity(
            opacity: 0.3,
            child: Transform.rotate(
              angle: _getRotation(dir.offset),
              child: Icon(
                dir.icon,
                color: AppColors.darkMuted,
                size: 16,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Offset _getAngle(Offset dir) {
    final absSum = dir.dx.abs() + dir.dy.abs();
    if (absSum == 0) return Offset.zero;
    return Offset(dir.dx / absSum, dir.dy / absSum);
  }

  double _getRotation(Offset dir) {
    if (dir.dx == 0 && dir.dy == -1) return 0; // N
    if (dir.dx == 1 && dir.dy == -1) return 0.785; // NE
    if (dir.dx == 1 && dir.dy == 0) return 1.57; // E
    if (dir.dx == 1 && dir.dy == 1) return 2.355; // SE
    if (dir.dx == 0 && dir.dy == 1) return 3.14; // S
    if (dir.dx == -1 && dir.dy == 1) return -2.355; // SW
    if (dir.dx == -1 && dir.dy == 0) return -1.57; // W
    if (dir.dx == -1 && dir.dy == -1) return -0.785; // NW
    return 0;
  }

  void _updateKnobPosition(Offset localPosition) {
    final center = Offset(widget.radius, widget.radius);
    final delta = localPosition - center;
    final distance = delta.distance;

    setState(() {
      if (distance > widget.radius) {
        _knobPosition = delta * (widget.radius / distance);
      } else {
        _knobPosition = delta;
      }
    });

    // Normalize to -1..1 range
    final normalized = Offset(
      _knobPosition.dx / widget.radius,
      _knobPosition.dy / widget.radius,
    );

    if (widget.onDirectionChanged != null) {
      widget.onDirectionChanged!(normalized);
    }
  }
}

class _DirectionIndicator {
  final Offset offset;
  final IconData icon;

  const _DirectionIndicator(this.offset, this.icon);
}