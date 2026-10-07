import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../account/account_top_bar.dart';
import '../calls/calls_store.dart';
import '../market/trader_market_screen.dart';
import '../portfolio/portfolio_mock.dart';
import '../trade/asset_trade_screen.dart';
import '../watchlist/edit_favorites_screen.dart';
import '../watchlist/watchlist_state.dart';
import '../live/market_prices.dart';
import 'leaderboard_row.dart';
import 'markets_mock.dart';
import 'market_chart_card.dart';

/// Explore tab: Assets and Leaderboard (Figma 185:110, 222:110). Assets are
/// chart cards (546:300).
///
/// Leaderboard ranks every trader market as flush rows with no chart
/// ([LeaderboardRow]): most right, this week's P&L, cap or change, with
/// yours lifted and your place in the header. Its Up and coming chip
/// narrows the board to markets opened in the last 30 days, ranked by
/// holders gained this week.
///
/// Search filters by name, the sort chips order the list (descending), and
/// stars add or remove favourites (shared with the market pages' stars),
/// which the Favourites rail follows in the order they were added.
class MarketsScreen extends StatefulWidget {
  const MarketsScreen({super.key, this.onNotBuilt});

  /// Called with a feature name when a control leads somewhere not built yet.
  final ValueChanged<String>? onNotBuilt;

  @override
  State<MarketsScreen> createState() => _MarketsScreenState();
}

class _MarketsScreenState extends State<MarketsScreen> {
  /// Height the floating search takes above the nav (field plus margins).
  static const double _searchSpace = 50;

  int _tab = 0; // 0 Assets, 1 Leaderboard
  final _search = TextEditingController();
  String _query = '';
  final _sort = [0, 0];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool get _traders => _tab == 1;
  List<String> get _sorts =>
      _traders ? MarketsMock.traderSorts : MarketsMock.assetSorts;
  String get _sortKey => _sorts[_sort[_tab]];
  bool get _upAndComing => _traders && _sortKey == 'Up and coming';

  /// Every market on the tab, for the Favorites rail.
  List<MarketItem> get _railSource =>
      _traders ? MarketsMock.traders : MarketsMock.assets;

  List<MarketItem> get _all => !_traders
      ? MarketsMock.assets
      : [
          for (final m in MarketsMock.traders)
            if (!_upAndComing ||
                (MarketsMock.traderCards[m.id]?.days ?? 999) <=
                    MarketsMock.newMarketDays)
              m,
        ];

  /// What a chip orders by (descending); null keeps designed order.
  static double? _sortValue(MarketItem m, String key) {
    final c = MarketsMock.traderCards[m.id];
    return switch (key) {
      'Most right' => double.tryParse(
        (CallsStore.recordOf(m.id) ?? '').split('%').first,
      ),
      'Top P&L' => c?.weekPnl,
      'Up and coming' => c?.newHolders.toDouble(),
      _ => m.sortValues[key],
    };
  }

  void _selectTab(int i) {
    if (i == _tab) return;
    setState(() {
      _tab = i;
      _query = '';
      _search.clear();
    });
  }

  ValueNotifier<List<String>> get _favorites =>
      _traders ? WatchlistState.traders : WatchlistState.assets;

  void _toggleFavorite(String id) => _traders
      ? WatchlistState.toggleTrader(id)
      : WatchlistState.toggleAsset(id);

  void _open(MarketItem m) {
    if (_traders) {
      Navigator.of(context).push(TraderMarketScreen.route(m.name));
    } else {
      Navigator.of(context).push(AssetTradeScreen.route(m.id));
    }
  }

  /// The whole list in chip order, each market with its place.
  List<(int, MarketItem)> _ranked() {
    final key = _sortKey;
    final list = [..._all];
    // Items without a value for this chip keep designed order.
    if (list.every((m) => _sortValue(m, key) != null)) {
      list.sort((a, b) => _sortValue(b, key)!.compareTo(_sortValue(a, key)!));
    }
    return [for (final (i, m) in list.indexed) (i + 1, m)];
  }

