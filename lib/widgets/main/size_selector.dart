import 'package:flutter/material.dart';

import '../../theme.dart';
import 'size_carousel.dart';

class SizeSelector extends StatelessWidget {
  final int selectedSize;
  final ValueChanged<int> onSizeChanged;

  const SizeSelector({
    super.key,
    required this.selectedSize,
    required this.onSizeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'SELECT GRID SIZE',
          style: TextStyle(
            color: bullpenAccentColor.withValues(alpha: 0.7),
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 160,
          child: SizeCarousel(
            selectedSize: selectedSize,
            onSizeChanged: onSizeChanged,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '$selectedSize × $selectedSize',
          style: const TextStyle(
            color: bullpenAccentColor,
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${selectedSize * 2} bulls to place',
          style: TextStyle(
            color: bullpenAccentColor.withValues(alpha: 0.5),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
