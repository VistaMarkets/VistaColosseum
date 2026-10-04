import 'package:flutter/foundation.dart';

import '../features/markets/markets_mock.dart';
import '../features/people/follow_mock.dart';
import '../features/portfolio/portfolio_mock.dart';
import '../features/trade/trade_mock.dart';

/// All mutable demo state, in one place. Seeded from the mocks, which are
/// the fixture and never live state; [reset] puts every value back to that
/// seed. Identities, prices and calls stay const fixtures and are not here.
///
/// Simulated: nothing is sent, and nothing survives a restart. Money is
/// `int` cents.
abstract final class Scenario {
  /// Which fixture the demo runs on; shown when the demo is reset.
  static const fixtureVersion = 'fixture-v1';

  /// `--dart-define=HAS_MARKET=true` starts with the user's market listed.
  static const _startWithMarket = bool.fromEnvironment('HAS_MARKET');

  static final cashCents = ValueNotifier<int>(PortfolioMock.cashCents);
  static final positions = ValueNotifier<List<PortfolioPosition>>(
    PortfolioMock.positions,
  );
  static final openOrders = ValueNotifier<List<OpenOrder>>(
    OpenOrdersMock.orders,
  );

  /// The user's own market: whether it is listed, its ticker (suggested
  /// before listing), and its id once listed (the symbol, as markets use).
  static final hasMarket = ValueNotifier<bool>(_startWithMarket);
  static final ticker = ValueNotifier<String>(PortfolioMock.marketSymbol);
  static final marketId = ValueNotifier<String?>(_seedMarketId);

  /// Liked calls, keyed `callerHandle/ticker`.
  static final liked = ValueNotifier<Set<String>>(const {});

  /// Starred assets and trader markets, in the order starred.
  static final favoriteAssets = ValueNotifier<List<String>>(
    MarketsMock.assetFavorites,
  );
  static final favoriteTraders = ValueNotifier<List<String>>(
    MarketsMock.traderFavorites,
  );

  /// The user's Followers and Following lists, and the handles the user
  /// follows (every Follow button reads this).
  static final followers = ValueNotifier<List<FollowPerson>>(
    FollowMock.followers,
  );
  static final following = ValueNotifier<List<FollowPerson>>(
    FollowMock.following,
  );
  static final followed = ValueNotifier<Set<String>>(_seedFollowed);

  /// The demo's "now", fixed at the fixture's start (where charts end).
  static final clock = ValueNotifier<DateTime>(TradeMock.chartEnd);

  static String? get _seedMarketId =>
      _startWithMarket ? PortfolioMock.marketSymbol : null;

  /// A handle's last entry wins, as the follow lists showed it.
  static Set<String> get _seedFollowed => Set.unmodifiable({
    for (final MapEntry(:key, :value) in {
      for (final p in [...FollowMock.followers, ...FollowMock.following])
        p.handle: p.following,
    }.entries)
      if (value) key,
  });

  /// Puts every value back to the fixture seed.
  static void reset() {
    cashCents.value = PortfolioMock.cashCents;
    positions.value = PortfolioMock.positions;
    openOrders.value = OpenOrdersMock.orders;
    hasMarket.value = _startWithMarket;
    ticker.value = PortfolioMock.marketSymbol;
    marketId.value = _seedMarketId;
    liked.value = const {};
    favoriteAssets.value = MarketsMock.assetFavorites;
    favoriteTraders.value = MarketsMock.traderFavorites;
    followers.value = FollowMock.followers;
    following.value = FollowMock.following;
    followed.value = _seedFollowed;
    clock.value = TradeMock.chartEnd;
  }
}
