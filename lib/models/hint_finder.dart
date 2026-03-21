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

/// Yields all combinations of [k] elements from [items].
Iterable<List<int>> _combinations(List<int> items, int k) sync* {
  if (k == 0) {
    yield [];
    return;
  }
  for (int i = 0; i <= items.length - k; i++) {
    for (final rest in _combinations(items.sublist(i + 1), k - 1)) {
      yield [items[i], ...rest];
    }
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

  // Rule 5: Forced cells — a row/col/pen needs k more bulls and exactly k
  // valid (empty + not adjacent to bull) positions remain → every OTHER empty
  // cell in that group is excludable.

  bool isValid(int r, int c) {
    return marks[r][c] == CellMark.empty &&
        !hasAdjacentMatch(
            r, c, size, (nr, nc) => marks[nr][nc] == CellMark.bull);
  }

  // Pre-compute valid rows/cols per pen for naked-set detection.
  final penValidRows = <int, Set<int>>{};
  final penValidCols = <int, Set<int>>{};
  for (final pen in board.pens) {
    final rows = <int>{};
    final cols = <int>{};
    for (final cell in pen.cells) {
      if (isValid(cell.row, cell.col)) {
        rows.add(cell.row);
        cols.add(cell.col);
      }
    }
    penValidRows[pen.id] = rows;
    penValidCols[pen.id] = cols;
  }
  final activeRows = [for (int r = 0; r < size; r++) if (rowCounts[r] < 2) r];
  final activeCols = [for (int c = 0; c < size; c++) if (colCounts[c] < 2) c];

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

  // Rule 6: Naked sets (pigeonhole) — if N pens are fully contained within
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

      // Find pens fully contained within this row subset.
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
        // All capacity is spoken for — exclude cells from other pens.
        for (final r in rowSubset) {
          for (int c = 0; c < size; c++) {
            if (marks[r][c] == CellMark.empty &&
                !containedPenIds.contains(board.cellAt(r, c).penId)) {
              final rowLabels =
                  rowSubset.map((r) => '${r + 1}').join(', ');
              final nPens = containedPenIds.length;
              final rowWord = rowSubset.length == 1 ? 'Row' : 'Rows';
              final penWord = nPens == 1 ? 'pen' : 'pens';
              final rowRef = rowSubset.length == 1 ? 'it' : 'them';
              return Hint(
                row: r,
                col: c,
                reason:
                    '$rowWord $rowLabels must supply all bulls for '
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
              final colLabels =
                  colSubset.map((c) => '${c + 1}').join(', ');
              final nPens = containedPenIds.length;
              final colWord = colSubset.length == 1 ? 'Column' : 'Columns';
              final penWord = nPens == 1 ? 'pen' : 'pens';
              final colRef = colSubset.length == 1 ? 'it' : 'them';
              return Hint(
                row: r,
                col: c,
                reason:
                    '$colWord $colLabels must supply all bulls for '
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

  // Rule 6b: Hidden sets — if N rows can only serve N pens (every valid cell
  // in those rows belongs to one of those N pens), then those pens must place
  // all their bulls within those rows. Exclude those pens' cells outside.

  // Pre-compute: for each active row, which pens have valid cells in it.
  final rowToPens = <int, Set<int>>{};
  for (final r in activeRows) {
    final pens = <int>{};
    for (int c = 0; c < size; c++) {
      if (isValid(r, c)) pens.add(board.cellAt(r, c).penId);
    }
    rowToPens[r] = pens;
  }
  final colToPens = <int, Set<int>>{};
  for (final c in activeCols) {
    final pens = <int>{};
    for (int r = 0; r < size; r++) {
      if (isValid(r, c)) pens.add(board.cellAt(r, c).penId);
    }
    colToPens[c] = pens;
  }

  // Row hidden sets.
  for (int subsetSize = 1;
      subsetSize <= activeRows.length && subsetSize <= (size ~/ 2);
      subsetSize++) {
    for (final rowSubset in _combinations(activeRows, subsetSize)) {
      // Union of pens that have valid cells in these rows.
      final touchingPens = <int>{};
      for (final r in rowSubset) {
        touchingPens.addAll(rowToPens[r] ?? {});
      }

      final remainingCapacity =
          rowSubset.fold<int>(0, (sum, r) => sum + 2 - rowCounts[r]);
      final remainingNeed = touchingPens.fold<int>(
          0, (sum, penId) => sum + 2 - (penCounts[penId] ?? 0));

      if (touchingPens.length >= 2 &&
          remainingNeed == remainingCapacity) {
        // These pens are locked to these rows. Exclude their cells elsewhere.
        final rowSet = rowSubset.toSet();
        for (final penId in touchingPens) {
          final pen = board.penById(penId);
          for (final cell in pen.cells) {
            if (!rowSet.contains(cell.row) &&
                marks[cell.row][cell.col] == CellMark.empty) {
              final rowLabels =
                  rowSubset.map((r) => '${r + 1}').join(', ');
              final rowWord = rowSubset.length == 1 ? 'Row' : 'Rows';
              return Hint(
                row: cell.row,
                col: cell.col,
                reason:
                    '$rowWord $rowLabels can only serve '
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

      if (touchingPens.length >= 2 &&
          remainingNeed == remainingCapacity) {
        final colSet = colSubset.toSet();
        for (final penId in touchingPens) {
          final pen = board.penById(penId);
          for (final cell in pen.cells) {
            if (!colSet.contains(cell.col) &&
                marks[cell.row][cell.col] == CellMark.empty) {
              final colLabels =
                  colSubset.map((c) => '${c + 1}').join(', ');
              final colWord = colSubset.length == 1 ? 'Column' : 'Columns';
              return Hint(
                row: cell.row,
                col: cell.col,
                reason:
                    '$colWord $colLabels can only serve '
                    '${touchingPens.length} pens '
                    '\u2014 this pen must place its bulls there, not here',
              );
            }
          }
        }
      }
    }
  }

  // Rule 7: Pen look-ahead — placing a bull in this cell would leave no valid
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
        // Partner's row already full → invalid partner.
        if (r2 != r && rowCounts[r2] >= 2) continue;
        // Partner's col already full → invalid partner.
        if (c2 != c && colCounts[c2] >= 2) continue;
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

  // Rule 8: Row look-ahead — placing a bull here would leave no valid spot
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
      final penId1 = board.cellAt(r, c).penId;
      for (final (_, c2) in validInRow) {
        if (c2 == c) continue;
        // Adjacent in same row → invalid partner.
        if ((c2 - c).abs() <= 1) continue;
        // Partner's column already full → invalid partner.
        if (colCounts[c2] >= 2) continue;
        // Partner's pen constraint.
        final penId2 = board.cellAt(r, c2).penId;
        if (penId1 == penId2) {
          // Same pen — would be full after placing at (r, c).
          if ((penCounts[penId1] ?? 0) + 1 >= 2) continue;
        } else {
          // Different pen — already full.
          if ((penCounts[penId2] ?? 0) >= 2) continue;
        }
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

  // Rule 9: Column look-ahead — placing a bull here would leave no valid spot
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
      final penId1 = board.cellAt(r, c).penId;
      for (final (r2, _) in validInCol) {
        if (r2 == r) continue;
        // Adjacent in same column → invalid partner.
        if ((r2 - r).abs() <= 1) continue;
        // Partner's row already full → invalid partner.
        if (rowCounts[r2] >= 2) continue;
        // Partner's pen constraint.
        final penId2 = board.cellAt(r2, c).penId;
        if (penId1 == penId2) {
          // Same pen — would be full after placing at (r, c).
          if ((penCounts[penId1] ?? 0) + 1 >= 2) continue;
        } else {
          // Different pen — already full.
          if ((penCounts[penId2] ?? 0) >= 2) continue;
        }
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

  // Rule 10: Depth-2 look-ahead — simulate placing a bull at a valid cell,
  // then check if any row, column, or pen becomes impossible (needs k more
  // bulls but has fewer than k valid positions after accounting for the
  // simulated placement and its adjacency exclusions).
  for (int r = 0; r < size; r++) {
    for (int c = 0; c < size; c++) {
      if (!isValid(r, c)) continue;

      // Simulate placing a bull at (r, c).
      // A cell is "sim-valid" if it's currently valid AND not adjacent to
      // the simulated bull AND respects updated row/col/pen counts.
      bool isSimValid(int r2, int c2) {
        if (r2 == r && c2 == c) return false;
        if (!isValid(r2, c2)) return false;
        // Adjacent to simulated bull.
        if ((r2 - r).abs() <= 1 && (c2 - c).abs() <= 1) return false;
        return true;
      }

      final simRowCount = List.of(rowCounts);
      final simColCount = List.of(colCounts);
      final simPenCount = Map.of(penCounts);
      simRowCount[r]++;
      simColCount[c]++;
      final simPenId = board.cellAt(r, c).penId;
      simPenCount[simPenId] = (simPenCount[simPenId] ?? 0) + 1;

      bool impossible = false;
      String? reason;

      // Check rows.
      for (int r2 = 0; r2 < size && !impossible; r2++) {
        final needed = 2 - simRowCount[r2];
        if (needed <= 0) continue;
        int validCount = 0;
        for (int c2 = 0; c2 < size; c2++) {
          if (isSimValid(r2, c2) &&
              simColCount[c2] < 2 &&
              (simPenCount[board.cellAt(r2, c2).penId] ?? 0) < 2) {
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
        final needed = 2 - simColCount[c2];
        if (needed <= 0) continue;
        int validCount = 0;
        for (int r2 = 0; r2 < size; r2++) {
          if (isSimValid(r2, c2) &&
              simRowCount[r2] < 2 &&
              (simPenCount[board.cellAt(r2, c2).penId] ?? 0) < 2) {
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
        final needed = 2 - (simPenCount[pen.id] ?? 0);
        if (needed <= 0) continue;
        int validCount = 0;
        for (final cell in pen.cells) {
          if (isSimValid(cell.row, cell.col) &&
              simRowCount[cell.row] < 2 &&
              simColCount[cell.col] < 2) {
            validCount++;
          }
        }
        if (validCount < needed) {
          impossible = true;
          reason = 'Placing a bull here would make a pen '
              'impossible to fill';
        }
      }

      if (impossible) {
        return Hint(row: r, col: c, reason: reason!);
      }
    }
  }

  // Rule 11: Forced bull placement — when no exclusion hint is available,
  // check if any row, column, or pen has exactly k valid positions for k
  // needed bulls. Those positions MUST contain bulls.

  // Row forced placement.
  for (int r = 0; r < size; r++) {
    final needed = 2 - rowCounts[r];
    if (needed <= 0) continue;

    final validCells = <(int, int)>[
      for (int c = 0; c < size; c++)
        if (isValid(r, c)) (r, c),
    ];

    if (validCells.length == needed) {
      for (final (vr, vc) in validCells) {
        if (marks[vr][vc] == CellMark.empty) {
          return Hint(
            row: vr,
            col: vc,
            type: HintType.mustPlace,
            reason:
                'Row ${r + 1} needs $needed more bull${needed > 1 ? 's' : ''} '
                'and this is ${needed == 1 ? 'the only' : 'one of the only $needed'} '
                'valid position${needed > 1 ? 's' : ''}',
          );
        }
      }
    }
  }

  // Column forced placement.
  for (int c = 0; c < size; c++) {
    final needed = 2 - colCounts[c];
    if (needed <= 0) continue;

    final validCells = <(int, int)>[
      for (int r = 0; r < size; r++)
        if (isValid(r, c)) (r, c),
    ];

    if (validCells.length == needed) {
      for (final (vr, vc) in validCells) {
        if (marks[vr][vc] == CellMark.empty) {
          return Hint(
            row: vr,
            col: vc,
            type: HintType.mustPlace,
            reason:
                'Column ${c + 1} needs $needed more bull${needed > 1 ? 's' : ''} '
                'and this is ${needed == 1 ? 'the only' : 'one of the only $needed'} '
                'valid position${needed > 1 ? 's' : ''}',
          );
        }
      }
    }
  }

  // Pen forced placement.
  for (final pen in board.pens) {
    final needed = 2 - (penCounts[pen.id] ?? 0);
    if (needed <= 0) continue;

    final validCells = <(int, int)>[
      for (final cell in pen.cells)
        if (isValid(cell.row, cell.col)) (cell.row, cell.col),
    ];

    if (validCells.length == needed) {
      for (final (vr, vc) in validCells) {
        if (marks[vr][vc] == CellMark.empty) {
          return Hint(
            row: vr,
            col: vc,
            type: HintType.mustPlace,
            reason:
                'This pen needs $needed more bull${needed > 1 ? 's' : ''} '
                'and this is ${needed == 1 ? 'the only' : 'one of the only $needed'} '
                'valid position${needed > 1 ? 's' : ''}',
          );
        }
      }
    }
  }

  // Rule 12: Pair-forced placement — when a group needs 2 more bulls and has
  // more than 2 valid cells, enumerate all valid non-adjacent pairs. If a cell
  // appears in EVERY valid pair, it must contain a bull (e.g., a pen with 3
  // valid cells where 2 are adjacent — the isolated cell is forced).

  // Helper: find valid pairs for a list of valid cells needing 2 bulls.
  // Returns the index of a cell that appears in ALL pairs, or -1.
  int findPairForced(List<(int, int)> validCells) {
    if (validCells.length <= 2) return -1; // Already handled by Rule 11.

    // Enumerate valid pairs.
    final pairs = <(int, int)>[];
    for (int i = 0; i < validCells.length; i++) {
      final (r1, c1) = validCells[i];
      for (int j = i + 1; j < validCells.length; j++) {
        final (r2, c2) = validCells[j];
        // Adjacent → invalid pair.
        if ((r1 - r2).abs() <= 1 && (c1 - c2).abs() <= 1) continue;
        // Same row, row must have room for 2 more.
        if (r1 == r2 && rowCounts[r1] > 0) continue;
        // Different rows, each must have room.
        if (r1 != r2 && (rowCounts[r1] >= 2 || rowCounts[r2] >= 2)) continue;
        // Same column, column must have room for 2 more.
        if (c1 == c2 && colCounts[c1] > 0) continue;
        // Different columns, each must have room.
        if (c1 != c2 && (colCounts[c1] >= 2 || colCounts[c2] >= 2)) continue;
        // Same pen is fine (we're within one group's analysis).
        pairs.add((i, j));
      }
    }

    if (pairs.isEmpty) return -1;

    // Find a cell index that appears in every pair.
    for (int i = 0; i < validCells.length; i++) {
      if (pairs.every((p) => p.$1 == i || p.$2 == i)) {
        return i;
      }
    }
    return -1;
  }

  // Pen pair-forced.
  for (final pen in board.pens) {
    final needed = 2 - (penCounts[pen.id] ?? 0);
    if (needed != 2) continue;

    final validCells = <(int, int)>[
      for (final cell in pen.cells)
        if (isValid(cell.row, cell.col)) (cell.row, cell.col),
    ];

    final idx = findPairForced(validCells);
    if (idx >= 0) {
      final (vr, vc) = validCells[idx];
      return Hint(
        row: vr,
        col: vc,
        type: HintType.mustPlace,
        reason: 'This cell must be a bull \u2014 it is needed as a partner '
            'for every possible placement in this pen',
      );
    }
  }

  // Row pair-forced.
  for (int r = 0; r < size; r++) {
    final needed = 2 - rowCounts[r];
    if (needed != 2) continue;

    final validCells = <(int, int)>[
      for (int c = 0; c < size; c++)
        if (isValid(r, c)) (r, c),
    ];

    final idx = findPairForced(validCells);
    if (idx >= 0) {
      final (vr, vc) = validCells[idx];
      return Hint(
        row: vr,
        col: vc,
        type: HintType.mustPlace,
        reason: 'This cell must be a bull \u2014 it is needed as a partner '
            'for every possible placement in row ${r + 1}',
      );
    }
  }

  // Column pair-forced.
  for (int c = 0; c < size; c++) {
    final needed = 2 - colCounts[c];
    if (needed != 2) continue;

    final validCells = <(int, int)>[
      for (int r = 0; r < size; r++)
        if (isValid(r, c)) (r, c),
    ];

    final idx = findPairForced(validCells);
    if (idx >= 0) {
      final (vr, vc) = validCells[idx];
      return Hint(
        row: vr,
        col: vc,
        type: HintType.mustPlace,
        reason: 'This cell must be a bull \u2014 it is needed as a partner '
            'for every possible placement in column ${c + 1}',
      );
    }
  }

  return null;
}
