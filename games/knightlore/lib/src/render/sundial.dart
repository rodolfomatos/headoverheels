import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// The sundial from the original: a dial of forty days with a marker that
/// turns as the days pass, and a wolf on the night side.
///
/// The geometry is kept as pure functions so a test can check the marker really
/// does travel, instead of trusting a picture.
class SundialGeometry {
  const SundialGeometry({required this.days, required this.totalDays});

  /// The day the game is on, 1 to [totalDays].
  final int days;

  /// The length of the game in days.
  final int totalDays;

  /// Where the marker sits, in radians. Zero is noon and it turns clockwise.
  ///
  /// A full turn covers the whole game, so the last day lands on the start
  /// again: the dial is a circle, as in the original.
  double get markerAngle => -math.pi / 2 + 2 * math.pi * progress;

  /// How far the dial has turned, 0 to 1. The marker makes a full turn over
  /// the whole game.
  double get progress => (days - 1) / totalDays;

  /// Every tick of the dial, as a position on the unit circle.
  List<Offset> get ticks => List.generate(totalDays, (index) {
        final angle = -math.pi / 2 + 2 * math.pi * index / totalDays;
        return Offset(math.cos(angle), math.sin(angle));
      });

  /// The marker position on a circle of [radius].
  Offset markerAt(double radius) =>
      Offset(math.cos(markerAngle) * radius, math.sin(markerAngle) * radius);
}

/// Draws the sundial.
class SundialPainter extends CustomPainter {
  const SundialPainter({
    required this.geometry,
    required this.isNight,
    this.size = const Size(92, 92),
  });

  final SundialGeometry geometry;
  final bool isNight;
  final Size size;

  @override
  void paint(Canvas canvas, Size output) {
    final radius = math.min(output.width, output.height) / 2 - 6;
    final centre = Offset(output.width / 2, output.height / 2);
    final face = Paint()
      ..color = const Color(0xF01A1E28)
      ..style = PaintingStyle.fill;
    final rim = Paint()
      ..color = const Color(0xFF6E7686)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(centre, radius, face);

    // The night half, so the dial says which half of the day it is.
    final nightColour = Paint()
      ..color = isNight
          ? const Color(0x554A6BC8)
          : const Color(0x33202830)
      ..style = PaintingStyle.fill;
    canvas.drawArc(
      Rect.fromCircle(center: centre, radius: radius - 1),
      math.pi / 2,
      math.pi,
      true,
      nightColour,
    );

    canvas.drawCircle(centre, radius, rim);

    // Forty ticks: one per day.
    final tick = Paint()
      ..color = const Color(0xFF98A0B0)
      ..strokeWidth = 1.2;
    for (final point in geometry.ticks) {
      final inner = centre + point * (radius - 5);
      final outer = centre + point * (radius - 1);
      canvas.drawLine(inner, outer, tick);
    }

    // The marker: a wedge pointing at today's tick.
    final marker = centre + geometry.markerAt(radius - 8);
    final markerColour = Paint()..color = const Color(0xFFE0A24A);
    final path = Path()
      ..moveTo(marker.dx, marker.dy - 6)
      ..lineTo(marker.dx + 5, marker.dy + 4)
      ..lineTo(marker.dx - 5, marker.dy + 4)
      ..close();
    canvas.drawPath(path, markerColour);
    canvas.drawCircle(centre, 3, Paint()..color = const Color(0xFFE0A24A));
  }

  @override
  bool shouldRepaint(SundialPainter old) =>
      old.geometry.days != geometry.days ||
      old.geometry.totalDays != geometry.totalDays ||
      old.isNight != isNight ||
      old.size != size;
}

/// The sundial as a widget, small enough for the corner of the screen.
class Sundial extends StatelessWidget {
  const Sundial({
    super.key,
    required this.daysLeft,
    required this.totalDays,
    required this.isNight,
  });

  final int daysLeft;
  final int totalDays;

  /// Which half of the dial is lit.
  final bool isNight;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: const Size(92, 92),
    painter: SundialPainter(
      geometry: SundialGeometry(
        days: totalDays - daysLeft + 1,
        totalDays: totalDays,
      ),
      isNight: isNight,
    ),
  );
}
