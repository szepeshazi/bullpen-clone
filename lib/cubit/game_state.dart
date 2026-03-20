import 'package:flutter/foundation.dart';

import '../models/models.dart';

/// Possible cell marks placed by the player.
enum CellMark { empty, dot, bull }

/// The possible states of the Bullpen game screen.
@immutable
sealed class GameState {
  const GameState();
}

/// Initial state before any grid has been generated.
class GameInitial extends GameState {
  const GameInitial();
}

/// A grid is currently being generated/solved in a background isolate.
class GameGenerating extends GameState {
  final int gridSize;

  const GameGenerating({required this.gridSize});
}

/// The player is actively playing a generated puzzle.
class GamePlaying extends GameState {
  final PuzzleBoard board;

  /// The known solution (used to verify win condition).
  final PuzzleState solution;

  final int gridSize;

  /// Player's marks per cell: row → col → CellMark.
  final List<List<CellMark>> marks;

  /// Set of (row, col) positions whose bulls are currently violating rules.
  /// Used to trigger shake animation.
  final Set<(int, int)> violations;

  /// Monotonically increasing counter bumped on every state change, so
  /// the UI always rebuilds even if marks are structurally identical.
  final int version;

  /// Whether the puzzle has been solved.
  final bool solved;

  /// Undo stack: previous mark snapshots (most recent last).
  final List<List<List<CellMark>>> undoStack;

  /// Redo stack: forward mark snapshots (most recent last).
  final List<List<List<CellMark>>> redoStack;

  GamePlaying({
    required this.board,
    required this.solution,
    required this.gridSize,
    required this.marks,
    this.violations = const {},
    this.version = 0,
    this.solved = false,
    this.undoStack = const [],
    this.redoStack = const [],
  });

  /// Creates the initial playing state from a generated board and solution.
  factory GamePlaying.initial({
    required PuzzleBoard board,
    required PuzzleState solution,
    required int gridSize,
  }) {
    return GamePlaying(
      board: board,
      solution: solution,
      gridSize: gridSize,
      marks: List.generate(
        board.size,
        (_) => List.filled(board.size, CellMark.empty),
      ),
    );
  }

  /// Creates a copy with updated fields.
  GamePlaying copyWith({
    List<List<CellMark>>? marks,
    Set<(int, int)>? violations,
    int? version,
    bool? solved,
    List<List<List<CellMark>>>? undoStack,
    List<List<List<CellMark>>>? redoStack,
  }) {
    return GamePlaying(
      board: board,
      solution: solution,
      gridSize: gridSize,
      marks: marks ?? this.marks,
      violations: violations ?? this.violations,
      version: version ?? this.version,
      solved: solved ?? this.solved,
      undoStack: undoStack ?? this.undoStack,
      redoStack: redoStack ?? this.redoStack,
    );
  }

  /// Whether undo is available.
  bool get canUndo => undoStack.isNotEmpty;

  /// Whether redo is available.
  bool get canRedo => redoStack.isNotEmpty;

  CellMark markAt(int row, int col) => marks[row][col];

  bool hasBullAt(int row, int col) => marks[row][col] == CellMark.bull;

  bool hasDotAt(int row, int col) => marks[row][col] == CellMark.dot;

  bool isViolation(int row, int col) => violations.contains((row, col));
}

/// Generation failed after exhausting all attempts.
class GameError extends GameState {
  final int gridSize;
  final String message;

  const GameError({required this.gridSize, required this.message});
}
