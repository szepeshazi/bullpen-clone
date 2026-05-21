import 'package:bullpen/theme.dart';
import 'package:bullpen/widgets/main/size_carousel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class SizeSelector extends StatelessWidget {
  final int selectedSize;
  final ValueChanged<int> onSizeChanged;

  const SizeSelector({
    required this.selectedSize,
    required this.onSizeChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Column(
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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IntProperty('selectedSize', selectedSize))
      ..add(ObjectFlagProperty<ValueChanged<int>>.has(
        'onSizeChanged',
        onSizeChanged,
      ));
  }
}
