import 'cell.dart';

class BullLocation {
  final Cell cell;

  const BullLocation({required this.cell});

  int get row => cell.row;
  int get col => cell.col;
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
