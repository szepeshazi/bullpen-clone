import 'cell.dart';

/// Represents the location of a placed bull on the grid.
class BullLocation {
  final Cell cell;

  const BullLocation({required this.cell});

  /// Row index of this bull.
  int get row => cell.row;

  /// Column index of this bull.
  int get col => cell.col;

  /// Pen id this bull belongs to.
  int get penId => cell.penId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BullLocation &&
          runtimeType == other.runtimeType &&
          cell == other.cell;

  @override
  int get hashCode => cell.hashCode;

  @override
  String toString() => 'BullLocation(row: $row, col: $col, pen: $penId)';
}
