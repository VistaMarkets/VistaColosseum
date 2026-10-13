import 'package:flutter/material.dart';

import '../../app_shell.dart';
import '../../design_system/design_system.dart';
import '../../scenario/scenario.dart';
import '../account/account_top_bar.dart';
import '../arena/arena_mock.dart';
import '../profile/profile_screen.dart';
import '../market/trader_market_mock.dart';
import '../market/trader_market_screen.dart';
import '../trade/asset_trade_screen.dart';
import '../trade/order_ticket.dart';
import '../calls/calls_store.dart';
import 'home_feed.dart';
import 'maker_suggestion.dart';
import 'trade_idea_card.dart';

/// Home's For You pages: every call, ranked ([HomeFeed.forYou]), with the
/// two Maker suggestions each between two of them.
List<Object> get homeFeed => _forYou(CallsStore.all.value);

List<Object> _forYou(List<Take> calls) {
  final ranked = HomeFeed.forYou(_listed(calls));
  return [
    for (final (i, t) in ranked.indexed) ...[
      t,
      if (i == 1) makerSuggestions[0],
      if (i == 2) makerSuggestions[1],
    ],
  ];
}

/// Calls on the user's own market (made days ago) drop out while that
/// market is a fresh listing (VC-MKT-001).
List<Take> _listed(List<Take> calls) => [
  for (final t in calls)
    if (!(t.ticker == TraderMarketMock.own && !TraderMarketMock.ownHasHistory))
      t,
];

/// Home feed (Figma 301:102, "Home · header A — caller first, aligned").
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.visible = true,
    this.onNotBuilt,
    this.onExplore,
    this.feed,
  });

  /// Whether the Home tab is showing; card animations only run while it is.
  final bool visible;

  /// Called with a feature name when a control leads somewhere not built yet.
  final ValueChanged<String>? onNotBuilt;

  /// Switches to the Explore tab (from the empty feed's Explore markets);
  /// without it, [AppShell.showExplore].
  final VoidCallback? onExplore;

  /// The pages to show (calls and Maker suggestions); [homeFeed] unless
  /// given.
  final List<Object>? feed;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// 0 = Following, 1 = For You (where Home opens).
  int _feed = 1;

  /// Home's feed pager. The pager's key, not the controller, starts each
  /// tab at its first card.
  final _pages = PageController();

  /// The card settled on screen. Updated only when a swipe comes to rest, so
  /// the outgoing card resets off-screen and the incoming one traces in view.
  int _settledPage = 0;

  @override
  void initState() {
    super.initState();
    Scenario.followed.addListener(_onFollowedChanged);
  }

  @override
  void dispose() {
    Scenario.followed.removeListener(_onFollowedChanged);
    _pages.dispose();
    super.dispose();
  }

  /// A follow or unfollow rebuilds Following and restarts it at its first
  /// card (the pager is keyed by the follows), so the card on screen is the
  /// one that plays, even when its cards are unchanged.
  void _onFollowedChanged() {
    if (_feed == 0) setState(() => _settledPage = 0);
  }

  /// The replay starts once the card has all but landed (within 2% of a
  /// page), not only when the scroll fully ends, so there's no dead beat
  /// after a swipe.
  bool _onScroll(ScrollNotification n) {
    final p = _pages.page;
    if (p == null) return false;
    final near = (p - p.round()).abs() < 0.02;
    if ((near || n is ScrollEndNotification) && p.round() != _settledPage) {
      setState(() => _settledPage = p.round());
    }
    return false;
  }

  /// For You: every page. Following: only the calls of traders the user
  /// follows (`Scenario.followed`, which every Follow button writes), ranked
  /// by [HomeFeed.following], no Maker suggestions.
  List<Object> _feedItems(List<Take> calls) {
    final given = widget.feed;
    if (_feed == 1) return given ?? _forYou(calls);
    if (given == null) return HomeFeed.following(_listed(calls));
    final followed = Scenario.followed.value;
    return [
      for (final i in given)
        if (i is Take && followed.contains(i.handle)) i,
    ];
  }

  @override
  Widget build(BuildContext context) {
    // The feed runs to the bottom of the screen, under the floating nav:
    // each card keeps its own content clear of the pill, and the next card
    // slides up through it as you swipe.
    final navSpace = MediaQuery.paddingOf(context).bottom;
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: VistaSpace.gutter),
            child: AccountTopBar(
              onNotBuilt: widget.onNotBuilt,
              showNotifications: true,
            ),
          ),
          const SizedBox(height: VistaSpace.md),
          // The feed tabs, centred. Calls are made from Arena's +.
          Center(
            child: VistaSegmentedTabs(
              labels: const ['Following', 'For You'],
              selectedIndex: _feed,
              onChanged: (i) {
                if (i == _feed) return;
                // A new feed starts at its top (a new pager, by its key).
                setState(() {
                  _feed = i;
                  _settledPage = 0;
                });
              },
            ),
          ),
          const SizedBox(height: VistaSpace.md),
          Expanded(
            // Users' calls, ranked: Following or For You.
            child: ValueListenableBuilder(
              valueListenable: CallsStore.all,
              builder: (context, calls, _) =>
                  _feedView(_feedItems(calls), navSpace),
            ),
          ),
        ],
      ),
    );
  }

  Widget _feedView(List<Object> items, double navSpace) {
    if (items.isEmpty) {
      return ListView(
        children: [
          VistaEmptyState(
            message: 'No calls to show',
            actionLabel: 'Explore markets',
            onAction: widget.onExplore ?? () => AppShell.showExplore(context),
          ),
        ],
      );
    }
    return NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: PageView.builder(
        // A new pager per tab, and per change of follows on Following,
        // starting at its first card.
        key: ValueKey(_feed == 0 ? Scenario.followed.value : _feed),
        controller: _pages,
        scrollDirection: Axis.vertical,
        itemCount: items.length,
        itemBuilder: (context, i) {
          final item = items[i];

          void goDetails(String ticker, {bool isTrader = false}) {
            Navigator.of(context).push(
              isTrader
                  ? TraderMarketScreen.route(ticker)
                  : AssetTradeScreen.route(ticker),
            );
          }

          if (item is Suggestion) {
            return Padding(
              padding: EdgeInsets.only(bottom: navSpace),
              child: Center(
                child: MakerSuggestionCard(
                  suggestion: item,
                  // The same first-time ticket an idea card opens.
                  onTrade: () => showFeedOrderTicket(
                    context,
                    symbol: item.asset,
                    side: item.direction,
                    onDetails: () => goDetails(item.asset),
                  ),
                ),
              ),
            );
          }
          final take = item as Take;
          final idea = HomeFeed.ideaOf(take);
          // An asset opens its trade page; a trader market, the trader's
          // market page.
          void details() => goDetails(idea.ticker, isTrader: idea.traderMarket);
          return Padding(
            padding: EdgeInsets.only(bottom: navSpace),
            child: TradeIdeaCard(
              key: ValueKey(take.id),
              idea: idea,
              active: widget.visible && i == _settledPage,
              onDetails: details,
              onCaller: () =>
                  Navigator.of(context)
                      .push(ProfileScreen.route(idea.callerHandle)),
              // The first-time ticket, on the call's side (simulated); its
              // Details is the card's. A copy carries the call it came from.
              onTrade: () => showFeedOrderTicket(
                context,
                symbol: idea.ticker,
                side: idea.side,
                sourceCallId: '${idea.callerHandle}/${idea.ticker}',
                sourceAuthorHandle: idea.callerHandle,
                onDetails: details,
              ),
            ),
          );
        },
      ),
    );
  }
}
