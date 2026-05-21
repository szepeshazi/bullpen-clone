import 'package:bullpen/cubit/game_cubit.dart';
import 'package:bullpen/cubit/game_state.dart';
import 'package:bullpen/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UndoRedoRow extends StatelessWidget {
  const UndoRedoRow({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocSelector<
        GameCubit,
        GameState,
        ({bool canUndo, bool canRedo, bool visible})
      >(
        selector: _select,
        builder: (context, s) {
          if (!s.visible) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ActionButton(
                  icon: Icons.undo,
                  tooltip: 'Undo',
                  onPressed: s.canUndo
                      ? () => context.read<GameCubit>().undo()
                      : null,
                ),
                const SizedBox(width: 24),
                _ActionButton(
                  icon: Icons.redo,
                  tooltip: 'Redo',
                  onPressed: s.canRedo
                      ? () => context.read<GameCubit>().redo()
                      : null,
                ),
                const SizedBox(width: 24),
                _ActionButton(
                  icon: Icons.lightbulb_outline,
                  tooltip: 'Hint',
                  onPressed: () => context.read<GameCubit>().requestHint(),
                ),
              ],
            ),
          );
        },
      );

  ({bool canUndo, bool canRedo, bool visible}) _select(GameState state) {
    if (state is GamePlaying && !state.solved) {
      return (canUndo: state.canUndo, canRedo: state.canRedo, visible: true);
    }
    return (canUndo: false, canRedo: false, visible: false);
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) => IconButton(
    onPressed: onPressed,
    icon: Icon(icon),
    tooltip: tooltip,
    color: bullpenAccentColor,
    disabledColor: bullpenAccentColor.withValues(alpha: 0.3),
    iconSize: 28,
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<IconData>('icon', icon));
    properties.add(StringProperty('tooltip', tooltip));
    properties.add(
      ObjectFlagProperty<VoidCallback?>.has('onPressed', onPressed),
    );
  }
}
