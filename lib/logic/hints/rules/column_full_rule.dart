import 'package:bullpen/cubit/game_state.dart';
import 'package:bullpen/logic/hints/hint.dart';
import 'package:bullpen/logic/hints/hint_context.dart';
import 'package:bullpen/logic/hints/hint_rule.dart';

/// Column already holds 2 bulls → exclude remaining empty cells.
class ColumnFullRule extends HintRule {
  const ColumnFullRule();

  @override
  Hint? evaluate(HintContext ctx) {
    for (var c = 0; c < ctx.size; c++) {
      if (ctx.colCounts[c] < 2) continue;
      for (var r = 0; r < ctx.size; r++) {
        if (ctx.marks[r][c] == CellMark.empty) {
          return Hint(
            row: r,
            col: c,
            reason: 'This column already has 2 bulls',
          );
        }
      }
    }
    return null;
  }
}
