import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../tokens/vista_colors.dart';
import '../tokens/vista_metrics.dart';
import '../tokens/vista_typography.dart';
import '../vista_assets.dart';
import 'vista_icon.dart';
import 'vista_pressable.dart';

/// Two-colour proportion bar (longs vs shorts) with a 2px gap.
class VistaSplitBar extends StatelessWidget {
  const VistaSplitBar({
    super.key,
    required this.leftFraction,
    this.height = 8,
    this.left = VistaColors.long,
    this.right = VistaColors.short,
  });

  /// Share of the left segment, 0–1.
  final double leftFraction;
  final double height;
  final Color left;
  final Color right;

  @override
  Widget build(BuildContext context) {
    final l = (leftFraction.clamp(0.0, 1.0) * 1000).round();
    Widget seg(Color c, int flex) => Expanded(
      flex: flex,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: c,
          borderRadius: BorderRadius.circular(VistaRadius.pill),
        ),
      ),
    );
    return Row(
      children: [
        seg(left, l),
        const SizedBox(width: VistaSpace.xxs),
        seg(right, 1000 - l),
      ],
    );
  }
}

/// Chart interval tabs ("1m 5m 15m …" with an underline), a more-intervals
/// chevron, the ƒx indicators pill and the chart-type toggle.
class VistaIntervalSelector extends StatelessWidget {
  const VistaIntervalSelector({
    super.key,
    required this.intervals,
    required this.selectedIndex,
    required this.onChanged,
    this.onMore,
    this.onIndicators,
    this.onChartType,
    this.chartTypeAsset = VistaAssets.chartTypeToggle,
  });

  final List<String> intervals;

  /// Toggle art: line selected (trader markets) or candles (asset trade).
  final String chartTypeAsset;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final VoidCallback? onMore;
  final VoidCallback? onIndicators;
  final VoidCallback? onChartType;

  @override
  Widget build(BuildContext context) {
    Widget tab({
      required Widget child,
      required bool selected,
      required String label,
      VoidCallback? onTap,
    }) => Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: VistaPressable(
        scale: 0.95,
        onTap: onTap,
        child: SizedBox(
          height: VistaSize.tapTarget,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 7),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                child,
                const SizedBox(height: VistaSpace.xs),
                Container(
                  width: 14,
                  height: 2,
                  decoration: BoxDecoration(
                    color: selected ? VistaColors.accent : null,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(left: VistaSpace.xl, right: VistaSpace.md),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var i = 0; i < intervals.length; i++)
                    tab(
                      label: intervals[i],
                      selected: i == selectedIndex,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onChanged(i);
                      },
                      child: Text(
                        intervals[i],
                        style: i == selectedIndex
                            ? VistaType.bodyStrong
                            : VistaType.bodyMedium.copyWith(
                                color: VistaColors.textMuted,
                              ),
                      ),
                    ),
                  tab(
                    label: 'More intervals',
                    selected: false,
                    onTap: onMore,
                    child: const VistaIcon(VistaAssets.chevronBox, size: 16),
                  ),
                ],
              ),
            ),
          ),
          Semantics(
            button: true,
            label: 'Indicators',
            excludeSemantics: true,
            child: VistaPressable(
              scale: 0.95,
              onTap: onIndicators,
              child: Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: VistaSpace.lg),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: VistaColors.surface,
                  borderRadius: BorderRadius.circular(VistaRadius.pill),
                ),
                child: Text('ƒx', style: VistaType.bodyStrong),
              ),
            ),
          ),
          const SizedBox(width: VistaSpace.sm),
          Semantics(
            button: true,
            label: 'Chart type',
            excludeSemantics: true,
            child: VistaPressable(
              scale: 0.95,
              onTap: onChartType,
              child: VistaIcon(chartTypeAsset, size: 60, height: 37),
            ),
          ),
        ],
      ),
    );
  }
}

