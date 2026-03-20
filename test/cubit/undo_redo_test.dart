import 'package:bullpen/cubit/game_cubit.dart';
import 'package:bullpen/cubit/game_state.dart';
import 'package:bullpen/models/cell.dart';
import 'package:bullpen/models/pen.dart';
import 'package:bullpen/models/puzzle_board.dart';
import 'package:bullpen/models/puzzle_state.dart';
import 'package:flutter_test/flutter_test.dart';

/// Creates a simple 8x8 board where each row is its own pen.
PuzzleBoard _makeBoard({int size = 8}) {
  final pens = <Pen>[];
  for (int penId = 0; penId < size; penId++) {
    final cells = List.generate(
      size,
      (col) => Cell(row: penId, col: col, penId: penId),
    );
    pens.add(Pen(id: penId, cells: cells));
  }
  return PuzzleBoard(size: size, pens: pens);
}

/// Creates a GameCubit already in GamePlaying state using a known board.
GameCubit _makeCubit() {
  final board = _makeBoard();
  final solution = PuzzleState(board: board);
  final cubit = GameCubit(skipGenerate: true);
  cubit.startPlaying(board: board, solution: solution);
  return cubit;
}

/// Returns the current GamePlaying state from the cubit, or fails.
GamePlaying _playing(GameCubit cubit) {
  final s = cubit.state;
  if (s is GamePlaying) return s;
  fail('Expected GamePlaying, got ${s.runtimeType}');
}

