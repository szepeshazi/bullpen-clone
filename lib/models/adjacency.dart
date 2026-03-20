/// Checks whether any cell in the 8-neighbor region of (row, col) satisfies
/// [test]. Stays within the [size] × [size] grid bounds.
bool hasAdjacentMatch(
  int row,
  int col,
  int size,
  bool Function(int nr, int nc) test,
) {
  for (int dr = -1; dr <= 1; dr++) {
    for (int dc = -1; dc <= 1; dc++) {
      if (dr == 0 && dc == 0) continue;
      final nr = row + dr, nc = col + dc;
      if (nr >= 0 && nr < size && nc >= 0 && nc < size && test(nr, nc)) {
        return true;
      }
    }
  }
  return false;
}
