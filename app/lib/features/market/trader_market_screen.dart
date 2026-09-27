import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../profile/holdings_table.dart';
import 'chart_sheet.dart';
import 'trader_market_chart.dart';
import 'trader_market_mock.dart';

/// A trader's market (Figma "Trader market — maya.eth": 236:102 chart open,
/// swiped-up panels 237:373 / 241:102 / 237:530 / 237:694).
///
/// Opens with the panels up on Market. Panels swipe sideways in the order
/// Market → Portfolio → Record → Holders; dragging the handle (or the chart)
/// down opens the chart full height, and dragging up brings the panels back.
class TraderMarketScreen extends StatefulWidget {
  const TraderMarketScreen({super.key, required this.handle});

  static Route<void> route(String handle) =>
      MaterialPageRoute(builder: (_) => TraderMarketScreen(handle: handle));

  final String handle;

  @override
  State<TraderMarketScreen> createState() => _TraderMarketScreenState();
}

class _TraderMarketScreenState extends State<TraderMarketScreen> {
  void _notBuilt(String what) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$what — not in the demo yet')));
  }

  @override
  Widget build(BuildContext context) {
    return ChartSheet(
      header: _header,
      chart: (t) => TraderMarketChart(collapse: t),
      intervals: TraderMarketMock.intervals,
      defaultInterval: TraderMarketMock.defaultInterval,
      onNotBuilt: _notBuilt,
      panels: [
        ChartSheetPanel('Market', _marketPanel()),
        ChartSheetPanel('Portfolio', _portfolioPanel()),
        ChartSheetPanel('Record', _recordPanel()),
        ChartSheetPanel('Holders', _holdersPanel()),
      ],
    );
  }

  Widget _header(double t) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        VistaSpace.xs,
        2,
        VistaSpace.xs,
        lerpDouble(10, 12, t)!,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              VistaIconButton(
                asset: VistaAssets.back,
                semanticLabel: 'Back',
                iconSize: VistaSize.icon,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              const VistaIcon(VistaAssets.traderAvatar, size: 32),
              const SizedBox(width: VistaSpace.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            widget.handle,
                            style: VistaType.headline,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: VistaSpace.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: VistaColors.surfaceRaised,
                            borderRadius: BorderRadius.circular(VistaRadius.sm),
                          ),
                          child: Text(
                            TraderMarketMock.openCalls,
                            style: VistaType.label.copyWith(
                              color: VistaColors.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 1),
                    Text(
                      t > 0.5 ? TraderMarketMock.unitLine : 'Trader market',
                      style: VistaType.caption.copyWith(
                        color: VistaColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              VistaIconButton(
                asset: VistaAssets.star,
                semanticLabel: 'Watch',
                iconSize: 22,
                onPressed: () => _notBuilt('Watchlist'),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: VistaSpace.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // "Market cap" label only with the chart open; the collapsed
                // header moves it into the subtitle.
                ClipRect(
                  child: Align(
                    alignment: Alignment.topLeft,
                    heightFactor: 1 - t,
                    child: Opacity(
                      opacity: 1 - t,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          'Market cap',
                          style: VistaType.bodyMedium.copyWith(
                            color: VistaColors.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    // Scales down on narrow phones instead of overflowing.
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.bottomLeft,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              TraderMarketMock.marketCap,
                              style: VistaType.display.copyWith(fontSize: 32),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              TraderMarketMock.capChange,
                              style: VistaType.subhead.copyWith(
                                color: VistaColors.long,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: VistaSpace.md),
                    Text(
                      TraderMarketMock.change24h,
                      style: VistaType.displayNumber.copyWith(
                        fontSize: 24,
                        color: VistaColors.long,
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _portfolioPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        chartSheetTitle(
          'Portfolio',
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const VistaIcon(VistaAssets.liveDotSmall, size: 6),
              const SizedBox(width: 5),
              Text(
                'Shared live by ${widget.handle}',
                style: VistaType.chip.copyWith(color: VistaColors.textMuted),
              ),
            ],
          ),
        ),
        const SizedBox(height: VistaSpace.md),
        HoldingsTable(onRowTap: () => _notBuilt('Call details')),
      ],
    );
  }

  Widget _recordPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        chartSheetTitle(
          'Record',
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _notBuilt('All receipts'),
            child: Text(
              'All receipts ›',
              style: VistaType.body.copyWith(
                fontSize: 14,
                color: VistaColors.accent,
              ),
            ),
          ),
        ),
        const SizedBox(height: VistaSpace.xl),
        Wrap(
          spacing: VistaSpace.xl,
          children: [
            for (final (text, color) in TraderMarketMock.recordSummary)
              Text(text, style: VistaType.body.copyWith(color: color)),
          ],
        ),
        const SizedBox(height: VistaSpace.xl),
        for (final r in TraderMarketMock.record)
          VistaReceipt(
            railAsset: r.rail,
            railHeight: 54,
            compact: true,
            title: r.title,
            lead: r.lead,
            leadColor: r.leadColor,
            detail: r.detail,
          ),
      ],
    );
  }

  Widget _marketPanel() {
    final small = VistaType.chip.copyWith(
      fontWeight: FontWeight.w500,
      color: VistaColors.textSecondary,
    );
    const gap = SizedBox(height: VistaSpace.lg);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        chartSheetTitle('Market'),
        gap,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Longs ${(TraderMarketMock.longShare * 100).round()}%',
              style: VistaType.bodyStrong.copyWith(color: VistaColors.long),
            ),
            Text(
              '${((1 - TraderMarketMock.longShare) * 100).round()}% Shorts',
              style: VistaType.bodyStrong.copyWith(color: VistaColors.short),
            ),
          ],
        ),
        gap,
        const VistaSplitBar(leftFraction: TraderMarketMock.longShare),
        gap,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(TraderMarketMock.longOi, style: small),
            Text(TraderMarketMock.openInterest, style: small),
            Text(TraderMarketMock.shortOi, style: small),
          ],
        ),
        gap,
        const VistaHairline(),
        gap,
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Longs pay shorts',
                    style: VistaType.bodyMedium.copyWith(
                      fontSize: 14,
                      color: VistaColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: VistaSpace.xxs),
                  Text(TraderMarketMock.fundingNext, style: VistaType.caption),
                ],
              ),
            ),
            Text(
              TraderMarketMock.fundingRate,
              style: VistaType.body.copyWith(
                fontSize: 14,
                color: VistaColors.short,
              ),
            ),
          ],
        ),
        gap,
        const VistaHairline(),
        gap,
        for (var r = 0; r < TraderMarketMock.stats.length; r++) ...[
          if (r > 0) const SizedBox(height: VistaSpace.xl),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var c = 0; c < 2; c++) ...[
                if (c > 0) const SizedBox(width: VistaSpace.gutter),
                Expanded(
                  child: VistaMetric(
                    large: true,
                    label: TraderMarketMock.stats[r][c].$1,
                    value: TraderMarketMock.stats[r][c].$2,
                    valueColor: TraderMarketMock.stats[r][c].$2.startsWith('+')
                        ? VistaColors.long
                        : VistaColors.textPrimary,
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _holdersPanel() {
    const gap = SizedBox(height: VistaSpace.lg);
    const long = TraderMarketMock.holdersLong;
    const short = TraderMarketMock.holdersShort;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        chartSheetTitle(
          'Holders',
          Text(
            TraderMarketMock.holdersChange,
            style: VistaType.body.copyWith(color: VistaColors.long),
          ),
        ),
        gap,
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              TraderMarketMock.holders,
              style: VistaType.display.copyWith(fontSize: 28),
            ),
            const SizedBox(width: VistaSpace.md),
            Text(
              'open positions',
              style: VistaType.bodyMedium.copyWith(
                fontSize: 14,
                color: VistaColors.textMuted,
              ),
            ),
          ],
        ),
        gap,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$long long',
              style: VistaType.bodyStrong.copyWith(color: VistaColors.long),
            ),
            Text(
              '$short short',
              style: VistaType.bodyStrong.copyWith(color: VistaColors.short),
            ),
          ],
        ),
        gap,
        const VistaSplitBar(leftFraction: long / (long + short), height: 6),
        gap,
        const VistaHairline(),
        gap,
        Text(
          'PEOPLE YOU FOLLOW',
          style: VistaType.labelStrong.copyWith(
            color: VistaColors.textSecondary,
          ),
        ),
        for (final h in TraderMarketMock.followed) ...[
          gap,
          Row(
            children: [
              VistaIcon(h.avatar, size: 30),
              const SizedBox(width: VistaSpace.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(h.handle, style: VistaType.subhead),
                    const SizedBox(height: VistaSpace.xxs),
                    Text(
                      '${h.side.label} · from ${h.from}',
                      style: VistaType.chip.copyWith(
                        fontWeight: FontWeight.w500,
                        color: VistaColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                h.pnl,
                style: VistaType.subhead.copyWith(
                  fontWeight: FontWeight.w700,
                  color: h.inProfit ? VistaColors.long : VistaColors.short,
                ),
              ),
            ],
          ),
        ],
        gap,
        Text(
          "Everyone else's positions stay private.",
          style: VistaType.chip.copyWith(
            fontWeight: FontWeight.w500,
            color: VistaColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
