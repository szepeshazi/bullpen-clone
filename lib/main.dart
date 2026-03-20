import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'dart:math' show min;

import 'cubit/game_cubit.dart';
import 'cubit/game_state.dart';
import 'theme.dart';
import 'widgets/bullpen_grid.dart';

void main() {
  runApp(const BullpenApp());
}

class BullpenApp extends StatelessWidget {
  const BullpenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bullpen',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: bullpenBgColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: bullpenAccentColor,
          surface: bullpenBgColor,
        ),
        useMaterial3: true,
      ),
      home: BlocProvider(
        create: (_) => GameCubit(),
        child: const BullpenHomePage(),
      ),
    );
  }
}

class BullpenHomePage extends StatelessWidget {
  const BullpenHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            const _ControlsRow(),
            const SizedBox(height: 8),
            const Expanded(child: _GridArea()),
            const SizedBox(height: 8),
            const _RemainingBullsIndicator(),
            const _HintReasonBanner(),
            const _UndoRedoRow(),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Controls row
// ---------------------------------------------------------------------------

class _ControlsRow extends StatelessWidget {
  const _ControlsRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          const Text(
            'Grid size',
            style: TextStyle(
              color: bullpenAccentColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 12),
          const _GridSizeDropdown(),
          const Spacer(),
          const _GenerateButton(),
        ],
      ),
    );
  }
}

class _GridSizeDropdown extends StatelessWidget {
  const _GridSizeDropdown();

  @override
  Widget build(BuildContext context) {
    final gridSize = context.select<GameCubit, int>((c) => c.gridSize);
    final isGenerating = context.select<GameCubit, bool>(
      (c) => c.state is GameGenerating,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: bullpenAccentColor.withValues(alpha: 0.4)),
      ),
      child: DropdownButton<int>(
        value: gridSize,
        underline: const SizedBox.shrink(),
        isDense: true,
        dropdownColor: Colors.white,
        style: const TextStyle(
          color: bullpenAccentColor,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        items: List.generate(9, (i) {
          final size = i + 8;
          return DropdownMenuItem(
            value: size,
            child: Text('$size × $size'),
          );
        }),
        onChanged: isGenerating
            ? null
            : (v) {
                if (v != null) context.read<GameCubit>().setGridSize(v);
              },
      ),
    );
  }
}

class _GenerateButton extends StatelessWidget {
  const _GenerateButton();

