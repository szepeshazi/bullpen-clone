import 'package:flutter/material.dart';

import '../../theme.dart';
import 'mini_grid.dart';

class GridCard extends StatelessWidget {
  final int size;
  final bool isSelected;

  const GridCard({super.key, required this.size, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? Colors.white
            : Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? bullpenAccentColor
              : bullpenAccentColor.withValues(alpha: 0.2),
          width: isSelected ? 2.5 : 1.5,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: bullpenAccentColor.withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: Center(child: MiniGrid(size: size)),
    );
  }
}
