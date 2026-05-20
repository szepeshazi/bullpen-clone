import '../../cubit/game_state.dart';
import '../../models/puzzle_board.dart';
import 'hint.dart';
import 'hint_context.dart';
import 'hint_rule.dart';
import 'rules/adjacency_rule.dart';
import 'rules/column_full_rule.dart';
import 'rules/depth_two_look_ahead_rule.dart';
import 'rules/forced_placement_rule.dart';
import 'rules/hidden_set_rule.dart';
import 'rules/look_ahead_rule.dart';
import 'rules/naked_set_rule.dart';
import 'rules/pair_forced_rule.dart';
import 'rules/pen_full_rule.dart';
import 'rules/row_full_rule.dart';

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
