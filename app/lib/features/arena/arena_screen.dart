import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../account/account_top_bar.dart';
import '../settings/settings_state.dart';
import '../trade/order_ticket.dart';
import '../profile/profile_screen.dart';
import 'arena_mock.dart';
import 'opinions_screen.dart';

/// Arena tab (Figma 33:2): battles between a Bull and a Bear caller.
class ArenaScreen extends StatefulWidget {
  const ArenaScreen({super.key, this.onNotBuilt});

  /// Called with a feature name when a control leads somewhere not built yet.
  final ValueChanged<String>? onNotBuilt;

  @override
  State<ArenaScreen> createState() => _ArenaScreenState();
}

class _ArenaScreenState extends State<ArenaScreen> {
  /// Height the floating search takes above the nav (field plus margins).
  static const double _searchSpace = 50;

  int _sort = 0;

  void _notBuilt(String what) => widget.onNotBuilt?.call(what);

  @override
  Widget build(BuildContext context) {
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
              // Sort chips stay put while the battles scroll.
              // One row that scrolls sideways when the chips outrun the
              // screen.
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(
                  VistaSpace.gutter,
                  0,
                  VistaSpace.gutter,
                  VistaSpace.xs,
                ),
                child: Row(
                  children: [
                    for (var i = 0; i < ArenaMock.sorts.length; i++) ...[
                      if (i > 0) const SizedBox(width: VistaSpace.md),
                      VistaFilterChip(
                        label: ArenaMock.sorts[i],
                        accent: true,
                        selected: i == _sort,
                        onPressed: () => setState(() => _sort = i),
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  // Room to scroll the last item clear of the search and nav.
                  padding: EdgeInsets.only(
                    bottom: VistaSpace.gutter + _searchSpace + navSpace,
                  ),
                  children: [
                    for (final b in ArenaMock.battles)
                      Padding(
                        // A clear gap between battles so each reads as its own.
                        padding: const EdgeInsets.fromLTRB(
                          7,
                          0,
                          7,
                          VistaSpace.section,
                        ),
                        child: ValueListenableBuilder(
                          valueListenable: DisplayPrefs.longOnRight,
                          builder: (context, longOnRight, _) => VistaBattleCard(
                            longOnRight: longOnRight,
                            ticker: b.ticker,
                            price: b.price,
                            change: b.change,
                            timeLeft: b.timeLeft,
                            question: b.question,
                            bull: b.bull,
                            bear: b.bear,
                            moreOpinions: b.moreOpinions,
                            // Simulated only: joining a side places nothing.
                            // Bull is long the battle's market, Bear short.
                            onBull: () => showOrderTicket(
                              context,
                              symbol: b.ticker,
                              side: TradeSide.long,
                            ),
                            onBear: () => showOrderTicket(
                              context,
                              symbol: b.ticker,
                              side: TradeSide.short,
                            ),
                            onOpinions: () =>
                                Navigator.of(context)
                                    .push(OpinionsScreen.route()),
                            onCaller: (handle) =>
                                Navigator.of(context)
                                    .push(ProfileScreen.route(handle)),
                          ),
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
                hint: 'Ask about a market',
                onChanged: (_) {},
                onSubmitted: (_) => _notBuilt('Ask'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
