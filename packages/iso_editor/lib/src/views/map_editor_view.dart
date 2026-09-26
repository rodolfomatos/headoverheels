import 'package:flutter/material.dart';
import 'package:iso_core/iso_core.dart';
import 'package:vector_math/vector_math.dart' show Vector2, Vector3;

import '../document/editor_document.dart';

class MapEditorView extends StatefulWidget {
  const MapEditorView({
    required this.document,
    required this.onCellSelected,
    this.selectedTileId = 1,
    super.key,
  });

  final EditorDocument document;
  final int selectedTileId;
  final ValueChanged<Vector3> onCellSelected;

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
            final scene = _transformation.toScene(details.localPosition);
            final cell = screenToGrid(Vector2(scene.dx, scene.dy));
            widget.onCellSelected(Vector3(cell.x, cell.y, 0));
          },
          child: CustomPaint(
            size: Size(
              widget.document.width * kTileWidth,
              widget.document.height * kTileHeight,
            ),
            painter: _MapPainter(
              document: widget.document,
              selectedTileId: widget.selectedTileId,
            ),
          ),
        ),
      ),
    );
  }
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
