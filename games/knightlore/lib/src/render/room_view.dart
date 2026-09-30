import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart'
    show Color, FilterQuality, Offset, Rect, Size;
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
    this.isNight = false,
  });

  final RoomSession session;
  ui.Image? tileset;
  final Map<String, ui.Image> sprites;

  /// Whether the room is drawn at night, which changes the wash.
  bool isNight;

  RoomMap? _map;
  int _animationTick = 0;

  /// How far a wall block's face hangs below its tile, in pixels. The same
  /// number the tileset generator extrudes faces by.
  static const double blockHeight = 16;

  /// The pixel bounds of the room in projection space, taken from the tiles
  /// themselves so nothing is cropped: half a tile on each side, plus the wall
  /// blocks hanging below the near edge.
  ///
  /// This is *not* where the room is drawn: [origin] moves it to the top left.
  Rect? get projection {
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
    final rect = projection;
    if (rect == null) return Offset.zero;
    return Offset(-rect.left, -rect.top);
  }

  /// The room where it is actually drawn, which is [projection] moved by
  /// [origin].
  ///
  /// Anything drawn over the whole room, such as the ambience wash, has to use
  /// this one: mixing the two spaces shifts the overlay by the origin and paints
  /// it over the wrong half of the screen.
  Rect? get bounds {
    final rect = projection;
    if (rect == null) return null;
    final offset = origin();
    return rect.shift(offset);
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
  ///
  /// This is a thin wrapper over [render], and that is the whole point of it:
  /// the centring and the scale used to live here, and the running game never
  /// came through here, so the game drew a room in the corner of the window at
  /// its own size while every test drew a room that filled the canvas. The
  /// tests could not see the fault because they are the code they test.
  void renderInto(ui.Canvas canvas, Size size) {
    canvasSize = size;
    render(canvas);
  }

  /// The scale and offset of the last render, at one for a canvas the size is
  /// not known for.
  ///
  /// A test, or anything else that renders off screen, can turn a room position
  /// into a canvas position with [canvasOf] instead of guessing the transform.
  double get previewScale => _previewScale;
  Offset get previewOffset => _previewOffset;
  double _previewScale = 1;
  Offset _previewOffset = Offset.zero;

  /// Where [point], a position in room coordinates, lands on the canvas.
  Offset canvasOf(Offset point) => _previewOffset + point * _previewScale;

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

  /// Every item in the current room, in the order a person would find them.
  ///
  /// The renderer asks the session what is on the floor rather than being told,
  /// so an item cannot be added without becoming visible and an item cannot
  /// become visible without being on the floor.
  List<ItemPlacement> drawableItems() {
    final found = <ItemPlacement>[];
    for (final entry in session.itemsHere.entries) {
      found.add(ItemPlacement(itemId: entry.key, position: entry.value));
    }
    found.sort((a, b) {
      final byRow = a.position.y.compareTo(b.position.y);
      return byRow != 0 ? byRow : a.position.x.compareTo(b.position.x);
    });
    return found;
  }

  @override
  void render(ui.Canvas canvas) {
    final map = _map;
    final sheet = tileset;
    if (map == null || sheet == null) return;

    // Fit the room to the canvas, here, in the one method every path goes
    // through. A canvas the size is not known for is drawn one for one, which
    // is what happened to the running game for as long as the centring lived
    // in `renderInto`: the room sat in the top left corner at its own size, and
    // no test could see it because every test called `renderInto`.
    final area = canvasSize;
    final known = area.width > 0 && area.height > 0;
    final previous = canvas.getSaveCount();
    var scale = 1.0;
    var offset = Offset.zero;
    if (known) {
      scale = _scaleFor(area);
      final room = roomSize;
      offset = Offset(
        (area.width - room.width * scale) / 2,
        (area.height - room.height * scale) / 2,
      );
      canvas.translate(offset.dx, offset.dy);
      canvas.scale(scale);
    }
    _drawRoom(canvas, map, sheet);
    if (known) canvas.restoreToCount(previous);
    _previewScale = scale;
    _previewOffset = offset;
  }

  void _drawRoom(ui.Canvas canvas, RoomMap map, ui.Image sheet) {
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

    // Shadows go under everything that stands up, so a prop or a knight sits
    // on the floor instead of floating over it.
    if (drawShadows) {
      for (final object in map.objects) {
        final shape = ShadowShape(
          centre: screenOf(object.position),
          radius: 9,
        );
        canvas.drawOval(shape.bounds, shape.paint);
      }
      for (final item in drawableItems()) {
        final shape = ShadowShape(centre: screenOf(item.position), radius: 7);
        canvas.drawOval(shape.bounds, shape.paint);
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

    // Items lie on the floor, so they go under the party: a knight standing
    // next to a scroll is in front of it.
    _drawItems(canvas);

    _renderParty(canvas, frame);

    // The wash of the area, painted over the finished room. It is the last
    // thing drawn so it tints the tiles, the props and the party together.
    final room = bounds;
    final ambience = Ambience.of(map.room.theme);
    // The area decides how strong its own light is; the game scales that, so a
    // room that is fading in does not arrive fully lit.
    final alpha = (ambience.strength * ambienceStrength).clamp(0.0, 1.0);
    if (room != null && alpha > 0) {
      canvas.drawRect(
        room.inflate(2),
        ui.Paint()..color = ambience.colour.withValues(alpha: alpha),
      );
    }

    // The room change fade goes over the wash, over everything.
    if (fade > 0) {
      final area = canvasSize;
      if (area.width > 0 && area.height > 0) {
        canvas.drawRect(
          Offset.zero & area,
          ui.Paint()..color = const Color(0xFF000000).withValues(alpha: fade),
        );
      }
    }
  }

  /// The canvas the fade covers. The game sets it from its own size, and
  /// [renderInto] sets it for an off-screen render.
  Size canvasSize = Size.zero;

  /// Whether figures cast a shadow. Off gives a flat, wireframe look, which is
  /// also how a test can tell what the shadow itself is doing.
  bool drawShadows = true;

  /// How much of the area's colour to lay over the room, 0 to 1. The game
  /// lowers it while a room transition is fading.
  double ambienceStrength = 1;

  /// How black the screen is right now, 0 to 1. The game drives this on a room
  /// change.
  ///
  /// The fade lives here rather than in the widget tree because the value
  /// changes every frame: a widget would rebuild the whole overlay sixty times
  /// a second to change one number.
  double fade = 0;

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

    if (drawShadows) {
      final shape = ShadowShape(centre: anchor, radius: 10);
      canvas.drawOval(shape.bounds, shape.paint);
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

  /// How far below a standing prop an item on the floor is drawn, so a scroll
  /// lies on the tile instead of standing on it.
  static const double _itemDrop = 6;

  void _drawItems(ui.Canvas canvas) {
    for (final item in drawableItems()) {
      final sprite = sprites[item.spriteName];
      final centre =
          screenOf(item.position).translate(0, -kTileHeight / 2 + _itemDrop);
      if (sprite == null) {
        // The game can reach this before the art does, and an item the player
        // has to find cannot be allowed to be invisible: it gets a shape and a
        // place on the floor rather than nothing.
        canvas.drawCircle(
          centre,
          6,
          ui.Paint()..color = const Color(0xFFF2D16B),
        );
        continue;
      }
      canvas.drawImageRect(
        sprite,
        Rect.fromLTWH(0, 0, sprite.width.toDouble(), sprite.height.toDouble()),
        Rect.fromCenter(
          center: centre,
          width: sprite.width.toDouble(),
          height: sprite.height.toDouble(),
        ),
        ui.Paint()..filterQuality = FilterQuality.none,
      );
    }
  }

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
    final rect = projection;
    if (rect == null) return Size.zero;
    return rect.size;
  }
}

/// An item lying on the floor of a room, and the sheet it is drawn from.
class ItemPlacement {
  ItemPlacement({required this.itemId, required this.position});

  /// The item's id in the catalogue, such as `scroll_flip`.
  final String itemId;

  /// Where it lies, in room coordinates.
  final Vector3 position;

  /// The name the sprite is looked up under: the item's own name, except for a
  /// scroll, where all six are the same sheet.
  String get spriteName => KnightLoreManifest.spriteForItem(itemId);
}
