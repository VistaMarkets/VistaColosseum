import 'package:flutter/widgets.dart';

import '../tokens/vista_colors.dart';
import '../tokens/vista_metrics.dart';
import '../tokens/vista_typography.dart';

/// Text glyph (e.g. "↗", "•••") centred in a 44pt tap target.
class VistaGlyphButton extends StatelessWidget {
  const VistaGlyphButton({
    super.key,
    required this.glyph,
    required this.semanticLabel,
    this.size = 15,
    this.onPressed,
  });

  final String glyph;
  final String semanticLabel;
  final double size;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: SizedBox.square(
          dimension: VistaSize.tapTarget,
          child: Center(
            child: Text(
              glyph,
              style: VistaType.headline.copyWith(fontSize: size),
            ),
          ),
        ),
      ),
    );
  }
}

/// Centred bold figure over a small label, e.g. "62 / Settled".
class VistaCountStat extends StatelessWidget {
  const VistaCountStat({
    super.key,
    required this.value,
    required this.label,
    this.valueColor = VistaColors.textPrimary,
    this.onPressed,
  });

  final String value;
  final String label;
  final Color valueColor;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final body = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: VistaType.subhead.copyWith(
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ),
        const SizedBox(height: 1),
        Text(
          label,
          style: VistaType.caption.copyWith(color: VistaColors.textMuted),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
    if (onPressed == null) return body;
    return Semantics(
      button: true,
      label: '$value $label',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: body,
      ),
    );
  }
}

/// Filter pill; the selected one is light with dark text.
class VistaFilterChip extends StatelessWidget {
  const VistaFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onPressed,
    this.accent = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  /// Sort-chip style: accent when selected, grey text when not.
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: SizedBox(
          height: VistaSize.tapTarget,
          child: Center(
            widthFactor: 1,
            child: Container(
              height: 30,
              padding: const EdgeInsets.symmetric(horizontal: VistaSpace.xl),
              decoration: BoxDecoration(
                color: selected
                    ? (accent ? VistaColors.accent : VistaColors.textPrimary)
                    : VistaColors.surfaceRaised,
                borderRadius: BorderRadius.circular(VistaRadius.pill),
              ),
              child: Center(
                widthFactor: 1,
                child: Text(
                  label,
                  style: VistaType.body.copyWith(
                    color: selected
                        ? (accent ? VistaColors.onAccent : VistaColors.ink)
                        : (accent
                              ? VistaColors.textChip
                              : VistaColors.textPrimary),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
