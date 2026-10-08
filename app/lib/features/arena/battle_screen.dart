import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../calls/calls_store.dart';
import '../live/market_prices.dart';
import '../market/trader_market_screen.dart';
import '../people/follow_state.dart';
import '../portfolio/portfolio_mock.dart';
import '../profile/profile_screen.dart';
import '../settings/settings_state.dart';
import '../trade/caller_play_screen.dart';
import '../trade/order_ticket.dart';
import 'arena_mock.dart';
import 'hub_call_card.dart';
import 'pick_position_screen.dart';

/// A live battle (Figma 599:222), opened from a Live battles card: about
/// the people in it. The question and time left, the most right callers
/// in it to follow (with their side), then every call (All / Long /
/// Short) as call cards, and Join longs / Join shorts, which make your
/// case from a position like Argue does.
class BattleScreen extends StatefulWidget {
  const BattleScreen({super.key, required this.battle});

  final LiveBattle battle;

  static Route<void> route(LiveBattle battle) =>
      MaterialPageRoute(builder: (_) => BattleScreen(battle: battle));

  @override
  State<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends State<BattleScreen> {
  int _filter = 0; // 0 All, 1 Long, 2 Short

  void _push(Route<void> route) => Navigator.of(context).push(route);

  /// Join a side: pick (or open) a position on it, write the call with the
  /// battle attached. It joins (moving the split) and lands here first.
  Future<void> _join(LiveBattle b, TradeSide side) async {
    final take = await Navigator.of(context)
        .push(PickPositionScreen.route(debate: b, side: side));
    if (take == null || !mounted) return;
    CallsStore.add(take);
    setState(() => _filter = 0);
  }

  static int _pct(Take t) => int.tryParse(t.accuracy.split('%').first) ?? 0;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: BattlesStore.all,
      builder: (context, all, _) => ValueListenableBuilder(
        valueListenable: CallsStore.all,
        builder: (context, calls, _) => _page(
          all.where((x) => x.id == widget.battle.id).firstOrNull ??
              widget.battle,
          calls,
        ),
      ),
    );
  }

  Widget _page(LiveBattle b, List<Take> calls) {
    final on = Debates.callsOn(b, calls);
    final longs = (b.takes * b.longShare).round();
    // One row per person, best record first.
    final seen = <String>{};
    final mostRight = [
      for (final t in [...on]..sort((x, y) => _pct(y).compareTo(_pct(x))))
        if (seen.add(t.handle)) t,
    ].take(3).toList();
    final thread = [
      for (final t in on)
        if (switch (_filter) {
          1 => t.side == TradeSide.long,
          2 => t.side == TradeSide.short,
          _ => true,
        })
          t,
    ];
    const side = VistaSpace.gutter + VistaSpace.xs;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: VistaSpace.gutter),
                children: [
                  _Header(battle: b),
                  if (mostRight.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        side,
                        VistaSpace.section,
                        side,
                        VistaSpace.xs,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Most right in this battle',
                              style: VistaType.title.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            'who to follow',
                            style: VistaType.meta.copyWith(
                              color: VistaColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    for (final t in mostRight)
                      _MostRightRow(
                        take: t,
                        calls: calls,
                        onTap: () => _push(ProfileScreen.route(t.handle)),
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        side,
                        VistaSpace.sm,
                        side,
                        0,
                      ),
                      child: Text(
                        'By % right on settled calls. Their call in this '
                        'battle is below.',
                        style: VistaType.caption.copyWith(
                          color: VistaColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      side,
                      VistaSpace.xxl,
                      side,
                      VistaSpace.xs,
                    ),
                    child: Wrap(
                      spacing: VistaSpace.md,
                      children: [
                        for (final (i, label) in [
                          'All ${b.takes}',
                          'Long $longs',
                          'Short ${b.takes - longs}',
                        ].indexed)
                          VistaFilterChip(
                            label: label,
                            accent: true,
                            selected: i == _filter,
                            onPressed: () => setState(() => _filter = i),
                          ),
                      ],
                    ),
                  ),
                  if (thread.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(VistaSpace.section),
                      child: Text(
                        'No case made for this side yet. Make the first one.',
                        textAlign: TextAlign.center,
                        style: VistaType.body.copyWith(
                          color: VistaColors.textMuted,
                        ),
                      ),
                    ),
                  for (final t in thread)
                    HubCallCard(
                      take: t,
                      showDebate: false,
                      onCaller: () => _push(ProfileScreen.route(t.handle)),
                      onMarket: () => _push(TraderMarketScreen.route(t.handle)),
                      onPosition: () => _push(
                        CallerPlayScreen.route(CallsStore.postOf(t), t.ticker),
                      ),
                      // Simulated only: joining places nothing real.
                      onJoin: () => showOrderTicket(
                        context,
                        symbol: t.ticker,
                        side: t.side,
                      ),
                    ),
                ],
              ),
            ),
            _JoinDock(onJoin: (s) => _join(b, s)),
          ],
        ),
      ),
    );
  }
}

