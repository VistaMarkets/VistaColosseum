import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../calls/calls_store.dart';
import '../live/market_prices.dart';
import '../market/trader_market_screen.dart';
import '../profile/profile_screen.dart';
import '../settings/settings_state.dart';
import '../trade/caller_play_screen.dart';
import '../trade/order_ticket.dart';
import 'arena_mock.dart';
import 'pick_position_screen.dart';
import 'take_card.dart';

/// A debate as a thread: the question, its live split and time left (or
/// how it settled), then every call on it. Argue long / short makes your
/// case as a call: pick (or open) a position on that side, write it, and it
/// joins the debate, moves the split and shows here, in the Arena feed and
/// on Home. Every call stands on a position.
class DebateScreen extends StatefulWidget {
  const DebateScreen({super.key, required this.debate});

  final LiveBattle debate;

  static Route<void> route(LiveBattle debate) =>
      MaterialPageRoute(builder: (_) => DebateScreen(debate: debate));

  @override
  State<DebateScreen> createState() => _DebateScreenState();
}

class _DebateScreenState extends State<DebateScreen> {
  int _filter = 0; // 0 All, 1 Long, 2 Short

  static const _filters = ['All', 'Long', 'Short'];

  void _push(Route<void> route) => Navigator.of(context).push(route);

  /// Argue a side: pick (or open) a position on it, write the call with
  /// the debate attached. It joins the debate (moving the split) and lands
  /// in every call feed.
  Future<void> _argue(LiveBattle b, TradeSide side) async {
    final take = await Navigator.of(context)
        .push(PickPositionScreen.route(debate: b, side: side));
    if (take == null || !mounted) return;
    CallsStore.add(take);
    setState(() => _filter = 0);
  }

  @override
  Widget build(BuildContext context) {
    // The live debate, so a call joining it moves the split here.
    return ValueListenableBuilder(
      valueListenable: BattlesStore.all,
      builder: (context, all, _) => _page(
        all.where((x) => x.id == widget.debate.id).firstOrNull ?? widget.debate,
      ),
    );
  }

  Widget _page(LiveBattle b) {
    final long = (b.longShare * 100).round();
    final result = b.result;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                VistaSpace.gutter,
                VistaSpace.md,
                VistaSpace.gutter,
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
                          Text(b.question, style: VistaType.headline),
                          const SizedBox(height: VistaSpace.xs),
                          ValueListenableBuilder(
                            valueListenable: MarketPrices.of(b.ticker),
                            builder: (context, price, _) => Text(
                              '${b.ticker} '
                              '${MarketPrices.format(price, compact: true)} · '
                              '${b.timeLeft}',
                              style: VistaType.bodyMedium.copyWith(
                                color: VistaColors.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                VistaSpace.gutter + VistaSpace.xs,
                VistaSpace.lg,
                VistaSpace.gutter + VistaSpace.xs,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Text(
                        '$long% long',
                        style: VistaType.labelStrong.copyWith(
                          color: VistaColors.long,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '${b.takes} calls',
                          textAlign: TextAlign.center,
                          style: VistaType.caption.copyWith(
                            color: VistaColors.textMuted,
                          ),
                        ),
                      ),
                      Text(
                        '${100 - long}% short',
                        style: VistaType.labelStrong.copyWith(
                          color: VistaColors.short,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: VistaSpace.sm),
                  VistaSplitBar(leftFraction: b.longShare, height: 6),
                  if (result != null) ...[
                    const SizedBox(height: VistaSpace.lg),
                    _SettledBanner(debate: b, result: result),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                VistaSpace.gutter,
                VistaSpace.lg,
                VistaSpace.gutter,
                0,
              ),
              child: Wrap(
                spacing: VistaSpace.md,
                children: [
                  for (var i = 0; i < _filters.length; i++)
                    VistaFilterChip(
                      label: _filters[i],
                      accent: true,
                      selected: i == _filter,
                      onPressed: () => setState(() => _filter = i),
                    ),
                ],
              ),
            ),
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: CallsStore.all,
                builder: (context, calls, _) {
                  final thread = [
                    for (final t in Debates.callsOn(b, calls))
                      if (switch (_filter) {
                        1 => t.side == TradeSide.long,
                        2 => t.side == TradeSide.short,
                        _ => true,
                      })
                        t,
                  ];
                  if (thread.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(VistaSpace.section),
                      child: Text(
                        b.settled ? 'No calls on this side.' : 'No case made for this side yet. Make the first one.',
                        textAlign: TextAlign.center,
                        style: VistaType.body.copyWith(
                          color: VistaColors.textMuted,
                        ),
                      ),
                    );
                  }
                  return ListView(
                    padding: const EdgeInsets.only(bottom: VistaSpace.gutter),
                    children: [
                      for (final t in thread)
                        TakeItem(
                          take: t,
                          onCaller: () => _push(ProfileScreen.route(t.handle)),
                          onMarket: () =>
                              _push(TraderMarketScreen.route(t.handle)),
                          onCall: t.call == null
                              ? null
                              : () => _push(
                                  CallerPlayScreen.route(
                                    CallsStore.postOf(t),
                                    t.ticker,
                                  ),
                                ),
                          // Simulated only: joining places nothing real.
                          onJoin: b.settled
                              ? null
                              : () => showOrderTicket(
                                  context,
                                  symbol: t.ticker,
                                  side: t.side,
                                ),
                        ),
                    ],
                  );
                },
              ),
            ),
            if (!b.settled) _ArgueDock(onArgue: (side) => _argue(b, side)),
          ],
        ),
      ),
    );
  }
}

/// How a settled debate ended, above its thread.
class _SettledBanner extends StatelessWidget {
  const _SettledBanner({required this.debate, required this.result});

  final LiveBattle debate;
  final DebateResult result;

  @override
  Widget build(BuildContext context) {
    final color = result.longRight ? VistaColors.long : VistaColors.short;
    final share = result.longRight ? debate.longShare : 1 - debate.longShare;
    return Container(
      padding: const EdgeInsets.all(VistaSpace.xl),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(VistaRadius.md * 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SETTLED · ${result.longRight ? 'LONG' : 'SHORT'} SIDE RIGHT',
            style: VistaType.labelStrong.copyWith(color: color),
          ),
          const SizedBox(height: VistaSpace.xs),
          Text(
            '${debate.ticker} settled at ${result.settledAt} · '
            '${(share * 100).round()}% of ${debate.takes} calls had it right · '
            '${result.age} ago',
            style: VistaType.bodyMedium.copyWith(
              color: VistaColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Argue long / Argue short, under the thread of a live debate.
class _ArgueDock extends StatelessWidget {
  const _ArgueDock({required this.onArgue});

  final ValueChanged<TradeSide> onArgue;

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
            label: 'Argue long',
            variant: VistaPillVariant.long,
            onPressed: () => onArgue(TradeSide.long),
          ),
          short: VistaPillButton(
            label: 'Argue short',
            variant: VistaPillVariant.short,
            onPressed: () => onArgue(TradeSide.short),
          ),
        ),
      ),
    );
  }
}
