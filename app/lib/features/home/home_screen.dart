import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../../scenario/scenario.dart';
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

  bool _onScrollEnd(ScrollEndNotification n) {
    final page = _pages.page?.round() ?? 0;
    if (page != _settledPage) setState(() => _settledPage = page);
    return false;
  }

  /// For You: every page. Following: only the calls of traders the user
  /// follows (`Scenario.followed`, which every Follow button writes), no
  /// Maker suggestions. The follows are not in a persona's books, so both
  /// personas see one Following feed; the Following list's people
  /// (`Scenario.following`) do not feed it.
  List<Object> get _feedItems {
    final all = widget.feed ?? homeFeed;
    if (_feed == 1) return all;
    final followed = Scenario.followed.value;
    return [
      for (final i in all)
        if (i is TradeIdea && followed.contains(i.callerHandle)) i,
    ];
  }

  void _switchTab(int i) {
    if (i == _feed) return;
    setState(() {
      _feed = i;
      _settledPage = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: VistaSpace.gutter),
            child: AccountTopBar(onNotBuilt: widget.onNotBuilt),
          ),
          const SizedBox(height: VistaSpace.md),
          VistaSegmentedTabs(
            labels: const ['Following', 'For You'],
            selectedIndex: _feed,
            onChanged: _switchTab,
          ),
          const SizedBox(height: VistaSpace.md),
          Expanded(child: _feedView()),
        ],
      ),
    );
  }

  Widget _feedView() {
    final items = _feedItems;
    return items.isEmpty
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
              // A new pager per tab, and per change of follows on
              // Following, starting at its first card.
              key: ValueKey(_feed == 0 ? Scenario.followed.value : _feed),
              controller: _pages,
              scrollDirection: Axis.vertical,
              itemCount: items.length,
              itemBuilder: (context, i) {
                final item = items[i];
                if (item is Suggestion) {
                  return Center(
                    child: MakerSuggestionCard(
                      suggestion: item,
                      // The same first-time ticket an idea card opens.
                      onTrade: () => showFeedOrderTicket(
                        context,
                        symbol: item.asset,
                        side: item.direction,
                        onDetails: () =>
                            Navigator.of(context)
                                .push(AssetTradeScreen.route(item.asset)),
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
                  onDetails: () => Navigator.of(context).push(
                    idea.traderMarket
                        ? TraderMarketScreen.route(idea.ticker)
                        : AssetTradeScreen.route(idea.ticker),
                  ),
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
                    onDetails: () => Navigator.of(context).push(
                      idea.traderMarket
                          ? TraderMarketScreen.route(idea.ticker)
                          : AssetTradeScreen.route(idea.ticker),
                    ),
                  ),
                );
              },
            ),
          );
  }
}
