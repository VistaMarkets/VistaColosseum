import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../account/account_top_bar.dart';
import '../profile/profile_screen.dart';
import '../market/trader_market_screen.dart';
import '../trade/asset_trade_screen.dart';
import '../trade/order_ticket.dart';
import '../calls/calls_store.dart';
import 'home_feed.dart';
import 'trade_idea_card.dart';

/// Home feed (Figma 301:102, "Home · header A — caller first, aligned").
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.visible = true,
    this.onNotBuilt,
    this.onExplore,
  });

  /// Whether the Home tab is showing; card animations only run while it is.
  final bool visible;

  /// Called with a feature name when a control leads somewhere not built yet.
  final ValueChanged<String>? onNotBuilt;

  /// Switches to the Explore tab (from the + flow's empty state).
  final VoidCallback? onExplore;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _feed = 0;

  final _pages = PageController();

  /// The card settled on screen. Updated only when a swipe comes to rest, so
  /// the outgoing card resets off-screen and the incoming one traces in view.
  int _settledPage = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
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
                // A new feed starts at its top.
                setState(() {
                  _feed = i;
                  _settledPage = 0;
                });
                if (_pages.hasClients) _pages.jumpToPage(0);
              },
            ),
          ),
          const SizedBox(height: VistaSpace.md),
          Expanded(
            // Users' calls, ranked: Following or For You.
            child: ValueListenableBuilder(
              valueListenable: CallsStore.all,
              builder: (context, calls, _) {
                final feed = _feed == 0
                    ? HomeFeed.following(calls)
                    : HomeFeed.forYou(calls);
                if (feed.isEmpty) {
                  return Center(
                    child: Text(
                      'No calls from people you follow yet',
                      style: VistaType.body.copyWith(
                        color: VistaColors.textMuted,
                      ),
                    ),
                  );
                }
                return NotificationListener<ScrollNotification>(
                  onNotification: _onScroll,
                  child: PageView.builder(
                    controller: _pages,
                    scrollDirection: Axis.vertical,
                    itemCount: feed.length,
                    itemBuilder: (context, i) {
                      final idea = HomeFeed.ideaOf(feed[i]);
                      void details() => Navigator.of(context).push(
                        idea.traderMarket
                            ? TraderMarketScreen.route(idea.ticker)
                            : AssetTradeScreen.route(idea.ticker),
                      );
                      return Padding(
                        padding: EdgeInsets.only(bottom: navSpace),
                        child: TradeIdeaCard(
                          key: ValueKey(feed[i].id),
                          idea: idea,
                          active: widget.visible && i == _settledPage,
                          // An asset opens its trade page; a trader market,
                          // the trader's market page.
                          onDetails: details,
                          onCaller: () =>
                              Navigator.of(context)
                                  .push(ProfileScreen.route(idea.callerHandle)),
                          // The first-time ticket, on the call's side
                          // (simulated); its Details is the card's.
                          onTrade: () => showFeedOrderTicket(
                            context,
                            symbol: idea.ticker,
                            side: idea.side,
                            onDetails: details,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
