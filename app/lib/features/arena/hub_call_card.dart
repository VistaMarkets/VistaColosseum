import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../live/market_prices.dart';
import '../markets/markets_mock.dart';
import '../people/follow_state.dart';
import 'arena_mock.dart';
import 'take_card.dart';

/// An initial in a filled circle (a person until avatars come from the
/// backend).
class PersonInitial extends StatelessWidget {
  const PersonInitial(this.handle, {super.key, this.size = 22, this.ring});

  final String handle;
  final double size;
  final Color? ring;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: VistaColors.surfaceRaised,
      shape: BoxShape.circle,
      border: Border.all(
        color: ring ?? VistaColors.background,
        width: size > 30 ? 2.5 : 2,
      ),
    ),
    child: Text(
      handle.isEmpty ? '' : handle[0].toUpperCase(),
      style: VistaType.labelStrong.copyWith(
        fontSize: size * 0.4,
        color: VistaColors.textPrimary,
        height: 1,
      ),
    ),
  );
}

/// A call on the hub (Figma call · @maya.eth): the caller and record, their
/// market, the position and debate badges, the call, its live position, like
/// and Join. No replies yet.
class HubCallCard extends StatelessWidget {
  const HubCallCard({
    super.key,
    required this.take,
    required this.onCaller,
    required this.onMarket,
    required this.onPosition,
    required this.onJoin,
    this.onDebate,
  });

  final Take take;
  final VoidCallback onCaller;
  final VoidCallback onMarket;
  final VoidCallback onPosition;
  final VoidCallback onJoin;
  final VoidCallback? onDebate;

  @override
  Widget build(BuildContext context) {
    final t = take;
    final c = t.call;
    final record = t.accuracy.split(' ').first;
    final good = (int.tryParse(record.replaceAll('%', '')) ?? 0) >= 55;
    final muted = VistaType.bodyMedium.copyWith(color: VistaColors.textMuted);
    final market = MarketsMock.traders.where((m) => m.id == t.handle);
    return Container(
      padding: const EdgeInsets.fromLTRB(
        VistaSpace.gutter + VistaSpace.xs,
        VistaSpace.gutter,
        VistaSpace.gutter + VistaSpace.xs,
        VistaSpace.lg,
      ),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: VistaColors.hairline)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            button: true,
            label: "${t.handle}'s profile",
            excludeSemantics: true,
            child: GestureDetector(
              onTap: onCaller,
              child: PersonInitial(t.handle, size: 40, ring: t.side.color),
            ),
          ),
          const SizedBox(width: VistaSpace.xl),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: GestureDetector(
                        onTap: onCaller,
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(text: t.handle),
                              TextSpan(
                                text: '  $record right',
                                style: TextStyle(
                                  color: good
                                      ? VistaColors.long
                                      : VistaColors.textMuted,
                                ),
                              ),
                              TextSpan(text: ' · ${t.age}', style: muted),
                            ],
                          ),
                          style: VistaType.body.copyWith(fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: VistaSpace.sm),
                    FollowChip(handle: t.handle),
                  ],
                ),
                if (market.isNotEmpty)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onMarket,
                    child: Padding(
                      padding: const EdgeInsets.only(top: VistaSpace.xs),
                      child: ValueListenableBuilder(
                        valueListenable: MarketPrices.of(t.handle),
                        builder: (context, price, _) {
                          final ch = market.first.changePct;
                          return Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text:
                                      '${MarketsMock.traderCards[t.handle]?.symbol ?? t.handle} ',
                                  style: muted,
                                ),
                                TextSpan(
                                  text:
                                      '${MarketPrices.format(price, compact: true)} ',
                                ),
                                TextSpan(
                                  text:
                                      '${ch >= 0 ? '▲' : '▼'}${ch.abs().toStringAsFixed(1)}% ›',
                                  style: TextStyle(color: vistaChangeColor(ch)),
                                ),
                              ],
                            ),
                            style: VistaType.figures(VistaType.body),
                          );
                        },
                      ),
                    ),
                  ),
                const SizedBox(height: VistaSpace.sm),
                Wrap(
                  spacing: VistaSpace.sm,
                  runSpacing: VistaSpace.xs,
                  children: [
                    _Badge(
                      '${t.side.label.toUpperCase()} ${t.ticker}'
                      '${c == null ? '' : ' ${c.leverage}x'}',
                      t.side.color,
                    ),
                    if (t.battle != null)
                      GestureDetector(
                        onTap: onDebate,
                        child: _Badge('${t.battle!} ›', VistaColors.textMuted),
                      ),
                  ],
                ),
                const SizedBox(height: VistaSpace.sm),
                Text(
                  t.body,
                  style: VistaType.subheadMuted.copyWith(
                    fontWeight: FontWeight.w400,
                    color: VistaColors.textPrimary,
                    height: 21 / 15,
                  ),
                ),
                const SizedBox(height: VistaSpace.sm),
                if (c != null)
                  BackedPositionCard(
                    post: c,
                    ticker: t.ticker,
                    onTap: onPosition,
                  ),
                SizedBox(
                  height: VistaSize.tapTarget,
                  child: Row(
                    children: [
                      TakeAgreeButton(take: t),
                      const Spacer(),
                      VistaJoinPill(side: t.side, onTap: onJoin),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.label, this.color);

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: color == VistaColors.textMuted
          ? VistaColors.surfaceRaised
          : color.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(VistaRadius.sm),
    ),
    child: Text(label, style: VistaType.labelStrong.copyWith(color: color)),
  );
}
