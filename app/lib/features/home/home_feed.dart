import 'dart:math' as math;

import '../../design_system/design_system.dart';
import '../arena/arena_mock.dart';
import '../calls/calls_store.dart';
import '../live/market_prices.dart';
import '../markets/markets_mock.dart';
import '../people/follow_state.dart';
import '../portfolio/portfolio_mock.dart';
import '../trade/caller_play_screen.dart';
import '../trade/trade_mock.dart';
import 'mock_trade_idea.dart';

/// The Home feed: users' calls (the same `CallsStore` Arena and the trade
/// pages' Callers read), ranked and shown as replay cards.
///
/// Ranking (a demo stand-in for the backend's):
/// - engagement = agrees + 3 × joined. Joining is a trade, so it counts for
///   more than a like.
/// - popularity = √engagement: more is better with diminishing returns, so
///   a big call leads without burying everything (a log flattened 4.4k likes
///   down to barely more than 17).
/// - freshness = 1 / (hours since posted + 2)^0.8, so calls fade over a
///   day or so instead of dropping off a cliff.
/// - ×1.5 when you follow the caller (For You only), ×1.2 when the call is
///   backed by a position.
/// - score = popularity × freshness × boosts. A call you have just posted
///   shows first, as on X.
abstract final class HomeFeed {
  /// Who the viewer follows (shared with call cards and profiles).
  static Set<String> get followed => FollowState.following.value;

  static bool _mine(Take t) => t.handle == PortfolioMock.handle;
  static bool _justPosted(Take t) => _mine(t) && t.age == 'now';

  /// Every call, ranked.
  static List<Take> forYou(List<Take> calls) => _rank(calls, followBoost: true);

  /// Calls from people the viewer follows, ranked the same way; your own
  /// just-posted call shows first here too.
  static List<Take> following(List<Take> calls) => _rank([
    for (final t in calls)
      if (_justPosted(t) || followed.contains(t.handle)) t,
  ], followBoost: false);

  /// How high [t] ranks (see the class comment).
  static double score(Take t, {bool followBoost = true}) {
    final engagement = t.likes + 3 * (t.joined ?? 0);
    final popularity = math.sqrt(engagement);
    final hours = CallsStore.minutesAgo(t.age) / 60;
    final freshness = 1 / math.pow(hours + 2, 0.8);
    var boost = 1.0;
    if (followBoost && followed.contains(t.handle)) boost *= 1.5;
    if (t.backed) boost *= 1.2;
    return popularity * freshness * boost;
  }

  static List<Take> _rank(List<Take> calls, {required bool followBoost}) {
    final scored = [
      for (final t in calls) (t, score(t, followBoost: followBoost)),
    ];
    scored.sort((a, b) {
      final pa = _justPosted(a.$1), pb = _justPosted(b.$1);
      if (pa != pb) return pa ? -1 : 1;
      return b.$2.compareTo(a.$2);
    });
    return [for (final (t, _) in scored) t];
  }

  static final _cards = <String, TradeIdea>{};

  /// The Home card for [t]: its own replay when it has one; otherwise a
  /// card built from the call (its entry, its battle or its own words as
  /// the headline, its own counts). Cached so the replay and likes stay put.
  static TradeIdea ideaOf(Take t) =>
      t.idea ?? _cards.putIfAbsent(t.id, () => _build(t));

  static TradeIdea _build(Take t) {
    final long = t.side == TradeSide.long;
    final played = t.call == null
        ? null
        : callerPlayIdea(CallsStore.postOf(t), t.ticker);
    final row = MarketsMock.assets.where((m) => m.id == t.ticker);
    return TradeIdea(
      callerHandle: t.handle,
      age: t.age,
      side: t.side,
      ticker: t.ticker,
      assetName: TradeMock.quotes[t.ticker]?.name ?? t.ticker,
      coinAsset: row.isEmpty ? VistaAssets.coinPlaceholder : row.first.rowIcon,
      // Backed: the position's entry. Unbacked: about where it stood when
      // posted (mock).
      callPrice:
          played?.callPrice ??
          MarketPrices.base(t.ticker) * (long ? 0.99 : 1.01),
      // The call's own words (or its battle) are the headline.
      question: t.battle ?? t.body,
      likes: _short(t.likes),
      traders: _short(t.joined ?? 0),
      whale: r'$1.2M',
      // No made-up activity on a call nobody has joined yet.
      fills: (t.joined ?? 0) > 0 ? played?.fills ?? const [] : const [],
    );
  }

  /// 4400 → "4.4k", 48 → "48".
  static String _short(int n) =>
      n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : '$n';
}
