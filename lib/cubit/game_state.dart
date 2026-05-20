import 'package:flutter/foundation.dart';

import '../logic/hint_finder.dart';
import '../models/models.dart';

enum CellMark { empty, dot, bull }

/// The possible states of the Bullpen game screen.
@immutable
sealed class GameState {
  const GameState();
}

class GameInitial extends GameState {
  const GameInitial();
}

class GameGenerating extends GameState {
  final int gridSize;
  const GameGenerating({required this.gridSize});
}

class GamePlaying extends GameState {
  final PuzzleBoard board;
  final PuzzleState solution;
  final int gridSize;
  final List<List<CellMark>> marks;
  final Set<(int, int)> violations;

  /// Monotonic counter bumped on every state change so the UI rebuilds even
  /// when marks are structurally identical (e.g., after a no-op gesture).
  final int version;

  final bool solved;
  final List<List<List<CellMark>>> undoStack;
  final List<List<List<CellMark>>> redoStack;
  final (int, int)? hintCell;
  final String? hintReason;
  final HintType? hintType;

  const GamePlaying({
    required this.board,
    required this.solution,
    required this.gridSize,
    required this.marks,
    this.violations = const {},
    this.version = 0,
    this.solved = false,
    this.undoStack = const [],
    this.redoStack = const [],
    this.hintCell,
    this.hintReason,
    this.hintType,
  });

  bool get hasHint => hintCell != null;

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
  ///
  /// Set [clearHint] to `true` to reset hintCell/hintReason/hintType to `null`
  /// — sidesteps the `??` ambiguity for nullable fields.
  GamePlaying copyWith({
    List<List<CellMark>>? marks,
    Set<(int, int)>? violations,
    int? version,
    bool? solved,
    List<List<List<CellMark>>>? undoStack,
    List<List<List<CellMark>>>? redoStack,
    (int, int)? hintCell,
    String? hintReason,
    HintType? hintType,
    bool clearHint = false,
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
      hintCell: clearHint ? null : (hintCell ?? this.hintCell),
      hintReason: clearHint ? null : (hintReason ?? this.hintReason),
      hintType: clearHint ? null : (hintType ?? this.hintType),
    );
  }

  bool get canUndo => undoStack.isNotEmpty;
  bool get canRedo => redoStack.isNotEmpty;
  CellMark markAt(int row, int col) => marks[row][col];
  bool hasBullAt(int row, int col) => marks[row][col] == CellMark.bull;
  bool hasDotAt(int row, int col) => marks[row][col] == CellMark.dot;
  bool isViolation(int row, int col) => violations.contains((row, col));
}

class GameError extends GameState {
  final int gridSize;
  final String message;

  const GameError({required this.gridSize, required this.message});
}
