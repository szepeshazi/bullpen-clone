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
        _RingWithBull(sweep: _sweepController, breath: _breathController),
        const SizedBox(height: 16),
        _BuildingLabel(
          controller: _dotsController,
          gridSize: widget.gridSize,
        ),
      ],
    ),
  );
}

class _RingWithBull extends StatelessWidget {
  final AnimationController sweep;
  final AnimationController breath;
  const _RingWithBull({required this.sweep, required this.breath});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 140,
    height: 140,
    child: Stack(
      alignment: Alignment.center,
      children: [
        AnimatedBuilder(
          animation: sweep,
          builder: (context, _) => CustomPaint(
            size: const Size(140, 140),
            painter: _SweepRingPainter(progress: sweep.value),
          ),
        ),
        AnimatedBuilder(
          animation: breath,
          builder: (context, child) {
            final t = Curves.easeInOut.transform(breath.value);
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
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('sweep', sweep))
      ..add(DiagnosticsProperty('breath', breath));
  }
}

class _BuildingLabel extends StatelessWidget {
  final AnimationController controller;
  final int gridSize;
  const _BuildingLabel({required this.controller, required this.gridSize});

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) {
      final dotCount = 1 + (controller.value * 3).floor() % 3;
      return Text(
        'Building $gridSize×$gridSize pen${'.' * dotCount}',
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: bullpenAccentColor,
        ),
      );
    },
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('controller', controller))
      ..add(IntProperty('gridSize', gridSize));
  }
}

class _SweepRingPainter extends CustomPainter {
  final double progress;
  _SweepRingPainter({required this.progress});

  // Sweep gradient is angle-only, so a single shader works for every frame —
  // we rotate the canvas instead of rebuilding the gradient each paint.
  static Shader? _shader;
  static double _shaderRadius = -1;

  static Shader _ensureShader(double radius) {
    if (_shader == null || _shaderRadius != radius) {
      _shader = SweepGradient(
        colors: [
          bullpenAccentColor.withValues(alpha: 0),
          bullpenAccentColor.withValues(alpha: 0.9),
        ],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: radius));
      _shaderRadius = radius;
    }
    return _shader!;
  }

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
      ..shader = _ensureShader(radius);

    canvas
      ..save()
      ..translate(center.dx, center.dy)
      ..rotate(progress * pi * 2)
      ..drawArc(
        Rect.fromCircle(center: Offset.zero, radius: radius),
        0,
        pi * 1.4,
        false,
        sweepPaint,
      )
      ..restore();
  }

  @override
  bool shouldRepaint(_SweepRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
