import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../design_system/design_system.dart';
import '../live/live_feed.dart';
import '../live/market_prices.dart';
import '../trade/trade_mock.dart';
import '../markets/markets_mock.dart';
import 'arena_mock.dart';

/// Arena pieces from Figma 505:204 ("Arena — takes feed"): the live battle
/// tiles in the carousel and the flush, X-style take rows under them.

/// Body text of a take: 15pt regular on a 21pt line.
final _takeBody = VistaType.subheadMuted.copyWith(
  fontWeight: FontWeight.w400,
  color: VistaColors.textPrimary,
  height: 21 / 15,
);

/// Takes the viewer agreed with, by take id. In memory only.
abstract final class TakeLikes {
  static final liked = ValueNotifier<Set<String>>(const {});

  static void toggle(String id) {
    final on = !liked.value.contains(id);
    liked.value = on
        ? Set.unmodifiable({...liked.value, id})
        : Set.unmodifiable(liked.value.where((h) => h != id));
  }

  static void reset() => liked.value = const {};
}

/// A section heading in the Arena list: "Live battles  See all".
class ArenaSectionHead extends StatelessWidget {
  const ArenaSectionHead({
    super.key,
    required this.title,
    required this.trailing,
    this.top = VistaSpace.section,
    this.bottom = VistaSpace.xs,
  });

  final String title;
  final Widget trailing;
  final double top;
  final double bottom;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        VistaSpace.gutter + VistaSpace.xs,
        top,
        VistaSpace.gutter + VistaSpace.xs,
        bottom,
      ),
      child: Row(
        children: [
          Expanded(child: Text(title, style: VistaType.tab)),
          trailing,
        ],
      ),
    );
  }
}

/// A live battle in the carousel: market and live price, the question, the
/// long/short split and how many takes it has.
class BattleTile extends StatelessWidget {
  const BattleTile({super.key, required this.battle, this.onTap})
    : flush = false;

  /// The same battle as a full-width row with a hairline under it, for the
  /// Live battles page.
  const BattleTile.row({super.key, required this.battle, this.onTap})
    : flush = true;

  static const double width = 244;

  final LiveBattle battle;
  final VoidCallback? onTap;
  final bool flush;

