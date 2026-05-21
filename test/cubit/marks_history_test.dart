import 'package:bullpen/cubit/game_state.dart';
import 'package:bullpen/cubit/marks_history.dart';
import 'package:flutter_test/flutter_test.dart';

List<List<CellMark>> _emptySnapshot(int size) =>
    List.generate(size, (_) => List.filled(size, CellMark.empty));

void main() {
  group('MarksHistory', () {
    test('push adds a snapshot', () {
      final snapshot = _emptySnapshot(8);
      final result = MarksHistory.push([], snapshot);
      expect(result.length, 1);
      expect(result.first, snapshot);
    });

    test('push at capacity drops the oldest entry', () {
      var stack = <List<List<CellMark>>>[];
      for (var i = 0; i < MarksHistory.maxSize; i++) {
        stack = MarksHistory.push(stack, _emptySnapshot(8));
      }
      expect(stack.length, MarksHistory.maxSize);

      final newSnapshot = _emptySnapshot(4);
      stack = MarksHistory.push(stack, newSnapshot);

      expect(stack.length, MarksHistory.maxSize);
      expect(stack.last, newSnapshot);
    });

    test('clone produces a deep copy', () {
      final original = _emptySnapshot(4);
      final copy = MarksHistory.clone(original);

      copy[0][0] = CellMark.bull;
      expect(original[0][0], CellMark.empty,
          reason: 'mutation of clone must not affect original');
    });
  });
}
