import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';

import '../tokens/vista_colors.dart';
import '../tokens/vista_metrics.dart';
import '../tokens/vista_typography.dart';
import 'vista_pressable.dart';
import '../tokens/vista_motion.dart';

/// Wraps [child] in a tappable, labelled button with at least a 44pt target.
class _Tappable extends StatelessWidget {
  const _Tappable({
    required this.label,
    required this.child,
    this.onPressed,
    this.selected,
  });

  final String label;
  final Widget child;
  final VoidCallback? onPressed;
  final bool? selected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: VistaPressable(scale: 0.95, onTap: onPressed, child: child),
    );
  }
}

/// Small accent pill with a leading glyph, e.g. "+ Deposit". The visual pill
/// is 32 tall inside a 44 tap target.
class VistaCompactButton extends StatelessWidget {
  const VistaCompactButton({
    super.key,
    required this.label,
    this.leading,
    this.onPressed,
  });

  final String label;

  /// Leading text glyph set at 15pt ("+").
  final String? leading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final style = VistaType.bodyStrong.copyWith(color: VistaColors.onAccent);
    return _Tappable(
      label: label,
      onPressed: onPressed,
      child: SizedBox(
        height: VistaSize.tapTarget,
        child: Center(
          widthFactor: 1,
          child: Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: VistaSpace.xxl),
            decoration: BoxDecoration(
              color: VistaColors.accent,
              borderRadius: BorderRadius.circular(VistaRadius.pill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (leading != null) ...[
                  Text(leading!, style: style.copyWith(fontSize: 15)),
                  const SizedBox(width: VistaSpace.xs),
                ],
                Text(label, style: style),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Neutral pill, usually with a trailing chevron, e.g. "Your market ›".
/// [large] is the 15pt profile variant ("market").
class VistaChevronPill extends StatelessWidget {
  const VistaChevronPill({
    super.key,
    required this.label,
    this.onPressed,
    this.chevron = true,
    this.large = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool chevron;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final style = large ? VistaType.subhead : VistaType.body;
    return _Tappable(
      label: label,
      onPressed: onPressed,
      child: SizedBox(
        height: VistaSize.tapTarget,
        child: Center(
          widthFactor: 1,
          child: Container(
            height: 30,
            padding: large
                ? const EdgeInsets.symmetric(horizontal: 18)
                : EdgeInsets.only(left: 12, right: chevron ? 10 : 12),
            decoration: BoxDecoration(
              color: VistaColors.surfaceRaised,
              borderRadius: BorderRadius.circular(VistaRadius.pill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: style),
                if (chevron) ...[
                  const SizedBox(width: VistaSpace.xs),
                  Text(
                    '›',
                    style: VistaType.row.copyWith(color: VistaColors.textMuted),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Count + label chip, e.g. "1,204 Followers ›".
class VistaStatChip extends StatelessWidget {
  const VistaStatChip({
    super.key,
    required this.value,
    required this.label,
    this.onPressed,
  });

  final String value;
  final String label;

  /// Null makes it a static chip: no chevron, medium-weight label.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final muted = VistaType.caption.copyWith(color: VistaColors.textMuted);
    if (onPressed == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: VistaColors.surface,
          borderRadius: BorderRadius.circular(VistaRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value, style: VistaType.bodyStrong),
            const SizedBox(width: VistaSpace.sm),
            Flexible(
              child: Text(
                label,
                style: muted.copyWith(fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }
    return _Tappable(
      label: '$value $label',
      onPressed: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: VistaColors.surface,
          borderRadius: BorderRadius.circular(VistaRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value, style: VistaType.bodyStrong),
            const SizedBox(width: VistaSpace.xs),
            Text(label, style: muted),
            const SizedBox(width: VistaSpace.xs),
            Text('›', style: muted.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

/// Equal-width segment row with a filled pill on the selection, e.g. chart
/// time spans (1h · 4h · 1D …).
class VistaSpanSelector extends StatelessWidget {
  const VistaSpanSelector({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            if (i > 0) const SizedBox(width: VistaSpace.xs),
            Expanded(child: _segment(i)),
          ],
        ],
      ),
    );
  }

  Widget _segment(int i) {
    final selected = i == selectedIndex;
    return _Tappable(
      label: labels[i],
      selected: selected,
      onPressed: () {
        HapticFeedback.selectionClick();
        onChanged(i);
      },
      child: Container(
        alignment: Alignment.center,
        // Selected: the light pill with dark text, as the leverage
        // choices use.
        decoration: BoxDecoration(
          color: selected ? VistaColors.textPrimary : null,
          borderRadius: BorderRadius.circular(VistaRadius.pill),
        ),
        child: Text(
          labels[i],
          style: selected
              ? VistaType.bodyStrong.copyWith(color: VistaColors.ink)
              : VistaType.bodyMedium.copyWith(color: VistaColors.textMuted),
        ),
      ),
    );
  }
}

/// Left-aligned text tabs with a short underline on the selection, e.g.
/// Positions / Open orders.
class VistaUnderlineTabs extends StatelessWidget {
  const VistaUnderlineTabs({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
    this.gap = 24,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  /// Space between tabs.
  final double gap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          if (i > 0) const SizedBox(width: 24),
          _tab(i),
        ],
      ],
    );
  }

  Widget _tab(int i) {
    final selected = i == selectedIndex;
    return _Tappable(
      label: labels[i],
      selected: selected,
      onPressed: () {
        HapticFeedback.selectionClick();
        onChanged(i);
      },
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: VistaSize.tapTarget),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedDefaultTextStyle(
              duration: VistaMotion.state,
              curve: VistaMotion.enter,
              style: VistaType.tab.copyWith(
                color: selected
                    ? VistaColors.textPrimary
                    : VistaColors.textMuted,
              ),
              child: Text(labels[i]),
            ),
            const SizedBox(height: VistaSpace.md),
            // The bar grows out from the centre of the picked tab.
            AnimatedContainer(
              duration: VistaMotion.state,
              curve: VistaMotion.enter,
              width: selected ? 52 : 0,
              height: 2,
              decoration: BoxDecoration(
                color: VistaColors.textPrimary,
                borderRadius: BorderRadius.circular(VistaRadius.pill),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Round 30pt − / + stepper button (44pt target), e.g. nudging a level.
class VistaStepButton extends StatelessWidget {
  const VistaStepButton({
    super.key,
    required this.glyph,
    required this.semanticLabel,
    required this.onPressed,
  });

  final String glyph;
  final String semanticLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return _Tappable(
      label: semanticLabel,
      onPressed: onPressed,
      child: SizedBox.square(
        dimension: VistaSize.tapTarget,
        child: Center(
          child: Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: VistaColors.surfaceRaised,
              shape: BoxShape.circle,
            ),
            child: Text(glyph, style: VistaType.subhead),
          ),
        ),
      ),
    );
  }
}
