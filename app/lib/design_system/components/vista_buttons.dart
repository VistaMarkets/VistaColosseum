import 'package:flutter/widgets.dart';

import '../tokens/vista_colors.dart';
import '../tokens/vista_metrics.dart';
import '../tokens/vista_typography.dart';
import 'vista_icon.dart';

enum VistaPillVariant { neutral, long, short, accent }

/// Full-height rounded action button ("PillButton" in Figma).
class VistaPillButton extends StatelessWidget {
  const VistaPillButton({
    super.key,
    required this.label,
    this.variant = VistaPillVariant.neutral,
    this.leadingAsset,
    this.onPressed,
  });

  final String label;
  final VistaPillVariant variant;

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
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
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
                  style: VistaType.headline.copyWith(color: fg),
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
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
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
