import 'package:flutter/widgets.dart';

import '../tokens/vista_colors.dart';
import '../tokens/vista_metrics.dart';
import '../tokens/vista_typography.dart';
import 'vista_icon.dart';

/// Rounded card row: leading mark, title over a coloured tag, a spark chart,
/// and a coloured value over its percentage. Used for positions.
class VistaListRow extends StatelessWidget {
  const VistaListRow({
    super.key,
    required this.leading,
    required this.title,
    required this.tag,
    required this.tagColor,
    required this.sparkAsset,
    required this.value,
    required this.change,
    required this.valueColor,
    this.onPressed,
  });

  /// 30×30 mark — see [VistaListRow.coin] and [VistaListRow.initial].
  final Widget leading;
  final String title;
  final String tag;
  final Color tagColor;

  /// Spark chart vector (88×30).
  final String sparkAsset;
  final String value;
  final String change;
  final Color valueColor;
  final VoidCallback? onPressed;

  /// Coin artwork as the leading mark.
  static Widget coin(String asset) =>
      VistaIcon(asset, size: 30.588, height: VistaSize.listLeading);

  /// Tinted circle with an initial, for people rather than assets.
  static Widget initial(String letter) => Container(
    width: VistaSize.listLeading,
    height: VistaSize.listLeading,
    alignment: Alignment.center,
    decoration: const BoxDecoration(
      color: VistaColors.accentTint,
      shape: BoxShape.circle,
    ),
    child: Text(
      letter,
      style: VistaType.body.copyWith(color: VistaColors.accent),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onPressed != null,
      label: '$title, $tag, $value, $change',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: Container(
          constraints: const BoxConstraints(minHeight: 59),
          padding: const EdgeInsets.symmetric(
            horizontal: VistaSpace.gutter,
            vertical: VistaSpace.xl,
          ),
          decoration: BoxDecoration(
            color: VistaColors.surface,
            borderRadius: BorderRadius.circular(VistaRadius.card),
            border: Border.all(color: VistaColors.hairline),
          ),
          child: Row(
            children: [
              leading,
              const SizedBox(width: VistaSpace.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: VistaType.subhead,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: VistaSpace.xxs),
                    Text(
                      tag,
                      style: VistaType.labelStrong.copyWith(color: tagColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: VistaSpace.lg),
              // Spark chart; the vector bleeds 0.85% past each side.
              SizedBox(
                width: 88,
                height: 30,
                child: OverflowBox(
                  maxWidth: 88 * 1.017,
                  child: VistaIcon(sparkAsset, size: 88 * 1.017, height: 30),
                ),
              ),
              const SizedBox(width: VistaSpace.lg),
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 64),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      value,
                      style: VistaType.headline.copyWith(color: valueColor),
                    ),
                    const SizedBox(height: VistaSpace.xxs),
                    Text(
                      change,
                      style: VistaType.label.copyWith(
                        fontWeight: FontWeight.w500,
                        color: valueColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
