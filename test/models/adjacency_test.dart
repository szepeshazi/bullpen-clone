import 'package:bullpen/models/adjacency.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('hasAdjacentMatch', () {
    test('finds match in all 8 neighbors', () {
      // Place a marker at (2,2) in a 5x5 grid, check all 8 directions.
      final occupied = <(int, int)>{(2, 2)};
      final dirs = [
        (1, 1), (1, 2), (1, 3), // top-left, top, top-right
        (2, 1), /*   */ (2, 3), // left, right
        (3, 1), (3, 2), (3, 3), // bottom-left, bottom, bottom-right
      ];
      for (final (r, c) in dirs) {
        expect(
          hasAdjacentMatch(r, c, 5, (nr, nc) => occupied.contains((nr, nc))),
          isTrue,
          reason: 'Cell ($r,$c) should be adjacent to (2,2)',
        );
      }
    });

    test('returns false when no adjacent match', () {
      final occupied = <(int, int)>{(0, 0)};
      expect(
        hasAdjacentMatch(2, 2, 5, (nr, nc) => occupied.contains((nr, nc))),
        isFalse,
      );
    });

    test('handles grid edges correctly', () {
      final occupied = <(int, int)>{(0, 1)};
      // (0,0) is adjacent to (0,1).
      expect(
        hasAdjacentMatch(0, 0, 5, (nr, nc) => occupied.contains((nr, nc))),
        isTrue,
      );
    });

    test('handles corners correctly', () {
      // Nothing around (0,0) in a 1x1 grid.
      expect(
        hasAdjacentMatch(0, 0, 1, (nr, nc) => true),
        isFalse,
      );
    });

    test('does not match the cell itself', () {
      // Only (2,2) is occupied; check (2,2) — should not self-match.
      final occupied = <(int, int)>{(2, 2)};
      expect(
        hasAdjacentMatch(2, 2, 5, (nr, nc) => occupied.contains((nr, nc))),
        isFalse,
      );
    });
  });
}
