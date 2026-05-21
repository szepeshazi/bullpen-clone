/// Valid grid sizes for a Bullpen puzzle.
const puzzleSupportedSizes = [8, 10, 12];

bool isPuzzleSizeSupported(int size) => puzzleSupportedSizes.contains(size);
