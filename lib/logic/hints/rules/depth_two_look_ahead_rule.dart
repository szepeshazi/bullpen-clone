import 'package:bullpen/logic/hints/hint.dart';
import 'package:bullpen/logic/hints/hint_context.dart';
import 'package:bullpen/logic/hints/hint_rule.dart';

/// Simulates placing a bull at each valid cell and checks whether any
/// row/column/pen then becomes provably infeasible. Mutates context counts
/// temporarily and restores them afterwards.
class DepthTwoLookAheadRule extends HintRule {
  const DepthTwoLookAheadRule();

  @override
  Hint? evaluate(HintContext ctx) {
    final cells = _validCells(ctx);

    for (final (r, c) in cells) {
      if (ctx.essential.contains((r, c))) continue;
      final hint = _trySimulate(ctx, r, c);
      if (hint != null) return hint;
    }
    return null;
  }

  List<(int, int)> _validCells(HintContext ctx) => [
    for (int r = 0; r < ctx.size; r++)
      for (int c = 0; c < ctx.size; c++)
        if (ctx.valid[r][c]) (r, c),
  ];

  Hint? _trySimulate(HintContext ctx, int r, int c) {
    final simPenId = ctx.board.cellAt(r, c).penId;
    ctx.rowCounts[r]++;
    ctx.colCounts[c]++;
    ctx.penCounts[simPenId] = (ctx.penCounts[simPenId] ?? 0) + 1;

    try {
      final reason = _firstImpossibility(ctx, r, c);
      if (reason != null) return Hint(row: r, col: c, reason: reason);
      return null;
    } finally {
      ctx.rowCounts[r]--;
      ctx.colCounts[c]--;
      ctx.penCounts[simPenId] = ctx.penCounts[simPenId]! - 1;
    }
  }

  String? _firstImpossibility(HintContext ctx, int r, int c) {
    bool simValid(int r2, int c2) {
      if (r2 == r && c2 == c) return false;
      if (!ctx.valid[r2][c2]) return false;
      if ((r2 - r).abs() <= 1 && (c2 - c).abs() <= 1) return false;
      return true;
    }

    for (var r2 = 0; r2 < ctx.size; r2++) {
      final needed = 2 - ctx.rowCounts[r2];
      if (needed <= 0) continue;
      final candidates = <(int, int)>[
        for (int c2 = 0; c2 < ctx.size; c2++)
          if (simValid(r2, c2) &&
              ctx.colCounts[c2] < 2 &&
              (ctx.penCounts[ctx.board.cellAt(r2, c2).penId] ?? 0) < 2)
            (r2, c2),
      ];
      if (!_hasFeasiblePlacement(ctx, candidates, needed)) {
        return 'Placing a bull here would make row ${r2 + 1} '
            'impossible to fill';
      }
    }

    for (var c2 = 0; c2 < ctx.size; c2++) {
      final needed = 2 - ctx.colCounts[c2];
      if (needed <= 0) continue;
      final candidates = <(int, int)>[
        for (int r2 = 0; r2 < ctx.size; r2++)
          if (simValid(r2, c2) &&
              ctx.rowCounts[r2] < 2 &&
              (ctx.penCounts[ctx.board.cellAt(r2, c2).penId] ?? 0) < 2)
            (r2, c2),
      ];
      if (!_hasFeasiblePlacement(ctx, candidates, needed)) {
        return 'Placing a bull here would make column ${c2 + 1} '
            'impossible to fill';
      }
    }

    for (final pen in ctx.board.pens) {
      final needed = 2 - (ctx.penCounts[pen.id] ?? 0);
      if (needed <= 0) continue;
      final candidates = <(int, int)>[
        for (final cell in pen.cells)
          if (simValid(cell.row, cell.col) &&
              ctx.rowCounts[cell.row] < 2 &&
              ctx.colCounts[cell.col] < 2)
            (cell.row, cell.col),
      ];
      if (!_hasFeasiblePlacement(ctx, candidates, needed)) {
        return 'Placing a bull here would make a pen impossible to fill';
      }
    }

    return null;
  }

  bool _hasFeasiblePlacement(
    HintContext ctx,
    List<(int, int)> candidates,
    int needed,
  ) {
    if (candidates.length < needed) return false;
    if (needed <= 1) return true;
    for (var i = 0; i < candidates.length; i++) {
      final (r1, c1) = candidates[i];
      for (var j = i + 1; j < candidates.length; j++) {
        final (r2, c2) = candidates[j];
        if ((r1 - r2).abs() <= 1 && (c1 - c2).abs() <= 1) continue;
        if (r1 == r2 && ctx.rowCounts[r1] + 2 > 2) continue;
        if (r1 != r2 && (ctx.rowCounts[r1] >= 2 || ctx.rowCounts[r2] >= 2)) {
          continue;
        }
        if (c1 == c2 && ctx.colCounts[c1] + 2 > 2) continue;
        if (c1 != c2 && (ctx.colCounts[c1] >= 2 || ctx.colCounts[c2] >= 2)) {
          continue;
        }
        final p1 = ctx.board.cellAt(r1, c1).penId;
        final p2 = ctx.board.cellAt(r2, c2).penId;
        if (p1 == p2 && (ctx.penCounts[p1] ?? 0) + 2 > 2) continue;
        if (p1 != p2 &&
            ((ctx.penCounts[p1] ?? 0) >= 2 || (ctx.penCounts[p2] ?? 0) >= 2)) {
          continue;
        }
        return true;
      }
    }
    return false;
  }
}
