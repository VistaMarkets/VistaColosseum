import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../account/account_state.dart';
import '../account/account_top_bar.dart';
import '../profile/profile_screen.dart';
import '../portfolio/portfolio_mock.dart';
import '../trade/asset_trade_screen.dart';
import '../watchlist/edit_favorites_screen.dart';
import '../watchlist/watchlist_state.dart';
import '../live/market_prices.dart';
import 'explore_sections.dart';
import 'leaderboard.dart';
import 'markets_mock.dart';
import 'market_chart_card.dart';

/// Explore tab: Assets and Leaderboard (Figma 185:110, 222:110). Every
/// market is the same chart card (546:300).
///
/// Leaderboard ranks every trader market ([LeaderboardCard]) by most right,
/// P&L, cap or change over a 24h / 7d / 30d / All window, which the cards'
/// change and charts follow; yours is outlined and your place is in the
/// header. Its Up and coming chip narrows the board to markets opened in
/// the last 30 days, ranked by holders gained.
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
  int _tab = 0; // 0 Assets, 1 Leaderboard
  final _search = TextEditingController();
  String _query = '';
  final _sort = [0, 0];

  /// Leaderboard time window, an index into [Leaderboard.windows] (7d).
  int _window = 1;

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
            // Yours is on the board once you've made it.
            if (m.id != PortfolioMock.handle || AccountState.hasMarket.value)
              if (!_upAndComing ||
                  (MarketsMock.traderCards[m.id]?.days ?? 999) <=
                      MarketsMock.newMarketDays)
                m,
        ];

  /// What a chip orders by (descending); null keeps designed order.
  double? _sortValue(MarketItem m, String key) =>
      _traders ? Leaderboard.value(m, key, _window) : m.sortValues[key];

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
      // The board is about people: a card opens the trader's profile (their
      // market is a tap away from there).
      Navigator.of(context).push(ProfileScreen.route(m.name));
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

  /// 24h · 7d · 30d · All: small text pills, the picked one filled.
  Widget _windowSelector() => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (final (i, w) in Leaderboard.windows.indexed)
        Semantics(
          button: true,
          selected: i == _window,
          label: w,
          excludeSemantics: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _window = i),
            child: SizedBox(
              height: VistaSize.tapTarget,
              child: Center(
                child: AnimatedContainer(
                  duration: VistaMotion.state,
                  padding: const EdgeInsets.symmetric(
                    horizontal: VistaSpace.lg,
                    vertical: VistaSpace.xs,
                  ),
                  decoration: BoxDecoration(
                    color: i == _window
                        ? VistaColors.surfaceRaised
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(VistaRadius.pill),
                  ),
                  child: Text(
                    w,
                    style: VistaType.figures(VistaType.label).copyWith(
                      color: i == _window
                          ? VistaColors.textPrimary
                          : VistaColors.textMuted,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
    ],
  );

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
    final label = VistaType.label.copyWith(
      color: VistaColors.textMuted,
      letterSpacing: 0.6,
    );

    // The list runs to the bottom of the screen and scrolls under the
    // floating nav.
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
              Expanded(
                child: ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  // Room to scroll the last item clear of the nav.
                  padding: EdgeInsets.only(
                    bottom: VistaSpace.gutter + navSpace,
                  ),
                  children: [
                    // Search at the top, as on Arena.
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        VistaSpace.gutter,
                        VistaSpace.xl,
                        VistaSpace.gutter,
                        VistaSpace.md,
                      ),
                      child: VistaSearchField(
                        hint: _traders ? 'Search traders' : 'Search markets',
                        controller: _search,
                        onChanged: (q) => setState(() => _query = q),
                      ),
                    ),
                    Padding(
                      padding: gutter,
                      child: VistaUnderlineTabs(
                        labels: const ['Assets', 'Leaderboard'],
                        selectedIndex: _tab,
                        onChanged: _selectTab,
                      ),
                    ),
                    // Favorites sit on Assets only; the board is the board.
                    if (!_traders && favItems.isNotEmpty) ...[
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
                    // Sideways sections: why a market is worth a look. Off
                    // while searching, so results sit under the search.
                    if (!_traders && _query.isEmpty)
                      ExploreSections(
                        onAsset: (m) =>
                            Navigator.of(context)
                                .push(AssetTradeScreen.route(m.id)),
                        onTrader: (m) =>
                            Navigator.of(context)
                                .push(ProfileScreen.route(m.name)),
                      ),
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
                          // The window every card's change and chart follow.
                          if (_traders)
                            _windowSelector()
                          else
                            SizedBox(
                              height: VistaSize.tapTarget,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text('ALL MARKETS', style: label),
                              ),
                            ),
                          const Spacer(),
                          if (_upAndComing)
                            Text(
                              'UNDER ${MarketsMock.newMarketDays} DAYS OLD',
                              style: label,
                            )
                          // Your place, whatever the search shows.
                          else if (_traders && youRank != null)
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
                    for (final (rank, m) in rows)
                      Padding(
                        // Slim board rows sit closer, as Portfolio's do.
                        padding: EdgeInsets.fromLTRB(
                          VistaSpace.gutter,
                          0,
                          VistaSpace.gutter,
                          _traders ? VistaSpace.sm : VistaSpace.md,
                        ),
                        child: _traders
                            ? LeaderboardCard(
                                rank: rank,
                                market: m,
                                metric: _sortKey,
                                window: _window,
                                isYou: m.id == PortfolioMock.handle,
                                onPressed: () => _open(m),
                              )
                            : AssetMarketCard(
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
        ],
      ),
    );
  }
}
