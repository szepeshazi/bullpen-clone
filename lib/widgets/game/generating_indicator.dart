import 'dart:async';
import 'dart:math';

import 'package:bullpen/theme.dart';
import 'package:bullpen/widgets/grid_constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class GeneratingIndicator extends StatefulWidget {
  final int gridSize;
  const GeneratingIndicator({required this.gridSize, super.key});

  @override
  State<GeneratingIndicator> createState() => _GeneratingIndicatorState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('gridSize', gridSize));
  }
}

class _GeneratingIndicatorState extends State<GeneratingIndicator>
    with TickerProviderStateMixin {
  late final AnimationController _breathController;
  late final AnimationController _sweepController;
  late final AnimationController _dotsController;

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _sweepController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    unawaited(_breathController.repeat(reverse: true));
    unawaited(_sweepController.repeat());
    unawaited(_dotsController.repeat());
  }

  @override
  void dispose() {
    _breathController.dispose();
    _sweepController.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 140,
          height: 140,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: _sweepController,
                builder: (context, _) => CustomPaint(
                  size: const Size(140, 140),
                  painter: _SweepRingPainter(progress: _sweepController.value),
                ),
              ),
              AnimatedBuilder(
                animation: _breathController,
                builder: (context, child) {
                  final t = Curves.easeInOut.transform(_breathController.value);
                  final scale = 0.94 + t * 0.12;
                  final tilt = sin(t * pi * 2) * 0.05;
                  return Transform.rotate(
                    angle: tilt,
                    child: Transform.scale(scale: scale, child: child),
                  );
                },
                child: SvgPicture.asset(
                  bullSvgAsset,
                  width: 84,
                  height: 84,
                  colorFilter: const ColorFilter.mode(
                    bullpenAccentColor,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AnimatedBuilder(
          animation: _dotsController,
          builder: (context, _) {
            final dotCount = 1 + (_dotsController.value * 3).floor() % 3;
            return Text(
              'Building ${widget.gridSize}×${widget.gridSize} pen'
              '${'.' * dotCount}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: bullpenAccentColor,
              ),
            );
          },
        ),
      ],
    ),
  );
}

class _SweepRingPainter extends CustomPainter {
  final double progress;
  _SweepRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 6;

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color = bullpenAccentColor.withValues(alpha: 0.15);
    canvas.drawCircle(center, radius, trackPaint);

    final sweepPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        transform: GradientRotation(progress * pi * 2),
        colors: [
          bullpenAccentColor.withValues(alpha: 0),
          bullpenAccentColor.withValues(alpha: 0.9),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      progress * pi * 2,
      pi * 1.4,
      false,
      sweepPaint,
    );
  }

  @override
  bool shouldRepaint(_SweepRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
