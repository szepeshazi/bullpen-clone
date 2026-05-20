import '../../../cubit/game_state.dart';
import '../../../models/adjacency.dart';
import '../hint.dart';
import '../hint_context.dart';
import '../hint_rule.dart';

/// Empty cell sits next to an existing bull (any of 8 neighbours) → exclude it.
class AdjacencyRule extends HintRule {
  const AdjacencyRule();

  @override
  Hint? evaluate(HintContext ctx) {
    for (int r = 0; r < ctx.size; r++) {
      for (int c = 0; c < ctx.size; c++) {
        if (ctx.marks[r][c] != CellMark.empty) continue;
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
}
