import 'package:bullpen/models/cell.dart';
import 'package:bullpen/models/pen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Pen', () {
    test('stores id and cells correctly', () {
      final cells = [
        const Cell(row: 0, col: 0, penId: 0),
        const Cell(row: 0, col: 1, penId: 0),
        const Cell(row: 1, col: 0, penId: 0),
      ];
      final pen = Pen(id: 0, cells: cells);

      expect(pen.id, 0);
      expect(pen.cells, hasLength(3));
      expect(pen.size, 3);
    });

    test('containsCell returns true for member cells', () {
      final cells = [
        const Cell(row: 2, col: 3, penId: 1),
        const Cell(row: 2, col: 4, penId: 1),
      ];
      final pen = Pen(id: 1, cells: cells);

      expect(pen.containsCell(const Cell(row: 2, col: 3, penId: 1)), isTrue);
    });

    test('containsCell returns false for non-member cells', () {
      final cells = [
        const Cell(row: 2, col: 3, penId: 1),
      ];
      final pen = Pen(id: 1, cells: cells);

      expect(pen.containsCell(const Cell(row: 0, col: 0, penId: 1)), isFalse);
    });
  });
}
