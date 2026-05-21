import 'package:bullpen/theme.dart';
import 'package:bullpen/widgets/main/mini_grid.dart';
import 'package:flutter/material.dart';

class GridCard extends StatelessWidget {
  final int size;
  final bool isSelected;

  const GridCard({required this.size, required this.isSelected, super.key});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(vertical: 8),
    decoration: BoxDecoration(
      color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.6),
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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('size', size));
    properties.add(DiagnosticsProperty<bool>('isSelected', isSelected));
  }
}
