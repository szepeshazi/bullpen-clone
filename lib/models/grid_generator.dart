import 'dart:math';

import 'cell.dart';
import 'pen.dart';
import 'puzzle_board.dart';

/// Generates a random Bullpen grid by partitioning the grid into
/// [size] contiguous pens of approximately equal size.
class GridGenerator {
  GridGenerator._();

  /// Generates a [PuzzleBoard] of the given [size] with randomly shaped pens.
  ///
  /// The grid is partitioned into exactly [size] pens. Each pen is a
  /// contiguous region of cells. The algorithm uses a seeded flood-fill
  /// approach: it places one seed per pen, then iteratively grows each
  /// pen by claiming adjacent unassigned cells until the grid is full.
  static PuzzleBoard generate(int size, {Random? random}) {
    if (size < 8 || size > 16) {
      throw ArgumentError('Grid size must be between 8 and 16, got $size');
    }

    final rng = random ?? Random();
    final numPens = size;
    final totalCells = size * size;

    // Assign target sizes: some pens are small (3–5 cells), the rest share
    // the remaining cells roughly equally.
    final targetSizes = _assignTargetSizes(numPens, totalCells, rng);

    // penAssignment[row][col] = penId or -1 if unassigned.
    final penAssignment = List.generate(
      size,
      (_) => List.filled(size, -1),
    );

    // Place seeds: spread them as evenly as possible across the grid.
    final seeds = _placeSeedsRandomly(size, numPens, rng);
    final frontiers = <int, List<(int, int)>>{};
    final penSizes = List.filled(numPens, 1); // seeds count as 1

    for (int penId = 0; penId < numPens; penId++) {
      final (r, c) = seeds[penId];
      penAssignment[r][c] = penId;
      frontiers[penId] = _neighbors(r, c, size)
          .where((n) => penAssignment[n.$1][n.$2] == -1)
          .toList();
    }

    // Phase 1: grow pens respecting target sizes.
    int assigned = numPens; // seeds are already assigned.
    int maxIterations = totalCells * 10; // safety valve
    while (assigned < totalCells && maxIterations-- > 0) {
      bool grew = false;
      for (int penId = 0; penId < numPens; penId++) {
        if (penSizes[penId] >= targetSizes[penId]) continue;
        if (_growPen(penId, penAssignment, frontiers, penSizes, size, rng)) {
          assigned++;
          grew = true;
        }
      }
      if (!grew) break; // no pen could grow — move to phase 2
    }

    // Phase 2: fill remaining cells ignoring target sizes.
    // Prefer growing the smallest pens first to avoid huge imbalances.
    maxIterations = totalCells * 10;
    while (assigned < totalCells && maxIterations-- > 0) {
      // Sort pen IDs by current size (smallest first).
      final order = List.generate(numPens, (i) => i)
        ..sort((a, b) => penSizes[a].compareTo(penSizes[b]));
      bool grew = false;
      for (final penId in order) {
        if (_growPen(penId, penAssignment, frontiers, penSizes, size, rng)) {
          assigned++;
          grew = true;
        }
      }
      if (!grew) break;
    }

    // Fallback: assign any remaining unassigned cells (run multiple passes
    // to handle clusters of unassigned cells).
    bool changed = true;
    while (changed) {
      changed = false;
      for (int r = 0; r < size; r++) {
        for (int c = 0; c < size; c++) {
          if (penAssignment[r][c] != -1) continue;
          for (final (nr, nc) in _neighbors(r, c, size)) {
            if (penAssignment[nr][nc] != -1) {
              penAssignment[r][c] = penAssignment[nr][nc];
              changed = true;
              break;
            }
          }
        }
      }
    }

    // Build Cell and Pen objects.
    final penCells = <int, List<Cell>>{};
    for (int penId = 0; penId < numPens; penId++) {
      penCells[penId] = [];
    }

    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        final penId = penAssignment[r][c];
        final cell = Cell(row: r, col: c, penId: penId);
        penCells[penId]!.add(cell);
      }
    }

    final pens = <Pen>[];
    for (int penId = 0; penId < numPens; penId++) {
      pens.add(Pen(id: penId, cells: penCells[penId]!));
    }

    return PuzzleBoard(size: size, pens: pens);
  }

  /// Tries to grow [penId] by one cell. Returns true if successful.
  static bool _growPen(
    int penId,
    List<List<int>> penAssignment,
    Map<int, List<(int, int)>> frontiers,
    List<int> penSizes,
    int size,
    Random rng,
  ) {
    final frontier = frontiers[penId]!;
    frontier.removeWhere((n) => penAssignment[n.$1][n.$2] != -1);
    if (frontier.isEmpty) return false;

    final idx = rng.nextInt(frontier.length);
    final (r, c) = frontier[idx];
    if (penAssignment[r][c] != -1) return false;

    penAssignment[r][c] = penId;
    penSizes[penId]++;

    for (final n in _neighbors(r, c, size)) {
      if (penAssignment[n.$1][n.$2] == -1) {
        frontier.add(n);
      }
    }
    return true;
  }

  /// Minimum small pen size. Pens of 3 cells in compact shapes can have
  /// all cells mutually adjacent, making it impossible to place 2
  /// non-adjacent bulls. 5 cells guarantees enough room.
  static const _minSmallPenSize = 5;

  /// Assigns a target cell count to each pen. A random subset of pens
  /// gets a small target (5–6 cells); the remaining cells are distributed
  /// evenly among the other pens.
  static List<int> _assignTargetSizes(int numPens, int totalCells, Random rng) {
    final avgSize = totalCells ~/ numPens;
    // Only create small pens if the average pen size is large enough
    // to accommodate them (need headroom for larger pens too).
    if (avgSize < _minSmallPenSize + 2) {
      // Uniform distribution — grid too small for meaningful variation.
      return _uniformTargets(numPens, totalCells);
    }

    // Choose how many small pens to create (roughly 20-35% of pens).
    final minSmall = (numPens * 0.2).floor().clamp(1, numPens - 1);
    final maxSmall = (numPens * 0.35).ceil().clamp(minSmall, numPens - 1);
    final numSmall = minSmall + rng.nextInt(maxSmall - minSmall + 1);

    // Shuffle pen indices to randomise which pens are small.
    final indices = List.generate(numPens, (i) => i)..shuffle(rng);
    final smallIndices = indices.sublist(0, numSmall).toSet();

    final targets = List.filled(numPens, 0);
    int usedCells = 0;

    // Assign small pen sizes (5–6 cells each).
    for (final i in smallIndices) {
      targets[i] = _minSmallPenSize + rng.nextInt(2); // 5 or 6
      usedCells += targets[i];
    }

    // Distribute remaining cells among non-small pens.
    final numLarge = numPens - numSmall;
    final remaining = totalCells - usedCells;
    final baseSize = remaining ~/ numLarge;
    int extra = remaining - baseSize * numLarge;

    for (int i = 0; i < numPens; i++) {
      if (smallIndices.contains(i)) continue;
      targets[i] = baseSize + (extra > 0 ? 1 : 0);
      if (extra > 0) extra--;
    }

    return targets;
  }

  /// Returns uniform target sizes when the grid is too small for variation.
  static List<int> _uniformTargets(int numPens, int totalCells) {
    final baseSize = totalCells ~/ numPens;
    int extra = totalCells - baseSize * numPens;
    return List.generate(numPens, (i) {
      final size = baseSize + (extra > 0 ? 1 : 0);
      if (extra > 0) extra--;
      return size;
    });
  }

  /// Places [count] seed positions spread across the grid with some
  /// randomness so pens don't look too uniform.
  static List<(int, int)> _placeSeedsRandomly(
    int size,
    int count,
    Random rng,
  ) {
    final seeds = <(int, int)>{};

    // Use a grid-based approach: divide into roughly sqrt(count) × sqrt(count)
    // regions and pick one random cell per region.
    final divisions = sqrt(count).ceil();
    final cellSize = size / divisions;

    for (int gr = 0; gr < divisions && seeds.length < count; gr++) {
      for (int gc = 0; gc < divisions && seeds.length < count; gc++) {
        final rStart = (gr * cellSize).floor();
        final rEnd = ((gr + 1) * cellSize).floor().clamp(0, size);
        final cStart = (gc * cellSize).floor();
        final cEnd = ((gc + 1) * cellSize).floor().clamp(0, size);

        if (rEnd <= rStart || cEnd <= cStart) continue;

        final r = rStart + rng.nextInt(rEnd - rStart);
        final c = cStart + rng.nextInt(cEnd - cStart);
        seeds.add((r, c));
      }
    }

    // Fill remaining seeds randomly if needed.
    while (seeds.length < count) {
      seeds.add((rng.nextInt(size), rng.nextInt(size)));
    }

    return seeds.toList();
  }

  /// Returns orthogonal (4-connected) neighbors of (r, c) within the grid.
  static List<(int, int)> _neighbors(int r, int c, int size) {
    return [
      if (r > 0) (r - 1, c),
      if (r < size - 1) (r + 1, c),
      if (c > 0) (r, c - 1),
      if (c < size - 1) (r, c + 1),
    ];
  }
}
