import '../hint.dart';
import '../hint_context.dart';
import '../hint_rule.dart';

/// Group needs k more bulls and has exactly k valid positions left → those
/// positions must contain bulls.
class ForcedPlacementRule extends HintRule {
  const ForcedPlacementRule();

  @override
  Hint? evaluate(HintContext ctx) {
    for (int r = 0; r < ctx.size; r++) {
      final needed = 2 - ctx.rowCounts[r];
      if (needed <= 0) continue;
      final cells = [
        for (int c = 0; c < ctx.size; c++)
          if (ctx.valid[r][c]) (r, c),
      ];
      final hint = _firstForced(cells, needed, () => _rowReason(r, needed));
      if (hint != null) return hint;
    }

    for (int c = 0; c < ctx.size; c++) {
      final needed = 2 - ctx.colCounts[c];
      if (needed <= 0) continue;
      final cells = [
        for (int r = 0; r < ctx.size; r++)
          if (ctx.valid[r][c]) (r, c),
      ];
      final hint = _firstForced(cells, needed, () => _colReason(c, needed));
      if (hint != null) return hint;
    }

    for (final pen in ctx.board.pens) {
      final needed = 2 - (ctx.penCounts[pen.id] ?? 0);
      if (needed <= 0) continue;
      final cells = [
        for (final cell in pen.cells)
          if (ctx.valid[cell.row][cell.col]) (cell.row, cell.col),
      ];
      final hint = _firstForced(cells, needed, () => _penReason(needed));
      if (hint != null) return hint;
    }

    return null;
  }

  Hint? _firstForced(
    List<(int, int)> validCells,
    int needed,
    String Function() reasonBuilder,
  ) {
    if (validCells.length != needed) return null;
    final (r, c) = validCells.first;
    return Hint(
      row: r,
      col: c,
      type: HintType.mustPlace,
      reason: reasonBuilder(),
    );
  }

  String _rowReason(int r, int needed) =>
      'Row ${r + 1} needs $needed more bull${needed > 1 ? 's' : ''} '
      'and this is ${needed == 1 ? 'the only' : 'one of the only $needed'} '
      'valid position${needed > 1 ? 's' : ''}';

  String _colReason(int c, int needed) =>
      'Column ${c + 1} needs $needed more bull${needed > 1 ? 's' : ''} '
      'and this is ${needed == 1 ? 'the only' : 'one of the only $needed'} '
      'valid position${needed > 1 ? 's' : ''}';

  String _penReason(int needed) =>
      'This pen needs $needed more bull${needed > 1 ? 's' : ''} '
      'and this is ${needed == 1 ? 'the only' : 'one of the only $needed'} '
      'valid position${needed > 1 ? 's' : ''}';
}
