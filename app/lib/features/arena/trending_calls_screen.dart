import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../calls/calls_store.dart';
import '../home/home_feed.dart';
import '../market/trader_market_screen.dart';
import '../profile/profile_screen.dart';
import '../trade/caller_play_screen.dart';
import '../trade/order_ticket.dart';
import 'arena_mock.dart';
import 'debate_screen.dart';
import 'pick_position_screen.dart';
import 'settlement_item.dart';
import 'hub_call_card.dart';

/// Trending calls (Arena › Trending calls › See all): every call, nothing
/// else, in the hub's call cards, ordered Popular (the Home ranking) or
/// Recent, with settled calls mixed in as receipts. The + makes a call.
class TrendingCallsScreen extends StatefulWidget {
  const TrendingCallsScreen({super.key, this.onExplore});

  /// Switches to the Explore tab (from the + flow's empty state).
  final VoidCallback? onExplore;

  static Route<void> route({VoidCallback? onExplore}) => MaterialPageRoute(
    builder: (_) => TrendingCallsScreen(onExplore: onExplore),
  );

  @override
  State<TrendingCallsScreen> createState() => _TrendingCallsScreenState();
}

class _TrendingCallsScreenState extends State<TrendingCallsScreen> {
  /// Height the floating + button takes above the nav (button plus margins).
  static const double _composerSpace = 68;

  int _sort = 0; // ArenaMock.sorts

  void _push(Route<void> route) => Navigator.of(context).push(route);

  final _feedScroll = ScrollController();

  @override
  void dispose() {
    _feedScroll.dispose();
    super.dispose();
  }

  /// The + : pick the position to back the call, write it, post it. The
  /// new call leads the list, so it goes back to the top.
  Future<void> _newTake() async {
    final take = await Navigator.of(context)
        .push(PickPositionScreen.route(onExplore: widget.onExplore));
    if (take == null || !mounted) return;
    CallsStore.add(take);
    setState(() => _sort = 0);
    if (_feedScroll.hasClients) _feedScroll.jumpTo(0);
  }

  Widget _call(Take t) {
    final debate = Debates.of(t);
    return HubCallCard(
      take: t,
      onCaller: () => _push(ProfileScreen.route(t.handle)),
      onMarket: () => _push(TraderMarketScreen.route(t.handle)),
      onDebate: debate == null ? null : () => _push(DebateScreen.route(debate)),
      onPosition: () {
        if (t.call == null) return;
        _push(CallerPlayScreen.route(CallsStore.postOf(t), t.ticker));
      },
      // Simulated only: joining places nothing real.
      onJoin: () => showOrderTicket(context, symbol: t.ticker, side: t.side),
    );
  }

  /// Calls in the chosen order with settlements mixed in: by age for
  /// Recent; for Popular, one after every [_settlementEvery] calls, newest
  /// first.
  static const _settlementEvery = 3;

  List<Object> _feed(List<Take> calls, List<Settlement> settled) {
    if (_sort == 1) {
      final items = <(int, Object)>[
        for (final t in calls) (CallsStore.minutesAgo(t.age), t),
        for (final st in settled) (CallsStore.minutesAgo(st.when), st),
      ];
      mergeSort(items, compare: (a, b) => a.$1.compareTo(b.$1));
      return [for (final (_, x) in items) x];
    }
    final ranked = HomeFeed.forYou(calls);
    final out = <Object>[];
    var s = 0;
    for (final (i, t) in ranked.indexed) {
      out.add(t);
      if ((i + 1) % _settlementEvery == 0 && s < settled.length) {
        out.add(settled[s++]);
      }
    }
    out.addAll(settled.skip(s));
    return out;
  }

  @override
  Widget build(BuildContext context) {
    // The list runs to the bottom of the screen and scrolls under the
    // floating + button and nav, which sit over it with nothing behind them.
    final navSpace = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                // Back to the Arena hub.
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    VistaSpace.gutter,
                    VistaSpace.md,
                    VistaSpace.gutter,
                    0,
                  ),
                  child: Row(
                    children: [
                      VistaIconButton(
                        asset: VistaAssets.backSmall,
                        semanticLabel: 'Back',
                        iconSize: VistaSize.icon,
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                      const SizedBox(width: VistaSpace.xs),
                      Expanded(
                        child: Text('Trending calls', style: VistaType.title),
                      ),
                      _SortMenu(
                        sort: _sort,
                        onChanged: (i) => setState(() => _sort = i),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  // Every call, shared with the trade pages' Callers.
                  child: ValueListenableBuilder(
                    valueListenable: CallsStore.all,
                    builder: (context, takes, _) {
                      final items = _feed(takes, ArenaMock.settlements);
                      return ListView(
                        controller: _feedScroll,
                        // Room to scroll the last call clear of the + button.
                        padding: EdgeInsets.only(
                          bottom: VistaSpace.gutter + _composerSpace + navSpace,
                        ),
                        children: [
                          if (items.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(VistaSpace.section),
                              child: Text(
                                'No calls here yet.',
                                textAlign: TextAlign.center,
                                style: VistaType.body.copyWith(
                                  color: VistaColors.textMuted,
                                ),
                              ),
                            ),
                          for (final item in items)
                            if (item is Settlement)
                              SettlementItem(
                                settlement: item,
                                onCaller: item.handle == null
                                    ? null
                                    : () => _push(
                                        ProfileScreen.route(item.handle!),
                                      ),
                                onMarket: item.handle == null
                                    ? null
                                    : () => _push(
                                        TraderMarketScreen.route(item.handle!),
                                      ),
                                onDebate: item.debate == null
                                    ? null
                                    : () => _push(
                                        DebateScreen.route(item.debate!),
                                      ),
                              )
                            else if (item is Take)
                              _call(item),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
            // The + floats in the lower right, just above the nav.
            Positioned(
              right: VistaSpace.gutter,
              bottom: navSpace + VistaSpace.md,
              child: _AddTakeButton(onTap: _newTake),
            ),
          ],
        ),
      ),
    );
  }
}

/// The floating + in the lower right: starts a take by picking a position.
class _AddTakeButton extends StatelessWidget {
  const _AddTakeButton({required this.onTap});

  static const double size = 56;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Make a call',
      excludeSemantics: true,
      child: VistaPressable(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: VistaColors.accent,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0x59000000),
                offset: Offset(0, 6),
                blurRadius: 18,
              ),
            ],
          ),
          child: Text(
            '+',
            style: VistaType.displayMedium.copyWith(
              color: VistaColors.onAccent,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

/// The room's market at the top of its feed: name, live price and change,

/// "Popular ▾" by the Calls heading: picks how the calls are ordered.
class _SortMenu extends StatelessWidget {
  const _SortMenu({required this.sort, required this.onChanged});

  final int sort;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      tooltip: '',
      initialValue: sort,
      color: VistaColors.surfaceRaised,
      onSelected: onChanged,
      position: PopupMenuPosition.under,
      itemBuilder: (_) => [
        for (var i = 0; i < ArenaMock.sorts.length; i++)
          PopupMenuItem(
            value: i,
            child: Text(
              ArenaMock.sorts[i],
              style: VistaType.subhead.copyWith(
                color: i == sort ? VistaColors.accent : VistaColors.textPrimary,
              ),
            ),
          ),
      ],
      child: Semantics(
        button: true,
        label: 'Sort calls: ${ArenaMock.sorts[sort]}',
        excludeSemantics: true,
        child: SizedBox(
          height: VistaSize.tapTarget,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  ArenaMock.sorts[sort],
                  style: VistaType.bodyMedium.copyWith(
                    color: VistaColors.textMuted,
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: VistaColors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
