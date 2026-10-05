import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../live/live_feed.dart';
import '../live/market_prices.dart';
import 'trade_mock.dart';

/// Callers on an asset as a post thread: each caller's reasoning in their
/// own words over their order (side, leverage, entry, size, exits and live
/// P&L), posts joined by a line through the avatars. Read-only: no like,
/// repost or share. Tapping a caller opens their profile.
class CallerThread extends StatelessWidget {
  const CallerThread({
    super.key,
    required this.ticker,
    required this.posts,
    required this.onCaller,
    this.onPlay,
  });

  final String ticker;
  final List<CallerPost> posts;
  final ValueChanged<String> onCaller;

  /// Opens a caller's play (their order card was tapped).
  final ValueChanged<CallerPost>? onPlay;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: MarketPrices.of(ticker),
      builder: (context, price, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < posts.length; i++)
            _Post(
              post: posts[i],
              base: MarketPrices.base(ticker),
              price: price,
              threaded: i < posts.length - 1,
              onCaller: onCaller,
              onPlay: onPlay,
            ),
        ],
      ),
    );
  }
}

class _Post extends StatelessWidget {
  const _Post({
    required this.post,
    required this.base,
    required this.price,
    required this.threaded,
    required this.onCaller,
    this.onPlay,
  });

  final CallerPost post;
  final ValueChanged<CallerPost>? onPlay;

  /// The market's session price the order levels are set from, and its
  /// live price for P&L.
  final double base;
  final double price;

  /// Draws the thread line down to the next post.
  final bool threaded;
  final ValueChanged<String> onCaller;

  static const double _avatar = 36;

  @override
  Widget build(BuildContext context) {
    final p = post;
    final long = p.side == TradeSide.long;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Avatar, with the thread line running on to the next post.
          SizedBox(
            width: _avatar,
            child: Column(
              children: [
                Semantics(
                  button: true,
                  label: '${p.handle} profile',
                  excludeSemantics: true,
                  child: GestureDetector(
                    onTap: () => onCaller(p.handle),
                    child: VistaIcon(
                      long
                          ? VistaAssets.traderAvatar
                          : VistaAssets.callerAvatarShort,
                      size: _avatar,
                    ),
                  ),
                ),
                if (threaded)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Container(
                        width: 2,
                        decoration: BoxDecoration(
                          color: VistaColors.surfaceRaised,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: VistaSpace.lg),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: threaded ? VistaSpace.xl : 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onCaller(p.handle),
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            p.handle,
                            style: VistaType.subhead,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: VistaSpace.sm),
                        Text('· ${p.age}', style: VistaType.meta),
                      ],
                    ),
                  ),
                  const SizedBox(height: VistaSpace.xs),
                  Text(
                    p.message,
                    style: VistaType.rowRegular.copyWith(
                      height: 1.35,
                      color: VistaColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: VistaSpace.md),
                  // The order, embedded like a quoted post; tap for the play.
                  CallOrderCard(
                    post: p,
                    base: base,
                    price: price,
                    onTap: onPlay == null ? null : () => onPlay!(p),
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

/// A caller's order as a card, like a quoted post under their words: side
/// and leverage, entry and live P&L, then size and exits. Shared by the
/// trade page's Callers thread and Arena's opinions. [base] is the market's
/// session price the levels are set from; [price] its live price.
class CallOrderCard extends StatelessWidget {
  const CallOrderCard({
    super.key,
    required this.post,
    required this.base,
    required this.price,
    this.onTap,
  });

  final CallerPost post;
  final double base;
  final double price;

  /// Opens the caller's play.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = post;
    final long = p.side == TradeSide.long;
    final entry = base * p.entryRatio;
    final pnl = (price - entry) / entry * p.leverage * (long ? 1 : -1) * 100;
    String level(double ratio) =>
        MarketPrices.format(entry * ratio, compact: true);
    return Semantics(
      button: true,
      label: "Open ${p.handle}'s play",
      value: '${p.side.label} ${p.leverage}x, entry ${level(1)}',
      excludeSemantics: true,
      child: VistaPressable(
        scale: 0.98,
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(VistaSpace.lg),
          // The same grey backing as the position on an Arena call.
          decoration: BoxDecoration(
            color: VistaColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '${p.side.label.toUpperCase()} ${p.leverage}x',
                    style: VistaType.labelStrong.copyWith(color: p.side.color),
                  ),
                  const SizedBox(width: VistaSpace.sm),
                  Expanded(
                    child: Text(
                      'Entry ${level(1)}',
                      style: VistaType.figures(VistaType.body),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${pnl >= 0 ? '+' : '−'}${pnl.abs().toStringAsFixed(1)}%',
                    style: VistaType.figures(VistaType.bodyStrong).copyWith(
                      color: pnl >= 0 ? VistaColors.long : VistaColors.short,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: VistaSpace.xs),
              Text(
                'Size ${formatUsd(p.size)}'
                ' · TP ${level(p.takeProfit)}'
                ' · SL ${level(p.stopLoss)}',
                style: VistaType.figures(VistaType.caption)
                    .copyWith(color: VistaColors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
