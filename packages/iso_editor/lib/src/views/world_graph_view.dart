import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:iso_core/iso_core.dart';

class WorldGraphLayout {
  const WorldGraphLayout({required this.positions, required this.size});

  final Map<String, Offset> positions;
  final Size size;

  Offset? positionOf(String roomId) => positions[roomId];
}

WorldGraphLayout layoutWorldGraph(WorldGraph graph) {
  final themes = <String>[];
  for (final room in graph.rooms.values) {
    if (!themes.contains(room.theme)) themes.add(room.theme);
  }
  themes.sort();

  const nodeWidth = 150.0;
  const nodeHeight = 46.0;
  const rowGap = 28.0;
  const groupGap = 60.0;
  const margin = 30.0;

  final positions = <String, Offset>{};
  var x = margin;
  var maxHeight = nodeHeight;
  var widest = 0.0;

  for (final theme in themes) {
    final rooms = graph.getRoomsByTheme(theme)
      ..sort((a, b) => a.id.compareTo(b.id));
    var y = margin;
    for (final room in rooms) {
      positions[room.id] = Offset(x, y);
      y += nodeHeight + rowGap;
    }
    maxHeight = math.max(maxHeight, y - rowGap);
    widest = math.max(widest, x + nodeWidth);
    x += nodeWidth + groupGap;
  }

  return WorldGraphLayout(
    positions: positions,
    size: Size(
      math.max(widest + margin, 320),
      math.max(maxHeight + margin, 220),
    ),
  );
}

class WorldGraphView extends StatefulWidget {
  const WorldGraphView({
    required this.graph,
    required this.validation,
    this.selectedRoomId,
    this.onRoomSelected,
    this.onExitSelected,
    super.key,
  });

  final WorldGraph graph;
  final WorldValidation validation;
  final String? selectedRoomId;
  final ValueChanged<String>? onRoomSelected;
  final void Function(String roomId, RoomExit exit)? onExitSelected;

  @override
  State<WorldGraphView> createState() => _WorldGraphViewState();
}

class _WorldGraphViewState extends State<WorldGraphView> {
  final TransformationController _transformation = TransformationController();
  String? _selectedExitKey;

  @override
  void dispose() {
    _transformation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final layout = layoutWorldGraph(widget.graph);
    return ColoredBox(
      color: const Color(0xFF14161A),
      child: InteractiveViewer(
        transformationController: _transformation,
        alignment: Alignment.topLeft,
        minScale: 0.3,
        maxScale: 3,
        boundaryMargin: const EdgeInsets.all(400),
        // Listener, not GestureDetector: InteractiveViewer's scale recognizer
        // wins the arena and would swallow taps on the child.
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (event) {
            final position = _transformation.toScene(event.localPosition);
            for (final entry in layout.positions.entries) {
              final rect = Rect.fromLTWH(
                entry.value.dx,
                entry.value.dy,
                150,
                46,
              );
              if (!rect.contains(position)) continue;
              widget.onRoomSelected?.call(entry.key);
              return;
            }
            _selectExitAt(layout, position);
          },
          child: CustomPaint(
            size: layout.size,
            painter: _WorldGraphPainter(
              graph: widget.graph,
              layout: layout,
              validation: widget.validation,
              selectedRoomId: widget.selectedRoomId,
              selectedExitKey: _selectedExitKey,
            ),
          ),
        ),
      ),
    );
  }

  void _selectExitAt(WorldGraphLayout layout, Offset position) {
    for (final room in widget.graph.rooms.values) {
      for (final exit in room.exits) {
        final from = layout.positionOf(room.id);
        final to = layout.positionOf(exit.room);
        if (from == null || to == null) continue;
        final start = from + const Offset(75, 23);
        final end = to + const Offset(75, 23);
        if (_distanceToSegment(position, start, end) > 8) continue;
        final key = '${room.id}:${exit.direction}:${exit.room}';
        setState(() => _selectedExitKey = key);
        widget.onExitSelected?.call(room.id, exit);
        return;
      }
    }
    setState(() => _selectedExitKey = null);
  }

  double _distanceToSegment(Offset point, Offset start, Offset end) {
    final delta = end - start;
    final lengthSquared = delta.dx * delta.dx + delta.dy * delta.dy;
    if (lengthSquared == 0) return (point - start).distance;
    var t =
        ((point.dx - start.dx) * delta.dx + (point.dy - start.dy) * delta.dy) /
        lengthSquared;
    t = t.clamp(0.0, 1.0);
    return (point - (start + delta * t)).distance;
  }
}

class _WorldGraphPainter extends CustomPainter {
  const _WorldGraphPainter({
    required this.graph,
    required this.layout,
    required this.validation,
    required this.selectedRoomId,
    required this.selectedExitKey,
  });