  @override
  Widget build(BuildContext context) {
    final isGenerating = context.select<GameCubit, bool>(
      (c) => c.state is GameGenerating,
    );

    return ElevatedButton.icon(
      onPressed: isGenerating
          ? null
          : () => context.read<GameCubit>().generate(),
      icon: isGenerating
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.refresh, size: 20),
      label: Text(isGenerating ? 'Generating…' : 'Generate'),
      style: ElevatedButton.styleFrom(
        backgroundColor: bullpenAccentColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Remaining bulls indicator
// ---------------------------------------------------------------------------

class _RemainingBullsIndicator extends StatelessWidget {
  const _RemainingBullsIndicator();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<GameCubit, GameState,
        ({int remaining, bool visible})>(
      selector: (state) {
        if (state is GamePlaying && !state.solved) {
          final total = 2 * state.board.size;
          var placed = 0;
          for (final row in state.marks) {
            for (final cell in row) {
              if (cell == CellMark.bull) placed++;
            }
          }
          return (remaining: total - placed, visible: true);
        }
        return (remaining: 0, visible: false);
      },
      builder: (context, s) {
        if (!s.visible) return const SizedBox.shrink();
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Remaining bulls',
              style: TextStyle(
                color: bullpenAccentColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                alignment: WrapAlignment.center,
                children: List.generate(
                  s.remaining,
                  (_) => Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: bullpenAccentColor,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Undo / Redo row
// ---------------------------------------------------------------------------

class _UndoRedoRow extends StatelessWidget {
  const _UndoRedoRow();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<GameCubit, GameState, ({bool canUndo, bool canRedo, bool visible})>(
      selector: (state) {
        if (state is GamePlaying && !state.solved) {
          return (canUndo: state.canUndo, canRedo: state.canRedo, visible: true);
        }
        return (canUndo: false, canRedo: false, visible: false);
      },
      builder: (context, s) {
        if (!s.visible) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: s.canUndo
                    ? () => context.read<GameCubit>().undo()
                    : null,
                icon: const Icon(Icons.undo),
                tooltip: 'Undo',
                color: bullpenAccentColor,
                disabledColor: bullpenAccentColor.withValues(alpha: 0.3),
                iconSize: 28,
              ),
              const SizedBox(width: 24),
              IconButton(
                onPressed: s.canRedo
                    ? () => context.read<GameCubit>().redo()
                    : null,
                icon: const Icon(Icons.redo),
                tooltip: 'Redo',
                color: bullpenAccentColor,
                disabledColor: bullpenAccentColor.withValues(alpha: 0.3),
                iconSize: 28,
              ),
              const SizedBox(width: 24),
              IconButton(
                onPressed: () => context.read<GameCubit>().requestHint(),
                icon: const Icon(Icons.lightbulb_outline),
                tooltip: 'Hint',
                color: bullpenAccentColor,
                iconSize: 28,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Hint reason banner
// ---------------------------------------------------------------------------

class _HintReasonBanner extends StatelessWidget {
  const _HintReasonBanner();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<GameCubit, GameState, String?>(
      selector: (state) =>
          state is GamePlaying ? state.hintReason : null,
      builder: (context, reason) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: reason != null
              ? Padding(
                  key: ValueKey(reason),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.7),
                      border: Border.all(
                        color: bullpenAccentColor.withValues(alpha: 0.3),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lightbulb,
                            size: 16, color: bullpenAccentColor),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            reason,
                            style: const TextStyle(
                              color: bullpenAccentColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Grid area
// ---------------------------------------------------------------------------

class _GridArea extends StatelessWidget {
  const _GridArea();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GameCubit, GameState>(
      listenWhen: (prev, curr) => curr is GameError,
      listener: (context, state) {
        if (state is GameError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is GameGenerating) {
          return const Center(
            child: CircularProgressIndicator(color: bullpenAccentColor),
          );
        }
        if (state is GamePlaying) {
          return LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: BullpenGrid(gameState: state),
                  ),
                  if (state.hasHint)
                    _HintArrowOverlay(
                      hintCell: state.hintCell!,
                      boardSize: state.board.size,
                      areaWidth: constraints.maxWidth,
                      areaHeight: constraints.maxHeight,
                    ),
                  if (state.solved)
                    Positioned.fill(
                      child: CelebrationOverlay(
                        onDismiss: () => context.read<GameCubit>().generate(),
                      ),
                    ),
                ],
              );
            },
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Hint arrow overlay
// ---------------------------------------------------------------------------

class _HintArrowOverlay extends StatefulWidget {
  final (int, int) hintCell;
  final int boardSize;
  final double areaWidth;
  final double areaHeight;

  const _HintArrowOverlay({
    required this.hintCell,
    required this.boardSize,
    required this.areaWidth,
    required this.areaHeight,
  });

  @override
  State<_HintArrowOverlay> createState() => _HintArrowOverlayState();
}

class _HintArrowOverlayState extends State<_HintArrowOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _bounceController;
  late final Animation<double> _bounceOffset;
  late final AnimationController _fadeController;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);
    _bounceOffset = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    )..forward();
    _fadeIn = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (row, col) = widget.hintCell;
    const padding = 12.0;
    final availW = widget.areaWidth - padding * 2;
    final availH = widget.areaHeight - padding * 2;
    final maxSide = min(availW, availH);
    final gridSide = maxSide * gridFraction;
    final cellSize = gridSide / widget.boardSize;
    final gridContainer = gridSide + outerBorderWidth * 2;

    // Center offset within the padded area, then add the padding back.
    final originX = padding + (availW - gridContainer) / 2 + outerBorderWidth;
    final originY = padding + (availH - gridContainer) / 2 + outerBorderWidth;

    final cellCenterX = originX + (col + 0.5) * cellSize;
    final cellCenterY = originY + (row + 0.5) * cellSize;

    final arrowLen = cellSize * 0.55;

    return AnimatedBuilder(
      animation: Listenable.merge([_bounceOffset, _fadeIn]),
      builder: (context, child) {
        // Bounce diagonally: arrow slides from bottom-right toward top-left.
        // At rest (bounce=0) the tip sits exactly at cell center.
        final bounce = _bounceOffset.value;
        final dx = bounce * 0.707;
        final dy = bounce * 0.707;

        return Positioned(
          left: cellCenterX + dx,
          top: cellCenterY + dy,
          child: Opacity(
            opacity: _fadeIn.value,
            child: CustomPaint(
              size: Size(arrowLen, arrowLen),
              painter: _DiagonalArrowPainter(color: bullpenAccentColor),
            ),
          ),
        );
      },
    );
  }
}

class _DiagonalArrowPainter extends CustomPainter {
  final Color color;
  const _DiagonalArrowPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width; // square canvas

    // Mouse-pointer cursor shape pointing top-left, symmetric along
    // the diagonal (y=x) axis. Tip at (0, 0), body extends down-right.
    final path = Path()
      ..moveTo(0, 0) // tip
      // Left side — arrowhead.
      ..lineTo(0, s * 0.58) // left edge down
      ..lineTo(s * 0.18, s * 0.38) // left notch inward
      // Tail — constant width, parallel to diagonal.
      ..lineTo(s * 0.74, s * 0.94) // tail end left
      ..lineTo(s * 0.94, s * 0.74) // tail end right
      // Right side — arrowhead (mirrored).
      ..lineTo(s * 0.38, s * 0.18) // right notch inward
      ..lineTo(s * 0.58, 0) // right edge
      ..close(); // back to tip

    // Fill.
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );

    // Outline for definition.
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF000000)
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.03
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_DiagonalArrowPainter oldDelegate) =>
      oldDelegate.color != color;
}
