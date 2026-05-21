import 'package:bullpen/cubit/game_state.dart';
import 'package:bullpen/logic/hints/hint.dart';
import 'package:bullpen/logic/hints/hint_context.dart';
import 'package:bullpen/logic/hints/hint_rule.dart';
import 'package:bullpen/logic/hints/rules/adjacency_rule.dart';
import 'package:bullpen/logic/hints/rules/column_full_rule.dart';
import 'package:bullpen/logic/hints/rules/depth_two_look_ahead_rule.dart';
import 'package:bullpen/logic/hints/rules/forced_placement_rule.dart';
import 'package:bullpen/logic/hints/rules/hidden_set_rule.dart';
import 'package:bullpen/logic/hints/rules/look_ahead_rule.dart';
import 'package:bullpen/logic/hints/rules/naked_set_rule.dart';
import 'package:bullpen/logic/hints/rules/pair_forced_rule.dart';
import 'package:bullpen/logic/hints/rules/pen_full_rule.dart';
import 'package:bullpen/logic/hints/rules/row_full_rule.dart';
import 'package:bullpen/models/puzzle_board.dart';

/// Runs hint rules in priority order; returns the first match.
class HintEngine {
  final List<HintRule> rules;

  const HintEngine(this.rules);

  /// Default rule set in the order findHint historically evaluated them.
  HintEngine.defaultRules()
    : rules = const [
        RowFullRule(),
        ColumnFullRule(),
        PenFullRule(),
        AdjacencyRule(),
        NakedSetRule(),
        HiddenSetRule(),
        LookAheadRule(),
        DepthTwoLookAheadRule(),
        ForcedPlacementRule(),
        PairForcedRule(),
      ];

  Hint? findHint(PuzzleBoard board, List<List<CellMark>> marks) {
    final ctx = HintContext.build(board, marks);
    for (final rule in rules) {
      final hint = rule.evaluate(ctx);
      if (hint != null) return hint;
    }
    return null;
  }
}