void main() {
  group('Undo / Redo', () {
    late GameCubit cubit;

    setUp(() {
      cubit = _makeCubit();
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state has no undo or redo available', () {
      final s = _playing(cubit);
      expect(s.canUndo, isFalse);
      expect(s.canRedo, isFalse);
    });

    test('undo does nothing when stack is empty', () {
      final before = _playing(cubit).version;
      cubit.undo();
      // State should not change (no emit when nothing to undo).
      expect(_playing(cubit).version, before);
    });

    test('redo does nothing when stack is empty', () {
      final before = _playing(cubit).version;
      cubit.redo();
      expect(_playing(cubit).version, before);
    });

    test('toggleDot pushes to undo stack', () {
      cubit.toggleDot(0, 0);
      final s = _playing(cubit);
      expect(s.canUndo, isTrue);
      expect(s.canRedo, isFalse);
      expect(s.markAt(0, 0), CellMark.dot);
    });

    test('toggleBull pushes to undo stack', () {
      cubit.toggleBull(0, 0);
      final s = _playing(cubit);
      expect(s.canUndo, isTrue);
      expect(s.markAt(0, 0), CellMark.bull);
    });

    test('undo restores previous marks after toggleDot', () {
      expect(_playing(cubit).markAt(0, 0), CellMark.empty);

      cubit.toggleDot(0, 0);
      expect(_playing(cubit).markAt(0, 0), CellMark.dot);

      cubit.undo();
      expect(_playing(cubit).markAt(0, 0), CellMark.empty);
      expect(_playing(cubit).canUndo, isFalse);
      expect(_playing(cubit).canRedo, isTrue);
    });

    test('undo restores previous marks after toggleBull', () {
      cubit.toggleBull(0, 0);
      expect(_playing(cubit).markAt(0, 0), CellMark.bull);

      cubit.undo();
      expect(_playing(cubit).markAt(0, 0), CellMark.empty);
    });

    test('redo restores undone action', () {
      cubit.toggleDot(0, 0);
      cubit.undo();
      expect(_playing(cubit).markAt(0, 0), CellMark.empty);

      cubit.redo();
      expect(_playing(cubit).markAt(0, 0), CellMark.dot);
      expect(_playing(cubit).canUndo, isTrue);
      expect(_playing(cubit).canRedo, isFalse);
    });

    test('new action after undo clears redo stack', () {
      cubit.toggleDot(0, 0);
      cubit.undo();
      expect(_playing(cubit).canRedo, isTrue);

      // New action should clear redo.
      cubit.toggleDot(1, 1);
      expect(_playing(cubit).canRedo, isFalse);
    });

    test('multiple undo steps work correctly', () {
      cubit.toggleDot(0, 0);
      cubit.toggleDot(1, 1);
      cubit.toggleDot(2, 2);

      expect(_playing(cubit).undoStack.length, 3);

      cubit.undo();
      expect(_playing(cubit).markAt(2, 2), CellMark.empty);
      expect(_playing(cubit).markAt(1, 1), CellMark.dot);
      expect(_playing(cubit).markAt(0, 0), CellMark.dot);

      cubit.undo();
      expect(_playing(cubit).markAt(1, 1), CellMark.empty);
      expect(_playing(cubit).markAt(0, 0), CellMark.dot);

      cubit.undo();
      expect(_playing(cubit).markAt(0, 0), CellMark.empty);

      expect(_playing(cubit).canUndo, isFalse);
      expect(_playing(cubit).redoStack.length, 3);
    });

    test('multiple redo steps work correctly', () {
      cubit.toggleDot(0, 0);
      cubit.toggleDot(1, 1);

      cubit.undo();
      cubit.undo();

      cubit.redo();
      expect(_playing(cubit).markAt(0, 0), CellMark.dot);
      expect(_playing(cubit).markAt(1, 1), CellMark.empty);

      cubit.redo();
      expect(_playing(cubit).markAt(0, 0), CellMark.dot);
      expect(_playing(cubit).markAt(1, 1), CellMark.dot);
    });

    test('undo/redo cycle preserves marks exactly', () {
      cubit.toggleDot(0, 0);
      cubit.toggleBull(3, 3);
      cubit.toggleDot(5, 5);

      // Capture the state at each step by undoing.
      cubit.undo(); // undo dot at 5,5
      expect(_playing(cubit).markAt(5, 5), CellMark.empty);
      expect(_playing(cubit).markAt(3, 3), CellMark.bull);

      cubit.redo(); // redo dot at 5,5
      expect(_playing(cubit).markAt(5, 5), CellMark.dot);
      expect(_playing(cubit).markAt(3, 3), CellMark.bull);
      expect(_playing(cubit).markAt(0, 0), CellMark.dot);
    });

    test('toggleDot then toggle same dot again both create undo entries', () {
      cubit.toggleDot(0, 0); // empty -> dot
      cubit.toggleDot(0, 0); // dot -> empty

      expect(_playing(cubit).markAt(0, 0), CellMark.empty);
      expect(_playing(cubit).undoStack.length, 2);

      cubit.undo();
      expect(_playing(cubit).markAt(0, 0), CellMark.dot);

      cubit.undo();
      expect(_playing(cubit).markAt(0, 0), CellMark.empty);
    });

    test('clearViolations does not affect undo/redo stacks', () {
      cubit.toggleBull(0, 0);
      final undoLen = _playing(cubit).undoStack.length;
      final redoLen = _playing(cubit).redoStack.length;

      cubit.clearViolations();

      expect(_playing(cubit).undoStack.length, undoLen);
      expect(_playing(cubit).redoStack.length, redoLen);
    });
  });

  group('Dot drag', () {
    late GameCubit cubit;

    setUp(() {
      cubit = _makeCubit();
    });

    tearDown(() {
      cubit.close();
    });

    test('startDotDrag places dot on empty cell', () {
      expect(cubit.startDotDrag(0, 0), isTrue);
      expect(_playing(cubit).markAt(0, 0), CellMark.dot);
    });

    test('startDotDrag on bull cell removes it (clearing mode)', () {
      cubit.toggleBull(0, 0);
      expect(cubit.startDotDrag(0, 0), isTrue);
      expect(_playing(cubit).markAt(0, 0), CellMark.empty);
    });

    test('startDotDrag on dot cell removes it', () {
      cubit.toggleDot(0, 0);
      expect(_playing(cubit).markAt(0, 0), CellMark.dot);

      cubit.startDotDrag(0, 0);
      expect(_playing(cubit).markAt(0, 0), CellMark.empty);
    });

    test('continueDotDrag places dots on subsequent cells', () {
      cubit.startDotDrag(0, 0);
      cubit.continueDotDrag(0, 1);
      cubit.continueDotDrag(0, 2);

      expect(_playing(cubit).markAt(0, 0), CellMark.dot);
      expect(_playing(cubit).markAt(0, 1), CellMark.dot);
      expect(_playing(cubit).markAt(0, 2), CellMark.dot);
    });

    test('placing mode skips bull cells during drag', () {
      cubit.toggleBull(0, 1);
      cubit.startDotDrag(0, 0); // starts on empty → placing mode
      cubit.continueDotDrag(0, 1); // bull — should be skipped in placing mode
      cubit.continueDotDrag(0, 2);

      expect(_playing(cubit).markAt(0, 0), CellMark.dot);
      expect(_playing(cubit).markAt(0, 1), CellMark.bull);
      expect(_playing(cubit).markAt(0, 2), CellMark.dot);
    });

    test('clearing mode removes bulls during drag', () {
      cubit.toggleBull(0, 0);
      cubit.toggleBull(0, 2);
      cubit.toggleDot(0, 1);

      cubit.startDotDrag(0, 0); // starts on bull → clearing mode
      cubit.continueDotDrag(0, 1); // dot → cleared
      cubit.continueDotDrag(0, 2); // bull → cleared
      cubit.endDotDrag();

      expect(_playing(cubit).markAt(0, 0), CellMark.empty);
      expect(_playing(cubit).markAt(0, 1), CellMark.empty);
      expect(_playing(cubit).markAt(0, 2), CellMark.empty);
    });

    test('drag starting on dot removes dots and bulls during drag', () {
      cubit.toggleDot(0, 0);
      cubit.toggleBull(0, 1);
      cubit.toggleDot(0, 2);

      cubit.startDotDrag(0, 0); // starts on dot → clearing mode
      cubit.continueDotDrag(0, 1); // bull → cleared
      cubit.continueDotDrag(0, 2); // dot → cleared
      cubit.endDotDrag();

      expect(_playing(cubit).markAt(0, 0), CellMark.empty);
      expect(_playing(cubit).markAt(0, 1), CellMark.empty);
      expect(_playing(cubit).markAt(0, 2), CellMark.empty);
    });

    test('clearing mode skips empty cells during drag', () {
      cubit.toggleBull(0, 0);
      // 0,1 is empty
      cubit.toggleDot(0, 2);

      cubit.startDotDrag(0, 0); // starts on bull → clearing mode
      cubit.continueDotDrag(0, 1); // empty → skipped
      cubit.continueDotDrag(0, 2); // dot → cleared
      cubit.endDotDrag();

      expect(_playing(cubit).markAt(0, 0), CellMark.empty);
      expect(_playing(cubit).markAt(0, 1), CellMark.empty); // still empty
      expect(_playing(cubit).markAt(0, 2), CellMark.empty);
    });

    test('entire drag is a single undo entry', () {
      final undoBefore = _playing(cubit).undoStack.length;

      cubit.startDotDrag(0, 0);
      cubit.continueDotDrag(0, 1);
      cubit.continueDotDrag(0, 2);
      cubit.endDotDrag();

      // Should have exactly one more undo entry.
      expect(_playing(cubit).undoStack.length, undoBefore + 1);

      // Undo reverts all three dots at once.
      cubit.undo();
      expect(_playing(cubit).markAt(0, 0), CellMark.empty);
      expect(_playing(cubit).markAt(0, 1), CellMark.empty);
      expect(_playing(cubit).markAt(0, 2), CellMark.empty);
    });

    test('drag clears redo stack', () {
      cubit.toggleDot(1, 1);
      cubit.undo();
      expect(_playing(cubit).canRedo, isTrue);

      cubit.startDotDrag(0, 0);
      cubit.endDotDrag();

      expect(_playing(cubit).canRedo, isFalse);
    });

    test('continueDotDrag without startDotDrag is a no-op', () {
      final version = _playing(cubit).version;
      cubit.continueDotDrag(0, 0);
      expect(_playing(cubit).version, version);
    });
  });
}
