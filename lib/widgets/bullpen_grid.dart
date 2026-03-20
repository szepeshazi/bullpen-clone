import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../cubit/game_cubit.dart';
import '../cubit/game_state.dart';
import '../models/models.dart';
import '../theme.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

/// Pastel pen colours matching the original Bullpen game.
const _penColors = <Color>[
  Color(0xFFF2C6D0), // pink / rose
  Color(0xFFB8E0F6), // light blue
  Color(0xFFF6EABA), // cream / yellow
  Color(0xFFBAE8CE), // mint green
  Color(0xFFCFC4E8), // lavender / purple
  Color(0xFFF5C4B3), // salmon / coral
  Color(0xFFE3F0B0), // lime / yellow-green
  Color(0xFFB8E0F6), // light blue (repeat for larger grids)
  Color(0xFFF2C6D0), // pink
  Color(0xFFF6EABA), // cream
  Color(0xFFBAE8CE), // mint
  Color(0xFFCFC4E8), // lavender
  Color(0xFFF5C4B3), // salmon
  Color(0xFFE3F0B0), // lime
  Color(0xFFD4ECF7), // ice blue
  Color(0xFFFAD8E8), // light pink
];

/// Dark purple/maroon used for pen borders and the outer frame.
const _penBorderColor = bullpenAccentColor;

/// Grid layout constants.
const gridFraction = 0.9;
const _penBorderWidth = 1.0;
const _cellBorderWidth = 0.75;
const outerBorderWidth = 3.5;
const _outerBorderRadius = 12.0;
const _bullPaddingFraction = 0.12;
const _dotSizeFraction = 0.15;

// ---------------------------------------------------------------------------
// Pre-computed colour cache
// ---------------------------------------------------------------------------

class _PenColorSet {
  final Color fill;
  final Color cellBorder;
  final Color dot;

  const _PenColorSet({
    required this.fill,
    required this.cellBorder,
    required this.dot,
  });
}

final Map<Color, _PenColorSet> _colorCache = {};

_PenColorSet _colorsForPen(Color penColor) {
  return _colorCache.putIfAbsent(penColor, () {
    final hsl = HSLColor.fromColor(penColor);
    final cellBorder = hsl
        .withSaturation((hsl.saturation * 1.1).clamp(0.0, 1.0))
        .withLightness((hsl.lightness - 0.08).clamp(0.0, 1.0))
        .toColor();
    final dot = hsl
        .withSaturation((hsl.saturation * 1.4).clamp(0.0, 1.0))
        .withLightness((hsl.lightness - 0.22).clamp(0.0, 1.0))
        .toColor();
    return _PenColorSet(fill: penColor, cellBorder: cellBorder, dot: dot);
  });
}

// ---------------------------------------------------------------------------
// Shared bull SVG asset path
// ---------------------------------------------------------------------------

const _bullSvgAsset = 'assets/bull-head.svg';

// ---------------------------------------------------------------------------
// BullpenGrid
// ---------------------------------------------------------------------------

/// Displays a [PuzzleBoard] with player interaction. Shows empty pens initially.
/// Tap to toggle dot marks, long-press to place/remove bulls, drag to place
/// a continuous stream of dots.
class BullpenGrid extends StatefulWidget {
  final GamePlaying gameState;

  const BullpenGrid({super.key, required this.gameState});

  @override
  State<BullpenGrid> createState() => _BullpenGridState();
}

class _BullpenGridState extends State<BullpenGrid> {
  // Grid geometry (set in build via LayoutBuilder).
  double _cellSize = 0;
  Offset _gridOrigin = Offset.zero;

  // Gesture state — we handle raw pointer events to avoid gesture arena
  // conflicts between tap, drag, and long-press.
  static const _dragThreshold = 8.0; // px to distinguish tap from drag
  static const _longPressDuration = Duration(milliseconds: 400);

  Offset? _downPos;
  bool _isDragging = false;
  bool _isLongPress = false;
  (int, int)? _lastDragCell;
  int? _activePointer;

  /// Converts a local position (relative to the grid container) to (row, col),
  /// or null if outside the grid.
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

    // Start long-press timer.
    final pointer = event.pointer;
    Future.delayed(_longPressDuration, () {
      if (_activePointer == pointer && !_isDragging) {
        _isLongPress = true;
        final cell = _lastDragCell;
        if (cell != null) {
          final (row, col) = cell;
          HapticFeedback.mediumImpact();
          context.read<GameCubit>().toggleBull(row, col);
        }
      }
    });
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (event.pointer != _activePointer || _isLongPress) return;

    final distance = (event.localPosition - _downPos!).distance;

