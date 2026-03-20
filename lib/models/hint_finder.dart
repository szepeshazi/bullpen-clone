import '../cubit/game_state.dart';
import 'adjacency.dart';
import 'puzzle_board.dart';

/// A hint that identifies a cell which can be excluded as a bull location.
class Hint {
  final int row;
  final int col;
  final String reason;
  const Hint({required this.row, required this.col, required this.reason});
}

/// Scans the board for the first excludable empty cell, checking rules in
/// priority order. Returns `null` when no hint can be found.
Hint? findHint(PuzzleBoard board, List<List<CellMark>> marks) {
  final size = board.size;

  // Pre-compute bull counts per row, column, pen.
  final rowCounts = List.filled(size, 0);
  final colCounts = List.filled(size, 0);
  final penCounts = <int, int>{};

  for (int r = 0; r < size; r++) {
    for (int c = 0; c < size; c++) {
      if (marks[r][c] == CellMark.bull) {
        rowCounts[r]++;
        colCounts[c]++;
        final penId = board.cellAt(r, c).penId;
        penCounts[penId] = (penCounts[penId] ?? 0) + 1;
      }
    }
  }

  // Rule 1: Row full — row has 2 bulls → any empty cell in that row.
  for (int r = 0; r < size; r++) {
    if (rowCounts[r] >= 2) {
      for (int c = 0; c < size; c++) {
        if (marks[r][c] == CellMark.empty) {
          return Hint(
            row: r,
            col: c,
            reason: 'This row already has 2 bulls',
          );
        }
      }
    }
  }

  // Rule 2: Column full — column has 2 bulls → any empty cell in that column.
  for (int c = 0; c < size; c++) {
    if (colCounts[c] >= 2) {
      for (int r = 0; r < size; r++) {
        if (marks[r][c] == CellMark.empty) {
          return Hint(
            row: r,
            col: c,
            reason: 'This column already has 2 bulls',
          );
        }
      }
    }
  }

  // Rule 3: Pen full — pen has 2 bulls → any empty cell in that pen.
  for (final pen in board.pens) {
    if ((penCounts[pen.id] ?? 0) >= 2) {
      for (final cell in pen.cells) {
        if (marks[cell.row][cell.col] == CellMark.empty) {
          return Hint(
            row: cell.row,
            col: cell.col,
            reason: 'This pen already has 2 bulls',
          );
        }
      }
    }
  }

  // Rule 4: Adjacency — empty cell is adjacent (8-neighbor) to a bull.
  for (int r = 0; r < size; r++) {
    for (int c = 0; c < size; c++) {
      if (marks[r][c] == CellMark.empty &&
          hasAdjacentMatch(
              r, c, size, (nr, nc) => marks[nr][nc] == CellMark.bull)) {
        return Hint(
          row: r,
          col: c,
          reason: 'This cell is adjacent to an existing bull',
        );
      }
    }
  }

  // Rule 5: Forced cells — a row/col/pen needs k more bulls and exactly k
  // valid (empty + not adjacent to bull) positions remain → every OTHER empty
  // cell in that group is excludable.

  bool isValid(int r, int c) {
    return marks[r][c] == CellMark.empty &&
        !hasAdjacentMatch(
            r, c, size, (nr, nc) => marks[nr][nc] == CellMark.bull);
  }

  // Row forced.
  for (int r = 0; r < size; r++) {
    final needed = 2 - rowCounts[r];
    if (needed <= 0) continue;

    final validCells = <(int, int)>[];
    final emptyCells = <(int, int)>[];
    for (int c = 0; c < size; c++) {
      if (marks[r][c] == CellMark.empty) {
        emptyCells.add((r, c));
        if (isValid(r, c)) validCells.add((r, c));
      }
    }

    if (validCells.length == needed && emptyCells.length > needed) {
      final validSet = validCells.toSet();
      for (final (er, ec) in emptyCells) {
        if (!validSet.contains((er, ec))) {
          return Hint(
            row: er,
            col: ec,
            reason:
                'Row ${r + 1} needs $needed more bull${needed > 1 ? 's' : ''} '
                'and only $needed valid position${needed > 1 ? 's' : ''} '
                'remain \u2014 this isn\'t one of them',
          );
        }
      }
    }
  }

  // Column forced.
  for (int c = 0; c < size; c++) {
    final needed = 2 - colCounts[c];
    if (needed <= 0) continue;

    final validCells = <(int, int)>[];
    final emptyCells = <(int, int)>[];
    for (int r = 0; r < size; r++) {
      if (marks[r][c] == CellMark.empty) {
        emptyCells.add((r, c));
        if (isValid(r, c)) validCells.add((r, c));
      }
    }

    if (validCells.length == needed && emptyCells.length > needed) {
      final validSet = validCells.toSet();
      for (final (er, ec) in emptyCells) {
        if (!validSet.contains((er, ec))) {
          return Hint(
            row: er,
            col: ec,
            reason:
                'Column ${c + 1} needs $needed more bull${needed > 1 ? 's' : ''} '
                'and only $needed valid position${needed > 1 ? 's' : ''} '
                'remain \u2014 this isn\'t one of them',
          );
        }
      }
    }
  }

  // Pen forced.
  for (final pen in board.pens) {
    final needed = 2 - (penCounts[pen.id] ?? 0);
    if (needed <= 0) continue;

    final validCells = <(int, int)>[];
    final emptyCells = <(int, int)>[];
    for (final cell in pen.cells) {
      if (marks[cell.row][cell.col] == CellMark.empty) {
        emptyCells.add((cell.row, cell.col));
        if (isValid(cell.row, cell.col)) {
          validCells.add((cell.row, cell.col));
        }
      }
    }

    if (validCells.length == needed && emptyCells.length > needed) {
      final validSet = validCells.toSet();
      for (final (er, ec) in emptyCells) {
        if (!validSet.contains((er, ec))) {
          return Hint(
            row: er,
            col: ec,
            reason:
                'This pen needs $needed more bull${needed > 1 ? 's' : ''} '
                'and only $needed valid position${needed > 1 ? 's' : ''} '
                'remain \u2014 this isn\'t one of them',
          );
        }
      }
    }
  }

  // Rule 6: Pen look-ahead — placing a bull in this cell would leave no valid
  // spot for the pen's remaining bull(s), so it can be excluded.
  for (final pen in board.pens) {
    final needed = 2 - (penCounts[pen.id] ?? 0);
    if (needed != 2) continue; // Only when pen still needs both bulls.

    final validInPen = <(int, int)>[
      for (final cell in pen.cells)
        if (isValid(cell.row, cell.col)) (cell.row, cell.col),
    ];

    for (final (r, c) in validInPen) {
      // Simulate placing a bull at (r, c). Check if any partner remains.
      bool hasPartner = false;
      for (final (r2, c2) in validInPen) {
        if (r2 == r && c2 == c) continue;
        // Adjacent to simulated bull → invalid partner.
        if ((r2 - r).abs() <= 1 && (c2 - c).abs() <= 1) continue;
        // Same row and row would be full → invalid partner.
        if (r2 == r && rowCounts[r] + 1 >= 2) continue;
        // Same col and col would be full → invalid partner.
        if (c2 == c && colCounts[c] + 1 >= 2) continue;
        hasPartner = true;
        break;
      }
      if (!hasPartner) {
        return Hint(
          row: r,
          col: c,
          reason: 'Placing a bull here would leave no valid spot '
              'for the second bull in this pen',
        );
      }
    }
  }

  // Rule 7: Row look-ahead — placing a bull here would leave no valid spot
  // for the row's remaining bull(s).
  for (int r = 0; r < size; r++) {
    final needed = 2 - rowCounts[r];
    if (needed != 2) continue;

    final validInRow = <(int, int)>[
      for (int c = 0; c < size; c++)
        if (isValid(r, c)) (r, c),
    ];

    for (final (_, c) in validInRow) {
      bool hasPartner = false;
      for (final (_, c2) in validInRow) {
        if (c2 == c) continue;
        // Adjacent in same row → invalid partner.
        if ((c2 - c).abs() <= 1) continue;
        // Partner's column already full → invalid partner.
        if (colCounts[c2] >= 2) continue;
        // Same pen and pen would be full after placing at (r, c).
        final penId1 = board.cellAt(r, c).penId;
        final penId2 = board.cellAt(r, c2).penId;
        if (penId1 == penId2 && (penCounts[penId1] ?? 0) + 1 >= 2) continue;
        hasPartner = true;
        break;
      }
      if (!hasPartner) {
        return Hint(
          row: r,
          col: c,
          reason: 'Placing a bull here would leave no valid spot '
              'for the second bull in row ${r + 1}',
        );
      }
    }
  }

  // Rule 8: Column look-ahead — placing a bull here would leave no valid spot
  // for the column's remaining bull(s).
  for (int c = 0; c < size; c++) {
    final needed = 2 - colCounts[c];
    if (needed != 2) continue;

    final validInCol = <(int, int)>[
      for (int r = 0; r < size; r++)
        if (isValid(r, c)) (r, c),
    ];

    for (final (r, _) in validInCol) {
      bool hasPartner = false;
      for (final (r2, _) in validInCol) {
        if (r2 == r) continue;
        // Adjacent in same column → invalid partner.
        if ((r2 - r).abs() <= 1) continue;
        // Partner's row already full → invalid partner.
        if (rowCounts[r2] >= 2) continue;
        // Same pen and pen would be full after placing at (r, c).
        final penId1 = board.cellAt(r, c).penId;
        final penId2 = board.cellAt(r2, c).penId;
        if (penId1 == penId2 && (penCounts[penId1] ?? 0) + 1 >= 2) continue;
        hasPartner = true;
        break;
      }
      if (!hasPartner) {
        return Hint(
          row: r,
          col: c,
          reason: 'Placing a bull here would leave no valid spot '
              'for the second bull in column ${c + 1}',
        );
      }
    }
  }

  return null;
}
