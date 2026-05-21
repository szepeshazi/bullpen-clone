import 'package:bullpen/cubit/game_state.dart';
import 'package:bullpen/logic/hints/hint.dart';
import 'package:bullpen/logic/hints/hint_engine.dart';
import 'package:bullpen/models/puzzle_board.dart';

export 'hints/hint.dart';

/// Scans the board for the first hint, checking rules in priority order.
/// Returns `null` when no hint can be found.
Hint? findHint(PuzzleBoard board, List<List<CellMark>> marks) => HintEngine.defaultRules().findHint(board, marks);
