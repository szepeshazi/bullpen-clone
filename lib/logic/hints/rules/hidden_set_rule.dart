import 'package:bullpen/cubit/game_state.dart';
import 'package:bullpen/logic/hints/combinations.dart';
import 'package:bullpen/logic/hints/hint.dart';
import 'package:bullpen/logic/hints/hint_context.dart';
import 'package:bullpen/logic/hints/hint_rule.dart';

/// Dual of NakedSet: if N rows can serve only N pens, those pens must place
/// all bulls within those rows — exclude their cells elsewhere.
class HiddenSetRule extends HintRule {
  const HiddenSetRule();

  @override
  Hint? evaluate(HintContext ctx) => _scan(ctx, axis: _Axis.row) ?? _scan(ctx, axis: _Axis.col);

  Hint? _scan(HintContext ctx, {required _Axis axis}) {
    final active = axis == _Axis.row ? ctx.activeRows : ctx.activeCols;
    final counts = axis == _Axis.row ? ctx.rowCounts : ctx.colCounts;
    final toPens = axis == _Axis.row ? ctx.rowToPens : ctx.colToPens;

    for (var subsetSize = 1;
        subsetSize <= active.length && subsetSize <= (ctx.size ~/ 2);
        subsetSize++) {
      for (final subset in combinations(active, subsetSize)) {
        final hint = _checkSubset(ctx, axis, subset, counts, toPens);
        if (hint != null) return hint;
      }
    }
    return null;
  }

  Hint? _checkSubset(
    HintContext ctx,
    _Axis axis,
    List<int> subset,
    List<int> counts,
    Map<int, Set<int>> toPens,
  ) {
    final touching = <int>{};
    for (final i in subset) {
      touching.addAll(toPens[i] ?? const {});
    }
    if (touching.length < 2) return null;

    final remainingCapacity =
        subset.fold<int>(0, (sum, i) => sum + 2 - counts[i]);
    final remainingNeed = touching.fold<int>(
      0,
      (sum, penId) => sum + 2 - (ctx.penCounts[penId] ?? 0),
    );
    if (remainingNeed != remainingCapacity) return null;

    final subsetSet = subset.toSet();
    for (final penId in touching) {
      final pen = ctx.board.penById(penId);
      for (final cell in pen.cells) {
        final group = axis == _Axis.row ? cell.row : cell.col;
        if (subsetSet.contains(group)) continue;
        if (ctx.marks[cell.row][cell.col] != CellMark.empty) continue;
        if (ctx.essential.contains((cell.row, cell.col))) continue;
        return Hint(
          row: cell.row,
          col: cell.col,
          reason: _reason(axis, subset, touching.length),
        );
      }
    }
    return null;
  }

  String _reason(_Axis axis, List<int> subset, int penCount) {
    final labels = subset.map((i) => '${i + 1}').join(', ');
    final groupWord = axis == _Axis.row
        ? (subset.length == 1 ? 'Row' : 'Rows')
        : (subset.length == 1 ? 'Column' : 'Columns');
    return '$groupWord $labels can only serve $penCount pens '
        '— this pen must place its bulls there, not here';
  }
}

enum _Axis { row, col }
