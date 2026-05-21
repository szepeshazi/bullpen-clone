import 'package:bullpen/theme.dart';
import 'package:flutter/material.dart';

const penFillColors = <Color>[
  Color(0xFFF2C6D0), // pink / rose
  Color(0xFFB8E0F6), // light blue
  Color(0xFFF6EABA), // cream / yellow
  Color(0xFFBAE8CE), // mint green
  Color(0xFFCFC4E8), // lavender / purple
  Color(0xFFF5C4B3), // salmon / coral
  Color(0xFFE3F0B0), // lime / yellow-green
  Color(0xFFD4ECF7), // ice blue
  Color(0xFFFAD8E8), // light pink
];

const Color penBorderColor = bullpenAccentColor;

class PenColorSet {
  final Color fill;
  final Color cellBorder;
  final Color dot;

  const PenColorSet({
    required this.fill,
    required this.cellBorder,
    required this.dot,
  });
}

final Map<Color, PenColorSet> _cache = {};

PenColorSet colorsForPenId(int penId) =>
    _colorSetFor(penFillColors[penId % penFillColors.length]);

PenColorSet _colorSetFor(Color penColor) => _cache.putIfAbsent(penColor, () {
  final hsl = HSLColor.fromColor(penColor);
  final cellBorder = hsl
      .withSaturation((hsl.saturation * 1.1).clamp(0.0, 1.0))
      .withLightness((hsl.lightness - 0.08).clamp(0.0, 1.0))
      .toColor();
  final dot = hsl
      .withSaturation((hsl.saturation * 1.4).clamp(0.0, 1.0))
      .withLightness((hsl.lightness - 0.22).clamp(0.0, 1.0))
      .toColor();
  return PenColorSet(fill: penColor, cellBorder: cellBorder, dot: dot);
});
