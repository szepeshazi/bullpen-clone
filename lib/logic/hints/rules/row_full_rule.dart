import 'package:bullpen/cubit/game_state.dart';
import 'package:bullpen/logic/hints/hint.dart';
import 'package:bullpen/logic/hints/hint_context.dart';

/// Row already holds 2 bulls → any remaining empty cell in it can be excluded.
Hint? rowFullRule(HintContext ctx) {
  for (var r = 0; r < ctx.size; r++) {
    if (ctx.rowCounts[r] < 2) {
      continue;
    }
    for (var c = 0; c < ctx.size; c++) {
      if (ctx.marks[r][c] == CellMark.empty) {
        return Hint(row: r, col: c, reason: 'This row already has 2 bulls');
      }
    }
  }
  return null;
}
