import 'dart:collection';
import 'dart:math';

import 'package:bullpen/models/grid_generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GridGenerator', () {
    test('rejects size below 8', () {
      expect(
        () => GridGenerator.generate(7),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects size above 16', () {
      expect(
        () => GridGenerator.generate(17),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('generates exactly size pens', () {
      final board = GridGenerator.generate(8, random: Random(42));
      expect(board.pens, hasLength(8));
    });

    test('every cell is assigned to exactly one pen', () {
      final board = GridGenerator.generate(10, random: Random(42));
      final assignedCells = <(int, int)>{};

      for (final pen in board.pens) {
        for (final cell in pen.cells) {
          final key = (cell.row, cell.col);
          expect(assignedCells.contains(key), isFalse,
              reason: 'Cell ($key) assigned to multiple pens');
          assignedCells.add(key);
          expect(cell.penId, pen.id,
              reason: 'Cell penId should match pen.id');
        }
      }

      expect(assignedCells, hasLength(10 * 10));
    });

    test('each pen is contiguous (4-connected)', () {
      final board = GridGenerator.generate(8, random: Random(42));

      for (final pen in board.pens) {
        if (pen.cells.isEmpty) continue;

        final cellSet = <(int, int)>{};
        for (final c in pen.cells) {
          cellSet.add((c.row, c.col));
        }

        final visited = <(int, int)>{};
        final queue = Queue<(int, int)>();
        final start = (pen.cells.first.row, pen.cells.first.col);
        queue.add(start);
        visited.add(start);

        while (queue.isNotEmpty) {
          final (r, c) = queue.removeFirst();
          for (final (nr, nc) in [
            (r - 1, c),
            (r + 1, c),
            (r, c - 1),
            (r, c + 1),
          ]) {
            final neighbor = (nr, nc);
            if (cellSet.contains(neighbor) && !visited.contains(neighbor)) {
              visited.add(neighbor);
              queue.add(neighbor);
            }
          }
        }

        expect(visited.length, pen.cells.length,
            reason: 'Pen ${pen.id} is not fully contiguous: '
                'reached ${visited.length} of ${pen.cells.length} cells');
      }
    });

    test('pens have valid sizes (some small, all at least 5)', () {
      final board = GridGenerator.generate(8, random: Random(42));
      final avgSize = 64 ~/ 8; // 8

      bool hasSmall = false;
      for (final pen in board.pens) {
        expect(pen.size, greaterThanOrEqualTo(5),
            reason: 'Pen ${pen.id} has only ${pen.size} cells (min 5)');
        if (pen.size < avgSize) hasSmall = true;
      }
      expect(hasSmall, isTrue,
          reason: 'Expected at least one pen smaller than average');
    });

    test('works for boundary size 8', () {
      final board = GridGenerator.generate(8, random: Random(1));
      expect(board.size, 8);
      expect(board.pens, hasLength(8));

      int totalCells = board.pens.fold(0, (sum, pen) => sum + pen.size);
      expect(totalCells, 64);
    });

    test('works for boundary size 16', () {
      final board = GridGenerator.generate(16, random: Random(1));
      expect(board.size, 16);
      expect(board.pens, hasLength(16));

      int totalCells = board.pens.fold(0, (sum, pen) => sum + pen.size);
      expect(totalCells, 256);
    });

    test('cellAt returns cells with correct penId from generator', () {
      final board = GridGenerator.generate(8, random: Random(42));

      for (final pen in board.pens) {
        for (final cell in pen.cells) {
          final retrieved = board.cellAt(cell.row, cell.col);
          expect(retrieved.penId, pen.id);
        }
      }
    });

    test('deterministic with same seed', () {
      final board1 = GridGenerator.generate(8, random: Random(99));
      final board2 = GridGenerator.generate(8, random: Random(99));

      for (int r = 0; r < 8; r++) {
        for (int c = 0; c < 8; c++) {
          expect(board1.cellAt(r, c).penId, board2.cellAt(r, c).penId,
              reason: 'Cell ($r, $c) should have same penId with same seed');
        }
      }
    });
  });
}
