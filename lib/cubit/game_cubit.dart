import 'dart:async';

import 'package:bullpen/cubit/game_state.dart';
import 'package:bullpen/cubit/marks_history.dart';
import 'package:bullpen/logic/board_evaluator.dart';
import 'package:bullpen/logic/grid_generator.dart';
import 'package:bullpen/logic/grid_solver.dart';
import 'package:bullpen/logic/hint_finder.dart';
import 'package:bullpen/logic/puzzle_config.dart';
import 'package:bullpen/models/puzzle_board.dart';
import 'package:bullpen/models/puzzle_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class _SolveResult {
  final PuzzleBoard board;
  final PuzzleState state;
  const _SolveResult(this.board, this.state);
}

/// Manages the game lifecycle: size selection, generation, player interaction.
class GameCubit extends Cubit<GameState> {
  int _gridSize;
  var _generateToken = 0;

  GameCubit({int initialSize = 8, bool skipGenerate = false})
    : _gridSize = initialSize,
      super(const GameInitial()) {
    if (!skipGenerate) {
      unawaited(generate());
    }
  }

  int get gridSize => _gridSize;

  /// Updates the grid size and re-emits the current state so the UI rebuilds.
  /// Does NOT regenerate — call [generate] explicitly.
  void setGridSize(int size) {
    if (!isPuzzleSizeSupported(size) || size == _gridSize) {
      return;
    }
    _gridSize = size;
    final current = state;
    switch (current) {
      case GameInitial():
        emit(const GameInitial());
      case GameGenerating():
        emit(GameGenerating(gridSize: size));
      case GamePlaying():
        emit(current.copyWith(version: current.version + 1));
      case GameError():
        emit(GameError(gridSize: size, message: current.message));
    }
  }

  /// Test hook: drop the cubit straight into a known playing state.
  void startPlaying({
    required PuzzleBoard board,
    required PuzzleState solution,
  }) {
    _gridSize = board.size;
    emit(
      GamePlaying.initial(
        board: board,
        solution: solution,
        gridSize: board.size,
      ),
    );
  }

  Future<void> generate() async {
    final size = _gridSize;
    final token = ++_generateToken;
    emit(GameGenerating(gridSize: size));

    try {
      final result = await _runGenerationLoop(
        size,
        token,
      ).timeout(_generateTimeout);
      if (isClosed || token != _generateToken) {
        return;
      }
      emit(
        GamePlaying.initial(
          board: result.board,
          solution: result.state,
          gridSize: size,
        ),
      );
    } on TimeoutException {
      if (isClosed || token != _generateToken) {
        return;
      }
      _generateToken++;
      emit(
        GameError(
          gridSize: size,
          message: 'Could not generate a puzzle in time.',
        ),
      );
    } on Exception catch (e) {
      if (isClosed || token != _generateToken) {
        return;
      }
      emit(GameError(gridSize: size, message: e.toString()));
    }
  }

  Future<_SolveResult> _runGenerationLoop(int size, int token) async {
    while (!isClosed && token == _generateToken) {
      final result = await compute(_generateAndSolve, size);
      if (isClosed || token != _generateToken) {
        throw const _GenerationCancelled();
      }
      if (result != null) {
        return result;
      }
    }
    throw const _GenerationCancelled();
  }

  @override
  Future<void> close() {
    _generateToken++;
    return super.close();
  }

  void requestHint() {
    final current = state;
    if (current is! GamePlaying || current.solved) {
      return;
    }

    final hint = findHint(current.board, current.marks);
    if (hint == null) {
      return;
    }

    emit(
      current.copyWith(
        hintCell: (hint.row, hint.col),
        hintReason: hint.reason,
        hintType: hint.type,
        version: current.version + 1,
      ),
    );
  }

  /// Applies the current hint (dot for exclude, bull for mustPlace), then
  /// immediately requests the next hint.
  void applyHint() {
    final current = state;
    if (current is! GamePlaying || current.solved || !current.hasHint) {
      return;
    }

    final (row, col) = current.hintCell!;
    if (current.hintType == HintType.mustPlace) {
      toggleBull(row, col);
    } else {
      toggleDot(row, col);
    }
    requestHint();
  }

  // Snapshot saved at drag start; used as the single undo entry for the drag.
  List<List<CellMark>>? _dragUndoSnapshot;
  // Whether the current drag places dots (true) or clears marks (false).
  var _dragPlacing = true;

  void toggleDot(int row, int col) {
    final current = state;
    if (current is! GamePlaying || current.solved) {
      return;
    }

    final mark = current.markAt(row, col);
    final newMarks = MarksHistory.clone(current.marks);
    newMarks[row][col] = mark == CellMark.empty ? CellMark.dot : CellMark.empty;

    emit(
      current.copyWith(
        marks: newMarks,
        violations: BoardEvaluator.findViolations(current.board, newMarks),
        version: current.version + 1,
        undoStack: MarksHistory.push(
          current.undoStack,
          MarksHistory.clone(current.marks),
        ),
        redoStack: const [],
        clearHint: true,
      ),
    );
  }

  /// Begins a drag. Starting on empty → placing mode; otherwise → clearing.
  /// Returns true if the drag started.
  bool startDotDrag(int row, int col) {
    final current = state;
    if (current is! GamePlaying || current.solved) {
      return false;
    }

    final mark = current.markAt(row, col);
    _dragUndoSnapshot = MarksHistory.clone(current.marks);
    _dragPlacing = mark == CellMark.empty;

    final newMarks = MarksHistory.clone(current.marks);
    newMarks[row][col] = _dragPlacing ? CellMark.dot : CellMark.empty;

    emit(
      current.copyWith(
        marks: newMarks,
        violations: BoardEvaluator.findViolations(current.board, newMarks),
        version: current.version + 1,
        clearHint: true,
      ),
    );
    return true;
  }