  @override
  Widget build(BuildContext context) {
    final b = battle;
    final long = (b.longShare * 100).round();
    return Semantics(
      button: true,
      label: '${b.ticker} debate: ${b.question}, $long% long, ${b.timeLeft}',
      excludeSemantics: true,
      child: VistaPressable(
        scale: 0.98,
        onTap: onTap,
        child: Container(
          width: flush ? double.infinity : width,
          padding: flush
              ? const EdgeInsets.symmetric(
                  horizontal: VistaSpace.gutter + VistaSpace.xs,
                  vertical: VistaSpace.gutter,
                )
              : const EdgeInsets.all(VistaSpace.xxl),
          decoration: flush
              ? const BoxDecoration(
                  color: VistaColors.background,
                  border: Border(
                    bottom: BorderSide(color: VistaColors.hairline),
                  ),
                )
              : BoxDecoration(
                  color: VistaColors.surface,
                  borderRadius: BorderRadius.circular(VistaRadius.card),
                ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    b.ticker,
                    style: VistaType.subhead.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: VistaSpace.sm),
                  ValueListenableBuilder(
                    valueListenable: MarketPrices.of(b.ticker),
                    builder: (context, price, _) => Text(
                      MarketPrices.format(price, compact: true),
                      style: VistaType.figures(VistaType.subhead),
                    ),
                  ),
                  const SizedBox(width: VistaSpace.sm),
                  Expanded(
                    child: Text(
                      b.change,
                      style: VistaType.figures(VistaType.body).copyWith(
                        color: b.change.startsWith('+')
                            ? VistaColors.long
                            : VistaColors.short,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: VistaSpace.md,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: VistaColors.surfaceRaised,
                      borderRadius: BorderRadius.circular(VistaRadius.pill),
                    ),
                    child: Text(b.timeLeft, style: VistaType.chip),
                  ),
                ],
              ),
              const SizedBox(height: VistaSpace.lg),
              Text(
                b.question,
                style: flush ? VistaType.tab : VistaType.subhead,
                maxLines: flush ? 3 : 2,
                overflow: TextOverflow.ellipsis,
              ),
              // Tiles in the carousel share a height; push the bar down.
              if (!flush) const Spacer(),
              const SizedBox(height: VistaSpace.lg),
              VistaSplitBar(leftFraction: b.longShare, height: 6),
              const SizedBox(height: VistaSpace.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$long% long',
                    style: VistaType.chip.copyWith(color: VistaColors.long),
                  ),
                  Text(
                    '${b.takes} ${b.takes == 1 ? 'call' : 'calls'}',
                    style: VistaType.chip.copyWith(
                      fontWeight: FontWeight.w500,
                      color: VistaColors.textMuted,
                    ),
                  ),
                  Text(
                    '${100 - long}% short',
                    style: VistaType.chip.copyWith(color: VistaColors.short),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One take in the feed, flush with a hairline under it: avatar ringed in
/// the side's colour, handle, side and asset ("LONG BTC"), record; the battle it's on (a plain
/// call has none); the text; the position behind it when backed;
/// then agree, joined and Join.
class TakeItem extends StatelessWidget {
  const TakeItem({
    super.key,
    required this.take,
    this.onCaller,
    this.onMarket,
    this.onBattle,
    this.onCall,
    this.onJoin,
  });

  final Take take;
  final VoidCallback? onCaller;

  /// Opens the caller's market (when they have one).
  final VoidCallback? onMarket;

  /// Opens the battle the take is on.
  final VoidCallback? onBattle;

  /// Opens the play behind a backed take.
  final VoidCallback? onCall;
  final VoidCallback? onJoin;

  @override
  Widget build(BuildContext context) {
    final t = take;
    final color = t.side.color;
    return Container(
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
          Semantics(
            button: true,
            label: "${t.handle}'s profile",
            excludeSemantics: true,
            // Looks like a profile (their initial until avatars come from
            // the backend) and presses like a button.
            child: VistaPressable(
              scale: 0.9,
              onTap: onCaller,
              child: Container(
                width: VistaSize.avatarLarge,
                height: VistaSize.avatarLarge,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: VistaColors.surfaceRaised,
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2),
                ),
                child: Text(
                  t.handle.isEmpty ? '' : t.handle[0].toUpperCase(),
                  style: VistaType.subhead.copyWith(height: 1),
                ),
              ),
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
                      child: Semantics(
                        button: true,
                        label: "${t.handle}'s profile",
                        excludeSemantics: true,
                        child: VistaPressable(
                          onTap: onCaller,
                          child: Text(
                            t.handle,
                            style: VistaType.subhead,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: VistaSpace.sm),
                    // The side and the asset, in the side's colour: "LONG BTC".
                    Text(
                      '${t.side.label.toUpperCase()} ${t.ticker}',
                      style: VistaType.labelStrong.copyWith(color: color),
                    ),
                    const SizedBox(width: VistaSpace.sm),
                    Expanded(
                      child: Text(
                        '· ${t.age}',
                        style: VistaType.bodyMedium.copyWith(
                          color: VistaColors.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                // Their market, live, on its own line under the name.
                _CallerMarket(handle: t.handle, onTap: onMarket),
                // A take on a battle links it; a plain call shows nothing
                // here. The chip sits in a 44pt tap row; its own gaps are
                // folded into the row's height.
                if (t.battle != null)
                  _BattleChip(
                    label: t.battle!,
                    semantics: 'Open the debate: ${t.battle}',
                    onTap: onBattle,
                  )
                else
                  const SizedBox(height: VistaSpace.md),
                Text(t.body, style: _takeBody),
                if (t.call case final call?) ...[
                  const SizedBox(height: VistaSpace.md),
                  BackedPositionCard(
                    post: call,
                    ticker: t.ticker,
                    onTap: onCall,
                  ),
                ],
                const SizedBox(height: VistaSpace.xs),
                Row(
                  children: [
                    _AgreeButton(take: t),
                    if (t.joined case final joined?) ...[
                      const SizedBox(width: VistaSpace.gutter),
                      Semantics(
                        label: '$joined joined from this call',
                        excludeSemantics: true,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const VistaIcon(VistaAssets.takePeople, size: 18),
                            const SizedBox(width: 5),
                            Text('$joined joined', style: _actionCount),
                          ],
                        ),
                      ),
                    ],
                    const Spacer(),
                    VistaJoinPill(side: t.side, onTap: onJoin),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

final _actionCount = VistaType.bodyMedium.copyWith(
  color: VistaColors.textMuted,
);

/// The position behind a backed take, live: side and leverage, P/L since
/// entry, then entry, size and exits.
class BackedPositionCard extends StatelessWidget {
  const BackedPositionCard({
    super.key,
    required this.post,
    required this.ticker,
    this.onTap,
  });

  final CallerPost post;
  final String ticker;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = post;
    final entry = MarketPrices.base(ticker) * p.entryRatio;
    String level(double ratio) =>
        MarketPrices.format(entry * ratio, compact: true);
    return Semantics(
      button: true,
      label: "Open ${p.handle}'s position",
      value: '${p.side.label} ${p.leverage}x, entry ${level(1)}',
      excludeSemantics: true,
      child: VistaPressable(
        scale: 0.98,
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: VistaSpace.xl,
            vertical: VistaSpace.lg,
          ),
          decoration: BoxDecoration(
            color: VistaColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '${p.side.label.toUpperCase()} ${p.leverage}x',
                    style: VistaType.bodyStrong.copyWith(color: p.side.color),
                  ),
                  const Spacer(),
                  ValueListenableBuilder(
                    valueListenable: MarketPrices.of(ticker),
                    builder: (context, price, _) {
                      final pnl =
                          (price - entry) /
                          entry *
                          p.leverage *
                          (p.side == TradeSide.long ? 1 : -1) *
                          100;
                      return Text(
                        '${pnl >= 0 ? '+' : '−'}'
                        '${pnl.abs().toStringAsFixed(1)}%',
                        style: VistaType.figures(VistaType.subhead).copyWith(
                          color: pnl >= 0
                              ? VistaColors.long
                              : VistaColors.short,
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: VistaSpace.xs),
              Text(
                'Entry ${level(1)} · ${formatUsd(p.size)}'
                ' · TP ${_short(entry * p.takeProfit)}'
                ' · SL ${_short(entry * p.stopLoss)}',
                style: VistaType.figures(VistaType.chip).copyWith(
                  fontWeight: FontWeight.w500,
                  color: VistaColors.textMuted,
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// An exit level in short form: $72,000 → "$72k", $64,900 → "$64.9k",
/// $187.22 → "$187".
String _short(double v) {
  if (v < 100) return MarketPrices.format(v, compact: true);
  if (v < 1000) return '\$${v.round()}';
  final k = (v / 1000).toStringAsFixed(1);
  return '\$${k.endsWith('.0') ? k.substring(0, k.length - 2) : k}k';
}

/// The battle a take is on: "Reclaims $72,000 by Fri ›".
class _BattleChip extends StatelessWidget {
  const _BattleChip({required this.label, required this.semantics, this.onTap});

  final String label;
  final String semantics;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semantics,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          height: VistaSize.tapTarget,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.fromLTRB(
                VistaSpace.lg,
                VistaSpace.xs,
                VistaSpace.md,
                VistaSpace.xs,
              ),
              decoration: BoxDecoration(
                color: VistaColors.surface,
                borderRadius: BorderRadius.circular(VistaRadius.pill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      style: VistaType.figures(VistaType.chip).copyWith(
                        fontWeight: FontWeight.w500,
                        color: VistaColors.textTertiary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: VistaSpace.xs),
                  Text(
                    '›',
                    style: VistaType.body.copyWith(
                      color: VistaColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Agree with a take: the Home card's heart button and its count.
class _AgreeButton extends StatelessWidget {
  const _AgreeButton({required this.take});

  final Take take;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: TakeLikes.liked,
      builder: (context, liked, _) {
        final on = liked.contains(take.id);
        final count = take.likes + (on ? 1 : 0);
        return Semantics(
          button: true,
          toggled: on,
          label: 'Agree, $count',
          excludeSemantics: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              HapticFeedback.lightImpact();
              TakeLikes.toggle(take.id);
            },
            child: SizedBox(
              height: VistaSize.tapTarget,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // The Home card's Like, smaller: outline until agreed,
                  // then the red heart with a small overshoot.
                  TweenAnimationBuilder<double>(
                    key: ValueKey(on),
                    tween: Tween(begin: on ? 0.7 : 1, end: 1),
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOutBack,
                    builder: (context, scale, child) =>
                        Transform.scale(scale: scale, child: child),
                    child: VistaIcon(
                      on ? VistaAssets.like : VistaAssets.likeOutline,
                      size: 40,
                    ),
                  ),
                  const SizedBox(width: VistaSpace.xxs),
                  Text('$count', style: _actionCount),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The caller's market under their name: "Market \$0.172 ▲2.4% ›", live,
/// tapping through to it. Callers with no market show nothing.
class _CallerMarket extends StatelessWidget {
  const _CallerMarket({required this.handle, this.onTap});

  final String handle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final market = MarketsMock.traders.where((m) => m.id == handle);
    if (market.isEmpty) return const SizedBox.shrink();
    final change = market.first.changePct;
    final up = change >= 0;
    final muted = VistaType.bodyMedium.copyWith(color: VistaColors.textMuted);
    return Semantics(
      button: onTap != null,
      label: "$handle's market",
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.only(top: VistaSpace.xxs),
          child: ValueListenableBuilder(
            valueListenable: MarketPrices.of(handle),
            builder: (context, price, _) => Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: 'Market ', style: muted),
                  TextSpan(
                    // Short: "\$0.172" (a trader market trades in cents).
                    text: price < 1
                        ? '\$${price.toStringAsFixed(3)}'
                        : MarketPrices.format(price, compact: true),
                    style: VistaType.figures(VistaType.body)
                        .copyWith(color: VistaColors.textPrimary),
                  ),
                  TextSpan(
                    text:
                        ' ${up ? '▲' : '▼'}${change.abs().toStringAsFixed(1)}%',
                    style: VistaType.figures(VistaType.body).copyWith(
                      color: up ? VistaColors.long : VistaColors.short,
                    ),
                  ),
                  TextSpan(text: ' ›', style: muted),
                ],
              ),
              maxLines: 1,
            ),
          ),
        ),
      ),
    );
  }
}
