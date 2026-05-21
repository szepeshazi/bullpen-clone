import 'package:bullpen/cubit/game_cubit.dart';
import 'package:bullpen/cubit/game_state.dart';
import 'package:bullpen/models/models.dart' show PuzzleBoard;
import 'package:bullpen/models/puzzle_board.dart' show PuzzleBoard;
import 'package:bullpen/widgets/bullpen_cell.dart';
import 'package:bullpen/widgets/grid_constants.dart';
import 'package:bullpen/widgets/pen_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Displays a [PuzzleBoard] with player interaction.
/// Tap toggles dots, long-press places/removes bulls, drag streams dots.
class BullpenGrid extends StatefulWidget {
  final GamePlaying gameState;

  static const longPressDuration = Duration(milliseconds: 400);

  const BullpenGrid({required this.gameState, super.key});

  @override
  State<BullpenGrid> createState() => _BullpenGridState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<GamePlaying>('gameState', gameState));
  }
}

class _BullpenGridState extends State<BullpenGrid> {
  double _cellSize = 0;
  Offset _gridOrigin = Offset.zero;

  static const _dragThreshold = 8.0;

  Offset? _downPos;
  var _isDragging = false;
  var _isLongPress = false;
  (int, int)? _lastDragCell;
  int? _activePointer;

  (int, int)? _cellAt(Offset localPosition) {
    final pos = localPosition - _gridOrigin;
    if (_cellSize <= 0) return null;
    final col = (pos.dx / _cellSize).floor();
    final row = (pos.dy / _cellSize).floor();
    final size = widget.gameState.board.size;
    if (row < 0 || row >= size || col < 0 || col >= size) return null;
    return (row, col);
  }

  void _onPointerDown(PointerDownEvent event) {
    if (_activePointer != null) return; // ignore multi-touch
    _activePointer = event.pointer;
    _downPos = event.localPosition;
    _isDragging = false;
    _isLongPress = false;
    _lastDragCell = _cellAt(event.localPosition);

    final pointer = event.pointer;
    Future.delayed(BullpenGrid.longPressDuration, () {
      if (!mounted) return;
      if (_activePointer != pointer || _isDragging) return;
      _isLongPress = true;
      final cell = _lastDragCell;
      if (cell == null) return;
      final (row, col) = cell;
      HapticFeedback.mediumImpact();
      context.read<GameCubit>().toggleBull(row, col);
    });
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (event.pointer != _activePointer || _isLongPress) return;

    final distance = (event.localPosition - _downPos!).distance;

    if (!_isDragging && distance >= _dragThreshold) {
      _isDragging = true;
      final cell = _cellAt(_downPos!);
      if (cell != null) {
        final (row, col) = cell;
        if (context.read<GameCubit>().startDotDrag(row, col)) {
          HapticFeedback.lightImpact();
          _lastDragCell = cell;
        }
      }
    }

    if (_isDragging) {
      final cell = _cellAt(event.localPosition);
      if (cell != null && cell != _lastDragCell) {
        _lastDragCell = cell;
        final (row, col) = cell;
        context.read<GameCubit>().continueDotDrag(row, col);
      }
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    if (event.pointer != _activePointer) return;

    if (_isDragging) {
      context.read<GameCubit>().endDotDrag();
    } else if (!_isLongPress) {
      final cell = _cellAt(event.localPosition);
      if (cell != null) {
        final (row, col) = cell;
        HapticFeedback.lightImpact();
        context.read<GameCubit>().toggleDot(row, col);
      }
    }

    _reset();
  }

  void _onPointerCancel(PointerCancelEvent event) {
    if (event.pointer != _activePointer) return;
    if (_isDragging) {
      context.read<GameCubit>().endDotDrag();
    }
    _reset();
  }

  void _reset() {
    _activePointer = null;
    _downPos = null;
    _isDragging = false;
    _isLongPress = false;
    _lastDragCell = null;
  }

  @override
  Widget build(BuildContext context) {
    final board = widget.gameState.board;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxSide = constraints.maxWidth < constraints.maxHeight
            ? constraints.maxWidth
            : constraints.maxHeight;
        final gridSide = maxSide * gridFraction;
        _cellSize = gridSide / board.size;
        _gridOrigin = const Offset(outerBorderWidth, outerBorderWidth);

        return Center(
          child: Listener(
            onPointerDown: _onPointerDown,
            onPointerMove: _onPointerMove,
            onPointerUp: _onPointerUp,
            onPointerCancel: _onPointerCancel,
            child: _GridFrame(
              gridSide: gridSide,
              child: _GridBody(
                gameState: widget.gameState,
                cellSize: _cellSize,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GridFrame extends StatelessWidget {
  final double gridSide;
  final Widget child;

  const _GridFrame({required this.gridSide, required this.child});

  @override
  Widget build(BuildContext context) => Container(
    width: gridSide + outerBorderWidth * 2,
    height: gridSide + outerBorderWidth * 2,
    decoration: BoxDecoration(
      border: Border.all(color: penBorderColor, width: outerBorderWidth),
      borderRadius: BorderRadius.circular(outerBorderRadius),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(outerBorderRadius - outerBorderWidth),
      child: SizedBox(width: gridSide, height: gridSide, child: child),
    ),
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('gridSide', gridSide));
  }
}

class _GridBody extends StatelessWidget {
  final GamePlaying gameState;
  final double cellSize;

  const _GridBody({required this.gameState, required this.cellSize});

  @override
  Widget build(BuildContext context) {
    final size = gameState.board.size;
    return Column(
      children: List.generate(
        size,
        (row) => Row(
          children: List.generate(
            size,
            (col) => BullpenCell(
              key: ValueKey((row, col)),
              gameState: gameState,
              row: row,
              col: col,
              cellSize: cellSize,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<GamePlaying>('gameState', gameState));
    properties.add(DoubleProperty('cellSize', cellSize));
  }
}
