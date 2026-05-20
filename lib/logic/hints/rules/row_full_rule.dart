import '../../../cubit/game_state.dart';
import '../hint.dart';
import '../hint_context.dart';
import '../hint_rule.dart';

/// Row already holds 2 bulls → any remaining empty cell in it can be excluded.
class RowFullRule extends HintRule {
  const RowFullRule();

  @override
  Hint? evaluate(HintContext ctx) {
    for (int r = 0; r < ctx.size; r++) {
      if (ctx.rowCounts[r] < 2) continue;
      for (int c = 0; c < ctx.size; c++) {
        if (ctx.marks[r][c] == CellMark.empty) {
          return Hint(
            row: r,
            col: c,
            reason: 'This row already has 2 bulls',
          );
        }
      }
    }
    return null;
  }
}
