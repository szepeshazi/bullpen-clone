import 'package:bullpen/theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BullpenTitle extends StatelessWidget {
  final bool compact;

  const BullpenTitle({required this.compact, super.key});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      SvgPicture.asset(
        'assets/bull-head.svg',
        width: compact ? 56 : 80,
        height: compact ? 56 : 80,
        colorFilter: const ColorFilter.mode(
          bullpenAccentColor,
          BlendMode.srcIn,
        ),
      ),
      SizedBox(height: compact ? 8 : 16),
      const Text(
        'BULLPEN',
        style: TextStyle(
          color: bullpenAccentColor,
          fontSize: 36,
          fontWeight: FontWeight.w800,
          letterSpacing: 6,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        'Place the bulls. Break no rules.',
        style: TextStyle(
          color: bullpenAccentColor.withValues(alpha: 0.6),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<bool>('compact', compact));
  }
}