/// Back, the question, and the market price · time left (urgent in red).
class _Header extends StatelessWidget {
  const _Header({required this.battle});

  final LiveBattle battle;

  @override
  Widget build(BuildContext context) {
    final b = battle;
    final muted = VistaType.bodyMedium.copyWith(color: VistaColors.textMuted);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        VistaSpace.gutter,
        VistaSpace.md,
        VistaSpace.gutter + VistaSpace.xs,
        0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VistaIconButton(
            asset: VistaAssets.backSmall,
            semanticLabel: 'Back',
            iconSize: VistaSize.icon,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: VistaSpace.md),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: VistaSpace.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    b.question,
                    style: VistaType.title.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: VistaSpace.xs),
                  ValueListenableBuilder(
                    valueListenable: MarketPrices.of(b.ticker),
                    builder: (context, price, _) => Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text:
                                '${b.ticker} '
                                '${MarketPrices.format(price, compact: true)}'
                                ' · ',
                          ),
                          TextSpan(
                            text: b.timeLeft,
                            style: const TextStyle(color: VistaColors.short),
                          ),
                        ],
                      ),
                      style: muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One of the most right in the battle: who and their record, how many
/// calls they've made on this market, their side here, and Follow.
class _MostRightRow extends StatelessWidget {
  const _MostRightRow({
    required this.take,
    required this.calls,
    required this.onTap,
  });

  final Take take;
  final List<Take> calls;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = take;
    final mine = t.handle == PortfolioMock.handle;
    final count = calls
        .where((x) => x.handle == t.handle && x.ticker == t.ticker)
        .length;
    final lev = t.call?.leverage;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: VistaSpace.gutter + VistaSpace.xs,
          vertical: VistaSpace.lg,
        ),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: VistaColors.hairline)),
        ),
        child: Row(
          children: [
            PersonInitial(t.handle, size: 40, ring: t.side.color),
            const SizedBox(width: VistaSpace.xl),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: t.handle,
                          style: const TextStyle(
                            color: VistaColors.textPrimary,
                          ),
                        ),
                        TextSpan(
                          text: '  ${t.accuracy}',
                          style: const TextStyle(color: VistaColors.long),
                        ),
                        TextSpan(
                          text:
                              ' · $count ${t.ticker} call'
                              '${count == 1 ? '' : 's'}',
                        ),
                      ],
                    ),
                    style: VistaType.body.copyWith(
                      fontSize: 14,
                      color: VistaColors.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: VistaSpace.xxs),
                  Text(
                    '${t.side.label.toUpperCase()}'
                    '${lev == null ? '' : ' ${lev}x'}',
                    style: VistaType.labelStrong.copyWith(color: t.side.color),
                  ),
                ],
              ),
            ),
            if (!mine) ...[
              const SizedBox(width: VistaSpace.md),
              ValueListenableBuilder(
                valueListenable: FollowState.following,
                builder: (context, following, _) => VistaFollowButton(
                  following: following.contains(t.handle),
                  onPressed: () => FollowState.toggle(t.handle),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Join longs / Join shorts: make your case on a side (from a position).
class _JoinDock extends StatelessWidget {
  const _JoinDock({required this.onJoin});

  final ValueChanged<TradeSide> onJoin;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(
        VistaSpace.gutter,
        VistaSpace.lg,
        VistaSpace.gutter,
        bottom > 0 ? bottom : VistaSpace.gutter,
      ),
      decoration: const BoxDecoration(
        color: VistaColors.background,
        border: Border(top: BorderSide(color: VistaColors.hairline)),
      ),
      child: ValueListenableBuilder(
        valueListenable: DisplayPrefs.longOnRight,
        builder: (context, longOnRight, _) => VistaSidePair(
          longOnRight: longOnRight,
          gap: VistaSpace.md,
          long: VistaPillButton(
            label: 'Join longs',
            variant: VistaPillVariant.long,
            onPressed: () => onJoin(TradeSide.long),
          ),
          short: VistaPillButton(
            label: 'Join shorts',
            variant: VistaPillVariant.short,
            onPressed: () => onJoin(TradeSide.short),
          ),
        ),
      ),
    );
  }
}
