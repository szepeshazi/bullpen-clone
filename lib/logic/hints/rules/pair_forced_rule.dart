import 'package:bullpen/logic/hints/hint.dart';
import 'package:bullpen/logic/hints/hint_context.dart';

/// Group needs 2 more bulls; if a cell appears in every valid non-adjacent
/// pair, it must contain a bull.
Hint? pairForcedRule(HintContext ctx) {
  for (final pen in ctx.board.pens) {
    if ((ctx.penCounts[pen.id] ?? 0) != 0) {
      continue;
    }
    final cells = [
      for (final cell in pen.cells)
        if (ctx.valid[cell.row][cell.col]) (cell.row, cell.col),
    ];
    final hint = _check(ctx, cells, 'this pen');
    if (hint != null) {
      return hint;
    }
  }

  for (var r = 0; r < ctx.size; r++) {
    if (ctx.rowCounts[r] != 0) {
      continue;
    }
    final cells = [
      for (int c = 0; c < ctx.size; c++)
        if (ctx.valid[r][c]) (r, c),
    ];
    final hint = _check(ctx, cells, 'row ${r + 1}');
    if (hint != null) {
      return hint;
    }
  }

  for (var c = 0; c < ctx.size; c++) {
    if (ctx.colCounts[c] != 0) {
      continue;
    }
    final cells = [
      for (int r = 0; r < ctx.size; r++)
        if (ctx.valid[r][c]) (r, c),
    ];
    final hint = _check(ctx, cells, 'column ${c + 1}');
    if (hint != null) {
      return hint;
    }
  }
  return null;
}

Hint? _check(HintContext ctx, List<(int, int)> validCells, String group) {
  final idx = _findForcedIndex(ctx, validCells);
  if (idx < 0) {
    return null;
  }
  final (r, c) = validCells[idx];
  return Hint(
    row: r,
    col: c,
    type: HintType.mustPlace,
    reason:
        'This cell must be a bull — it is needed as a partner '
        'for every possible placement in $group',
  );
}

int _findForcedIndex(HintContext ctx, List<(int, int)> validCells) {
  if (validCells.length <= 2) {
    return -1;
  }

  final pairs = <(int, int)>[];
  for (var i = 0; i < validCells.length; i++) {
    final (r1, c1) = validCells[i];
    for (var j = i + 1; j < validCells.length; j++) {
      final (r2, c2) = validCells[j];
      if ((r1 - r2).abs() <= 1 && (c1 - c2).abs() <= 1) {
        continue;
      }
      if (r1 == r2 && ctx.rowCounts[r1] > 0) {
        continue;
      }
      if (r1 != r2 && (ctx.rowCounts[r1] >= 2 || ctx.rowCounts[r2] >= 2)) {
        continue;
      }
      if (c1 == c2 && ctx.colCounts[c1] > 0) {
        continue;
      }
      if (c1 != c2 && (ctx.colCounts[c1] >= 2 || ctx.colCounts[c2] >= 2)) {
        continue;
      }
      pairs.add((i, j));
    }
  }
  if (pairs.isEmpty) {
    return -1;
  }
  for (var i = 0; i < validCells.length; i++) {
    if (pairs.every((p) => p.$1 == i || p.$2 == i)) {
      return i;
    }
  }
  return -1;
}
