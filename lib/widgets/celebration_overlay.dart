import 'dart:math';

import 'package:bullpen/theme.dart';
import 'package:flutter/material.dart';

class CelebrationOverlay extends StatefulWidget {
  final VoidCallback onDismiss;
  const CelebrationOverlay({required this.onDismiss, super.key});

  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ObjectFlagProperty<VoidCallback>.has('onDismiss', onDismiss));
  }
}

class _CelebrationOverlayState extends State<CelebrationOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final AnimationController _confettiController;
  late final Animation<double> _fadeIn;
  late final Animation<double> _scaleIn;
  final _random = Random();
  late final List<_ConfettiPiece> _confetti;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeIn = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _scaleIn = Tween<double>(begin: 0.3, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.elasticOut),
    );

    _confettiController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _confetti = List.generate(80, (_) => _ConfettiPiece.random(_random));

    _fadeController.forward();
    _confettiController.repeat();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: widget.onDismiss,
      child: FadeTransition(
        opacity: _fadeIn,
        child: Stack(
          children: [
            Container(color: Colors.black.withValues(alpha: 0.5)),
            AnimatedBuilder(
              animation: _confettiController,
              builder: (context, _) => CustomPaint(
                painter: _ConfettiPainter(
                  confetti: _confetti,
                  progress: _confettiController.value,
                ),
                size: MediaQuery.of(context).size,
              ),
            ),
            Center(
              child: ScaleTransition(
                scale: _scaleIn,
                child: const _CongratsCard(),
              ),
            ),
          ],
        ),
      ),
    );
}

class _CongratsCard extends StatelessWidget {
  const _CongratsCard();

  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🎉', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          const Text(
            'Congratulations!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: bullpenAccentColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'All bulls are in their pens!',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          Text(
            'Tap anywhere to continue',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade400,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
}

class _ConfettiPiece {
  final double x;
  final double startY;
  final double speed;
  final double size;
  final double rotation;
  final double wobbleSpeed;
  final double wobbleAmount;
  final Color color;

  const _ConfettiPiece({
    required this.x,
    required this.startY,
    required this.speed,
    required this.size,
    required this.rotation,
    required this.wobbleSpeed,
    required this.wobbleAmount,
    required this.color,
  });

  static const _colors = [
    Color(0xFFFF6B6B),
    Color(0xFFFFD93D),
    Color(0xFF6BCB77),
    Color(0xFF4D96FF),
    Color(0xFFF2C6D0),
    Color(0xFFCFC4E8),
    Color(0xFFFF8C42),
    Color(0xFF42E8E0),
  ];

  factory _ConfettiPiece.random(Random rng) => _ConfettiPiece(
      x: rng.nextDouble(),
      startY: -rng.nextDouble() * 0.3,
      speed: 0.3 + rng.nextDouble() * 0.7,
      size: 4 + rng.nextDouble() * 8,
      rotation: rng.nextDouble() * pi * 2,
      wobbleSpeed: 1 + rng.nextDouble() * 3,
      wobbleAmount: 0.02 + rng.nextDouble() * 0.04,
      color: _colors[rng.nextInt(_colors.length)],
    );
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiPiece> confetti;
  final double progress;

  _ConfettiPainter({required this.confetti, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final piece in confetti) {
      final t = (progress * piece.speed + piece.startY) % 1.3;
      final y = t * size.height * 1.2;
      final wobble = sin(t * piece.wobbleSpeed * pi * 2) * piece.wobbleAmount;
      final x = (piece.x + wobble) * size.width;

      final paint = Paint()..color = piece.color;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(piece.rotation + progress * pi * 2 * piece.speed);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: piece.size,
            height: piece.size * 0.6,
          ),
          Radius.circular(piece.size * 0.1),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
