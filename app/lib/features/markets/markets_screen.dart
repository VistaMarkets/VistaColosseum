import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../account/account_top_bar.dart';
import '../market/trader_market_screen.dart';
import '../trade/asset_trade_screen.dart';
import '../watchlist/edit_favorites_screen.dart';
import '../watchlist/watchlist_state.dart';
import '../live/market_prices.dart';
import 'markets_mock.dart';
import 'market_chart_card.dart';

/// Explore tab: Assets and Traders markets (Figma 185:110, 222:110). Every
/// market in the list is a chart card (546:300).
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

  int _tab = 0; // 0 Assets, 1 Traders
  final _search = TextEditingController();
  String _query = '';
  final _sort = [0, 0];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool get _traders => _tab == 1;
  List<MarketItem> get _all =>
      _traders ? MarketsMock.traders : MarketsMock.assets;
  List<String> get _sorts =>
      _traders ? MarketsMock.traderSorts : MarketsMock.assetSorts;

  void _notBuilt(String what) => widget.onNotBuilt?.call(what);

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

  List<MarketItem> _sorted() {
    final key = _sorts[_sort[_tab]];
    final q = _query.toLowerCase();
    // Trader markets also match their ticker ("maya" or "MAYA").
    final list = _all
        .where(
          (m) =>
              m.name.toLowerCase().contains(q) ||
              (MarketsMock.traderCards[m.id]?.symbol.toLowerCase().contains(
                    q,
                  ) ??
                  false),
        )
        .toList();
    // Items without a value for this chip (e.g. "New") keep designed order.
    if (list.every((m) => m.sortValues.containsKey(key))) {
      list.sort((a, b) => b.sortValues[key]!.compareTo(a.sortValues[key]!));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: _favorites,
      builder: (context, favs, _) => _build(favs),
    );
  }

  Widget _build(List<String> favs) {
    // In favourite order, not list order.
    final byId = {for (final m in _all) m.id: m};
    final favItems = [
      for (final id in favs)
        if (byId[id] != null) byId[id]!,
    ];
    final rows = _sorted();
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
                  showSettings: true,
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
                        labels: const ['Assets', 'Traders'],
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
                                  sparkAsset: m.spark,
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
                    Padding(
                      padding: gutter,
                      child: Wrap(
                        spacing: VistaSpace.md,
                        children: [
                          for (var i = 0; i < _sorts.length; i++)
                            VistaFilterChip(
                              label: _sorts[i],
                              accent: true,
                              selected: i == _sort[_tab],
                              onPressed: () {
                                if (_sorts[i] == 'New') {
                                  _notBuilt('Sort by new');
                                  return;
                                }
                                setState(() => _sort[_tab] = i);
                              },
                            ),
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
                              _traders ? 'ALL TRADER MARKETS' : 'ALL MARKETS',
                              style: VistaType.label.copyWith(
                                color: VistaColors.textMuted,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                          Text(
                            'A–Z',
                            style: VistaType.label.copyWith(
                              color: VistaColors.textSecondary,
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
                    for (final m in rows)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          VistaSpace.gutter,
                          0,
                          VistaSpace.gutter,
                          VistaSpace.md,
                        ),
                        child: _traders
                            ? TraderMarketCard(
                                market: m,
                                starred: favs.contains(m.id),
                                onStar: () => _toggleFavorite(m.id),
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
