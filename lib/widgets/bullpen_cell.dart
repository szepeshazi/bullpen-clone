import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../cubit/game_state.dart';
import 'grid_constants.dart';
import 'pen_palette.dart';
import 'shaking_bull.dart';

class BullpenCell extends StatelessWidget {
  final GamePlaying gameState;
  final int row;
  final int col;
  final double cellSize;

  const BullpenCell({
    super.key,
    required this.gameState,
    required this.row,
    required this.col,
    required this.cellSize,
  });

  /// top, left, bottom, right.
  static const _borderDirs = [(-1, 0), (0, -1), (1, 0), (0, 1)];

  @override
  Widget build(BuildContext context) {
    final board = gameState.board;
    final cell = board.cellAt(row, col);
    final colors = colorsForPenId(cell.penId);
    final mark = gameState.markAt(row, col);
    final isViolation = gameState.isViolation(row, col);

    final borders = _computePenBorders(board.size, cell.penId);

    return SizedBox(
      width: cellSize,
      height: cellSize,
      child: Container(
        decoration: BoxDecoration(
          color: colors.fill,
          border: Border(
            top: _borderSide(borders[0], colors),
            left: _borderSide(borders[1], colors),
            bottom: _borderSide(borders[2], colors),
            right: _borderSide(borders[3], colors),
          ),
        ),
        child: _markWidget(mark, colors, isViolation),
      ),
    );
  }

  List<bool> _computePenBorders(int size, int penId) {
    final board = gameState.board;
    return _borderDirs.map((d) {
      final nr = row + d.$1, nc = col + d.$2;
      return nr < 0 || nr >= size || nc < 0 || nc >= size ||
          board.cellAt(nr, nc).penId != penId;
    }).toList();
  }

  BorderSide _borderSide(bool isPenEdge, PenColorSet colors) {
    return BorderSide(
      color: isPenEdge ? penBorderColor : colors.cellBorder,
      width: isPenEdge ? penBorderWidth : cellBorderWidth,
    );
  }

  Widget _markWidget(CellMark mark, PenColorSet colors, bool isViolation) {
    switch (mark) {
      case CellMark.bull:
        return isViolation
            ? ShakingBull(cellSize: cellSize, version: gameState.version)
            : Padding(
                padding: EdgeInsets.all(cellSize * bullPaddingFraction),
                child: SvgPicture.asset(bullSvgAsset, fit: BoxFit.contain),
              );
      case CellMark.dot:
        return Center(
          child: Container(
            width: cellSize * dotSizeFraction,
            height: cellSize * dotSizeFraction,
            decoration: BoxDecoration(
              color: colors.dot,
              shape: BoxShape.circle,
              border: Border.all(color: penBorderColor, width: 1.0),
            ),
          ),
        );
      case CellMark.empty:
        return const SizedBox.shrink();
    }
  }
}
