import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/models.dart';
import 'game_state.dart';

/// Result of the background isolate generation+solving.
class _SolveResult {
  final PuzzleBoard board;
  final PuzzleState state;
  const _SolveResult(this.board, this.state);
}

/// Cubit that manages the Bullpen game lifecycle: grid size selection,
/// generation, solving, and player interaction.
class GameCubit extends Cubit<GameState> {
  int _gridSize;

  GameCubit({int initialSize = 8, bool skipGenerate = false})
      : _gridSize = initialSize,
        super(const GameInitial()) {
    if (!skipGenerate) generate();
  }

  /// Currently selected grid size.
  int get gridSize => _gridSize;

  /// Updates the grid size and re-emits the current state so the UI rebuilds.
  /// Does NOT automatically regenerate — call [generate] explicitly.
  void setGridSize(int size) {
    if (size < 8 || size > 16 || size == _gridSize) return;
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

  /// Directly sets the cubit to a playing state with a known board.
  /// Used for testing.
  void startPlaying({
    required PuzzleBoard board,
    required PuzzleState solution,
  }) {
    _gridSize = board.size;
    emit(GamePlaying.initial(
      board: board,
      solution: solution,
      gridSize: board.size,
    ));
  }

  /// Generates a new random grid and solves it in a background isolate.
  Future<void> generate() async {
    final size = _gridSize;
    emit(GameGenerating(gridSize: size));

    try {
      final result = await compute(_generateAndSolve, size);
      if (result != null) {
        emit(GamePlaying.initial(
          board: result.board,
          solution: result.state,
          gridSize: size,
        ));
      } else {
        emit(GameError(
          gridSize: size,
          message: 'Could not generate a solvable $size\u00d7$size grid. '
              'Try again or pick a different size.',
        ));
      }
    } catch (e) {
      emit(GameError(gridSize: size, message: e.toString()));
    }
  }

  // ---------------------------------------------------------------------------
  // Hints
  // ---------------------------------------------------------------------------

  /// Computes and displays a hint for the next excludable cell.
  void requestHint() {
    final current = state;
    if (current is! GamePlaying || current.solved) return;

    final hint = findHint(current.board, current.marks);
    if (hint == null) return;

    emit(current.copyWith(
      hintCell: (hint.row, hint.col),
      hintReason: hint.reason,
      version: current.version + 1,
    ));
  }

  // ---------------------------------------------------------------------------
  // Player interaction
  // ---------------------------------------------------------------------------

  // Snapshot saved at drag start, used as the single undo entry for the
  // entire drag operation.
  List<List<CellMark>>? _dragUndoSnapshot;

  // Whether the current drag is placing dots (true) or clearing marks (false).
  bool _dragPlacing = true;

  /// Toggles the dot mark on a cell (empty <-> dot).
  /// Tapping a bull removes it.
  void toggleDot(int row, int col) {
    final current = state;
    if (current is! GamePlaying || current.solved) return;

    final mark = current.markAt(row, col);

    final newMarks = _cloneMarks(current.marks);
    newMarks[row][col] = mark == CellMark.empty ? CellMark.dot : CellMark.empty;

    emit(current.copyWith(
      marks: newMarks,
      violations: _findViolations(current.board, newMarks),
      version: current.version + 1,
      undoStack: _pushUndo(current.undoStack, _cloneMarks(current.marks)),
      redoStack: const [],
      clearHint: true,
    ));
  }

  /// Begins a drag gesture. Saves the undo snapshot and applies the first cell.
  /// Starting on an empty cell enters "placing" mode (adds dots).
  /// Starting on a dot or bull enters "clearing" mode (removes dots and bulls).
  /// Returns true if the drag started.
  bool startDotDrag(int row, int col) {
    final current = state;
    if (current is! GamePlaying || current.solved) return false;

    final mark = current.markAt(row, col);

    // Save snapshot for undo before any changes.
    _dragUndoSnapshot = _cloneMarks(current.marks);
    _dragPlacing = mark == CellMark.empty; // empty → place dots, otherwise → clear

    final newMarks = _cloneMarks(current.marks);
    newMarks[row][col] = _dragPlacing ? CellMark.dot : CellMark.empty;

    emit(current.copyWith(
      marks: newMarks,
      violations: _findViolations(current.board, newMarks),
      version: current.version + 1,
      clearHint: true,
    ));
    return true;
  }

  /// Continues a drag into a new cell. In placing mode, adds dots (skips bulls).
  /// In clearing mode, clears both dots and bulls.
  void continueDotDrag(int row, int col) {
    final current = state;
    if (current is! GamePlaying || current.solved) return;
    if (_dragUndoSnapshot == null) return;

    final mark = current.markAt(row, col);

    if (_dragPlacing) {
      // Placing mode: only place dots on empty cells, skip bulls.
      if (mark != CellMark.empty) return;
    } else {
      // Clearing mode: clear dots and bulls, skip empty.
      if (mark == CellMark.empty) return;
    }

    final target = _dragPlacing ? CellMark.dot : CellMark.empty;

    final newMarks = _cloneMarks(current.marks);
    newMarks[row][col] = target;

    emit(current.copyWith(
      marks: newMarks,
      violations: _findViolations(current.board, newMarks),
      version: current.version + 1,
      clearHint: true,
    ));
  }

  /// Ends a dot drag. Pushes the saved snapshot as a single undo entry.
  void endDotDrag() {
    final current = state;
    if (_dragUndoSnapshot == null) return;

    final snapshot = _dragUndoSnapshot!;
    _dragUndoSnapshot = null;

    if (current is! GamePlaying) return;

    emit(current.copyWith(
      undoStack: _pushUndo(current.undoStack, snapshot),
      redoStack: const [],
      version: current.version + 1,
      clearHint: true,
    ));
  }

  /// Places or removes a bull at a cell. If placing causes violations,
  /// emits the violation set so the UI can shake the offending bulls.
  void toggleBull(int row, int col) {
    final current = state;
    if (current is! GamePlaying || current.solved) return;

    final mark = current.markAt(row, col);
    final newMarks = _cloneMarks(current.marks);

    final newUndoStack = _pushUndo(current.undoStack, _cloneMarks(current.marks));

    if (mark == CellMark.bull) {
      // Remove the bull, then recheck for remaining violations.
      newMarks[row][col] = CellMark.empty;
      final remaining = _findViolations(current.board, newMarks);
      emit(current.copyWith(
        marks: newMarks,
        violations: remaining,
        version: current.version + 1,
        undoStack: newUndoStack,
        redoStack: const [],
        clearHint: true,
      ));
      return;
    }

    // Place a bull.
    newMarks[row][col] = CellMark.bull;

    // Check for violations.
    final violations = _findViolations(current.board, newMarks);

    if (violations.isNotEmpty) {
      emit(current.copyWith(
        marks: newMarks,
        violations: violations,
        version: current.version + 1,
        undoStack: newUndoStack,
        redoStack: const [],
        clearHint: true,
      ));
      return;
    }

    // Check for win condition.
    final solved = _checkSolved(current.board, newMarks);
    emit(current.copyWith(
      marks: newMarks,
      violations: const {},
      version: current.version + 1,
      solved: solved,
      undoStack: newUndoStack,
      redoStack: const [],
      clearHint: true,
    ));
  }

  /// Undoes the last player action.
  void undo() {
    final current = state;
    if (current is! GamePlaying || !current.canUndo) return;

    final newUndo = [...current.undoStack];
    final previousMarks = newUndo.removeLast();

    emit(current.copyWith(
      marks: previousMarks,
      violations: _findViolations(current.board, previousMarks),
      version: current.version + 1,
      solved: false,
      undoStack: newUndo,
      redoStack: [...current.redoStack, _cloneMarks(current.marks)],
      clearHint: true,
    ));
  }

  /// Redoes the last undone action.
  void redo() {
    final current = state;
    if (current is! GamePlaying || !current.canRedo) return;

    final newRedo = [...current.redoStack];
    final nextMarks = newRedo.removeLast();

    // Re-check violations and solved state for the restored marks.
    final violations = _findViolations(current.board, nextMarks);
    final solved =
        violations.isEmpty ? _checkSolved(current.board, nextMarks) : false;

    emit(current.copyWith(
      marks: nextMarks,
      violations: violations,
      version: current.version + 1,
      solved: solved,
      undoStack: _pushUndo(current.undoStack, _cloneMarks(current.marks)),
      redoStack: newRedo,
      clearHint: true,
    ));
  }

  /// Clears violations (called after shake animation completes).
  void clearViolations() {
    final current = state;
    if (current is! GamePlaying) return;
    if (current.violations.isEmpty) return;
    emit(current.copyWith(
      violations: const {},
      version: current.version + 1,
      clearHint: true,
    ));
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Maximum undo/redo history entries to prevent unbounded memory growth.
  static const _maxHistorySize = 100;

  List<List<CellMark>> _cloneMarks(List<List<CellMark>> marks) {
    return [for (final row in marks) [...row]];
  }

  /// Returns a new undo stack with [snapshot] appended, capped to
  /// [_maxHistorySize] entries.
  List<List<List<CellMark>>> _pushUndo(
    List<List<List<CellMark>>> stack,
    List<List<CellMark>> snapshot,
  ) {
    final newStack = [...stack, snapshot];
    if (newStack.length > _maxHistorySize) {
      return newStack.sublist(newStack.length - _maxHistorySize);
    }
    return newStack;
  }

  /// Collects all bull positions and their row/col/pen counts from [marks].
  ({
    List<(int, int)> bulls,
    List<int> rowCounts,
    List<int> colCounts,
    Map<int, int> penCounts,
  }) _countBulls(PuzzleBoard board, List<List<CellMark>> marks) {
    final size = board.size;
    final bulls = <(int, int)>[];
    final rowCounts = List.filled(size, 0);
    final colCounts = List.filled(size, 0);
    final penCounts = <int, int>{};

    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        if (marks[r][c] != CellMark.bull) continue;
        bulls.add((r, c));
        rowCounts[r]++;
        colCounts[c]++;
        final penId = board.cellAt(r, c).penId;
        penCounts[penId] = (penCounts[penId] ?? 0) + 1;
      }
    }

    return (
      bulls: bulls,
      rowCounts: rowCounts,
      colCounts: colCounts,
      penCounts: penCounts,
    );
  }

