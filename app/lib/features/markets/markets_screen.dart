import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../market/trader_market_screen.dart';
import '../trade/asset_trade_screen.dart';
import 'markets_mock.dart';

/// Explore tab: Assets and Traders markets (Figma 185:110, 222:110).
///
/// Search filters by name, the sort chips order the list (descending), and
/// stars add or remove favourites, which the Favourites rail follows.
class MarketsScreen extends StatefulWidget {
  const MarketsScreen({super.key, this.onNotBuilt});

  /// Called with a feature name when a control leads somewhere not built yet.
  final ValueChanged<String>? onNotBuilt;

  @override
  State<MarketsScreen> createState() => _MarketsScreenState();
}

class _MarketsScreenState extends State<MarketsScreen> {
  int _tab = 0; // 0 Assets, 1 Traders
  final _search = TextEditingController();
  String _query = '';
  final _sort = [0, 0];
  final _favorites = [
    {...MarketsMock.assetFavorites},
    {...MarketsMock.traderFavorites},
  ];

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

  void _toggleFavorite(String id) => setState(() {
    final favs = _favorites[_tab];
    favs.contains(id) ? favs.remove(id) : favs.add(id);
  });

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
    final list = _all.where((m) => m.name.toLowerCase().contains(q)).toList();
    // Items without a value for this chip (e.g. "New") keep designed order.
    if (list.every((m) => m.sortValues.containsKey(key))) {
      list.sort((a, b) => b.sortValues[key]!.compareTo(a.sortValues[key]!));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final favs = _favorites[_tab];
    final favItems = _all.where((m) => favs.contains(m.id)).toList();
    final rows = _sorted();
    const gutter = EdgeInsets.symmetric(horizontal: VistaSpace.gutter);

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          VistaSearchTopBar(
            controller: _search,
            hint: _traders ? 'Search traders' : 'Search markets',
            onChanged: (q) => setState(() => _query = q),
            onBell: () => _notBuilt('Notifications'),
          ),
          Expanded(
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.only(bottom: VistaSpace.gutter),
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
                          onTap: () => _notBuilt('Edit favorites'),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
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
                  SizedBox(
                    height: 150,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: gutter,
                      itemCount: favItems.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(width: VistaSpace.lg),
                      itemBuilder: (context, i) {
                        final m = favItems[i];
                        return VistaMarketCard(
                          icon: m.railIcon,
                          name: m.name,
                          badge: m.badge ?? '',
                          price: m.price,
                          changePct: m.changePct,
                          sparkAsset: m.spark,
                          footLeft: m.footLeft,
                          footRight: m.footRight,
                          onPressed: () => _open(m),
                        );
                      },
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
                    padding: const EdgeInsets.only(top: 24),
                    child: Center(
                      child: Text('No matches', style: VistaType.bodyRegular),
                    ),
                  ),
                for (final m in rows)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(6, 0, 6, VistaSpace.md),
                    child: VistaMarketRow(
                      starred: favs.contains(m.id),
                      onStar: () => _toggleFavorite(m.id),
                      icon: m.rowIcon,
                      name: m.name,
                      badge: m.badge,
                      subline: m.subline,
                      price: m.price,
                      changePct: m.changePct,
                      third: m.third,
                      onPressed: () => _open(m),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