  final WorldGraph graph;
  final WorldGraphLayout layout;
  final WorldValidation validation;
  final String? selectedRoomId;
  final String? selectedExitKey;

  static const nodeWidth = 150.0;
  static const nodeHeight = 46.0;

  @override
  void paint(Canvas canvas, Size size) {
    final edgePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    final nodePaint = Paint();
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    for (final room in graph.rooms.values) {
      for (final exit in room.exits) {
        final from = layout.positionOf(room.id);
        final to = layout.positionOf(exit.room);
        if (from == null || to == null) continue;
        final target = graph.getRoom(exit.room);
        final broken = target == null;
        final key = '${room.id}:${exit.direction}:${exit.room}';
        edgePaint.color = broken
            ? const Color(0xFFE57373)
            : key == selectedExitKey
            ? const Color(0xFF8AB4F8)
            : const Color(0xFF5C6370);
        edgePaint.strokeWidth = key == selectedExitKey ? 2.6 : 1.6;

        final start = from + const Offset(nodeWidth / 2, nodeHeight / 2);
        final end = to + const Offset(nodeWidth / 2, nodeHeight / 2);
        canvas.drawLine(start, end, edgePaint);
        _drawArrowHead(canvas, start, end, edgePaint);
        if (exit.isLocked) {
          _drawLock(canvas, end, edgePaint);
        }
      }
    }

    for (final room in graph.rooms.values) {
      final position = layout.positionOf(room.id);
      if (position == null) continue;
      final rect = Rect.fromLTWH(
        position.dx,
        position.dy,
        nodeWidth,
        nodeHeight,
      );
      final issues = validation.issues
          .where((issue) => issue.roomId == room.id)
          .toList();
      final hasError = issues.any((issue) => issue.isError);
      final hasWarning = issues.any((issue) => !issue.isError);
      final isStart = room.id == graph.startRoom;
      final isSelected = room.id == selectedRoomId;

      nodePaint.color = isSelected
          ? const Color(0xFF2F4A7D)
          : isStart
          ? const Color(0xFF1F3B57)
          : const Color(0xFF23262E);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(6)),
        nodePaint,
      );
      borderPaint.color = hasError
          ? const Color(0xFFE57373)
          : hasWarning
          ? const Color(0xFFFFB74D)
          : isSelected
          ? const Color(0xFF8AB4F8)
          : const Color(0xFF3A3F4B);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(6)),
        borderPaint,
      );

      _text(
        canvas,
        room.id,
        Offset(rect.left + 8, rect.top + 6),
        const TextStyle(color: Color(0xFFE6E8EE), fontSize: 11),
        maxWidth: rect.width - 16,
      );
      _text(
        canvas,
        '${room.theme} · ${room.exits.length} exits'
        '${isStart ? ' · start' : ''}',
        Offset(rect.left + 8, rect.top + 24),
        const TextStyle(color: Color(0xFF9AA3B2), fontSize: 10),
        maxWidth: rect.width - 16,
      );

      if (issues.isNotEmpty) {
        _text(
          canvas,
          '${issues.length} issue${issues.length == 1 ? '' : 's'}',
          Offset(rect.left + 8, rect.top + 34),
          TextStyle(
            color: hasError ? const Color(0xFFE57373) : const Color(0xFFFFB74D),
            fontSize: 9,
          ),
          maxWidth: rect.width - 16,
        );
      }
    }
  }

  void _drawArrowHead(Canvas canvas, Offset start, Offset end, Paint paint) {
    final delta = end - start;
    final length = math.sqrt(delta.dx * delta.dx + delta.dy * delta.dy);
    if (length < 4) return;
    final unit = Offset(delta.dx / length, delta.dy / length);
    final tip = end - unit * 6;
    final base = tip - unit * 10;
    canvas.drawLine(tip, base + Offset(-unit.dy * 4, unit.dx * 4), paint);
    canvas.drawLine(tip, base - Offset(-unit.dy * 4, unit.dx * 4), paint);
  }

  void _drawLock(Canvas canvas, Offset at, Paint paint) {
    canvas.drawCircle(at + const Offset(-4, 0), 3, paint);
    canvas.drawLine(at + const Offset(-8, 0), at, paint);
  }

  void _text(
    Canvas canvas,
    String value,
    Offset at,
    TextStyle style, {
    required double maxWidth,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: value, style: style),
      maxLines: 1,
      ellipsis: '…',
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
    painter.paint(canvas, at);
  }

  @override
  bool shouldRepaint(covariant _WorldGraphPainter oldDelegate) {
    return oldDelegate.graph != graph ||
        oldDelegate.layout != layout ||
        oldDelegate.validation != validation ||
        oldDelegate.selectedRoomId != selectedRoomId ||
        oldDelegate.selectedExitKey != selectedExitKey;
  }
}
