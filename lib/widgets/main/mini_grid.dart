import 'package:bullpen/theme.dart';
import 'package:flutter/material.dart';

/// Tiny preview of an N×N grid used inside size carousel cards.
class MiniGrid extends StatelessWidget {
  final int size;

  const MiniGrid({required this.size, super.key});

  static const _gridVisualSize = 80.0;

  @override
  Widget build(BuildContext context) => SizedBox(
      width: _gridVisualSize,
      height: _gridVisualSize,
      child: CustomPaint(
        painter: _MiniGridPainter(
          gridSize: size,
          cellSize: _gridVisualSize / size,
        ),
      ),
    );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('size', size));
  }
}

class _MiniGridPainter extends CustomPainter {
  final int gridSize;
  final double cellSize;

  const _MiniGridPainter({required this.gridSize, required this.cellSize});

  @override
  void paint(Canvas canvas, Size size) {
    _drawGridLines(canvas, size);
    _drawBorder(canvas, size);
    _drawDecorativeBulls(canvas);
  }

  void _drawGridLines(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = bullpenAccentColor.withValues(alpha: 0.25)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    for (var r = 0; r <= gridSize; r++) {
      final y = r * cellSize;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    for (var c = 0; c <= gridSize; c++) {
      final x = c * cellSize;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  void _drawBorder(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = bullpenAccentColor.withValues(alpha: 0.5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  void _drawDecorativeBulls(Canvas canvas) {
    final paint = Paint()
      ..color = bullpenAccentColor.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;
    for (final (r, c) in _decorativeBullPositions(gridSize)) {
      final cx = (c + 0.5) * cellSize;
      final cy = (r + 0.5) * cellSize;
      canvas.drawCircle(Offset(cx, cy), cellSize * 0.3, paint);
    }
  }

  List<(int, int)> _decorativeBullPositions(int n) {
    if (n <= 9) return [(0, 2), (2, 0), (1, n - 1), (n - 1, 1)];
    if (n <= 12) {
      return [(0, 3), (2, 0), (1, n - 2), (n - 1, 2), (n - 2, n - 1)];
    }
    return [(0, 3), (2, 0), (1, n - 2), (n - 1, 2), (n - 2, n - 1), (n - 3, 4)];
  }

  @override
  bool shouldRepaint(_MiniGridPainter oldDelegate) =>
      oldDelegate.gridSize != gridSize;
}
