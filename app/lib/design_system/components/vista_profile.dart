import 'package:flutter/widgets.dart';

import '../tokens/vista_colors.dart';
import '../tokens/vista_metrics.dart';
import '../tokens/vista_typography.dart';
import 'vista_icon.dart';

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

/// Opponent line on an arena receipt: "ARENA vs (avatar) name".
class VistaVersus {
  const VistaVersus({required this.name, required this.avatarAsset});

  final String name;
  final String avatarAsset;
}

/// A call or arena receipt in a timeline: rail segment, title, optional
/// versus line, and a coloured lead with quieter detail.
class VistaReceipt extends StatelessWidget {
  const VistaReceipt({
    super.key,
    required this.railAsset,
    required this.title,
    required this.lead,
    required this.leadColor,
    required this.detail,
    this.versus,
    this.railHeight,
    this.compact = false,
  });

  /// Rail vector (10 wide; 56 tall for calls, 76 for arena receipts).
  final String railAsset;

  /// Overrides the rail height (e.g. 54 in the compact record panel).
  final double? railHeight;

  /// Tighter spacing, no bottom padding (the rail sets the row height).
  final bool compact;
  final String title;
  final String lead;
  final Color leadColor;
  final String detail;
  final VistaVersus? versus;

  @override
  Widget build(BuildContext context) {
    final meta = VistaType.chip.copyWith(fontWeight: FontWeight.w500);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        VistaIcon(
          railAsset,
          size: 10,
          height: railHeight ?? (versus == null ? 56 : 76),
        ),
        const SizedBox(width: VistaSpace.xl),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: compact ? 0 : VistaSpace.gutter),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: VistaType.subhead),
                if (versus != null) ...[
                  const SizedBox(height: VistaSpace.xs),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: VistaColors.surfaceRaised,
                          borderRadius: BorderRadius.circular(VistaRadius.sm),
                        ),
                        child: Text('ARENA', style: VistaType.micro),
                      ),
                      const SizedBox(width: VistaSpace.sm),
                      Text(
                        'vs',
                        style: VistaType.label.copyWith(
                          color: VistaColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: VistaSpace.sm),
                      VistaIcon(versus!.avatarAsset, size: 16),
                      const SizedBox(width: VistaSpace.sm),
                      Flexible(
                        child: Text(
                          versus!.name,
                          style: VistaType.chip,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                SizedBox(height: compact ? 3 : VistaSpace.xs),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: lead,
                        style: meta.copyWith(
                          fontWeight: FontWeight.w700,
                          color: leadColor,
                        ),
                      ),
                      TextSpan(text: ' · $detail'),
                    ],
                  ),
                  style: meta.copyWith(color: VistaColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
