import 'package:bullpen/logic/hints/hint.dart';
import 'package:bullpen/logic/hints/hint_context.dart';

/// A single rule that may produce one hint from the current board state.
/// Rules are evaluated in priority order; the first non-null result wins.
abstract class HintRule {
  const HintRule();

  Hint? evaluate(HintContext ctx);
}
