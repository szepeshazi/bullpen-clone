import 'package:bullpen/cubit/game_cubit.dart';
import 'package:bullpen/cubit/game_state.dart';
import 'package:bullpen/logic/hint_finder.dart';
import 'package:bullpen/theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

const _mustPlaceColor = Color(0xFF2E7D32);

class HintReasonBanner extends StatelessWidget {
  const HintReasonBanner({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocSelector<GameCubit, GameState, ({String? reason, HintType? type})>(
        selector: _select,
        builder: (context, hint) {
          final reason = hint.reason;
          final isMustPlace = hint.type == HintType.mustPlace;
          final color = isMustPlace ? _mustPlaceColor : bullpenAccentColor;

          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: reason == null
                ? const SizedBox.shrink()
                : _Banner(
                    key: ValueKey(reason),
                    reason: reason,
                    color: color,
                    isMustPlace: isMustPlace,
                    onApply: () => context.read<GameCubit>().applyHint(),
                  ),
          );
        },
      );

  ({String? reason, HintType? type}) _select(GameState state) =>
      state is GamePlaying
      ? (reason: state.hintReason, type: state.hintType)
      : (reason: null, type: null);
}

class _Banner extends StatelessWidget {
  final String reason;
  final Color color;
  final bool isMustPlace;
  final VoidCallback onApply;

  const _Banner({
    required this.reason,
    required this.color,
    required this.isMustPlace,
    required this.onApply,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
    child: Container(
      padding: const EdgeInsets.only(left: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            isMustPlace ? Icons.add_circle : Icons.lightbulb,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              reason,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          _ApplyButton(color: color, onTap: onApply),
        ],
      ),
    ),
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('reason', reason));
    properties.add(ColorProperty('color', color));
    properties.add(DiagnosticsProperty<bool>('isMustPlace', isMustPlace));
    properties.add(ObjectFlagProperty<VoidCallback>.has('onApply', onApply));
  }
}

class _ApplyButton extends StatelessWidget {
  final Color color;
  final VoidCallback onTap;

  const _ApplyButton({required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.only(left: 8),
      child: SizedBox(
        width: 48,
        height: 48,
        child: Center(
          child: Icon(Icons.play_circle_filled, size: 28, color: color),
        ),
      ),
    ),
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ColorProperty('color', color));
    properties.add(ObjectFlagProperty<VoidCallback>.has('onTap', onTap));
  }
}
