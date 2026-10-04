import 'package:flutter/material.dart';

import '../../charting/charting.dart';
import '../../design_system/design_system.dart';
import '../live/live_feed.dart';
import '../live/market_prices.dart';
import '../market/chart_sheet.dart';
import '../settings/settings_state.dart';
import '../watchlist/watchlist_state.dart';
import '../profile/profile_screen.dart';
import 'asset_alerts.dart';
import 'caller_play_screen.dart';
import 'caller_thread.dart';
import 'candle_chart.dart';
import 'order_ticket.dart';
import 'trade_mock.dart';

/// An asset's trade page (Figma "Trade — BTC": 206:110 chart open, swiped-up
/// panels 214:110 Market, 214:428 Book, 214:746 Callers). Opens with the
/// panels up on Market.
class AssetTradeScreen extends StatefulWidget {
  const AssetTradeScreen({super.key, required this.ticker});

  static Route<void> route(String ticker) =>
      MaterialPageRoute(builder: (_) => AssetTradeScreen(ticker: ticker));

  final String ticker;

  @override
  State<AssetTradeScreen> createState() => _AssetTradeScreenState();
}

class _AssetTradeScreenState extends State<AssetTradeScreen> {
  bool _followingOnly = true;
  int _interval = TradeMock.defaultInterval;

  AssetQuote get _quote =>
      TradeMock.quotes[widget.ticker] ?? TradeMock.quotes['BTC']!;

