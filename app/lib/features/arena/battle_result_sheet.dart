import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../design_system/design_system.dart';
import '../calls/calls_store.dart';
import '../live/market_prices.dart';
import '../notifications/notifications_screen.dart';
import '../trade/order_filled_sheet.dart';
import 'arena_mock.dart';
import 'battle_screen.dart';

/// Settles any battle whose time is up. For the ones you were in, adds a
/// notification and shows the result: the order-filled burst when you won,
/// a plain sheet when you lost. Simulated; nothing is sent.
Future<void> settleBattles(BuildContext context) async {
  final navigator = Navigator.of(context);
  for (final b in BattlesStore.settleDue()) {
    final side = BattlesStore.yourSide(b);
    if (side == null) continue;
    final won = (side == TradeSide.long) == b.result!.longRight;
    Notifications.add(
      Note(
        kind: NoteKind.calls,
        lead: won ? 'You won' : 'You lost',
        rest: ' ${b.label}',
        detail: '${b.ticker} settled at ${b.result!.settledAt}',
        detailColor: won ? VistaColors.long : VistaColors.short,
        age: 'now',
        open: () => BattleScreen.route(b),
      ),
    );
    if (!navigator.mounted) return;
    HapticFeedback.heavyImpact();
    await showVistaSheet<void>(
      navigator.context,
      color: VistaColors.background,
      builder: (_) => BattleResultSheet(battle: b, side: side, won: won),
    );
  }
}

/// How a battle you were in ended (Figma D1, "You won the debate"): the
/// burst when you won, the statement, where it settled, your side, the
/// final split; Done, or See the battle.
class BattleResultSheet extends StatelessWidget {
  const BattleResultSheet({
    super.key,
    required this.battle,
    required this.side,
    required this.won,
  });

  final LiveBattle battle;
  final TradeSide side;
  final bool won;

  @override
  Widget build(BuildContext context) {
    final b = battle;
    final long = (b.longShare * 100).round();
    final label = VistaType.body.copyWith(color: VistaColors.textMuted);
    final value = VistaType.figures(VistaType.subheadMuted)
        .copyWith(fontWeight: FontWeight.w400, color: VistaColors.textPrimary);
    Widget row(String name, String v, {Color? color}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: VistaSpace.lg),
      child: Row(
        children: [
          Expanded(child: Text(name, style: label)),
          Text(v, style: value.copyWith(color: color)),
        ],
      ),
    );
    const line = Divider(height: 1, thickness: 1, color: VistaColors.hairline);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final navigator = Navigator.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        VistaSpace.gutter,
        VistaSpace.section + VistaSpace.gutter,
        VistaSpace.gutter,
        bottom > 0 ? bottom : VistaSpace.gutter,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (won) const Center(child: FillBurst(width: 180)),
          const SizedBox(height: VistaSpace.md),
          Text(
            won ? 'You won the battle' : 'You lost the battle',
            textAlign: TextAlign.center,
            style: VistaType.displaySmall,
          ),
          const SizedBox(height: VistaSpace.xs),
          Text(
            b.label,
            textAlign: TextAlign.center,
            style: VistaType.subhead.copyWith(
              color: won ? VistaColors.long : VistaColors.textMuted,
            ),
          ),
          const SizedBox(height: VistaSpace.md),
          row('${b.ticker} settled at', b.result!.settledAt),
          line,
          row('You were', side.label.toUpperCase(), color: side.color),
          line,
          row('Final split', '$long% long   ${b.takes} calls'),
          line,
          row(
            'Your record',
            won ? '+1 right' : '+1 wrong',
            color: won ? VistaColors.long : VistaColors.short,
          ),
          const SizedBox(height: VistaSpace.lg),
          Row(
            children: [
              Expanded(
                child: VistaPillButton(
                  label: 'Done',
                  onPressed: () => navigator.pop(),
                ),
              ),
              const SizedBox(width: VistaSpace.md),
              Expanded(
                child: VistaPillButton(
                  label: 'See the battle',
                  variant: VistaPillVariant.accent,
                  foreground: VistaColors.onAccent,
                  onPressed: () {
                    navigator.pop();
                    navigator.push(BattleScreen.route(b));
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: VistaSpace.md),
          ValueListenableBuilder(
            valueListenable: MarketPrices.of(b.ticker),
            builder: (context, price, _) => Text(
              'Settled from the ${b.ticker} price   simulated',
              textAlign: TextAlign.center,
              style: VistaType.caption.copyWith(color: VistaColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}
