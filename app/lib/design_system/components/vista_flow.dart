import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';

import '../tokens/vista_colors.dart';
import '../tokens/vista_metrics.dart';
import '../tokens/vista_typography.dart';
import 'vista_pressable.dart';

/// Step indicator for a multi-screen flow: done steps are dim dots, the
/// current step a 16×5 pill, upcoming steps faint dots.
class VistaStepDots extends StatelessWidget {
  const VistaStepDots({super.key, required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Step ${index + 1} of $count',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < count; i++) ...[
            if (i > 0) const SizedBox(width: VistaSpace.sm),
            Container(
              width: i == index ? 16 : 5,
              height: 5,
              decoration: BoxDecoration(
                color: i == index
                    ? VistaColors.textPrimary
                    : VistaColors.textPrimary.withValues(
                        alpha: i < index ? 0.6 : 0.25,
                      ),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Large accent call to action (54 tall) with an optional glow; dims and
/// ignores taps while [enabled] is false.
class VistaPrimaryButton extends StatelessWidget {
  const VistaPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.enabled = true,
    this.glow = false,
    this.height = 54,
    this.trailing,
  });

  final String label;
  final VoidCallback onPressed;
  final bool enabled;
  final bool glow;
  final double height;

  /// Trailing glyph, e.g. "→".
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final text = VistaType.headline.copyWith(color: VistaColors.onAccent);
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: VistaPressable(
        scale: 0.97,
        onTap: enabled ? onPressed : null,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: enabled ? 1 : 0.4,
          child: Container(
            height: height,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: VistaColors.accent,
              borderRadius: BorderRadius.circular(VistaRadius.pill),
              boxShadow: glow && enabled
                  ? const [BoxShadow(color: Color(0x735AA6DE), blurRadius: 20)]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    label,
                    style: text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: VistaSpace.md),
                  Text(trailing!, style: text),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Required-consent checkbox with its statement; the whole row toggles.
class VistaCheckRow extends StatelessWidget {
  const VistaCheckRow({
    super.key,
    required this.checked,
    required this.onChanged,
    required this.child,
    this.semanticLabel,
  });

  final bool checked;
  final ValueChanged<bool> onChanged;
  final Widget child;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: checked,
      label: semanticLabel,
      child: VistaPressable(
        scale: 0.97,
        onTap: () {
          HapticFeedback.selectionClick();
          onChanged(!checked);
        },
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 28),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                width: 20,
                height: 20,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: checked ? VistaColors.accent : null,
                  borderRadius: BorderRadius.circular(VistaRadius.sm),
                  border: checked
                      ? null
                      : Border.all(color: VistaColors.textMuted, width: 1.5),
                ),
                child: checked
                    ? Text(
                        '✓',
                        style: VistaType.bodyStrong.copyWith(
                          color: VistaColors.ink,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: VistaSpace.lg),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}
