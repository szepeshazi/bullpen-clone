import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'grid_constants.dart';

class ShakingBull extends StatefulWidget {
  final double cellSize;
  final int version;
  const ShakingBull({super.key, required this.cellSize, required this.version});

  @override
  State<ShakingBull> createState() => _ShakingBullState();
}

class _ShakingBullState extends State<ShakingBull>
    with TickerProviderStateMixin {
  late final AnimationController _shakeController;
  late final AnimationController _smokeController;
  late final Animation<double> _shakeX;
  late final Animation<double> _shakeY;
  late final Animation<double> _smokeAnimation;
  late final Animation<double> _redAnimation;

  @override
  void initState() {
    super.initState();
    final rng = Random();

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _shakeX = _randomShake(rng, 18, 16).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.easeOut),
    );
    _shakeY = _randomShake(rng, 18, 8).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.easeOut),
    );

    _redAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 0.75), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.75, end: 0.70), weight: 7),
    ]).animate(_shakeController);

    _smokeController = AnimationController(
      duration: const Duration(milliseconds: 2400),
      vsync: this,
    );
    _smokeAnimation = CurvedAnimation(
      parent: _smokeController,
      curve: Curves.linear,
    );

    _shakeController.forward();
    _smokeController.forward();
  }

  @override
  void didUpdateWidget(covariant ShakingBull oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.version != widget.version) {
      _shakeController.forward(from: 0);
      _smokeController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _smokeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.cellSize;

    return AnimatedBuilder(
      animation: Listenable.merge([_shakeX, _shakeY, _smokeAnimation]),
      builder: (context, child) {
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              ..._SmokePuffs.build(size, _smokeAnimation.value),
              Transform.translate(
                offset: Offset(_shakeX.value, _shakeY.value),
                child: _RedTintedBull(
                  cellSize: size,
                  redAmount: _redAnimation.value,
                  child: child!,
                ),
              ),
            ],
          ),
        );
      },
      child: SvgPicture.asset(bullSvgAsset, fit: BoxFit.contain),
    );
  }
}

/// Builds a randomised shake tween sequence with [numSteps] oscillations.
/// Amplitudes decay over time to create a jittery, organic tremor.
TweenSequence<double> _randomShake(Random rng, int numSteps, double maxAmp) {
  final items = <TweenSequenceItem<double>>[];
  double prev = 0;
  for (int i = 0; i < numSteps; i++) {
    final decay = 1.0 - i / numSteps;
    final amp = maxAmp * decay;
    final sign = (i.isEven ? 1.0 : -1.0) * (0.5 + rng.nextDouble() * 0.5);
    final target = sign * amp * (0.4 + rng.nextDouble() * 0.6);
    items.add(TweenSequenceItem(
      tween: Tween(begin: prev, end: target),
      weight: 1.0 + rng.nextDouble(),
    ));
    prev = target;
  }
  items.add(TweenSequenceItem(tween: Tween(begin: prev, end: 0), weight: 1));
  return TweenSequence(items);
}

class _RedTintedBull extends StatelessWidget {
  final double cellSize;
  final double redAmount;
  final Widget child;

  const _RedTintedBull({
    required this.cellSize,
    required this.redAmount,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(cellSize * bullPaddingFraction),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.red.withValues(alpha: redAmount * 0.8),
              blurRadius: cellSize * 0.3,
              spreadRadius: cellSize * 0.05,
            ),
          ],
        ),
        child: ColorFiltered(
          colorFilter: ColorFilter.mode(
            Colors.red.withValues(alpha: redAmount),
            BlendMode.srcATop,
          ),
          child: child,
        ),
      ),
    );
  }
}

class _SmokePuffs {
  static const _repetitions = 3;

  /// (dx, dy, timeFactor, opacityFactor, sizeFactor) per puff.
  /// Mirrored to left/right nostrils.
  static const _puffParams = [
    (0.30, 0.60, 1.0, 1.0, 0.9),
    (0.42, 0.48, 0.85, 0.85, 0.7),
    (0.22, 0.44, 0.70, 0.65, 0.55),
    (0.15, 0.62, 0.55, 0.50, 0.50),
  ];

  static List<Widget> build(double cellSize, double raw) {
    if (raw <= 0.005) return const [];

    final widgets = <Widget>[];
    for (int burst = 0; burst < _repetitions; burst++) {
      final burstStart = burst / _repetitions;
      final burstEnd = (burst + 1) / _repetitions;
      if (raw < burstStart || raw > burstEnd) continue;

      final t = ((raw - burstStart) / (burstEnd - burstStart)).clamp(0.0, 1.0);
      final eased = Curves.easeOut.transform(t);
      final opacity = eased < 0.25 ? eased / 0.25 : (1.0 - eased) / 0.75;
      final burstScale = 1.0 - burst * 0.15;

      for (final (dx, dy, tf, of_, sf) in _puffParams) {
        final scaledSf = sf * burstScale;
        widgets.add(_puff(cellSize, -dx, dy, eased * tf, opacity * of_, scaledSf));
        widgets.add(_puff(cellSize, dx, dy, eased * tf, opacity * of_, scaledSf));
      }
    }
    return widgets;
  }

  static Widget _puff(
    double cellSize,
    double dx,
    double dy,
    double t,
    double opacity,
    double sizeFactor,
  ) {
    final puffSize = cellSize * sizeFactor * (0.3 + t * 0.7);
    final x = cellSize / 2 + dx * cellSize * t - puffSize / 2;
    final y = cellSize * 0.65 + dy * cellSize * t - puffSize / 2;
    final clamped = opacity.clamp(0.0, 1.0);

    return Positioned(
      left: x,
      top: y,
      child: Opacity(
        opacity: clamped,
        child: Container(
          width: puffSize,
          height: puffSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.grey.shade400.withValues(alpha: clamped * 0.6),
              width: 1.0,
            ),
            gradient: RadialGradient(
              colors: [
                Colors.white,
                Colors.grey.shade200,
                Colors.grey.shade300.withValues(alpha: 0.0),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),
      ),
    );
  }
}
