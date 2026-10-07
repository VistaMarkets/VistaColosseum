import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../calls/calls_store.dart';
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
/// / replies / counters / Join, then the top reply.
class HubCallCard extends StatelessWidget {
  const HubCallCard({
    super.key,
    required this.take,
    required this.onCaller,
    required this.onMarket,
    required this.onPosition,
    required this.onJoin,
    required this.onReplies,
    this.onDebate,
    this.showReply = true,
  });

  /// The top reply and "View all replies" under the call (the hub); a
  /// room's list leaves them out.
  final bool showReply;

  final Take take;
  final VoidCallback onCaller;
  final VoidCallback onMarket;
  final VoidCallback onPosition;
  final VoidCallback onJoin;
  final VoidCallback onReplies;
  final VoidCallback? onDebate;

  @override
  Widget build(BuildContext context) {
    final t = take;
    final c = t.call;
    final thread = ArenaMock.threadOf(t);
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
                      // Gives way (shrinks a little) before the Join pill.
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              children: [
                                TakeAgreeButton(take: t),
                                if (thread != null) ...[
                                  const SizedBox(width: VistaSpace.md),
                                  _Count(
                                    Icons.chat_bubble_outline_rounded,
                                    thread.replies,
                                  ),
                                  const SizedBox(width: VistaSpace.lg),
                                  _Count(
                                    Icons.swap_horiz_rounded,
                                    thread.counters,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: VistaSpace.sm),
                      VistaJoinPill(side: t.side, onTap: onJoin),
                    ],
                  ),
                ),
                if (showReply && thread?.top != null)
                  _TopReply(reply: thread!.top!),
                if (showReply && thread != null && thread.replies > 0)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onReplies,
                    child: SizedBox(
                      height: 36,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'View all ${thread.replies} replies ›',
                          style: VistaType.body.copyWith(
                            color: VistaColors.accent,
                          ),
                        ),
                      ),
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

class _Count extends StatelessWidget {
  const _Count(this.icon, this.count);

  final IconData icon;
  final int count;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 18, color: VistaColors.textMuted),
      const SizedBox(width: 5),
      Text(
        '$count',
        style: VistaType.bodyMedium.copyWith(color: VistaColors.textMuted),
      ),
    ],
  );
}

/// The top reply under a call: who, their record and badge, what they said.
class _TopReply extends StatelessWidget {
  const _TopReply({required this.reply});

  final Reply reply;

  @override
  Widget build(BuildContext context) {
    final r = reply;
    final counter = r.counter;
    final side = counter == null
        ? null
        : (counter.startsWith('LONG') ? VistaColors.long : VistaColors.short);
    final record = CallsStore.recordOf(r.handle)?.split(' ').first;
    return Padding(
      padding: const EdgeInsets.only(top: VistaSpace.xxs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PersonInitial(
            r.handle,
            size: 26,
            ring: side ?? VistaColors.surfaceRaised,
          ),
          const SizedBox(width: VistaSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: r.handle),
                            if (record != null)
                              TextSpan(
                                text: '  $record right',
                                style: const TextStyle(color: VistaColors.long),
                              ),
                          ],
                        ),
                        style: VistaType.body,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: VistaSpace.sm),
                    _Badge(
                      counter == null ? 'No position' : 'COUNTER · $counter',
                      side ?? VistaColors.textMuted,
                    ),
                  ],
                ),
                const SizedBox(height: VistaSpace.xs),
                Text(
                  r.body,
                  style: VistaType.rowRegular.copyWith(
                    color: VistaColors.textPrimary,
                    height: 19 / 14,
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
