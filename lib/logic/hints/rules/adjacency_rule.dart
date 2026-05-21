import 'package:bullpen/cubit/game_state.dart';
import 'package:bullpen/logic/hints/hint.dart';
import 'package:bullpen/logic/hints/hint_context.dart';
import 'package:bullpen/models/adjacency.dart';

/// Empty cell sits next to an existing bull (any of 8 neighbours) → exclude it.
Hint? adjacencyRule(HintContext ctx) {
  for (var r = 0; r < ctx.size; r++) {
    for (var c = 0; c < ctx.size; c++) {
      if (ctx.marks[r][c] != CellMark.empty) {
        continue;
      }
      final hasBullNeighbour = hasAdjacentMatch(
        r,
        c,
        ctx.size,
        (nr, nc) => ctx.marks[nr][nc] == CellMark.bull,
      );
      if (hasBullNeighbour) {
        return Hint(
          row: r,
          col: c,
          reason: 'This cell is adjacent to an existing bull',
        );
      }
    }
  }
  return null;
}
