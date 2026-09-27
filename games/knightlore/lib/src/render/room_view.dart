import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart' show Color, FilterQuality, Offset, Rect;
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
  String? _area;
  int _animationTick = 0;

  Offset origin() {
    final map = _map;
    if (map == null) return Offset.zero;
    final centre = gridToScreen(Vector3(map.width / 2, map.height / 2, 0));
    return Offset(
        centre.x + map.width * kTileWidth / 4, centre.y + kTileHeight / 2);
  }

  Offset screenOf(Vector3 grid) {
    final point = gridToScreen(grid);
    final base = origin();
    return Offset(base.dx + point.x, base.dy + point.y);
  }

  Future<void> setRoom(RoomMap map, ui.Image tilesetImage) async {
    _map = map;
    tileset = tilesetImage;
    if (_area != map.room.theme) {
      _area = map.room.theme;
    }
  }

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

  Vector2 get roomSize {
    final map = _map;
    if (map == null) return Vector2.zero();
    return Vector2(
      (map.width + map.height) * kTileWidth / 2,
      (map.width + map.height) * kTileHeight / 2 + 24,
    );
  }
}