  /// Finds all bull positions that violate any rule.
  /// Rules: max 2 bulls per row, column, pen; no adjacent bulls.
  Set<(int, int)> _findViolations(
    PuzzleBoard board,
    List<List<CellMark>> marks,
  ) {
    final size = board.size;
    final violations = <(int, int)>{};
    final counts = _countBulls(board, marks);

    // Mark all bulls in over-full rows/cols/pens.
    for (final (r, c) in counts.bulls) {
      if (counts.rowCounts[r] > 2) violations.add((r, c));
      if (counts.colCounts[c] > 2) violations.add((r, c));
      final penId = board.cellAt(r, c).penId;
      if ((counts.penCounts[penId] ?? 0) > 2) violations.add((r, c));
    }

    // Adjacency violations.
    for (final (r, c) in counts.bulls) {
      if (hasAdjacentMatch(r, c, size, (nr, nc) => marks[nr][nc] == CellMark.bull)) {
        violations.add((r, c));
      }
    }

    return violations;
  }

  /// Checks if all bulls are correctly placed (matches solution constraints).
  bool _checkSolved(PuzzleBoard board, List<List<CellMark>> marks) {
    final size = board.size;
    final counts = _countBulls(board, marks);

    if (counts.bulls.length != 2 * size) return false;

    for (int i = 0; i < size; i++) {
      if (counts.rowCounts[i] != 2) return false;
      if (counts.colCounts[i] != 2) return false;
    }
    for (final pen in board.pens) {
      if ((counts.penCounts[pen.id] ?? 0) != 2) return false;
    }

    // Adjacency check.
    for (final (r, c) in counts.bulls) {
      if (hasAdjacentMatch(r, c, size, (nr, nc) => marks[nr][nc] == CellMark.bull)) {
        return false;
      }
    }

    return true;
  }
}

/// Top-level function for [compute] — runs in a background isolate.
_SolveResult? _generateAndSolve(int size) {
  const maxAttempts = 200;
  for (int attempt = 0; attempt < maxAttempts; attempt++) {
    final board = GridGenerator.generate(size);
    final state = GridSolver.solve(board);
    if (state != null) return _SolveResult(board, state);
  }
  return null;
}
