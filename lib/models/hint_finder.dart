import '../cubit/game_state.dart';
import 'adjacency.dart';
import 'puzzle_board.dart';

/// Whether a hint excludes a cell or identifies a forced bull placement.
enum HintType { exclude, mustPlace }

/// A hint that identifies a cell which can be excluded or must contain a bull.
class Hint {
  final int row;
  final int col;
  final String reason;
  final HintType type;
  const Hint({
    required this.row,
    required this.col,
    required this.reason,
    this.type = HintType.exclude,
  });
}

/// Yields all combinations of [k] elements from [items] using index-based
/// iteration (zero allocation beyond the yielded lists).
Iterable<List<int>> _combinations(List<int> items, int k) sync* {
  if (k == 0 || k > items.length) return;
  final indices = List.generate(k, (i) => i);
  yield [for (final i in indices) items[i]];
  while (true) {
    int i = k - 1;
    while (i >= 0 && indices[i] == i + items.length - k) {
      i--;
    }
    if (i < 0) return;
    indices[i]++;
    for (int j = i + 1; j < k; j++) {
      indices[j] = indices[j - 1] + 1;
    }
    yield [for (final i in indices) items[i]];
  }
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

  // --- After Rule 4, every empty cell has no adjacent bull. ---
  // Pre-compute a validity grid: valid ≡ empty (adjacency is guaranteed).
  final valid = List.generate(
    size,
    (r) => List.generate(size, (c) => marks[r][c] == CellMark.empty),
  );

  // Pre-compute per-pen valid rows/cols, active rows/cols, row/col→pen maps.
  final penValidRows = <int, Set<int>>{};
  final penValidCols = <int, Set<int>>{};
  for (final pen in board.pens) {
    final rows = <int>{};
    final cols = <int>{};
    for (final cell in pen.cells) {
      if (valid[cell.row][cell.col]) {
        rows.add(cell.row);
        cols.add(cell.col);
      }
    }
    penValidRows[pen.id] = rows;
    penValidCols[pen.id] = cols;
  }
  final activeRows = [for (int r = 0; r < size; r++) if (rowCounts[r] < 2) r];
  final activeCols = [for (int c = 0; c < size; c++) if (colCounts[c] < 2) c];

  final rowToPens = <int, Set<int>>{};
  for (final r in activeRows) {
    final pens = <int>{};
    for (int c = 0; c < size; c++) {
      if (valid[r][c]) pens.add(board.cellAt(r, c).penId);
    }
    rowToPens[r] = pens;
  }
  final colToPens = <int, Set<int>>{};
  for (final c in activeCols) {
    final pens = <int>{};
    for (int r = 0; r < size; r++) {
      if (valid[r][c]) pens.add(board.cellAt(r, c).penId);
    }
    colToPens[c] = pens;
  }

  // Rule 5: Naked sets (pigeonhole) — if N pens are fully contained within
  // N rows (or columns), those pens exhaust all bull slots in those rows,
  // so no other pen can place bulls there.

  // Row naked sets.
  for (int subsetSize = 1;
      subsetSize <= activeRows.length && subsetSize <= (size ~/ 2);
      subsetSize++) {
    for (final rowSubset in _combinations(activeRows, subsetSize)) {
      final rowSet = rowSubset.toSet();
      final remainingCapacity =
          rowSubset.fold<int>(0, (sum, r) => sum + 2 - rowCounts[r]);

      final containedPenIds = <int>{};
      int remainingNeed = 0;
      for (final pen in board.pens) {
        final validRows = penValidRows[pen.id]!;
        if (validRows.isNotEmpty && rowSet.containsAll(validRows)) {
          containedPenIds.add(pen.id);
          remainingNeed += 2 - (penCounts[pen.id] ?? 0);
        }
      }

      if (remainingNeed == remainingCapacity && containedPenIds.isNotEmpty) {
        for (final r in rowSubset) {
          for (int c = 0; c < size; c++) {
            if (marks[r][c] == CellMark.empty &&
                !containedPenIds.contains(board.cellAt(r, c).penId)) {
              final rowLabels = rowSubset.map((r) => '${r + 1}').join(', ');
              final nPens = containedPenIds.length;
              final rowWord = rowSubset.length == 1 ? 'Row' : 'Rows';
              final penWord = nPens == 1 ? 'pen' : 'pens';
              final rowRef = rowSubset.length == 1 ? 'it' : 'them';
              return Hint(
                row: r,
                col: c,
                reason: '$rowWord $rowLabels must supply all bulls for '
                    '$nPens $penWord fully within $rowRef '
                    '\u2014 no room for other pens\u2019 bulls in '
                    '${rowSubset.length == 1 ? 'this row' : 'these rows'}',
              );
            }
          }
        }
      }
    }
  }

  // Column naked sets.
  for (int subsetSize = 1;
      subsetSize <= activeCols.length && subsetSize <= (size ~/ 2);
      subsetSize++) {
    for (final colSubset in _combinations(activeCols, subsetSize)) {
      final colSet = colSubset.toSet();
      final remainingCapacity =
          colSubset.fold<int>(0, (sum, c) => sum + 2 - colCounts[c]);

      final containedPenIds = <int>{};
      int remainingNeed = 0;
      for (final pen in board.pens) {
        final validCols = penValidCols[pen.id]!;
        if (validCols.isNotEmpty && colSet.containsAll(validCols)) {
          containedPenIds.add(pen.id);
          remainingNeed += 2 - (penCounts[pen.id] ?? 0);
        }
      }

      if (remainingNeed == remainingCapacity && containedPenIds.isNotEmpty) {
        for (final c in colSubset) {
          for (int r = 0; r < size; r++) {
            if (marks[r][c] == CellMark.empty &&
                !containedPenIds.contains(board.cellAt(r, c).penId)) {
              final colLabels = colSubset.map((c) => '${c + 1}').join(', ');
              final nPens = containedPenIds.length;
              final colWord = colSubset.length == 1 ? 'Column' : 'Columns';
              final penWord = nPens == 1 ? 'pen' : 'pens';
              final colRef = colSubset.length == 1 ? 'it' : 'them';
              return Hint(
                row: r,
                col: c,
                reason: '$colWord $colLabels must supply all bulls for '
                    '$nPens $penWord fully within $colRef '
                    '\u2014 no room for other pens\u2019 bulls in '
                    '${colSubset.length == 1 ? 'this column' : 'these columns'}',
              );
            }
          }
        }
      }
    }
  }

  // Rule 5b: Hidden sets — if N rows can only serve N pens (every valid cell
  // in those rows belongs to one of those N pens), then those pens must place
  // all their bulls within those rows. Exclude those pens' cells outside.

  // Row hidden sets.
  for (int subsetSize = 1;
      subsetSize <= activeRows.length && subsetSize <= (size ~/ 2);
      subsetSize++) {
    for (final rowSubset in _combinations(activeRows, subsetSize)) {
      final touchingPens = <int>{};
      for (final r in rowSubset) {
        touchingPens.addAll(rowToPens[r] ?? {});
      }

      final remainingCapacity =
          rowSubset.fold<int>(0, (sum, r) => sum + 2 - rowCounts[r]);
      final remainingNeed = touchingPens.fold<int>(
          0, (sum, penId) => sum + 2 - (penCounts[penId] ?? 0));

      if (touchingPens.length >= 2 && remainingNeed == remainingCapacity) {
        final rowSet = rowSubset.toSet();
        for (final penId in touchingPens) {
          final pen = board.penById(penId);
          for (final cell in pen.cells) {
            if (!rowSet.contains(cell.row) &&
                marks[cell.row][cell.col] == CellMark.empty) {
              final rowLabels = rowSubset.map((r) => '${r + 1}').join(', ');
              final rowWord = rowSubset.length == 1 ? 'Row' : 'Rows';
              return Hint(
                row: cell.row,
                col: cell.col,
                reason: '$rowWord $rowLabels can only serve '
                    '${touchingPens.length} pens '
                    '\u2014 this pen must place its bulls there, not here',
              );
            }
          }
        }
      }
    }
  }

  // Column hidden sets.
  for (int subsetSize = 1;
      subsetSize <= activeCols.length && subsetSize <= (size ~/ 2);
      subsetSize++) {
    for (final colSubset in _combinations(activeCols, subsetSize)) {
      final touchingPens = <int>{};
      for (final c in colSubset) {
        touchingPens.addAll(colToPens[c] ?? {});
      }

      final remainingCapacity =
          colSubset.fold<int>(0, (sum, c) => sum + 2 - colCounts[c]);
      final remainingNeed = touchingPens.fold<int>(
          0, (sum, penId) => sum + 2 - (penCounts[penId] ?? 0));

      if (touchingPens.length >= 2 && remainingNeed == remainingCapacity) {
        final colSet = colSubset.toSet();
        for (final penId in touchingPens) {
          final pen = board.penById(penId);
          for (final cell in pen.cells) {
            if (!colSet.contains(cell.col) &&
                marks[cell.row][cell.col] == CellMark.empty) {
              final colLabels = colSubset.map((c) => '${c + 1}').join(', ');
              final colWord = colSubset.length == 1 ? 'Column' : 'Columns';
              return Hint(
                row: cell.row,
                col: cell.col,
                reason: '$colWord $colLabels can only serve '
                    '${touchingPens.length} pens '
                    '\u2014 this pen must place its bulls there, not here',
              );
            }
          }
        }
      }
    }
  }

  // Rule 6: Look-ahead — placing a bull in this cell would leave no valid
  // spot for the group's remaining bull(s).

  // Helper: check if any cell in [validCells] has no valid partner.
  Hint? lookAhead(
    List<(int, int)> validCells,
    bool Function(int r, int c, int r2, int c2) isPartnerInvalid,
    String reason,
  ) {
    for (final (r, c) in validCells) {
      bool hasPartner = false;
      for (final (r2, c2) in validCells) {
        if (r2 == r && c2 == c) continue;
        if ((r2 - r).abs() <= 1 && (c2 - c).abs() <= 1) continue;
        if (isPartnerInvalid(r, c, r2, c2)) continue;
        hasPartner = true;
        break;
      }
      if (!hasPartner) {
        return Hint(
          row: r,
          col: c,
          reason: 'Placing a bull here would leave no valid spot '
              'for the second bull in $reason',
        );
      }
    }
    return null;
  }

  // Pen look-ahead.
  for (final pen in board.pens) {
    if ((penCounts[pen.id] ?? 0) != 0) continue;

    final validInPen = <(int, int)>[
      for (final cell in pen.cells)
        if (valid[cell.row][cell.col]) (cell.row, cell.col),
    ];

    final hint = lookAhead(validInPen, (r, c, r2, c2) {
      if (r2 == r && rowCounts[r] + 1 >= 2) return true;
      if (c2 == c && colCounts[c] + 1 >= 2) return true;
      return false;
    }, 'this pen');
    if (hint != null) return hint;
  }

  // Row look-ahead.
  for (int r = 0; r < size; r++) {
    if (rowCounts[r] != 0) continue;

    final validInRow = <(int, int)>[
      for (int c = 0; c < size; c++)
        if (valid[r][c]) (r, c),
    ];

    final hint = lookAhead(validInRow, (r, c, r2, c2) {
      if (colCounts[c2] >= 2) return true;
      final penId1 = board.cellAt(r, c).penId;
      final penId2 = board.cellAt(r, c2).penId;
      if (penId1 == penId2 && (penCounts[penId1] ?? 0) + 1 >= 2) return true;
      return false;
    }, 'row ${r + 1}');
    if (hint != null) return hint;
  }

  // Column look-ahead.
  for (int c = 0; c < size; c++) {
    if (colCounts[c] != 0) continue;

    final validInCol = <(int, int)>[
      for (int r = 0; r < size; r++)
        if (valid[r][c]) (r, c),
    ];

    final hint = lookAhead(validInCol, (r, c, r2, c2) {
      if (rowCounts[r2] >= 2) return true;
      final penId1 = board.cellAt(r, c).penId;
      final penId2 = board.cellAt(r2, c).penId;
      if (penId1 == penId2 && (penCounts[penId1] ?? 0) + 1 >= 2) return true;
      return false;
    }, 'column ${c + 1}');
    if (hint != null) return hint;
  }

  // Rule 7: Depth-2 look-ahead — simulate placing a bull at a valid cell,
  // then check if any row, column, or pen becomes impossible (needs k more
  // bulls but has fewer than k valid positions).

  // Pre-compute list of valid cells.
  final validCellList = <(int, int)>[
    for (int r = 0; r < size; r++)
      for (int c = 0; c < size; c++)
        if (valid[r][c]) (r, c),
  ];

  for (final (r, c) in validCellList) {
    // Simulate placing a bull at (r, c) using incremental counts.
    final simPenId = board.cellAt(r, c).penId;
    rowCounts[r]++;
    colCounts[c]++;
    penCounts[simPenId] = (penCounts[simPenId] ?? 0) + 1;

    bool isSimValid(int r2, int c2) {
      if (r2 == r && c2 == c) return false;
      if (!valid[r2][c2]) return false;
      if ((r2 - r).abs() <= 1 && (c2 - c).abs() <= 1) return false;
      return true;
    }

    bool impossible = false;
    String? reason;

    // Check rows.
    for (int r2 = 0; r2 < size && !impossible; r2++) {
      final needed = 2 - rowCounts[r2];
      if (needed <= 0) continue;
      int validCount = 0;
      for (int c2 = 0; c2 < size; c2++) {
        if (isSimValid(r2, c2) &&
            colCounts[c2] < 2 &&
            (penCounts[board.cellAt(r2, c2).penId] ?? 0) < 2) {
          validCount++;
        }
      }
      if (validCount < needed) {
        impossible = true;
        reason = 'Placing a bull here would make row ${r2 + 1} '
            'impossible to fill';
      }
    }

    // Check columns.
    for (int c2 = 0; c2 < size && !impossible; c2++) {
      final needed = 2 - colCounts[c2];
      if (needed <= 0) continue;
      int validCount = 0;
      for (int r2 = 0; r2 < size; r2++) {
        if (isSimValid(r2, c2) &&
            rowCounts[r2] < 2 &&
            (penCounts[board.cellAt(r2, c2).penId] ?? 0) < 2) {
          validCount++;
        }
      }
      if (validCount < needed) {
        impossible = true;
        reason = 'Placing a bull here would make column ${c2 + 1} '
            'impossible to fill';
      }
    }

    // Check pens.
    for (final pen in board.pens) {
      if (impossible) break;
      final needed = 2 - (penCounts[pen.id] ?? 0);
      if (needed <= 0) continue;
      int validCount = 0;
      for (final cell in pen.cells) {
        if (isSimValid(cell.row, cell.col) &&
            rowCounts[cell.row] < 2 &&
            colCounts[cell.col] < 2) {
          validCount++;
        }
      }
      if (validCount < needed) {
        impossible = true;
        reason = 'Placing a bull here would make a pen '
            'impossible to fill';
      }
    }

    // Restore counts.
    rowCounts[r]--;
    colCounts[c]--;
    penCounts[simPenId] = penCounts[simPenId]! - 1;

    if (impossible) {
      return Hint(row: r, col: c, reason: reason!);
    }
  }

  // Rule 8: Forced bull placement — a row/col/pen has exactly k valid
  // positions for k needed bulls. Those positions MUST contain bulls.

  // Helper for simple forced placement.
  Hint? forcedPlacement(
    List<(int, int)> validCells,
    int needed,
    String Function() reasonBuilder,
  ) {
    if (validCells.length != needed) return null;
    for (final (vr, vc) in validCells) {
      return Hint(
        row: vr,
        col: vc,
        type: HintType.mustPlace,
        reason: reasonBuilder(),
      );
    }
    return null;
  }

  for (int r = 0; r < size; r++) {
    final needed = 2 - rowCounts[r];
    if (needed <= 0) continue;
    final cells = [for (int c = 0; c < size; c++) if (valid[r][c]) (r, c)];
    final hint = forcedPlacement(cells, needed, () =>
        'Row ${r + 1} needs $needed more bull${needed > 1 ? 's' : ''} '
        'and this is ${needed == 1 ? 'the only' : 'one of the only $needed'} '
        'valid position${needed > 1 ? 's' : ''}');
    if (hint != null) return hint;
  }

  for (int c = 0; c < size; c++) {
    final needed = 2 - colCounts[c];
    if (needed <= 0) continue;
    final cells = [for (int r = 0; r < size; r++) if (valid[r][c]) (r, c)];
    final hint = forcedPlacement(cells, needed, () =>
        'Column ${c + 1} needs $needed more bull${needed > 1 ? 's' : ''} '
        'and this is ${needed == 1 ? 'the only' : 'one of the only $needed'} '
        'valid position${needed > 1 ? 's' : ''}');
    if (hint != null) return hint;
  }

  for (final pen in board.pens) {
    final needed = 2 - (penCounts[pen.id] ?? 0);
    if (needed <= 0) continue;
    final cells = [
      for (final cell in pen.cells)
        if (valid[cell.row][cell.col]) (cell.row, cell.col),
    ];
    final hint = forcedPlacement(cells, needed, () =>
        'This pen needs $needed more bull${needed > 1 ? 's' : ''} '
        'and this is ${needed == 1 ? 'the only' : 'one of the only $needed'} '
        'valid position${needed > 1 ? 's' : ''}');
    if (hint != null) return hint;
  }

  // Rule 9: Pair-forced placement — when a group needs 2 more bulls,
  // enumerate all valid non-adjacent pairs. If a cell appears in EVERY
  // valid pair, it must contain a bull.

  int findPairForced(List<(int, int)> validCells) {
    if (validCells.length <= 2) return -1;

    final pairs = <(int, int)>[];
    for (int i = 0; i < validCells.length; i++) {
      final (r1, c1) = validCells[i];
      for (int j = i + 1; j < validCells.length; j++) {
        final (r2, c2) = validCells[j];
        if ((r1 - r2).abs() <= 1 && (c1 - c2).abs() <= 1) continue;
        if (r1 == r2 && rowCounts[r1] > 0) continue;
        if (r1 != r2 && (rowCounts[r1] >= 2 || rowCounts[r2] >= 2)) continue;
        if (c1 == c2 && colCounts[c1] > 0) continue;
        if (c1 != c2 && (colCounts[c1] >= 2 || colCounts[c2] >= 2)) continue;
        pairs.add((i, j));
      }
    }

    if (pairs.isEmpty) return -1;
    for (int i = 0; i < validCells.length; i++) {
      if (pairs.every((p) => p.$1 == i || p.$2 == i)) return i;
    }
    return -1;
  }

  Hint? pairForced(List<(int, int)> validCells, String groupName) {
    final idx = findPairForced(validCells);
    if (idx < 0) return null;
    final (vr, vc) = validCells[idx];
    return Hint(
      row: vr,
      col: vc,
      type: HintType.mustPlace,
      reason: 'This cell must be a bull \u2014 it is needed as a partner '
          'for every possible placement in $groupName',
    );
  }

  for (final pen in board.pens) {
    if ((penCounts[pen.id] ?? 0) != 0) continue;
    final cells = [
      for (final cell in pen.cells)
        if (valid[cell.row][cell.col]) (cell.row, cell.col),
    ];
    final hint = pairForced(cells, 'this pen');
    if (hint != null) return hint;
  }

  for (int r = 0; r < size; r++) {
    if (rowCounts[r] != 0) continue;
    final cells = [for (int c = 0; c < size; c++) if (valid[r][c]) (r, c)];
    final hint = pairForced(cells, 'row ${r + 1}');
    if (hint != null) return hint;
  }

  for (int c = 0; c < size; c++) {
    if (colCounts[c] != 0) continue;
    final cells = [for (int r = 0; r < size; r++) if (valid[r][c]) (r, c)];
    final hint = pairForced(cells, 'column ${c + 1}');
    if (hint != null) return hint;
  }

  return null;
}
