import 'dart:math';

import 'package:bullpen/logic/hint_finder.dart';
import 'package:bullpen/theme.dart';
import 'package:bullpen/widgets/grid_constants.dart';
import 'package:flutter/material.dart';

const _mustPlaceColor = Color(0xFF2E7D32);

class HintArrowOverlay extends StatefulWidget {
  final (int, int) hintCell;
  final HintType hintType;
  final int boardSize;
  final double areaWidth;
  final double areaHeight;

  const HintArrowOverlay({
    required this.hintCell,
    required this.hintType,
    required this.boardSize,
    required this.areaWidth,
    required this.areaHeight,
    super.key,
  });

  @override
  State<HintArrowOverlay> createState() => _HintArrowOverlayState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<(int, int)>('hintCell', hintCell));
    properties.add(EnumProperty<HintType>('hintType', hintType));
    properties.add(IntProperty('boardSize', boardSize));
    properties.add(DoubleProperty('areaWidth', areaWidth));
    properties.add(DoubleProperty('areaHeight', areaHeight));
  }
}

class _HintArrowOverlayState extends State<HintArrowOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _bounceController;
  late final Animation<double> _bounceOffset;
  late final AnimationController _fadeController;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);
    _bounceOffset = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    )..forward();
    _fadeIn = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final geom = _ArrowGeometry.compute(
      hintCell: widget.hintCell,
      boardSize: widget.boardSize,
      areaWidth: widget.areaWidth,
      areaHeight: widget.areaHeight,
    );

    final color = widget.hintType == HintType.mustPlace
        ? _mustPlaceColor
        : bullpenAccentColor;

    return AnimatedBuilder(
      animation: Listenable.merge([_bounceOffset, _fadeIn]),
      builder: (context, _) {
        // Arrow slides from bottom-right toward top-left.
        // At bounce=0 the tip sits exactly at cell center.
        final bounce = _bounceOffset.value;
        final dx = bounce * 0.707;
        final dy = bounce * 0.707;

        return Positioned(
          left: geom.cellCenterX + dx,
          top: geom.cellCenterY + dy,
          child: Opacity(
            opacity: _fadeIn.value,
            child: CustomPaint(
              size: Size(geom.arrowLen, geom.arrowLen),
              painter: _DiagonalArrowPainter(color: color),
            ),
          ),
        );
      },
    );
  }
}

class _ArrowGeometry {
  final double cellCenterX;
  final double cellCenterY;
  final double arrowLen;

  const _ArrowGeometry({
    required this.cellCenterX,
    required this.cellCenterY,
    required this.arrowLen,
  });

  factory _ArrowGeometry.compute({
    required (int, int) hintCell,
    required int boardSize,
    required double areaWidth,
    required double areaHeight,
  }) {
    final (row, col) = hintCell;
    const padding = 12.0;
    final availW = areaWidth - padding * 2;
    final availH = areaHeight - padding * 2;
    final maxSide = min(availW, availH);
    final gridSide = maxSide * gridFraction;
    final cellSize = gridSide / boardSize;
    final gridContainer = gridSide + outerBorderWidth * 2;

    final originX = padding + (availW - gridContainer) / 2 + outerBorderWidth;
    final originY = padding + (availH - gridContainer) / 2 + outerBorderWidth;

    return _ArrowGeometry(
      cellCenterX: originX + (col + 0.5) * cellSize,
      cellCenterY: originY + (row + 0.5) * cellSize,
      arrowLen: cellSize * 0.55,
    );
  }
}

class _DiagonalArrowPainter extends CustomPainter {
  final Color color;
  const _DiagonalArrowPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width; // square canvas

    // Cursor-pointer shape with tip at (0,0), symmetric along the y=x axis.
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(0, s * 0.58)
      ..lineTo(s * 0.18, s * 0.38)
      ..lineTo(s * 0.74, s * 0.94)
      ..lineTo(s * 0.94, s * 0.74)
      ..lineTo(s * 0.38, s * 0.18)
      ..lineTo(s * 0.58, 0)
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF000000)
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.03
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_DiagonalArrowPainter oldDelegate) =>
      oldDelegate.color != color;
}