    if (!_isDragging && distance >= _dragThreshold) {
      // Transition from potential tap to drag.
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
      // End drag.
      context.read<GameCubit>().endDotDrag();
    } else if (!_isLongPress) {
      // Short tap — toggle dot.
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
        // The grid origin within the outer container (accounts for border).
        _gridOrigin = Offset(outerBorderWidth, outerBorderWidth);

        return Center(
          child: Listener(
            onPointerDown: _onPointerDown,
            onPointerMove: _onPointerMove,
            onPointerUp: _onPointerUp,
            onPointerCancel: _onPointerCancel,
            child: Container(
              width: gridSide + outerBorderWidth * 2,
              height: gridSide + outerBorderWidth * 2,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _penBorderColor,
                  width: outerBorderWidth,
                ),
                borderRadius: BorderRadius.circular(_outerBorderRadius),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(
                    _outerBorderRadius - outerBorderWidth),
                child: SizedBox(
                  width: gridSide,
                  height: gridSide,
                  child: Column(
                    children: List.generate(board.size, (row) {
                      return Row(
                        children: List.generate(board.size, (col) {
                          return _CellWidget(
                            key: ValueKey((row, col)),
                            gameState: widget.gameState,
                            row: row,
                            col: col,
                            cellSize: _cellSize,
                          );
                        }),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// _CellWidget — pure display, no gesture handling
// ---------------------------------------------------------------------------

class _CellWidget extends StatelessWidget {
  final GamePlaying gameState;
  final int row;
  final int col;
  final double cellSize;

  const _CellWidget({
    super.key,
    required this.gameState,
    required this.row,
    required this.col,
    required this.cellSize,
  });

  /// Directions: top, left, bottom, right.
  static const _borderDirs = [(-1, 0), (0, -1), (1, 0), (0, 1)];

  @override
  Widget build(BuildContext context) {
    final board = gameState.board;
    final cell = board.cellAt(row, col);
    final penId = cell.penId;
    final colors = _colorsForPen(_penColors[penId % _penColors.length]);
    final mark = gameState.markAt(row, col);
    final isViolation = gameState.isViolation(row, col);

    final borders = _borderDirs.map((d) {
      final nr = row + d.$1, nc = col + d.$2;
      return nr < 0 || nr >= board.size || nc < 0 || nc >= board.size ||
          board.cellAt(nr, nc).penId != penId;
    }).toList();
    final bt = borders[0], bl = borders[1], bb = borders[2], br = borders[3];

    Widget cellContent;
    switch (mark) {
      case CellMark.bull:
        cellContent = isViolation
            ? _ShakingBull(cellSize: cellSize, version: gameState.version)
            : Padding(
                padding: EdgeInsets.all(cellSize * _bullPaddingFraction),
                child: SvgPicture.asset(_bullSvgAsset, fit: BoxFit.contain),
              );
      case CellMark.dot:
        cellContent = Center(
          child: Container(
            width: cellSize * _dotSizeFraction,
            height: cellSize * _dotSizeFraction,
            decoration: BoxDecoration(
              color: colors.dot,
              shape: BoxShape.circle,
              border: Border.all(
                color: _penBorderColor,
                width: 1.0,
              ),
            ),
          ),
        );
      case CellMark.empty:
        cellContent = const SizedBox.shrink();
    }

    return SizedBox(
      width: cellSize,
      height: cellSize,
      child: Container(
        decoration: BoxDecoration(
          color: colors.fill,
          border: Border(
            top: BorderSide(
              color: bt ? _penBorderColor : colors.cellBorder,
              width: bt ? _penBorderWidth : _cellBorderWidth,
            ),
            left: BorderSide(
              color: bl ? _penBorderColor : colors.cellBorder,
              width: bl ? _penBorderWidth : _cellBorderWidth,
            ),
            bottom: BorderSide(
              color: bb ? _penBorderColor : colors.cellBorder,
              width: bb ? _penBorderWidth : _cellBorderWidth,
            ),
            right: BorderSide(
              color: br ? _penBorderColor : colors.cellBorder,
              width: br ? _penBorderWidth : _cellBorderWidth,
            ),
          ),
        ),
        child: cellContent,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _ShakingBull — bull icon with a horizontal shake animation
// ---------------------------------------------------------------------------

class _ShakingBull extends StatefulWidget {
  final double cellSize;
  final int version;
  const _ShakingBull({required this.cellSize, required this.version});

  @override
  State<_ShakingBull> createState() => _ShakingBullState();
}

class _ShakingBullState extends State<_ShakingBull>
    with TickerProviderStateMixin {
  late final AnimationController _shakeController;
  late final AnimationController _smokeController;
  late final Animation<double> _shakeX;
  late final Animation<double> _shakeY;
  late final Animation<double> _smokeAnimation;
  late final Animation<double> _redAnimation;

  /// Builds a randomised shake tween sequence with [numSteps] oscillations.
  /// Each step picks a random magnitude in [−maxAmp, maxAmp] that decays
  /// over time, creating a jittery, organic tremor.
  static TweenSequence<double> _randomShake(
    Random rng,
    int numSteps,
    double maxAmp,
  ) {
    final items = <TweenSequenceItem<double>>[];
    double prev = 0;
    for (int i = 0; i < numSteps; i++) {
      // Decay amplitude over the sequence.
      final decay = 1.0 - i / numSteps;
      final amp = maxAmp * decay;
      // Random target, alternating sign bias for oscillation feel.
      final sign = (i.isEven ? 1.0 : -1.0) * (0.5 + rng.nextDouble() * 0.5);
      final target = sign * amp * (0.4 + rng.nextDouble() * 0.6);
      items.add(TweenSequenceItem(
        tween: Tween(begin: prev, end: target),
        weight: 1.0 + rng.nextDouble(),
      ));
      prev = target;
    }
    // Return to zero.
    items.add(TweenSequenceItem(
      tween: Tween(begin: prev, end: 0),
      weight: 1,
    ));
    return TweenSequence(items);
  }

  @override
  void initState() {
    super.initState();
    final rng = Random();

    // Shake — short, intense tremor.
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _shakeX = _randomShake(rng, 18, 16).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.easeOut),
    );
    _shakeY = _randomShake(rng, 18, 8).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.easeOut),
    );

    // Red glow: ramps up instantly, holds at high intensity, stays until
    // the conflict is resolved (widget unmounts).
    _redAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 0.75), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.75, end: 0.70), weight: 7),
    ]).animate(_shakeController);

    // Smoke puffs — 3 repeated bursts.
    _smokeController = AnimationController(
      duration: const Duration(milliseconds: 2400),
      vsync: this,
    );
    _smokeAnimation = CurvedAnimation(
      parent: _smokeController,
      curve: Curves.linear,
    );

    _shakeController.forward();
    _smokeController.forward();
  }

  @override
  void didUpdateWidget(covariant _ShakingBull oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.version != widget.version) {
      // New violation event — restart the shake and smoke.
      _shakeController.forward(from: 0);
      _smokeController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _smokeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.cellSize;

    return AnimatedBuilder(
      animation: Listenable.merge([_shakeX, _shakeY, _smokeAnimation]),
      builder: (context, child) {
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Smoke puffs — positioned near the nostrils (bottom-center).
              ..._buildSmokePuffs(size),
              // Bull with shake + glowing red tint.
              Transform.translate(
                offset: Offset(_shakeX.value, _shakeY.value),
                child: Padding(
                  padding: EdgeInsets.all(size * _bullPaddingFraction),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withValues(
                            alpha: _redAnimation.value * 0.8,
                          ),
                          blurRadius: size * 0.3,
                          spreadRadius: size * 0.05,
                        ),
                      ],
                    ),
                    child: ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        Colors.red.withValues(alpha: _redAnimation.value),
                        BlendMode.srcATop,
                      ),
                      child: child,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      child: SvgPicture.asset(_bullSvgAsset, fit: BoxFit.contain),
    );
  }

  /// Number of repeated smoke bursts.
  static const _smokeRepetitions = 3;

  // Smoke puff definitions per burst: (dx, dy, timeFactor, opacityFactor, sizeFactor).
  // Mirrored for left (negative dx) and right (positive dx) nostrils.
  static const _puffParams = [
    (0.30, 0.60, 1.0, 1.0, 0.9),
    (0.42, 0.48, 0.85, 0.85, 0.7),
    (0.22, 0.44, 0.70, 0.65, 0.55),
    (0.15, 0.62, 0.55, 0.50, 0.50),
  ];

  List<Widget> _buildSmokePuffs(double cellSize) {
    final raw = _smokeAnimation.value;
    if (raw <= 0.005) return [];

    final widgets = <Widget>[];

    // Split the overall animation [0..1] into _smokeRepetitions bursts.
    for (int burst = 0; burst < _smokeRepetitions; burst++) {
      final burstStart = burst / _smokeRepetitions;
      final burstEnd = (burst + 1) / _smokeRepetitions;

      if (raw < burstStart || raw > burstEnd) continue;

      // Local t within this burst: 0..1
      final t = ((raw - burstStart) / (burstEnd - burstStart)).clamp(0.0, 1.0);
      // Ease out each burst.
      final eased = Curves.easeOut.transform(t);

      // Opacity: appear quickly, fade out over the burst.
      final opacity = eased < 0.25 ? eased / 0.25 : (1.0 - eased) / 0.75;
      // Each successive burst is slightly smaller (diminishing anger).
      final burstScale = 1.0 - burst * 0.15;

      for (final (dx, dy, tf, of_, sf) in _puffParams) {
        final scaledSf = sf * burstScale;
        widgets.add(_smokePuff(cellSize, -dx, dy, eased * tf, opacity * of_, scaledSf));
        widgets.add(_smokePuff(cellSize, dx, dy, eased * tf, opacity * of_, scaledSf));
      }
    }

    return widgets;
  }

  /// A single smoke puff cloud.
  /// [dx] and [dy] are direction offsets from center-bottom of the cell,
  /// scaled by animation progress [t].
  Widget _smokePuff(
    double cellSize,
    double dx,
    double dy,
    double t,
    double opacity,
    double sizeFactor,
  ) {
    final puffSize = cellSize * sizeFactor * (0.3 + t * 0.7);
    // Start from nostrils (center-bottom area), drift outward and down.
    final x = cellSize / 2 + dx * cellSize * t - puffSize / 2;
    final y = cellSize * 0.65 + dy * cellSize * t - puffSize / 2;

    return Positioned(
      left: x,
      top: y,
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: Container(
          width: puffSize,
          height: puffSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.grey.shade400.withValues(alpha: opacity.clamp(0.0, 1.0) * 0.6),
              width: 1.0,
            ),
            gradient: RadialGradient(
              colors: [
                Colors.white,
                Colors.grey.shade200,
                Colors.grey.shade300.withValues(alpha: 0.0),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// CelebrationOverlay — confetti and congratulations
// ---------------------------------------------------------------------------

class CelebrationOverlay extends StatefulWidget {
  final VoidCallback onDismiss;
  const CelebrationOverlay({super.key, required this.onDismiss});

  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<CelebrationOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final AnimationController _confettiController;
  late final Animation<double> _fadeIn;
  late final Animation<double> _scaleIn;
  final _random = Random();
  late final List<_ConfettiPiece> _confetti;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeIn = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _scaleIn = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.elasticOut),
    );

    _confettiController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    // Generate confetti pieces.
    _confetti = List.generate(80, (_) => _ConfettiPiece.random(_random));

    _fadeController.forward();
    _confettiController.repeat();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onDismiss,
      child: FadeTransition(
        opacity: _fadeIn,
        child: Stack(
          children: [
            // Dimmed background.
            Container(color: Colors.black.withValues(alpha: 0.5)),

            // Confetti.
            AnimatedBuilder(
              animation: _confettiController,
              builder: (context, _) => CustomPaint(
                painter: _ConfettiPainter(
                  confetti: _confetti,
                  progress: _confettiController.value,
                ),
                size: MediaQuery.of(context).size,
              ),
            ),

            // Center message.
            Center(
              child: ScaleTransition(
                scale: _scaleIn,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '🎉',
                        style: TextStyle(fontSize: 64),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Congratulations!',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: bullpenAccentColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'All bulls are in their pens!',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Tap anywhere to continue',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade400,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Confetti rendering
// ---------------------------------------------------------------------------

class _ConfettiPiece {
  final double x; // 0..1 horizontal position
  final double startY; // starting vertical offset (-0.2..0)
  final double speed; // fall speed multiplier
  final double size;
  final double rotation;
  final double wobbleSpeed;
  final double wobbleAmount;
  final Color color;

  const _ConfettiPiece({
    required this.x,
    required this.startY,
    required this.speed,
    required this.size,
    required this.rotation,
    required this.wobbleSpeed,
    required this.wobbleAmount,
    required this.color,
  });

  static const _colors = [
    Color(0xFFFF6B6B),
    Color(0xFFFFD93D),
    Color(0xFF6BCB77),
    Color(0xFF4D96FF),
    Color(0xFFF2C6D0),
    Color(0xFFCFC4E8),
    Color(0xFFFF8C42),
    Color(0xFF42E8E0),
  ];

  factory _ConfettiPiece.random(Random rng) {
    return _ConfettiPiece(
      x: rng.nextDouble(),
      startY: -rng.nextDouble() * 0.3,
      speed: 0.3 + rng.nextDouble() * 0.7,
      size: 4 + rng.nextDouble() * 8,
      rotation: rng.nextDouble() * pi * 2,
      wobbleSpeed: 1 + rng.nextDouble() * 3,
      wobbleAmount: 0.02 + rng.nextDouble() * 0.04,
      color: _colors[rng.nextInt(_colors.length)],
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiPiece> confetti;
  final double progress;

  _ConfettiPainter({required this.confetti, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final piece in confetti) {
      final t = (progress * piece.speed + piece.startY) % 1.3;
      final y = t * size.height * 1.2;
      final wobble = sin(t * piece.wobbleSpeed * pi * 2) * piece.wobbleAmount;
      final x = (piece.x + wobble) * size.width;

      final paint = Paint()..color = piece.color;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(piece.rotation + progress * pi * 2 * piece.speed);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset.zero, width: piece.size, height: piece.size * 0.6),
          Radius.circular(piece.size * 0.1),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
