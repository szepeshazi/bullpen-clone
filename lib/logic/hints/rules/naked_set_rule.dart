import 'package:bullpen/cubit/game_state.dart';
import 'package:bullpen/logic/hints/combinations.dart';
import 'package:bullpen/logic/hints/hint.dart';
import 'package:bullpen/logic/hints/hint_context.dart';
import 'package:bullpen/logic/hints/hint_rule.dart';

/// Pigeonhole on rows/columns: if N rows fully contain N pens, no other pen
/// can place bulls in those rows.
class NakedSetRule extends HintRule {
  const NakedSetRule();

  @override
  Hint? evaluate(HintContext ctx) =>
      _scan(ctx, axis: _Axis.row) ?? _scan(ctx, axis: _Axis.col);

  Hint? _scan(HintContext ctx, {required _Axis axis}) {
    final active = axis == _Axis.row ? ctx.activeRows : ctx.activeCols;
    final counts = axis == _Axis.row ? ctx.rowCounts : ctx.colCounts;
    final penValid = axis == _Axis.row ? ctx.penValidRows : ctx.penValidCols;

    for (
      var subsetSize = 1;
      subsetSize <= active.length && subsetSize <= (ctx.size ~/ 2);
      subsetSize++
    ) {
      for (final subset in combinations(active, subsetSize)) {
        final hint = _checkSubset(ctx, axis, subset, counts, penValid);
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
    Map<int, Set<int>> penValid,
  ) {
    final subsetSet = subset.toSet();
    final remainingCapacity = subset.fold<int>(
      0,
      (sum, i) => sum + 2 - counts[i],
    );

    final containedPenIds = <int>{};
    var remainingNeed = 0;
    for (final pen in ctx.board.pens) {
      final pv = penValid[pen.id]!;
      if (pv.isNotEmpty && subsetSet.containsAll(pv)) {
        containedPenIds.add(pen.id);
        remainingNeed += 2 - (ctx.penCounts[pen.id] ?? 0);
      }
    }

    if (remainingNeed != remainingCapacity || containedPenIds.isEmpty) {
      return null;
    }
    return _firstExcludable(ctx, axis, subset, subsetSet, containedPenIds);
  }

  Hint? _firstExcludable(
    HintContext ctx,
    _Axis axis,
    List<int> subset,
    Set<int> subsetSet,
    Set<int> containedPenIds,
  ) {
    for (final i in subset) {
      for (var j = 0; j < ctx.size; j++) {
        final (r, c) = axis == _Axis.row ? (i, j) : (j, i);
        if (ctx.marks[r][c] != CellMark.empty) continue;
        if (containedPenIds.contains(ctx.board.cellAt(r, c).penId)) continue;
        if (ctx.essential.contains((r, c))) continue;
        return Hint(
          row: r,
          col: c,
          reason: _reason(axis, subset, containedPenIds),
        );
      }
    }
    return null;
  }

  String _reason(_Axis axis, List<int> subset, Set<int> containedPenIds) {
    final labels = subset.map((i) => '${i + 1}').join(', ');
    final nPens = containedPenIds.length;
    final groupWord = axis == _Axis.row
        ? (subset.length == 1 ? 'Row' : 'Rows')
        : (subset.length == 1 ? 'Column' : 'Columns');
    final penWord = nPens == 1 ? 'pen' : 'pens';
    final groupRef = subset.length == 1 ? 'it' : 'them';
    final groupPhrase = subset.length == 1
        ? (axis == _Axis.row ? 'this row' : 'this column')
        : (axis == _Axis.row ? 'these rows' : 'these columns');
    return '$groupWord $labels must supply all bulls for '
        '$nPens $penWord fully within $groupRef '
        '— no room for other pens’ bulls in $groupPhrase';
  }
}

enum _Axis { row, col }