  /// Continues a drag into a new cell. In placing mode only adds dots on
  /// empty cells (bulls are skipped); clearing removes dots and bulls only.
  void continueDotDrag(int row, int col) {
    final current = state;
    if (current is! GamePlaying || current.solved) {
      return;
    }
    if (_dragUndoSnapshot == null) {
      return;
    }

    final mark = current.markAt(row, col);
    if (_dragPlacing) {
      if (mark != CellMark.empty) {
        return;
      }
    } else {
      if (mark == CellMark.empty) {
        return;
      }
    }

    final target = _dragPlacing ? CellMark.dot : CellMark.empty;
    final newMarks = MarksHistory.clone(current.marks);
    newMarks[row][col] = target;

    emit(
      current.copyWith(
        marks: newMarks,
        violations: BoardEvaluator.findViolations(current.board, newMarks),
        version: current.version + 1,
        clearHint: true,
      ),
    );
  }

  /// Ends a drag. Pushes the saved snapshot as a single undo entry.
  void endDotDrag() {
    final current = state;
    if (_dragUndoSnapshot == null) {
      return;
    }

    final snapshot = _dragUndoSnapshot!;
    _dragUndoSnapshot = null;

    if (current is! GamePlaying) {
      return;
    }

    emit(
      current.copyWith(
        undoStack: MarksHistory.push(current.undoStack, snapshot),
        redoStack: const [],
        version: current.version + 1,
        clearHint: true,
      ),
    );
  }

  void toggleBull(int row, int col) {
    final current = state;
    if (current is! GamePlaying || current.solved) {
      return;
    }

    final mark = current.markAt(row, col);
    final newMarks = MarksHistory.clone(current.marks);
    final newUndoStack = MarksHistory.push(
      current.undoStack,
      MarksHistory.clone(current.marks),
    );

    if (mark == CellMark.bull) {
      newMarks[row][col] = CellMark.empty;
      emit(
        current.copyWith(
          marks: newMarks,
          violations: BoardEvaluator.findViolations(current.board, newMarks),
          version: current.version + 1,
          undoStack: newUndoStack,
          redoStack: const [],
          clearHint: true,
        ),
      );
      return;
    }

    newMarks[row][col] = CellMark.bull;
    final violations = BoardEvaluator.findViolations(current.board, newMarks);

    if (violations.isNotEmpty) {
      emit(
        current.copyWith(
          marks: newMarks,
          violations: violations,
          version: current.version + 1,
          undoStack: newUndoStack,
          redoStack: const [],
          clearHint: true,
        ),
      );
      return;
    }

    emit(
      current.copyWith(
        marks: newMarks,
        violations: const {},
        version: current.version + 1,
        solved: BoardEvaluator.isSolved(current.board, newMarks),
        undoStack: newUndoStack,
        redoStack: const [],
        clearHint: true,
      ),
    );
  }

  void undo() {
    final current = state;
    if (current is! GamePlaying || !current.canUndo) {
      return;
    }

    final newUndo = [...current.undoStack];
    final previousMarks = newUndo.removeLast();

    emit(
      current.copyWith(
        marks: previousMarks,
        violations: BoardEvaluator.findViolations(
          current.board,
          previousMarks,
        ),
        version: current.version + 1,
        solved: false,
        undoStack: newUndo,
        redoStack: [...current.redoStack, MarksHistory.clone(current.marks)],
        clearHint: true,
      ),
    );
  }

  void redo() {
    final current = state;
    if (current is! GamePlaying || !current.canRedo) {
      return;
    }

    final newRedo = [...current.redoStack];
    final nextMarks = newRedo.removeLast();

    final violations = BoardEvaluator.findViolations(current.board, nextMarks);
    final solved =
        violations.isEmpty && BoardEvaluator.isSolved(current.board, nextMarks);

    emit(
      current.copyWith(
        marks: nextMarks,
        violations: violations,
        version: current.version + 1,
        solved: solved,
        undoStack: MarksHistory.push(
          current.undoStack,
          MarksHistory.clone(current.marks),
        ),
        redoStack: newRedo,
        clearHint: true,
      ),
    );
  }

  /// Clears violations (after shake animation finishes).
  void clearViolations() {
    final current = state;
    if (current is! GamePlaying) {
      return;
    }
    if (current.violations.isEmpty) {
      return;
    }
    emit(
      current.copyWith(
        violations: const {},
        version: current.version + 1,
        clearHint: true,
      ),
    );
  }
}

/// Tries up to [_attemptsPerBatch] times to generate and solve a board.
/// Returns the first success, or null so the caller can dispatch another batch
/// (kept bounded so the calling cubit can observe cancellation between runs).
_SolveResult? _generateAndSolve(int size) {
  for (var attempt = 0; attempt < _attemptsPerBatch; attempt++) {
    final board = GridGenerator.generate(size);
    final state = GridSolver.solve(board);
    if (state != null) {
      return _SolveResult(board, state);
    }
  }
  return null;
}

const _attemptsPerBatch = 50;
const _generateTimeout = Duration(seconds: 10);

class _GenerationCancelled implements Exception {
  const _GenerationCancelled();
}
