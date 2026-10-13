import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../markets/markets_mock.dart';
import '../profile/profile_mock.dart';
import '../profile/receipts_screen.dart';
import 'arena_mock.dart';

/// A settled call or debate in the Arena feed, flush like a call.
///
/// A call shows whether it was right, entry to settle, its result, and the
/// caller's own market move as it settled ("MAYA ▲2.1% · Open market").
/// Tapping it opens the receipt. A debate shows which side was right and
/// opens its thread.
class SettlementItem extends StatelessWidget {
  const SettlementItem({
    super.key,
    required this.settlement,
    this.onCaller,
    this.onMarket,
    this.onDebate,
  });

  final Settlement settlement;
  final VoidCallback? onCaller;
  final VoidCallback? onMarket;
  final VoidCallback? onDebate;

  @override
  Widget build(BuildContext context) {
    final s = settlement;
    final debate = s.debate;
    final right = debate?.result?.longRight ?? s.right!;
    // A call is green when it was right; a debate by its winning side.
    final color = right ? VistaColors.long : VistaColors.short;
    final muted = VistaType.bodyMedium.copyWith(color: VistaColors.textMuted);

    final List<Widget> lines;
    final String semantics;
    final VoidCallback? onTap;
    if (debate != null) {
      final r = debate.result!;
      final share = r.longRight ? debate.longShare : 1 - debate.longShare;
      semantics =
          'Debate settled: ${debate.question}, '
          '${r.longRight ? 'long' : 'short'} side right';
      onTap = onDebate;
      lines = [
        Row(
          children: [
            Text('Debate settled', style: VistaType.subhead),
            const SizedBox(width: VistaSpace.sm),
            Text(
              '${r.longRight ? 'LONG' : 'SHORT'} SIDE RIGHT',
              style: VistaType.labelStrong.copyWith(color: color),
            ),
            const SizedBox(width: VistaSpace.sm),
            Expanded(
              child: Text(
                r.age,
                style: muted,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: VistaSpace.sm),
        Text(debate.question, style: _body),
        const SizedBox(height: VistaSpace.xs),
        Text(
          '${debate.ticker} settled at ${r.settledAt}   '
          '${(share * 100).round()}% of ${debate.takes} calls had it right',
          style: muted,
        ),
        _Link('Read the thread ›', onTap: onDebate),
      ];
    } else {
      final side = s.side!;
      final pnl = s.pnlPct!;
      semantics =
          "${s.handle}'s ${side.label} ${s.ticker} call settled "
          '${right ? 'right' : 'wrong'}';
      onTap = () => showReceiptSheet(context, _receipt(s));
      final symbol = MarketsMock.traderCards[s.handle]?.symbol;
      final move = s.marketMovePct!;
      lines = [
        Row(
          children: [
            Flexible(
              child: Text(
                s.handle!,
                style: VistaType.subhead,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: VistaSpace.sm),
            Text(
              right ? 'SETTLED RIGHT' : 'SETTLED WRONG',
              style: VistaType.labelStrong.copyWith(color: color),
            ),
            const SizedBox(width: VistaSpace.sm),
            Text(s.age, style: muted),
          ],
        ),
        const SizedBox(height: VistaSpace.sm),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '${side.label.toUpperCase()} ${s.ticker} ${s.leverage}x',
                style: TextStyle(color: side.color),
              ),
              TextSpan(
                text: '  ${s.entry} → ${s.close}  ',
                style: const TextStyle(color: VistaColors.textMuted),
              ),
              TextSpan(
                text: '${pnl >= 0 ? '+' : '−'}${pnl.abs().toStringAsFixed(1)}%',
                style: TextStyle(color: color),
              ),
            ],
          ),
          style: VistaType.figures(VistaType.bodyStrong),
        ),
        if (symbol != null)
          _Link(
            '$symbol ${move >= 0 ? '▲' : '▼'}${move.abs().toStringAsFixed(1)}%'
            ' as it settled   Open market ›',
            color: move >= 0 ? VistaColors.long : VistaColors.short,
            onTap: onMarket,
          ),
      ];
    }

    return Semantics(
      button: true,
      label: semantics,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            VistaSpace.gutter + VistaSpace.xs,
            VistaSpace.gutter,
            VistaSpace.gutter + VistaSpace.xs,
            VistaSpace.xs,
          ),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: VistaColors.hairline)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: debate == null ? onCaller : onDebate,
                child: Container(
                  width: VistaSize.avatarLarge,
                  height: VistaSize.avatarLarge,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 2),
                  ),
                  child: Icon(
                    right ? Icons.check_rounded : Icons.close_rounded,
                    size: 20,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(width: VistaSpace.xl),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: lines,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static ProfileReceipt _receipt(Settlement s) {
    final right = s.right!;
    final pnl = s.pnlPct!;
    return ProfileReceipt(
      kind: ReceiptKind.call,
      rail: right ? VistaAssets.railCallRight : VistaAssets.railArenaWrong,
      title:
          '${s.ticker} ${s.side!.label.toLowerCase()} ${s.leverage}x   '
          '${s.handle}',
      lead:
          '${right ? 'Right' : 'Wrong'}   '
          '${pnl >= 0 ? '+' : '−'}${pnl.abs().toStringAsFixed(1)}%',
      leadColor: right ? VistaColors.long : VistaColors.short,
      detail: right
          ? 'settled at take profit.'
          : 'stopped out before it could play out.',
      side: s.side!,
      entry: s.entry!,
      close: 'Settled ${s.close}',
    );
  }
}

final _body = VistaType.subheadMuted.copyWith(
  fontWeight: FontWeight.w400,
  color: VistaColors.textPrimary,
  height: 21 / 15,
);

/// A tappable line under a settlement, in a 44pt row.
class _Link extends StatelessWidget {
  const _Link(this.text, {this.color = VistaColors.accent, this.onTap});

  final String text;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        height: VistaSize.tapTarget,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            text,
            style: VistaType.figures(VistaType.body).copyWith(color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
