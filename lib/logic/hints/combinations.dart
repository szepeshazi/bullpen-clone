/// Yields all combinations of [k] elements from [items].
Iterable<List<int>> combinations(List<int> items, int k) sync* {
  if (k == 0 || k > items.length) {
    return;
  }
  if (k == 1) {
    for (final item in items) {
      yield [item];
    }
    return;
  }
  final indices = List.generate(k, (i) => i);
  yield [for (final i in indices) items[i]];
  while (true) {
    var i = k - 1;
    while (i >= 0 && indices[i] == i + items.length - k) {
      i--;
    }
    if (i < 0) {
      return;
    }
    indices[i]++;
    for (var j = i + 1; j < k; j++) {
      indices[j] = indices[j - 1] + 1;
    }
    yield [for (final i in indices) items[i]];
  }
}
