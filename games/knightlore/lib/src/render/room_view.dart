import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart' show Color, FilterQuality, Offset, Rect, Size;
import 'package:iso_core/iso_core.dart';
import 'package:knightlore/knightlore.dart';

/// Draws a room: the floor and wall tiles from the area tileset, then the
/// furniture, then the party. Everything is drawn through the generic
/// `iso_core` projection so the game and the editor agree on where things are.
class RoomView extends Component {
  RoomView({
    required this.session,
    required this.tileset,
    required this.sprites,
  });

  final RoomSession session;
  ui.Image? tileset;
  final Map<String, ui.Image> sprites;

  RoomMap? _map;
  int _animationTick = 0;

  /// How far a wall block's face hangs below its tile, in pixels. The same
  /// number the tileset generator extrudes faces by.
  static const double blockHeight = 16;

  /// The pixel bounds of the room, taken from the tiles themselves so nothing
  /// is cropped: half a tile on each side, plus the wall blocks.
  Rect? get bounds {
    final map = _map;
    if (map == null) return null;
    var minX = double.infinity;
    var minY = double.infinity;
    var maxX = -double.infinity;
    var maxY = -double.infinity;
    for (var y = 0; y < map.height; y++) {
      for (var x = 0; x < map.width; x++) {
        final point = gridToScreen(Vector3(x.toDouble(), y.toDouble(), 0));
        minX = math.min(minX, point.x - kTileWidth / 2);
        maxX = math.max(maxX, point.x + kTileWidth / 2);
        minY = math.min(minY, point.y - kTileHeight / 2);
        maxY = math.max(maxY, point.y + kTileHeight / 2 + blockHeight);
      }
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  /// The offset that turns a projected point into a canvas point.
  Offset origin() {
    final rect = bounds;
    if (rect == null) return Offset.zero;
    return Offset(-rect.left, -rect.top);
  }

  Offset screenOf(Vector3 grid) {
    final point = gridToScreen(grid);
    final base = origin();
    return Offset(base.dx + point.x, base.dy + point.y);
  }

  void setRoom(RoomMap map, ui.Image tilesetImage) {
    _map = map;
    tileset = tilesetImage;
  }

  RoomMap? get map => _map;

  /// Draws the room centred in a canvas of [size], scaled up to fill it.
  void renderInto(ui.Canvas canvas, Size size) {
    final previous = canvas.getSaveCount();
    final scale = _scaleFor(size);
    final room = roomSize;
    canvas.translate(
      (size.width - room.width * scale) / 2,
      (size.height - room.height * scale) / 2,
    );
    canvas.scale(scale);
    render(canvas);
    canvas.restoreToCount(previous);
  }

  /// The room fills the canvas, but never more than [maximumScale] so a small
  /// window does not turn a floor tile into a wall of pixels.
  double _scaleFor(Size size) {
    final room = roomSize;
    if (room.width <= 0 || room.height <= 0) return 1;
    final byWidth = size.width / room.width;
    final byHeight = size.height / room.height;
    return math.min(math.min(byWidth, byHeight), maximumScale);
  }

  /// A small window should not turn one floor tile into a wall of pixels.
  static const double maximumScale = 2.4;

  void tick() => _animationTick++;

  @override
  void render(ui.Canvas canvas) {
    final map = _map;
    final sheet = tileset;
    if (map == null || sheet == null) return;

    final frame = (_animationTick ~/ 6) % 2;

    for (var y = 0; y < map.height; y++) {
      for (var x = 0; x < map.width; x++) {
        final tile = map.tileAt(x, y);
        if (tile <= 0) continue;
        final index = _tileIndexFor(tile);
        final source = Rect.fromLTWH(
          index * kTileWidth.toDouble(),
          0,
          kTileWidth.toDouble(),
          sheet.height.toDouble(),
        );
        final centre = screenOf(Vector3(x.toDouble(), y.toDouble(), 0));
        // Walls are drawn first so the floor never covers a block.
        final paint = ui.Paint()..filterQuality = FilterQuality.none;
        canvas.drawImageRect(
          sheet,
          source,
          Rect.fromCenter(
            center: centre,
            width: kTileWidth.toDouble(),
            height: sheet.height.toDouble(),
          ),
          paint,
        );
      }
    }

    for (final object in map.objects) {
      final sprite = sprites[object.type];
      final centre = screenOf(object.position);
      if (sprite == null) {
        canvas.drawCircle(
            centre, 6, ui.Paint()..color = const Color(0xFFB9A7D8));
        continue;
      }
      canvas.drawImageRect(
        sprite,
        Rect.fromLTWH(0, 0, sprite.width.toDouble(), sprite.height.toDouble()),
        Rect.fromCenter(
          center: centre.translate(0, -kTileHeight / 2),
          width: sprite.width.toDouble(),
          height: sprite.height.toDouble(),
        ),
        ui.Paint()..filterQuality = FilterQuality.none,
      );
    }

    _renderParty(canvas, frame);
  }

  int _tileIndexFor(int tile) {
    // 1 = floor, 2 = wall block, 3 = wall top
    return switch (tile) {
      2 => 1,
      3 => 2,
      _ => 0,
    };
  }

  void _renderParty(ui.Canvas canvas, int frame) {
    final party = session.party;
    if (party.isEmpty) return;
    final leader = session.leader;
    final anchor = screenOf(leader.position);
    final sprite = sprites[_characterKey(leader.form)];

    if (party.length == 1) {
      if (sprite == null) {
        canvas.drawCircle(
            anchor, 8, ui.Paint()..color = const Color(0xFF9AA3B2));
        return;
      }
      _drawFrame(canvas, sprite, anchor, frame, spread: 0);
      return;
    }

    // The four knights stand shoulder to shoulder, as one creature.
    for (var index = 0; index < party.length; index++) {
      final knight = sprites[_characterKey(party[index].form)];
      if (knight == null) continue;
      _drawFrame(
        canvas,
        knight,
        anchor.translate((index - 1.5) * 12, 0),
        frame,
        spread: 0,
      );
    }
  }

  String _characterKey(KnightClass knight) => 'character_${knight.id}';

  void _drawFrame(
    ui.Canvas canvas,
    ui.Image sheet,
    Offset centre,
    int frame, {
    required double spread,
  }) {
    final frameWidth = sheet.width / 4;
    final source = Rect.fromLTWH(
      (frame % 4) * frameWidth,
      0,
      frameWidth,
      sheet.height.toDouble(),
    );
    final width = frameWidth * 2.4;
    final height = sheet.height * 2.4;
    canvas.drawImageRect(
      sheet,
      source,
      Rect.fromCenter(
        center: centre.translate(0, -height / 2 + 6),
        width: width + spread,
        height: height,
      ),
      ui.Paint()..filterQuality = FilterQuality.none,
    );
  }

  Size get roomSize {
    final rect = bounds;
    if (rect == null) return Size.zero;
    return rect.size;
  }
}
