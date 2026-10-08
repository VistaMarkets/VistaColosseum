import '../../scenario/scenario.dart';
import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../account/account_top_bar.dart';
import '../profile/profile_screen.dart';
import '../market/trader_market_screen.dart';
import '../trade/asset_trade_screen.dart';
import '../trade/order_ticket.dart';
import 'maker_suggestion.dart';
import 'mock_trade_idea.dart';
import 'trade_idea_card.dart';
import '../../app_shell.dart';

/// Home's pages: the idea cards, with the two Maker suggestions each
/// between two of them.
final homeFeed = <Object>[
  ...mockFeed.take(2),
  makerSuggestions[0],
  mockFeed[2],
  makerSuggestions[1],
  ...mockFeed.skip(3),
];

/// Home feed (Figma 301:102, "Home · header A — caller first, aligned").
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.visible = true,
    this.onNotBuilt,
    this.feed,
  });

  /// Whether the Home tab is showing; card animations only run while it is.
  final bool visible;

  /// Called with a feature name when a control leads somewhere not built yet.
  final ValueChanged<String>? onNotBuilt;

  /// The pages to show; [homeFeed] unless given.
  final List<Object>? feed;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _feed = 1;

  final _pages = PageController();

  /// The card settled on screen. Updated only when a swipe comes to rest, so
  /// the outgoing card resets off-screen and the incoming one traces in view.
  int _settledPage = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  bool _onScrollEnd(ScrollEndNotification n) {
    final page = _pages.page?.round() ?? 0;
    if (page != _settledPage) setState(() => _settledPage = page);
    return false;
  }

  List<Object> _getFeedItems(Set<String> followed) {
    if (widget.feed != null) return widget.feed!;
    if (_feed == 1) return homeFeed; // For You
    return homeFeed.where((item) {
      if (item is TradeIdea) return followed.contains(item.callerHandle);
      return false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ValueListenableBuilder<Set<String>>(
        valueListenable: Scenario.followed,
        builder: (context, followed, child) {
          final feedItems = _getFeedItems(followed);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: VistaSpace.gutter),
                child: AccountTopBar(onNotBuilt: widget.onNotBuilt),
              ),
              const SizedBox(height: VistaSpace.md),
              VistaSegmentedTabs(
                labels: const ['Following', 'For You'],
                selectedIndex: _feed,
                onChanged: (i) {
                  setState(() {
                    _feed = i;
                    _settledPage = 0;
                    if (_pages.hasClients) _pages.jumpToPage(0);
                  });
                },
              ),
              const SizedBox(height: VistaSpace.md),
              Expanded(
                child: feedItems.isEmpty
                ? ListView(
                    children: [
                      VistaEmptyState(
                        message: 'No calls to show',
                        actionLabel: 'Explore markets',
                        onAction: () => AppShell.showExplore(context),
                      ),
                    ],
                  )
                : NotificationListener<ScrollEndNotification>(
                    onNotification: _onScrollEnd,
                    child: PageView.builder(
                      controller: _pages,
                      scrollDirection: Axis.vertical,
                      itemCount: feedItems.length,
                      itemBuilder: (context, i) {
                        final item = feedItems[i];
                        
                        void goDetails(String ticker, {bool isTrader = false}) {
                          Navigator.of(context).push(
                            isTrader
                                ? TraderMarketScreen.route(ticker)
                                : AssetTradeScreen.route(ticker),
                          );
                        }

                        if (item is Suggestion) {
                          return Center(
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
                          );
                        }
                        final idea = item as TradeIdea;
                        return TradeIdeaCard(
                          idea: idea,
                          active: widget.visible && i == _settledPage,
                          // An asset opens its trade page; a trader market, the
                          // trader's market page.
                          onDetails: () => goDetails(idea.ticker, isTrader: idea.traderMarket),
                          onCaller: () =>
                              Navigator.of(context)
                                  .push(ProfileScreen.route(idea.callerHandle)),
                          // The first-time ticket, on the call's side (simulated);
                          // its Details is the card's.
                          onTrade: () => showFeedOrderTicket(
                            context,
                            symbol: idea.ticker,
                            side: idea.side,
                            sourceCallId: '${idea.callerHandle}/${idea.ticker}',
                            sourceAuthorHandle: idea.callerHandle,
                            onDetails: () => goDetails(idea.ticker, isTrader: idea.traderMarket),
                          ),
                        );
                      },
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
