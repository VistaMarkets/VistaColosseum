import 'package:flutter/widgets.dart';

import '../tokens/vista_colors.dart';
import '../tokens/vista_metrics.dart';
import '../tokens/vista_typography.dart';
import 'vista_icon.dart';

enum TradeSide { long, short }

extension TradeSideStyle on TradeSide {
  Color get color =>
      this == TradeSide.long ? VistaColors.long : VistaColors.short;
  String get label => this == TradeSide.long ? 'Long' : 'Short';
}

/// Coloured Long/Short text badge ("side badge").
class VistaSideBadge extends StatelessWidget {
  const VistaSideBadge({super.key, required this.side});

  final TradeSide side;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      child: Text(
        side.label,
        style: VistaType.labelStrong.copyWith(color: side.color),
      ),
    );
  }
}

/// Small rounded label, e.g. chart event annotations.
class VistaTag extends StatelessWidget {
  const VistaTag({
    super.key,
    required this.label,
    this.color = VistaColors.surfaceRaised,
    this.textColor = VistaColors.textPrimary,
    this.dense = false,
  });

  final String label;
  final Color color;
  final Color textColor;

  /// Dense: 10pt text, 6px radius (the entry annotation).
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: dense
          ? const EdgeInsets.symmetric(horizontal: 6, vertical: 3)
          : const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(
          dense ? VistaRadius.sm : VistaRadius.md,
        ),
      ),
      child: Text(
        label,
        maxLines: 1,
        style: (dense ? VistaType.micro : VistaType.labelStrong).copyWith(
          color: textColor,
        ),
      ),
    );
  }
}

/// Avatar + message pill used in the live fills stream.
class VistaActivityPill extends StatelessWidget {
  const VistaActivityPill({
    super.key,
    required this.avatarAsset,
    required this.message,
    this.amount,
    this.side,
  });

  final String avatarAsset;
  final String message;
  final String? amount;
  final TradeSide? side;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 4, 10, 4),
      decoration: BoxDecoration(
        color: VistaColors.surfaceOverlay,
        borderRadius: BorderRadius.circular(VistaRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          VistaIcon(avatarAsset, size: VistaSize.avatarXs),
          const SizedBox(width: VistaSpace.sm),
          Flexible(
            child: Text(
              message,
              style: VistaType.chip,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (amount != null) ...[
            const SizedBox(width: VistaSpace.sm),
            Text(
              amount!,
              style: VistaType.chip.copyWith(
                fontWeight: FontWeight.w700,
                color: side?.color ?? VistaColors.textPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
