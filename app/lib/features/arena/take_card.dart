import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../design_system/design_system.dart';
import '../live/live_feed.dart';
import '../live/market_prices.dart';
import '../trade/trade_mock.dart';
import 'arena_mock.dart';

/// Arena pieces from Figma 505:204 ("Arena — takes feed"): the live battle
/// tiles in the carousel and the flush, X-style take rows under them.

/// Body text of a take: 15pt regular on a 21pt line.
final _takeBody = VistaType.subheadMuted.copyWith(
  fontWeight: FontWeight.w400,
  color: VistaColors.textPrimary,
  height: 21 / 15,
);

/// Takes the viewer agreed with, by handle. In memory only.
abstract final class TakeLikes {
  static final liked = ValueNotifier<Set<String>>(const {});

  static void toggle(String handle) {
    final on = !liked.value.contains(handle);
    liked.value = on
        ? Set.unmodifiable({...liked.value, handle})
        : Set.unmodifiable(liked.value.where((h) => h != handle));
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
  const BattleTile({super.key, required this.battle, this.onTap});

  static const double width = 244;

  final LiveBattle battle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final b = battle;
    final long = (b.longShare * 100).round();
    return Semantics(
      button: true,
      label: '${b.ticker} battle: ${b.question}, $long% long, ${b.timeLeft}',
      excludeSemantics: true,
      child: VistaPressable(
        scale: 0.98,
        onTap: onTap,
        child: Container(
          width: width,
          padding: const EdgeInsets.all(VistaSpace.xxl),
          decoration: BoxDecoration(
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
                style: VistaType.subhead,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
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
                    '${b.takes} takes',
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
/// the side's colour, handle, side and record; the battle it's on (or, for
/// a plain call, the market); the text; the position behind it when backed;
/// then agree, joined and Join.
class TakeItem extends StatelessWidget {
  const TakeItem({
    super.key,
    required this.take,
    this.onCaller,
    this.onBattle,
    this.onMarket,
    this.onCall,
    this.onJoin,
  });

  final Take take;
  final VoidCallback? onCaller;

  /// Opens the battle the take is on.
  final VoidCallback? onBattle;

  /// Opens the market, for a plain call.
  final VoidCallback? onMarket;

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
            child: GestureDetector(
              onTap: onCaller,
              child: Container(
                width: VistaSize.avatarLarge,
                height: VistaSize.avatarLarge,
                decoration: BoxDecoration(
                  color: VistaColors.surfaceRaised,
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2),
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
                      child: GestureDetector(
                        onTap: onCaller,
                        child: Text(
                          t.handle,
                          style: VistaType.subhead,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: VistaSpace.sm),
                    _Tag(
                      t.side.label.toUpperCase(),
                      color: color,
                      fill: color.withValues(alpha: 0.16),
                      style: VistaType.labelStrong,
                    ),
                    const SizedBox(width: VistaSpace.sm),
                    Expanded(
                      child: Text(
                        '${t.accuracy} · ${t.age}',
                        style: VistaType.bodyMedium.copyWith(
                          color: VistaColors.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                // The chip sits in a 44pt tap row; its own gaps are folded
                // into the row's height.
                if (t.battle != null)
                  _ContextChip(
                    label: '${t.ticker} · ${t.battle}',
                    semantics: 'Open the battle: ${t.battle}',
                    onTap: onBattle,
                  )
                else
                  ValueListenableBuilder(
                    valueListenable: MarketPrices.of(t.ticker),
                    builder: (context, price, _) => _ContextChip(
                      label:
                          '${t.ticker} · '
                          '${MarketPrices.format(price, compact: true)}',
                      semantics: 'Open ${t.ticker}',
                      onTap: onMarket,
                    ),
                  ),
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
                        label: '$joined joined from this take',
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
                    _JoinButton(side: t.side, onTap: onJoin),
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

/// The position behind a backed take, live: side and leverage, "✓ Backed",
/// P/L since entry, then entry, size and exits.
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
                  const SizedBox(width: VistaSpace.sm),
                  _Tag(
                    '✓ Backed',
                    color: VistaColors.textPrimary,
                    fill: VistaColors.surfaceRaised,
                    style: VistaType.label,
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

/// A small rounded label: the LONG/SHORT side tag and "✓ Backed".
class _Tag extends StatelessWidget {
  const _Tag(
    this.text, {
    required this.color,
    required this.fill,
    required this.style,
  });

  final String text;
  final Color color;
  final Color fill;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: VistaSpace.sm,
        vertical: VistaSpace.xxs,
      ),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(VistaRadius.sm),
      ),
      child: Text(text, style: style.copyWith(color: color)),
    );
  }
}

/// What the take is about: the battle ("BTC · Reclaims $72,000 by Fri ›")
/// or, for a plain call, the market and its live price.
class _ContextChip extends StatelessWidget {
  const _ContextChip({
    required this.label,
    required this.semantics,
    this.onTap,
  });

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

/// Agree with a take: the heart and its count; red once agreed.
class _AgreeButton extends StatelessWidget {
  const _AgreeButton({required this.take});

  final Take take;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: TakeLikes.liked,
      builder: (context, liked, _) {
        final on = liked.contains(take.handle);
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
              TakeLikes.toggle(take.handle);
            },
            child: SizedBox(
              height: VistaSize.tapTarget,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  VistaIcon(
                    VistaAssets.takeHeart,
                    size: 18,
                    color: on ? VistaColors.short : null,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '$count',
                    style: on
                        ? _actionCount.copyWith(color: VistaColors.short)
                        : _actionCount,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// "Join long" / "Join short" in the side's tint: opens the order ticket.
class _JoinButton extends StatelessWidget {
  const _JoinButton({required this.side, this.onTap});

  final TradeSide side;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final label = 'Join ${side.label.toLowerCase()}';
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: VistaPressable(
        onTap: onTap,
        child: SizedBox(
          height: VistaSize.tapTarget,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: VistaSpace.xxl,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                color: side.color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(VistaRadius.pill),
              ),
              child: Text(
                label,
                style: VistaType.body.copyWith(color: side.color),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
