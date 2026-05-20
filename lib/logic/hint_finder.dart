import '../cubit/game_state.dart';
import '../models/puzzle_board.dart';
import 'hints/hint.dart';
import 'hints/hint_engine.dart';

export 'hints/hint.dart';

/// Scans the board for the first hint, checking rules in priority order.
/// Returns `null` when no hint can be found.
Hint? findHint(PuzzleBoard board, List<List<CellMark>> marks) {
  return HintEngine.defaultRules().findHint(board, marks);
}
