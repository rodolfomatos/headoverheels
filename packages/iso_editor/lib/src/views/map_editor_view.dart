import 'package:flutter/material.dart';
import 'package:iso_core/iso_core.dart';
import 'package:vector_math/vector_math.dart' show Vector2, Vector3;

import '../document/editor_document.dart';
import '../tmx/tsx_catalog.dart';

class MapEditorView extends StatefulWidget {
  const MapEditorView({
    required this.document,
    required this.onCellSelected,
    this.selectedTileId = 1,
    this.tileset,
    this.resolveImagePath,
    super.key,
  });

  final EditorDocument document;
  final int selectedTileId;
  final ValueChanged<Vector3> onCellSelected;
  final TsxTilesetDefinition? tileset;
  final String Function(String imageSource)? resolveImagePath;

  @override
  State<MapEditorView> createState() => _MapEditorViewState();
}

class _MapEditorViewState extends State<MapEditorView> {
  final TransformationController _transformation = TransformationController();

  @override
  void dispose() {
    _transformation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF181A1F),
      child: InteractiveViewer(
        transformationController: _transformation,
        minScale: 0.5,
        maxScale: 4,
        boundaryMargin: const EdgeInsets.all(512),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (details) {
            // The position is already the grid's, not the viewer's: this
            // detector is the child the viewer transforms, so its local
            // coordinates are scene coordinates. Running them through
            // `toScene` applied the pan a second time, which is why a tap
            // landed on the wrong cell as soon as the grid had been dragged and
            // the cell was right until then.
            final scene = details.localPosition;
            final originX = (widget.document.height - 1) * kTileWidth / 2;
            final cell = screenToGrid(Vector2(scene.dx - originX, scene.dy));
            widget.onCellSelected(Vector3(cell.x, cell.y, 0));
          },
          child: Stack(
            children: [
              CustomPaint(
                size: Size(
                  (widget.document.width + widget.document.height) *
                      kTileWidth /
                      2,
                  (widget.document.width + widget.document.height) *
                      kTileHeight /
                      2,
                ),
                painter: _MapPainter(
                  document: widget.document,
                  selectedTileId: widget.selectedTileId,
                ),
              ),
              if (widget.tileset != null && widget.resolveImagePath != null)
                Positioned.fill(
                  child: _TileImageLayer(
                    document: widget.document,
                    tileset: widget.tileset!,
                    imagePath: widget.resolveImagePath!(
                      widget.tileset!.imageSource,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TileImageLayer extends StatelessWidget {
  const _TileImageLayer({
    required this.document,
    required this.tileset,
    required this.imagePath,
  });

  final EditorDocument document;
  final TsxTilesetDefinition tileset;
  final String imagePath;

  @override
  Widget build(BuildContext context) {
    final originX = (document.height - 1) * kTileWidth / 2;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        for (final layer in document.layers.where((layer) => layer.visible))
          for (final entry in layer.cells.entries)
            if (entry.value > 0 && entry.value < tileset.tileCount)
              _positioned(entry.key.x, entry.key.y, originX, entry.value),
      ],
    );
  }

  Widget _positioned(int x, int y, double originX, int tileId) {
    final center = gridToScreen(Vector3(x.toDouble(), y.toDouble(), 0));
    final alignment = tileset.alignmentForTile(tileId);
    return Positioned(
      left: originX + center.x - kTileWidth / 2,
      top: center.y - kTileHeight / 2,
      width: kTileWidth,
      height: kTileHeight,
      child: ClipPath(
        clipper: const _TileDiamondClipper(),
        child: Image.asset(
          imagePath,
          fit: BoxFit.none,
          alignment: Alignment(alignment.x, alignment.y),
          filterQuality: FilterQuality.low,
          errorBuilder: (context, error, stack) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}

class _TileDiamondClipper extends CustomClipper<Path> {
  const _TileDiamondClipper();

  @override
  Path getClip(Size size) => Path()
    ..moveTo(size.width / 2, 0)
    ..lineTo(size.width, size.height / 2)
    ..lineTo(size.width / 2, size.height)
    ..lineTo(0, size.height / 2)
    ..close();

  @override
  bool shouldReclip(_TileDiamondClipper oldClipper) => false;
}

class _MapPainter extends CustomPainter {
  const _MapPainter({required this.document, required this.selectedTileId});

  final EditorDocument document;
  final int selectedTileId;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = const Color(0xFF343A46)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final tilePaint = Paint();
    final objectPaint = Paint()..color = const Color(0xFFFFC857);
    final objectBorder = Paint()
      ..color = const Color(0xFF8C6D1F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.save();
    canvas.translate((document.height - 1) * kTileWidth / 2, 0);

    for (var y = 0; y < document.height; y++) {
      for (var x = 0; x < document.width; x++) {
        final center = gridToScreen(Vector3(x.toDouble(), y.toDouble(), 0));
        final path = Path()
          ..moveTo(center.x, center.y - kTileHeight / 2)
          ..lineTo(center.x + kTileWidth / 2, center.y)
          ..lineTo(center.x, center.y + kTileHeight / 2)
          ..lineTo(center.x - kTileWidth / 2, center.y)
          ..close();
        canvas.drawPath(path, grid);
      }
    }

    for (final layer in document.layers.where((layer) => layer.visible)) {
      for (final entry in layer.cells.entries) {
        final center = gridToScreen(
          Vector3(entry.key.x.toDouble(), entry.key.y.toDouble(), 0),
        );
        tilePaint.color = _tileColor(entry.value);
        final path = Path()
          ..moveTo(center.x, center.y - kTileHeight / 2)
          ..lineTo(center.x + kTileWidth / 2, center.y)
          ..lineTo(center.x, center.y + kTileHeight / 2)
          ..lineTo(center.x - kTileWidth / 2, center.y)
          ..close();
        canvas.drawPath(path, tilePaint);
      }
    }

    for (final object in document.objects) {
      final center = gridToScreen(object.position);
      canvas.drawCircle(Offset(center.x, center.y), 9, objectPaint);
      canvas.drawCircle(Offset(center.x, center.y), 9, objectBorder);
    }
    canvas.restore();
  }

  Color _tileColor(int tileId) {
    final hue = (tileId * 47.0) % 360.0;
    if (tileId == selectedTileId) {
      return HSLColor.fromAHSL(1, hue, 0.65, 0.55).toColor();
    }
    return HSLColor.fromAHSL(1, hue, 0.35, 0.32).toColor();
  }

  @override
  bool shouldRepaint(covariant _MapPainter oldDelegate) {
    return oldDelegate.document != document ||
        oldDelegate.selectedTileId != selectedTileId;
  }
}
