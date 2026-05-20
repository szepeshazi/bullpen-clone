import '../../../cubit/game_state.dart';
import '../hint.dart';
import '../hint_context.dart';
import '../hint_rule.dart';

/// Pen already holds 2 bulls → exclude remaining empty cells in it.
class PenFullRule extends HintRule {
  const PenFullRule();

  @override
  Hint? evaluate(HintContext ctx) {
    for (final pen in ctx.board.pens) {
      if ((ctx.penCounts[pen.id] ?? 0) < 2) continue;
      for (final cell in pen.cells) {
        if (ctx.marks[cell.row][cell.col] == CellMark.empty) {
          return Hint(
            row: cell.row,
            col: cell.col,
            reason: 'This pen already has 2 bulls',
          );
        }
      }
    }
    return null;
  }
}
