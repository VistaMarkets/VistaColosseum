import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../profile/holdings_table.dart';
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

/// Short chart height with the panels up (Figma).
const double _shortChart = 196;

/// Fixed rows between chart and panel: interval selector + handle row.
const double _selectorH = 44;
const double _handleH = 12;

class _TraderMarketScreenState extends State<TraderMarketScreen>
    with SingleTickerProviderStateMixin {
  /// 0 = chart open, 1 = panels up.
  late final AnimationController _sheet = AnimationController(
    vsync: this,
    value: 1,
  );
  final _pages = PageController();
  int _page = 0;
  int _interval = TraderMarketMock.defaultInterval;

  /// Distance the chart grows between the two states; set during layout.
  double _travel = 300;

  static const _panelTitles = ['Market', 'Portfolio', 'Record', 'Holders'];

  @override
  void dispose() {
    _sheet.dispose();
    _pages.dispose();
    super.dispose();
  }

  void _notBuilt(String what) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$what — not in the demo yet')));
  }

  void _onDrag(DragUpdateDetails d) {
    _sheet.value = (_sheet.value - d.primaryDelta! / _travel).clamp(0.0, 1.0);
  }

  void _onDragEnd(DragEndDetails d) {
    final v = d.primaryVelocity ?? 0;
    final target = v > 400
        ? 0.0
        : v < -400
        ? 1.0
        : _sheet.value.roundToDouble();
    _settle(target);
  }

  void _settle(double target) {
    final instant = MediaQuery.disableAnimationsOf(context);
    _sheet.animateTo(
      target,
      duration: instant ? Duration.zero : const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: AnimatedBuilder(
          animation: _sheet,
          builder: (context, _) {
            final t = _sheet.value;
            return Column(
              children: [
                _header(t),
                Expanded(child: _body(t)),
                _tradeButtons(bottomInset),
              ],
            );
          },
        ),
      ),
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

  Widget _body(double t) {
    return LayoutBuilder(
      builder: (context, c) {
        // Chart-open padding (8 top, 14 bottom) folds away as panels rise.
        final padTop = lerpDouble(8, 0, t)!;
        final padBottom = lerpDouble(14, 0, t)!;
        final openChart = c.maxHeight - _selectorH - _handleH - 8 - 14;
        final shortChart = openChart < _shortChart ? openChart : _shortChart;
        _travel = (openChart - shortChart).clamp(1, double.infinity);
        final chartH = lerpDouble(openChart, shortChart, t)!;
        final panelH =
            c.maxHeight - _selectorH - _handleH - chartH - padTop - padBottom;

        return Column(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onVerticalDragUpdate: _onDrag,
              onVerticalDragEnd: _onDragEnd,
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      VistaSpace.gutter,
                      padTop,
                      VistaSpace.gutter,
                      padBottom,
                    ),
                    child: SizedBox(
                      height: chartH,
                      child: TraderMarketChart(collapse: t),
                    ),
                  ),
                  SizedBox(
                    height: _selectorH,
                    child: VistaIntervalSelector(
                      intervals: TraderMarketMock.intervals,
                      selectedIndex: _interval,
                      onChanged: (i) => setState(() => _interval = i),
                      onMore: () => _notBuilt('More intervals'),
                      onIndicators: () => _notBuilt('Indicators'),
                      onChartType: () => _notBuilt('Chart type'),
                    ),
                  ),
                  Semantics(
                    button: true,
                    label: t > 0.5 ? 'Expand chart' : 'Show panels',
                    onTap: () => _settle(t > 0.5 ? 0 : 1),
                    child: GestureDetector(
                      onTap: () => _settle(t > 0.5 ? 0 : 1),
                      child: const SizedBox(
                        height: _handleH,
                        width: double.infinity,
                        child: Center(child: VistaDragHandle()),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: panelH.clamp(0, double.infinity),
              child: ClipRect(
                child: Opacity(
                  opacity: t,
                  child: IgnorePointer(
                    ignoring: t < 0.5,
                    // Nothing to lay out until there is room for the dots.
                    child: panelH < 16 ? const SizedBox.shrink() : _panels(),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _panels() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: VistaSpace.xs),
          child: Semantics(
            label: 'Panel ${_page + 1} of 4, ${_panelTitles[_page]}',
            child: VistaPageDots(count: 4, index: _page),
          ),
        ),
        Expanded(
          child: PageView(
            controller: _pages,
            onPageChanged: (i) => setState(() => _page = i),
            children: [
              _panel(_marketPanel()),
              _panel(_portfolioPanel()),
              _panel(_recordPanel()),
              _panel(_holdersPanel()),
            ],
          ),
        ),
      ],
    );
  }

  /// Panel page: scrolls when the phone is too short to show it whole.
  Widget _panel(Widget child) => SingleChildScrollView(
    padding: const EdgeInsets.symmetric(
      horizontal: VistaSpace.gutter,
      vertical: VistaSpace.lg,
    ),
    child: child,
  );

  Widget _title(String text, [Widget? trailing]) => Row(
    children: [
      Expanded(child: Text(text, style: VistaType.headline)),
      ?trailing,
    ],
  );

  Widget _portfolioPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _title(
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
        _title(
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
        _title('Market'),
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
        _title(
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

  Widget _tradeButtons(double bottomInset) {
    return Container(
      decoration: const BoxDecoration(
        color: VistaColors.background,
        border: Border(top: BorderSide(color: VistaColors.hairline)),
      ),
      padding: EdgeInsets.fromLTRB(
        VistaSpace.gutter,
        VistaSpace.xl,
        VistaSpace.gutter,
        bottomInset > 0 ? bottomInset : VistaSpace.gutter,
      ),
      child: Row(
        children: [
          Expanded(
            child: VistaPillButton(
              label: 'Long',
              variant: VistaPillVariant.long,
              // Simulated only: the demo never places an order.
              onPressed: () => _notBuilt('Long (simulated)'),
            ),
          ),
          const SizedBox(width: VistaSpace.lg),
          Expanded(
            child: VistaPillButton(
              label: 'Short',
              variant: VistaPillVariant.short,
              onPressed: () => _notBuilt('Short (simulated)'),
            ),
          ),
        ],
      ),
    );
  }
}
