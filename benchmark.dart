// ignore_for_file: avoid_print -- standalone benchmark script, not library code
import 'lib/logic/grid_generator.dart';
import 'lib/logic/grid_solver.dart';

void main() {
  final sw = Stopwatch();
  for (final size in [8, 9, 10, 11, 12, 13, 14, 15, 16]) {
    var solved = 0;
    var attempts = 0;
    sw
      ..reset()
      ..start();
    while (solved < 3 && attempts < 1000) {
      final board = GridGenerator.generate(size);
      if (GridSolver.solve(board) != null) {
        solved++;
      }
      attempts++;
    }
    sw.stop();
    final msg =
        '${size}x$size: $solved/3 solved in $attempts attempts, '
        '${sw.elapsedMilliseconds}ms';
    print(msg);
    if (solved < 3) {
      print('  WARNING: could not solve 3 grids in 1000 attempts!');
    }
  }
}