  void _notBuilt(String what) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$what — not in the demo yet')));
  }

  void _favoriteChanged(String name, bool added) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            added ? 'Added $name to Favorites' : 'Removed $name from Favorites',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: DisplayPrefs.chartMode,
      builder: (context, mode, _) => _sheet(mode),
    );
  }

  Widget _sheet(PlotMode mode) {
    return ChartSheet(
      header: (_) => _header(),
      chart: (_) => CandleChart(
        ticker: _quote.ticker,
        price: MarketPrices.base(_quote.ticker),
        interval: _interval,
        mode: mode,
      ),
      // Toggle art shows the selected type: candles, or line.
      chartTypeAsset: mode == PlotMode.candles
          ? VistaAssets.chartTypeCandles
          : VistaAssets.chartTypeToggle,
      // Same preference as Settings › Display › Charts.
      onChartType: () => DisplayPrefs.chartMode.value = mode == PlotMode.candles
          ? PlotMode.line
          : PlotMode.candles,
      intervals: TradeMock.intervals,
      defaultInterval: TradeMock.defaultInterval,
      onIntervalChanged: (i) => setState(() => _interval = i),
      onSide: (side) =>
          showOrderTicket(context, symbol: _quote.ticker, side: side),
      onNotBuilt: _notBuilt,
      panels: [
        ChartSheetPanel('Market', _marketPanel()),
        ChartSheetPanel('Book', _bookPanel()),
        ChartSheetPanel('Callers', _callersPanel()),
        ChartSheetPanel('Alerts', AssetAlertsPanel(ticker: _quote.ticker)),
      ],
    );
  }

  Widget _header() {
    final q = _quote;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        VistaSpace.xs,
        2,
        VistaSpace.xs,
        VistaSpace.lg,
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
              const VistaIcon(VistaAssets.assetAvatar, size: 32),
              const SizedBox(width: VistaSpace.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(q.ticker, style: VistaType.headline),
                        const SizedBox(width: VistaSpace.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: VistaColors.surfaceRaised,
                            borderRadius: BorderRadius.circular(VistaRadius.md),
                          ),
                          child: Text(
                            q.leverage,
                            style: VistaType.label.copyWith(
                              color: VistaColors.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 1),
                    Text(
                      q.name,
                      style: VistaType.caption.copyWith(
                        color: VistaColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              ValueListenableBuilder(
                valueListenable: WatchlistState.assets,
                builder: (context, list, _) => VistaWatchButton(
                  watched: list.contains(q.ticker),
                  onPressed: () => _favoriteChanged(
                    q.ticker,
                    WatchlistState.toggleAsset(q.ticker),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: VistaSpace.lg),
          Padding(
            padding: const EdgeInsets.only(
              left: VistaSpace.xl,
              right: VistaSpace.lg,
            ),
            child: Row(
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
                        LiveUsd(
                          feedKey: MarketPrices.feedKey(q.ticker),
                          base: MarketPrices.base(q.ticker),
                          step: MarketPrices.step(q.ticker),
                          decimals: 2,
                          style: VistaType.displayLarge,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          q.changeUsd,
                          style: VistaType.subhead.copyWith(color: q.color),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: VistaSpace.md),
                Text(
                  q.pctLabel,
                  style: VistaType.displaySmall.copyWith(color: q.color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  TextStyle get _small => VistaType.chip.copyWith(
    fontWeight: FontWeight.w500,
    color: VistaColors.textSecondary,
  );

  TextStyle get _rowLabel =>
      VistaType.rowMedium.copyWith(color: VistaColors.textMuted);

  TextStyle get _rowValue => VistaType.row;

  Widget _marketPanel() {
    const gap = SizedBox(height: 9);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        chartSheetTitle(
          'Market',
          Text(
            TradeMock.openInterest,
            style: VistaType.body.copyWith(color: VistaColors.textMuted),
          ),
        ),
        gap,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Longs ${(TradeMock.longShare * 100).round()}%',
              style: VistaType.bodyStrong.copyWith(color: VistaColors.long),
            ),
            Text(
              '${((1 - TradeMock.longShare) * 100).round()}% Shorts',
              style: VistaType.bodyStrong.copyWith(color: VistaColors.short),
            ),
          ],
        ),
        gap,
        const VistaSplitBar(leftFraction: TradeMock.longShare),
        gap,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(TradeMock.longOi, style: _small),
            Text(TradeMock.shortOi, style: _small),
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
                  Text('Longs pay shorts', style: _rowLabel),
                  const SizedBox(height: VistaSpace.xxs),
                  Text(TradeMock.fundingNext, style: VistaType.caption),
                ],
              ),
            ),
            Text(
              TradeMock.fundingRate,
              style: _rowValue.copyWith(color: VistaColors.short),
            ),
          ],
        ),
        gap,
        const VistaHairline(),
        gap,
        Row(
          children: [
            Expanded(child: Text('24h range', style: _rowLabel)),
            Text(TradeMock.volume, style: _rowValue),
          ],
        ),
        const SizedBox(height: VistaSpace.sm),
        SizedBox(
          height: 12,
          child: LayoutBuilder(
            builder: (context, c) => Stack(
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: 4,
                  height: 4,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: VistaColors.surfaceRaised,
                      borderRadius: BorderRadius.circular(VistaRadius.pill),
                    ),
                  ),
                ),
                Positioned(
                  left: c.maxWidth * TradeMock.rangePosition - 6,
                  top: 0,
                  child: const VistaIcon(VistaAssets.rangeDot, size: 12),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: VistaSpace.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(TradeMock.rangeLow, style: _small),
            Text(TradeMock.rangeHigh, style: _small),
          ],
        ),
        gap,
        const VistaHairline(),
        gap,
        Row(
          children: [
            Expanded(child: Text('Funding · last 3 days', style: _rowLabel)),
            Text(TradeMock.fundingSummary, style: _rowValue),
          ],
        ),
      ],
    );
  }

  /// The book around the market's live price (the one price shown
  /// everywhere), moving with it.
  Widget _bookPanel() => ValueListenableBuilder(
    valueListenable: MarketPrices.of(_quote.ticker),
    builder: (context, price, _) => _book(TradeMock.book(price)),
  );

  Widget _book(
    ({
      List<(String, String, double)> bids,
      List<(String, String, double)> asks,
      String spread,
    })
    book,
  ) {
    final tabStyle = VistaType.headline;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Book', style: tabStyle),
        const SizedBox(height: VistaSpace.lg),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Bids',
              style: VistaType.chip.copyWith(
                fontWeight: FontWeight.w700,
                color: VistaColors.long,
              ),
            ),
            Text(
              book.spread,
              style: VistaType.label.copyWith(
                fontWeight: FontWeight.w500,
                color: VistaColors.textSecondary,
              ),
            ),
            Text(
              'Asks',
              style: VistaType.chip.copyWith(
                fontWeight: FontWeight.w700,
                color: VistaColors.short,
              ),
            ),
          ],
        ),
        for (var i = 0; i < book.bids.length; i++) ...[
          const SizedBox(height: VistaSpace.xs),
          Row(
            children: [
              Expanded(child: _bookSide(book.bids[i], bid: true)),
              const SizedBox(width: VistaSpace.sm),
              Expanded(child: _bookSide(book.asks[i], bid: false)),
            ],
          ),
        ],
      ],
    );
  }

  /// One half of a book row: depth bar from the centre outwards, price on
  /// the outside edge and size by the centre.
  Widget _bookSide((String, String, double) level, {required bool bid}) {
    final (price, size, depth) = level;
    final colour = bid ? VistaColors.long : VistaColors.short;
    final priceText = Text(
      price,
      style: VistaType.figures(VistaType.row).copyWith(color: colour),
    );
    final sizeText = Text(size, style: VistaType.figures(VistaType.rowMedium));
    return SizedBox(
      height: 26,
      child: Stack(
        children: [
          Align(
            alignment: bid ? Alignment.centerRight : Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: depth,
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colour.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: VistaSpace.md),
            child: Row(
              children: bid
                  ? [priceText, const Spacer(), sizeText]
                  : [sizeText, const Spacer(), priceText],
            ),
          ),
        ],
      ),
    );
  }

  Widget _callersPanel() {
    const gap = SizedBox(height: VistaSpace.xl);
    const long = TradeMock.callersLong;
    const short = TradeMock.callersShort;
    Widget toggle(String label, bool on) => GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _followingOnly = label == 'Following'),
      child: Text(
        label,
        style: VistaType.body.copyWith(
          color: on ? VistaColors.textPrimary : VistaColors.textMuted,
        ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        chartSheetTitle(
          'Callers in ${_quote.ticker}',
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              toggle('Following', _followingOnly),
              const SizedBox(width: VistaSpace.xl),
              toggle('Everyone', !_followingOnly),
            ],
          ),
        ),
        gap,
        CallerThread(
          ticker: _quote.ticker,
          // Following: people the user follows; Everyone: all callers.
          posts: [
            for (final p in TradeMock.callers)
              if (!_followingOnly || p.following) p,
          ],
          onCaller: (handle) =>
              Navigator.of(context).push(ProfileScreen.route(handle)),
          onPlay: (post) =>
              Navigator.of(context)
                  .push(CallerPlayScreen.route(post, _quote.ticker)),
        ),
        gap,
        const VistaHairline(),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _notBuilt('All callers'),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: VistaSpace.xl),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'All ${long + short} callers in ${_quote.ticker}',
                    style: VistaType.row.copyWith(color: VistaColors.textMuted),
                  ),
                ),
                Text(
                  '›',
                  style: VistaType.tab.copyWith(color: VistaColors.textMuted),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
