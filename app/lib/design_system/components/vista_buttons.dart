import 'package:flutter/widgets.dart';

import '../tokens/vista_colors.dart';
import '../tokens/vista_metrics.dart';
import '../tokens/vista_typography.dart';
import 'vista_chips.dart';
import 'vista_icon.dart';
import 'vista_pressable.dart';

enum VistaPillVariant { neutral, long, short, accent }

/// Full-height rounded action button ("PillButton" in Figma).
class VistaPillButton extends StatelessWidget {
  const VistaPillButton({
    super.key,
    required this.label,
    this.variant = VistaPillVariant.neutral,
    this.leadingAsset,
    this.onPressed,
    this.foreground,
  });

  final String label;
  final VistaPillVariant variant;

  /// Overrides the variant's label colour.
  final Color? foreground;

  /// Optional small glyph before the label (e.g. the Long arrow, 9×4.6).
  final String? leadingAsset;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (variant) {
      VistaPillVariant.neutral => (
        VistaColors.surfaceRaised,
        VistaColors.textPrimary,
      ),
      VistaPillVariant.long => (VistaColors.long, VistaColors.onAccent),
      VistaPillVariant.short => (VistaColors.short, VistaColors.onAccent),
      VistaPillVariant.accent => (VistaColors.accent, VistaColors.ink),
    };
    final fgColor = foreground ?? fg;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: VistaPressable(
        scale: 0.97,
        onTap: onPressed,
        child: Container(
          constraints: const BoxConstraints(minHeight: VistaSize.pillButton),
          padding: const EdgeInsets.symmetric(horizontal: VistaSpace.xl),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(VistaRadius.pill),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (leadingAsset != null) ...[
                VistaIcon(leadingAsset!, size: 9, height: 4.6),
                const SizedBox(width: VistaSpace.sm),
              ],
              Flexible(
                child: Text(
                  label,
                  style: VistaType.headline.copyWith(color: fgColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Circular social action with a count/label underneath ("_SocialRail").
class VistaRailButton extends StatelessWidget {
  const VistaRailButton({
    super.key,
    required this.asset,
    required this.label,
    required this.semanticLabel,
    this.onPressed,
  });

  final String asset;
  final String label;
  final String semanticLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$semanticLabel, $label',
      excludeSemantics: true,
      child: VistaPressable(
        scale: 0.9,
        onTap: onPressed,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            VistaIcon(asset, size: VistaSize.railButton),
            const SizedBox(height: VistaSpace.xxs),
            Text(label, style: VistaType.label),
          ],
        ),
      ),
    );
  }
}

/// Two equal buttons for opposite sides, long (or bull) and short (or bear),
/// in the order the viewer chose in Settings › Display: long on the left by
/// default, or on the right when [longOnRight] is set.
class VistaSidePair extends StatelessWidget {
  const VistaSidePair({
    super.key,
    required this.long,
    required this.short,
    required this.longOnRight,
    this.gap = VistaSpace.lg,
  });

  final Widget long;
  final Widget short;
  final bool longOnRight;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final (first, second) = longOnRight ? (short, long) : (long, short);
    return Row(
      children: [
        Expanded(child: first),
        SizedBox(width: gap),
        Expanded(child: second),
      ],
    );
  }
}

/// "Join long" / "Join short", solid in the side's colour (Figma 506:236),
/// in a 44pt tap row: joins a call by opening the order ticket on its side.
/// Used on Arena calls and the trade page's Callers.
class VistaJoinPill extends StatelessWidget {
  const VistaJoinPill({super.key, required this.side, this.onTap});

  final TradeSide side;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final label = 'Join ${side.label.toLowerCase()}';
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: VistaPressable(
        onTap: onTap,
        child: SizedBox(
          height: VistaSize.tapTarget,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: VistaSpace.xxl,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                color: side.color,
                borderRadius: BorderRadius.circular(VistaRadius.pill),
              ),
              child: Text(
                label,
                style: VistaType.body.copyWith(color: VistaColors.onAccent),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
