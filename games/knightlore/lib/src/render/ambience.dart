import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../world/knight_lore_world.dart';

/// The light of a place.
///
/// The original tinted every location: the mine is dark and warm, the tower is
/// cold and blue, the jungle is green. A flat colour wash over the room, keyed
/// by the room's theme, gets most of that feeling for one draw call.
class Ambience {
  const Ambience(this.colour, this.strength);

  /// The colour laid over the room.
  final Color colour;

  /// How much of it, 0 to 1. Kept low enough to read the tiles still.
  final double strength;

  /// The colour to paint before anything else, so the room edges the wash.
  Color get background => Color.lerp(Ambience.night, colour, strength)!;

  /// The darkest the wash is allowed to get at night.
  static const Color night = Color(0xFF0B0D12);

  /// The ambience of each area, as data.
  static const Map<String, Ambience> byArea = {
    KlAreas.castle: Ambience(Color(0xFF2A2E3A), 0.35),
    KlAreas.jungle: Ambience(Color(0xFF1E3A22), 0.4),
    KlAreas.cauldron: Ambience(Color(0xFF2E1E38), 0.45),
    KlAreas.mine: Ambience(Color(0xFF3A2C18), 0.4),
    KlAreas.tower: Ambience(Color(0xFF1E2440), 0.45),
  };

  /// The ambience of [area], falling back to a neutral room.
  static Ambience of(String area) =>
      byArea[area] ?? const Ambience(Color(0xFF20242C), 0.3);

  /// The background for [area] at [night] 0 (day) to 1 (night).
  Color backgroundFor(String area, {required bool isNight}) {
    final base = of(area);
    if (!isNight) return base.background;
    return Color.lerp(base.background, night, 0.55)!;
  }
}

/// The shadow a figure casts on the floor.
///
/// Drawn as a squashed ellipse under the feet: in this projection a circle on
/// the floor becomes an ellipse half as high.
class ShadowShape {
  const ShadowShape({required this.centre, required this.radius});

  /// Where the figure stands, in canvas pixels.
  final Offset centre;

  /// Half the width of the shadow in pixels.
  final double radius;

  /// The vertical squash of the floor.
  double get flatten => 0.5;

  Rect get bounds => Rect.fromCenter(
    center: centre.translate(0, radius * flatten * 0.35),
    width: radius * 2,
    height: radius * flatten * 2,
  );

  /// The paint for this shadow, fading at the edges.
  ///
  /// A hard ellipse looks like a sticker; the falloff is what makes it sit on
  /// the tile.
  ui.Paint get paint => ui.Paint()
    ..shader = ui.Gradient.radial(bounds.center, bounds.width / 2, [
      const Color(0x66000000),
      const Color(0x33000000),
      const Color(0x00000000),
    ], const [0.0, 0.55, 1.0]);
}
