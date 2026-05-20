import '../hint.dart';
import '../hint_context.dart';
import '../hint_rule.dart';

/// Placing a bull at this cell would leave no valid spot for the group's
/// remaining bull(s). Checks pen, row, and column groups in turn.
class LookAheadRule extends HintRule {
  const LookAheadRule();

  @override
  Hint? evaluate(HintContext ctx) {
    return _penLookAhead(ctx) ??
        _rowLookAhead(ctx) ??
        _colLookAhead(ctx);
  }

  Hint? _penLookAhead(HintContext ctx) {
    for (final pen in ctx.board.pens) {
      if ((ctx.penCounts[pen.id] ?? 0) != 0) continue;
      final valid = <(int, int)>[
        for (final cell in pen.cells)
          if (ctx.valid[cell.row][cell.col]) (cell.row, cell.col),
      ];
      final hint = _scan(ctx, valid, (r, c, r2, c2) {
        if (r2 == r && ctx.rowCounts[r] + 1 >= 2) return true;
        if (c2 == c && ctx.colCounts[c] + 1 >= 2) return true;
        return false;
      }, 'this pen');
      if (hint != null) return hint;
    }
    return null;
  }

  Hint? _rowLookAhead(HintContext ctx) {
    for (int r = 0; r < ctx.size; r++) {
      if (ctx.rowCounts[r] != 0) continue;
      final valid = <(int, int)>[
        for (int c = 0; c < ctx.size; c++)
          if (ctx.valid[r][c]) (r, c),
      ];
      final hint = _scan(ctx, valid, (r, c, r2, c2) {
        if (ctx.colCounts[c2] >= 2) return true;
        final p1 = ctx.board.cellAt(r, c).penId;
        final p2 = ctx.board.cellAt(r, c2).penId;
        if (p1 == p2 && (ctx.penCounts[p1] ?? 0) + 1 >= 2) return true;
        return false;
      }, 'row ${r + 1}');
      if (hint != null) return hint;
    }
    return null;
  }

  Hint? _colLookAhead(HintContext ctx) {
    for (int c = 0; c < ctx.size; c++) {
      if (ctx.colCounts[c] != 0) continue;
      final valid = <(int, int)>[
        for (int r = 0; r < ctx.size; r++)
          if (ctx.valid[r][c]) (r, c),
      ];
      final hint = _scan(ctx, valid, (r, c, r2, c2) {
        if (ctx.rowCounts[r2] >= 2) return true;
        final p1 = ctx.board.cellAt(r, c).penId;
        final p2 = ctx.board.cellAt(r2, c).penId;
        if (p1 == p2 && (ctx.penCounts[p1] ?? 0) + 1 >= 2) return true;
        return false;
      }, 'column ${c + 1}');
      if (hint != null) return hint;
    }
    return null;
  }

  Hint? _scan(
    HintContext ctx,
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
      if (!hasPartner && !ctx.essential.contains((r, c))) {
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
}
