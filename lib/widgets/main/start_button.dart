import 'package:bullpen/theme.dart';
import 'package:flutter/material.dart';

class StartButton extends StatefulWidget {
  final VoidCallback onPressed;

  const StartButton({required this.onPressed, super.key});

  @override
  State<StartButton> createState() => _StartButtonState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      ObjectFlagProperty<VoidCallback>.has('onPressed', onPressed),
    );
  }
}

class _StartButtonState extends State<StartButton>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _pulseAnimation,
    builder: (context, child) =>
        Transform.scale(scale: _pulseAnimation.value, child: child),
    child: SizedBox(
      width: 220,
      height: 56,
      child: ElevatedButton(
        onPressed: widget.onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bullpenAccentColor,
          foregroundColor: Colors.white,
          elevation: 6,
          shadowColor: bullpenAccentColor.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          textStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
        child: const Text('START'),
      ),
    ),
  );
}