  /// Name match; trader markets also match their ticker ("maya" or "MAYA").
  static bool _matches(MarketItem m, String q) =>
      m.name.toLowerCase().contains(q) ||
      (MarketsMock.traderCards[m.id]?.symbol.toLowerCase().contains(q) ??
          false);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: _favorites,
      builder: (context, favs, _) => _build(favs),
    );
  }

  Widget _build(List<String> favs) {
    // In favourite order, not list order.
    final byId = {for (final m in _railSource) m.id: m};
    final favItems = [
      for (final id in favs)
        if (byId[id] != null) byId[id]!,
    ];
    // Ranked before the search filters, so a match keeps its real place.
    final ranked = _ranked();
    final q = _query.toLowerCase();
    final rows = [
      for (final e in ranked)
        if (_matches(e.$2, q)) e,
    ];
    final youRank = ranked
        .where((e) => e.$2.id == PortfolioMock.handle)
        .firstOrNull
        ?.$1;
    const gutter = EdgeInsets.symmetric(horizontal: VistaSpace.gutter);

    // The list runs to the bottom of the screen and scrolls under the
    // floating search and nav, which sit over it with nothing behind them.
    final navSpace = MediaQuery.paddingOf(context).bottom;
    return SafeArea(
      bottom: false,
      child: Stack(
        children: [
          Column(
            children: [
              // The same account bar as Home and Portfolio.
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: VistaSpace.gutter,
                ),
                child: AccountTopBar(
                  onNotBuilt: widget.onNotBuilt,
                  showNotifications: true,
                ),
              ),
              const SizedBox(height: VistaSpace.md),
              Expanded(
                child: ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  // Room to scroll the last item clear of the search and nav.
                  padding: EdgeInsets.only(
                    bottom: VistaSpace.gutter + _searchSpace + navSpace,
                  ),
                  children: [
                    Padding(
                      padding: gutter,
                      child: VistaUnderlineTabs(
                        labels: const ['Assets', 'Leaderboard'],
                        selectedIndex: _tab,
                        onChanged: _selectTab,
                      ),
                    ),
                    if (favItems.isNotEmpty) ...[
                      const SizedBox(height: VistaSpace.xl),
                      Padding(
                        padding: gutter,
                        child: Row(
                          children: [
                            Text(
                              '★',
                              style: VistaType.body.copyWith(
                                fontSize: 15,
                                color: VistaColors.favorite,
                              ),
                            ),
                            const SizedBox(width: VistaSpace.sm),
                            Expanded(
                              child: Text('Favorites', style: VistaType.tab),
                            ),
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => Navigator.of(context).push(
                                EditFavoritesScreen.route(traders: _traders),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                child: Text(
                                  'Edit',
                                  style: VistaType.body.copyWith(
                                    color: VistaColors.accent,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Sized by its cards, so they hug their content rather
                      // than stretching to a fixed rail height.
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: gutter,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final (i, m) in favItems.indexed) ...[
                              if (i > 0) const SizedBox(width: VistaSpace.lg),
                              ValueListenableBuilder(
                                valueListenable: MarketPrices.of(m.id),
                                builder: (context, price, _) => VistaMarketCard(
                                  icon: m.railIcon,
                                  name: m.name,
                                  badge: m.badge ?? '',
                                  price: MarketPrices.format(
                                    price,
                                    compact: true,
                                  ),
                                  changePct: m.changePct,
                                  chart: MarketLineChart(
                                    id: m.id,
                                    changePct: m.changePct,
                                    price: price,
                                    height: 28,
                                  ),
                                  footLeft: m.footLeft,
                                  footRight: m.footRight,
                                  onPressed: () => _open(m),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: VistaSpace.xl),
                    // One line that scrolls sideways when the chips don't fit.
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: gutter,
                      child: Row(
                        children: [
                          for (var i = 0; i < _sorts.length; i++) ...[
                            if (i > 0) const SizedBox(width: VistaSpace.md),
                            VistaFilterChip(
                              label: _sorts[i],
                              accent: true,
                              selected: i == _sort[_tab],
                              onPressed: () => setState(() => _sort[_tab] = i),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        VistaSpace.gutter,
                        VistaSpace.xs,
                        VistaSpace.gutter,
                        VistaSpace.sm,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              !_traders
                                  ? 'ALL MARKETS'
                                  : _upAndComing
                                  ? 'OPENED IN THE LAST '
                                        '${MarketsMock.newMarketDays} DAYS'
                                  : 'RANKED THIS WEEK',
                              style: VistaType.label.copyWith(
                                color: VistaColors.textMuted,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                          // Your place, whatever the search shows.
                          if (_traders && youRank != null)
                            Text.rich(
                              TextSpan(
                                children: [
                                  const TextSpan(text: 'You  '),
                                  TextSpan(
                                    text: '#$youRank',
                                    style: const TextStyle(
                                      color: VistaColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              style: VistaType.label.copyWith(
                                color: VistaColors.textMuted,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (rows.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: VistaSpace.section),
                        child: Center(
                          child: Text(
                            'No matches',
                            style: VistaType.bodyRegular,
                          ),
                        ),
                      ),
                    // The board: flush rows split by hairlines, no charts.
                    if (_traders)
                      for (final (i, (rank, m)) in rows.indexed) ...[
                        if (i > 0)
                          const Divider(
                            height: 1,
                            thickness: 1,
                            indent: VistaSpace.gutter,
                            endIndent: VistaSpace.gutter,
                            color: VistaColors.hairline,
                          ),
                        LeaderboardRow(
                          rank: rank,
                          market: m,
                          metric: _sortKey,
                          isYou: m.id == PortfolioMock.handle,
                          onPressed: () => _open(m),
                        ),
                      ]
                    else
                      for (final (_, m) in rows)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            VistaSpace.gutter,
                            0,
                            VistaSpace.gutter,
                            VistaSpace.md,
                          ),
                          child: AssetMarketCard(
                            market: m,
                            starred: favs.contains(m.id),
                            onStar: () => _toggleFavorite(m.id),
                            onPressed: () => _open(m),
                          ),
                        ),
                  ],
                ),
              ),
            ],
          ),
          // The search floats just above the nav.
          Positioned(
            left: 0,
            right: 0,
            bottom: navSpace,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                VistaSpace.gutter,
                VistaSpace.sm,
                VistaSpace.gutter,
                VistaSpace.sm,
              ),
              child: VistaSearchField(
                bordered: true,
                hint: _traders ? 'Search traders' : 'Search markets',
                controller: _search,
                onChanged: (q) => setState(() => _query = q),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
