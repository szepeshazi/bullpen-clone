import 'package:bullpen/cubit/game_state.dart';

/// Pure helpers for managing the undo/redo mark snapshot stacks.
class MarksHistory {
  MarksHistory._();

  /// Maximum entries kept per stack before old ones are dropped.
  static const maxSize = 100;

  static List<List<CellMark>> clone(List<List<CellMark>> marks) => [for (final row in marks) [...row]];

  static List<List<List<CellMark>>> push(
    List<List<List<CellMark>>> stack,
    List<List<CellMark>> snapshot,
  ) {
    final next = [...stack, snapshot];
    if (next.length > maxSize) {
      return next.sublist(next.length - maxSize);
    }
    return next;
  }
}
