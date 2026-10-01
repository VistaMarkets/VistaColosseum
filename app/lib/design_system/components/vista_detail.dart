import 'package:flutter/widgets.dart';

import '../tokens/vista_colors.dart';
import '../tokens/vista_metrics.dart';
import '../tokens/vista_typography.dart';
import 'vista_icon.dart';

/// Header for a pushed detail screen: back chevron, avatar, title over a
/// subtitle, and an optional round trailing action. 56 tall.
class VistaDetailHeader extends StatelessWidget {
  const VistaDetailHeader({
    super.key,
    required this.avatarAsset,
    required this.title,
    required this.subtitle,
    required this.onBack,
    this.actionGlyph,
    this.actionLabel,
    this.onAction,
  });

  final String avatarAsset;
  final String title;
  final String subtitle;
  final VoidCallback onBack;

  /// Text glyph for the trailing round button (e.g. "↗").
  final String? actionGlyph;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Padding(
        padding: const EdgeInsets.only(left: 4, right: VistaSpace.gutter),
        child: Row(
          children: [
            Semantics(
              button: true,
              label: 'Back',
              excludeSemantics: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onBack,
                child: SizedBox.square(
                  dimension: VistaSize.tapTarget,
                  child: Center(
                    child: Text(
                      '‹',
                      style: VistaType.displayMedium.copyWith(
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: VistaSpace.xs),
            VistaIcon(avatarAsset, size: VistaSize.avatarLarge),
            const SizedBox(width: VistaSpace.xs + 6),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: VistaType.headline,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: VistaType.caption.copyWith(
                      color: VistaColors.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (actionGlyph != null) ...[
              const SizedBox(width: VistaSpace.xs),
              Semantics(
                button: true,
                label: actionLabel,
                excludeSemantics: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onAction,
                  child: Container(
                    width: VistaSize.tapTarget,
                    height: VistaSize.tapTarget,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: VistaColors.surface,
                      shape: BoxShape.circle,
                    ),
                    child: Text(actionGlyph!, style: VistaType.headline),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 1px hairline rule between sections.
class VistaHairline extends StatelessWidget {
  const VistaHairline({super.key});

  @override
  Widget build(BuildContext context) =>
      Container(height: 1, color: VistaColors.hairline);
}

/// Small label over a value, e.g. "Price / $0.4400". [large] is the stats
/// grid variant (12pt label over a 17pt value).
class VistaMetric extends StatelessWidget {
  const VistaMetric({
    super.key,
    required this.label,
    required this.value,
    this.large = false,
    this.valueColor = VistaColors.textPrimary,
  });

  final String label;
  final String value;
  final bool large;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    final labelStyle = large
        ? VistaType.chip.copyWith(
            fontWeight: FontWeight.w500,
            color: VistaColors.textSecondary,
          )
        : VistaType.caption.copyWith(color: VistaColors.textMuted);
    final valueStyle =
        (large
                ? VistaType.headline.copyWith(fontWeight: FontWeight.w600)
                : VistaType.subhead)
            .copyWith(color: valueColor);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: labelStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: large ? 3 : VistaSpace.xxs),
        Text(
          value,
          style: valueStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

/// Uppercase section title with an optional accent link on the right.
class VistaSectionHead extends StatelessWidget {
  const VistaSectionHead({
    super.key,
    required this.title,
    this.linkLabel,
    this.onLink,
    this.linkSize = 11,
    this.note,
  });

  final String title;
  final String? linkLabel;
  final VoidCallback? onLink;
  final double linkSize;

  /// Quiet, non-interactive text on the right (e.g. "Shared live").
  final String? note;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: VistaType.labelStrong.copyWith(
              color: VistaColors.textSecondary,
            ),
          ),
        ),
        if (linkLabel != null)
          Semantics(
            button: true,
            excludeSemantics: true,
            label: linkLabel,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onLink,
              // Pads the small link out to a usable tap target.
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text(
                  '$linkLabel ›',
                  style: VistaType.label.copyWith(
                    fontSize: linkSize,
                    color: VistaColors.accent,
                  ),
                ),
              ),
            ),
          ),
        if (note != null)
          Text(
            note!,
            style: VistaType.chip.copyWith(color: VistaColors.textMuted),
          ),
      ],
    );
  }
}

/// One entry in a vertical timeline: a coloured rail segment, then time,
/// title, and a coloured status with detail.
class VistaTimelineEntry extends StatelessWidget {
  const VistaTimelineEntry({
    super.key,
    required this.railAsset,
    required this.time,
    required this.title,
    required this.status,
    required this.statusColor,
    required this.detail,
  });

  /// Rail segment vector (12×64): dot plus connecting line.
  final String railAsset;
  final String time;
  final String title;
  final String status;
  final Color statusColor;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        VistaIcon(railAsset, size: 12, height: 64),
        const SizedBox(width: VistaSpace.xl),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: VistaSpace.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  time,
                  style: VistaType.label.copyWith(
                    color: VistaColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(title, style: VistaType.subhead),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      status,
                      style: VistaType.labelStrong.copyWith(color: statusColor),
                    ),
                    const SizedBox(width: VistaSpace.sm),
                    Flexible(
                      child: Text(
                        detail,
                        style: VistaType.caption.copyWith(
                          color: VistaColors.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
