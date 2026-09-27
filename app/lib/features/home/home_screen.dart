import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../account/account_top_bar.dart';
import '../profile/profile_screen.dart';
import '../trade/asset_trade_screen.dart';
import 'mock_trade_idea.dart';
import 'trade_idea_card.dart';

/// Home feed (Figma 301:102, "Home · header A — caller first, aligned").
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.visible = true, this.onNotBuilt});

  /// Whether the Home tab is showing; card animations only run while it is.
  final bool visible;

  /// Called with a feature name when a control leads somewhere not built yet.
  final ValueChanged<String>? onNotBuilt;

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

  bool _onScrollEnd(ScrollEndNotification n) {
    final page = _pages.page?.round() ?? 0;
    if (page != _settledPage) setState(() => _settledPage = page);
    return false;
  }

  void _notBuilt(String what) => widget.onNotBuilt?.call(what);

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
            onChanged: (i) => setState(() => _feed = i),
          ),
          const SizedBox(height: VistaSpace.md),
          Expanded(
            child: NotificationListener<ScrollEndNotification>(
              onNotification: _onScrollEnd,
              child: PageView.builder(
                controller: _pages,
                scrollDirection: Axis.vertical,
                itemCount: mockFeed.length,
                itemBuilder: (context, i) => TradeIdeaCard(
                  idea: mockFeed[i],
                  active: widget.visible && i == _settledPage,
                  onDetails: () =>
                      Navigator.of(context)
                          .push(AssetTradeScreen.route(mockFeed[i].ticker)),
                  onCaller: () =>
                      Navigator.of(context)
                          .push(ProfileScreen.route(mockFeed[i].callerHandle)),
                  // Simulated only: the demo never places an order.
                  onTrade: () => _notBuilt('Order flow (simulated)'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