/// Page indicator: the current page is a 16×6 pill, others 6pt dots.
class VistaPageDots extends StatelessWidget {
  const VistaPageDots({super.key, required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) const SizedBox(width: VistaSpace.sm),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: i == index ? 16 : 6,
            height: 6,
            decoration: BoxDecoration(
              // Inactive dots match the exported dot (#F5F3FF at 30%).
              color: i == index
                  ? VistaColors.textPrimary
                  : VistaColors.textPrimary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ],
      ],
    );
  }
}

/// Grabber pill for a draggable sheet (36×4, white at 25%).
class VistaDragHandle extends StatelessWidget {
  const VistaDragHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 4,
      decoration: BoxDecoration(
        color: const Color(0x40FFFFFF),
        borderRadius: BorderRadius.circular(VistaRadius.pill),
      ),
    );
  }
}

/// ★ / ☆ favourite toggle in a 28×44 tap target.
class VistaStarButton extends StatelessWidget {
  const VistaStarButton({
    super.key,
    required this.starred,
    required this.onPressed,
    this.size = 15,
  });

  final bool starred;
  final VoidCallback onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      toggled: starred,
      label: 'Favorite',
      excludeSemantics: true,
      child: VistaPressable(
        scale: 0.9,
        onTap: onPressed,
        child: SizedBox(
          width: 28,
          height: VistaSize.tapTarget,
          child: Center(
            child: Text(
              starred ? '★' : '☆',
              style: VistaType.body.copyWith(
                fontSize: size,
                color: starred ? VistaColors.favorite : VistaColors.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The header star on an asset or trader market page: the outline star when
/// not watched, filled in the favourite colour when watched, with a small
/// pop as it changes. 44pt tap target.
class VistaWatchButton extends StatefulWidget {
  const VistaWatchButton({
    super.key,
    required this.watched,
    required this.onPressed,
  });

  final bool watched;
  final VoidCallback onPressed;

  @override
  State<VistaWatchButton> createState() => _VistaWatchButtonState();
}

class _VistaWatchButtonState extends State<VistaWatchButton>
    with SingleTickerProviderStateMixin {
  late final _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
    value: 1,
  );

  @override
  void didUpdateWidget(VistaWatchButton old) {
    super.didUpdateWidget(old);
    // Pop only on a change, not when the page first builds.
    if (old.watched != widget.watched) _pop.forward(from: 0);
  }

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      toggled: widget.watched,
      label: 'Favorite',
      excludeSemantics: true,
      child: VistaPressable(
        scale: 0.9,
        onTap: widget.onPressed,
        child: SizedBox.square(
          dimension: VistaSize.tapTarget,
          child: Center(
            child: ScaleTransition(
              scale: _pop.drive(
                Tween(
                  begin: 1.3,
                  end: 1.0,
                ).chain(CurveTween(curve: Curves.easeOutBack)),
              ),
              child: VistaIcon(
                widget.watched ? VistaAssets.starFilled : VistaAssets.star,
                size: 22,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Up/down change label, e.g. "▲ 1.2%" / "▼ 0.4%".
String vistaChangeLabel(double pct) =>
    '${pct >= 0 ? '▲' : '▼'} ${pct.abs().toStringAsFixed(1)}%';

Color vistaChangeColor(double pct) =>
    pct >= 0 ? VistaColors.long : VistaColors.short;

/// Favourite card in a horizontal rail: icon, name, badge and star; price
/// with change; a line chart; two footnotes.
class VistaMarketCard extends StatelessWidget {
  const VistaMarketCard({
    super.key,
    required this.icon,
    required this.name,
    required this.badge,
    required this.price,
    required this.changePct,
    required this.chart,
    required this.footLeft,
    required this.footRight,
    this.onPressed,
  });

  final String icon;
  final String name;
  final String badge;
  final String price;
  final double changePct;

  /// The 152×28 chart under the price, in the app's line style.
  final Widget chart;
  final String footLeft;
  final String footRight;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final foot = VistaType.caption.copyWith(color: VistaColors.textMuted);
    return Semantics(
      button: true,
      label: '$name, $price, ${vistaChangeLabel(changePct)}',
      excludeSemantics: true,
      child: VistaPressable(
        scale: 0.98,
        onTap: onPressed,
        child: Container(
          width: 176,
          padding: const EdgeInsets.all(VistaSpace.xl),
          decoration: BoxDecoration(
            color: VistaColors.surface,
            borderRadius: BorderRadius.circular(VistaRadius.card),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  VistaIcon(icon, size: 20),
                  const SizedBox(width: VistaSpace.sm),
                  Expanded(
                    child: Row(
                      children: [
                        // Shrinks slightly before truncating: the card is a
                        // fixed 176 wide.
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(name, style: VistaType.bodyStrong),
                          ),
                        ),
                        if (badge.isNotEmpty) ...[
                          const SizedBox(width: VistaSpace.sm),
                          _Badge(badge),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: VistaSpace.sm),
                  Text(
                    '★',
                    style: VistaType.label.copyWith(
                      color: VistaColors.favorite,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: VistaSpace.sm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(price, style: VistaType.figures(VistaType.headline)),
                  const SizedBox(width: VistaSpace.sm),
                  Text(
                    vistaChangeLabel(changePct),
                    style: VistaType.figures(VistaType.label)
                        .copyWith(color: vistaChangeColor(changePct)),
                  ),
                ],
              ),
              const SizedBox(height: VistaSpace.sm),
              SizedBox(width: 152, height: 28, child: chart),
              const SizedBox(height: VistaSpace.sm),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      footLeft,
                      style: foot,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(footRight, style: foot),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pill-shaped list row: star, icon, name with badge over a subline, then
/// price, change and a third figure in right-aligned columns.
class VistaMarketRow extends StatelessWidget {
  const VistaMarketRow({
    super.key,
    required this.starred,
    required this.onStar,
    required this.icon,
    required this.name,
    required this.subline,
    required this.price,
    required this.changePct,
    required this.third,
    this.badge,
    this.onPressed,
  });

  final bool starred;
  final VoidCallback onStar;
  final String icon;
  final String name;
  final String? badge;
  final String subline;
  final String price;
  final double changePct;

  /// Last column: funding for assets, market cap for traders.
  final String third;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    Widget col(double width, Widget child) => SizedBox(
      width: width,
      child: Align(
        alignment: Alignment.centerRight,
        child: FittedBox(fit: BoxFit.scaleDown, child: child),
      ),
    );
    return VistaPressable(
      scale: 0.98,
      onTap: onPressed,
      child: Container(
        height: 56,
        padding: const EdgeInsets.only(left: 6, right: VistaSpace.gutter),
        decoration: BoxDecoration(
          color: VistaColors.surface,
          borderRadius: BorderRadius.circular(VistaRadius.pill),
        ),
        child: Row(
          children: [
            VistaStarButton(starred: starred, onPressed: onStar),
            Expanded(
              child: Row(
                children: [
                  VistaIcon(icon, size: 26),
                  const SizedBox(width: VistaSpace.md),
                  Flexible(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                name,
                                style: VistaType.bodyStrong,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (badge != null) ...[
                              const SizedBox(width: VistaSpace.xs),
                              _Badge(badge!),
                            ],
                          ],
                        ),
                        Text(
                          subline,
                          style: VistaType.caption.copyWith(
                            color: VistaColors.textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Figma: 78 / 58 / 70. Price and last column give up a few
            // points so handles fit in the wider Open Runde face.
            col(72, Text(price, style: VistaType.figures(VistaType.body))),
            col(
              58,
              Text(
                vistaChangeLabel(changePct),
                style: VistaType.figures(VistaType.body)
                    .copyWith(color: vistaChangeColor(changePct)),
              ),
            ),
            col(64, Text(third, style: VistaType.figures(VistaType.body))),
          ],
        ),
      ),
    );
  }
}

/// "50x" / "3 open" tag.
class _Badge extends StatelessWidget {
  const _Badge(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: VistaColors.surfaceRaised,
        borderRadius: BorderRadius.circular(VistaRadius.sm),
      ),
      child: Text(
        label,
        style: VistaType.label.copyWith(color: VistaColors.textMuted),
      ),
    );
  }
}

/// Bar histogram; bars whose index falls in [selected] are accent, the rest
/// neutral. Heights are relative to the tallest bar.
class VistaHistogram extends StatelessWidget {
  const VistaHistogram({
    super.key,
    required this.values,
    required this.selected,
    this.height = 38,
  });

  final List<double> values;

  /// Inclusive index range drawn in the accent colour.
  final (int, int) selected;
  final double height;

  @override
  Widget build(BuildContext context) {
    final maxV = values.fold<double>(0, (m, v) => v > m ? v : m);
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < values.length; i++) ...[
            if (i > 0) const SizedBox(width: VistaSpace.xs),
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                height: maxV == 0 ? 0 : height * values[i] / maxV,
                decoration: BoxDecoration(
                  color: i >= selected.$1 && i <= selected.$2
                      ? VistaColors.accent
                      : VistaColors.surfaceRaised,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Two-thumb range slider on the Vista track (4pt, accent between the
/// thumbs, 24pt light thumbs), snapping to [divisions].
class VistaRangeSlider extends StatelessWidget {
  const VistaRangeSlider({
    super.key,
    required this.values,
    required this.onChanged,
    this.divisions = 10,
    this.semanticFormatter,
  });

  final RangeValues values;
  final ValueChanged<RangeValues> onChanged;
  final int divisions;
  final String Function(double)? semanticFormatter;

  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 4,
        activeTrackColor: VistaColors.accent,
        inactiveTrackColor: VistaColors.surfaceRaised,
        thumbColor: VistaColors.textPrimary,
        overlayShape: SliderComponentShape.noOverlay,
        rangeThumbShape: const RoundRangeSliderThumbShape(
          enabledThumbRadius: 12,
          elevation: 0,
          pressedElevation: 0,
        ),
        rangeTickMarkShape: const RoundRangeSliderTickMarkShape(
          tickMarkRadius: 0,
        ),
        rangeTrackShape: const RoundedRectRangeSliderTrackShape(),
        showValueIndicator: ShowValueIndicator.never,
      ),
      child: SizedBox(
        height: 24,
        child: RangeSlider(
          values: values,
          divisions: divisions,
          semanticFormatterCallback: semanticFormatter,
          onChanged: (v) {
            // Keep at least one bucket selected.
            if (v.end - v.start >= 1 / divisions - 1e-9) onChanged(v);
          },
        ),
      ),
    );
  }
}

/// The line under a market's price (Figma 232:159, "24h change · V3"): an
/// arrow, the move in money and percent in the direction's colour, then the
/// window in grey, e.g. "▲ $798.00 (1.20%)  Past 24 hours".
class VistaChangeLine extends StatelessWidget {
  const VistaChangeLine({
    super.key,
    required this.up,
    required this.amount,
    required this.percent,
    this.window = 'Past 24 hours',
  });

  final bool up;

  /// Unsigned, e.g. "$798.00"; the arrow carries the direction.
  final String amount;

  /// Unsigned, e.g. "1.20%".
  final String percent;
  final String window;

  @override
  Widget build(BuildContext context) {
    final color = up ? VistaColors.long : VistaColors.short;
    return Semantics(
      label: '${up ? 'Up' : 'Down'} $amount, $percent, $window',
      excludeSemantics: true,
      child: Row(
        children: [
          RotatedBox(
            quarterTurns: up ? 0 : 2,
            child: SvgPicture.asset(
              VistaAssets.changeArrowUp,
              width: 9,
              height: 7.2,
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            ),
          ),
          const SizedBox(width: VistaSpace.sm),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Text(
                    '$amount ($percent)',
                    style: VistaType.figures(VistaType.subhead)
                        .copyWith(fontWeight: FontWeight.w700, color: color),
                  ),
                  const SizedBox(width: VistaSpace.sm),
                  Text(
                    window,
                    style: VistaType.subheadMuted.copyWith(
                      color: VistaColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
