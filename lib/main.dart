import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
            ],
          ),
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
          return Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: BullpenGrid(gameState: state),
              ),
              if (state.solved)
                Positioned.fill(
                  child: CelebrationOverlay(
                    onDismiss: () => context.read<GameCubit>().generate(),
                  ),
                ),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
