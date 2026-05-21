/// Whether a hint excludes a cell or identifies a forced bull placement.
enum HintType { exclude, mustPlace }

/// A hint that identifies a cell which can be excluded or must contain a bull.
class Hint {
  final int row;
  final int col;
  final String reason;
  final HintType type;

  const Hint({
    required this.row,
    required this.col,
    required this.reason,
    this.type = HintType.exclude,
  });
}
