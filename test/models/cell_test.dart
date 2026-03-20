import 'package:bullpen/models/cell.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Cell', () {
    test('cells with same row and col are equal regardless of penId', () {
      const a = Cell(row: 3, col: 5, penId: 0);
      const b = Cell(row: 3, col: 5, penId: 7);
      expect(a, equals(b));
    });

    test('cells with different row are not equal', () {
      const a = Cell(row: 0, col: 5, penId: 0);
      const b = Cell(row: 1, col: 5, penId: 0);
      expect(a, isNot(equals(b)));
    });

    test('cells with different col are not equal', () {
      const a = Cell(row: 3, col: 0, penId: 0);
      const b = Cell(row: 3, col: 1, penId: 0);
      expect(a, isNot(equals(b)));
    });

    test('hashCode is consistent with equality', () {
      const a = Cell(row: 3, col: 5, penId: 0);
      const b = Cell(row: 3, col: 5, penId: 7);
      expect(a.hashCode, equals(b.hashCode));
    });

    test('copyWith changes penId', () {
      const original = Cell(row: 1, col: 2, penId: 3);
      final copy = original.copyWith(penId: 99);
      expect(copy.row, 1);
      expect(copy.col, 2);
      expect(copy.penId, 99);
    });

    test('toString includes row, col, and pen', () {
      const cell = Cell(row: 1, col: 2, penId: 3);
      expect(cell.toString(), contains('row: 1'));
      expect(cell.toString(), contains('col: 2'));
      expect(cell.toString(), contains('pen: 3'));
    });
  });
}
