import '../../design_system/design_system.dart';
import '../market/market_mock.dart';
import '../market/trader_market_mock.dart';
import '../people/follow_mock.dart';

/// A live position shown in "Holding now".
class Holding {
  const Holding({
    required this.ticker,
    required this.side,
    required this.leverage,
    required this.entry,
    required this.current,
    required this.pnl,
  });

  final String ticker;
  final TradeSide side;
  final int leverage;
  final String entry;
  final String current;
  final String pnl;

  bool get inProfit => !pnl.startsWith('−');
}

/// A profile's market block: its cap, unit price, 24h change and open.
typedef MarketFigures = ({
  String market,
  String price,
  String cap,
  String change,
  String openPrice,
});

/// Sample profile content from Figma 303:102 (maya.eth). Every profile in the
/// demo shows this content under its own handle. Simulated.
abstract final class ProfileMock {
  static const followers = FollowMock.followerCount;
  static const market = r'$44.0M';
  static const bio =
      'Macro-first. Mostly BTC and SOL, rarely leveraged past 5x. '
      'I write down why before I enter.';

  static const price = r'$0.4400';
  static const cap = r'$44.0M cap';
  static const change = '+4.27%';
  static const openPrice = r'Open $0.4220';

  /// [handle]'s market figures: the user's own market reads its cap
  /// (VC-MKT-001, `TraderMarketMock.own`); every other profile shows the
  /// fixture above.
  static MarketFigures marketOf(String handle) {
    if (handle != TraderMarketMock.own) {
      return (
        market: market,
        price: price,
        cap: cap,
        change: change,
        openPrice: openPrice,
      );
    }
    final c = TraderMarketMock.ownCapCents;
    final supply = YourMarketMock.supplyUnits;
    return (
      market: formatCap(c),
      price: formatUnitPrice(c, supply),
      cap: '${formatCap(c)} cap',
      change: TraderMarketMock.change24hOf(handle),
      openPrice:
          'Open ${formatUnitPrice(c - TraderMarketMock.ownDayMoveCents, supply)}',
    );
  }

  static const holdings = [
    Holding(
      ticker: 'SOL',
      side: TradeSide.long,
      leverage: 5,
      entry: r'$198.40',
      current: r'$214.90',
      pnl: '+41.6%',
    ),
    Holding(
      ticker: 'ETH',
      side: TradeSide.long,
      leverage: 3,
      entry: r'$2,927',
      current: r'$2,968',
      pnl: '+4.2%',
    ),
    Holding(
      ticker: 'BTC',
      side: TradeSide.short,
      leverage: 2,
      entry: r'$67,020',
      current: r'$67,412',
      pnl: '−1.2%',
    ),
  ];
  static const cashShare = 'Cash · 9%';
}

/// A private account with no market: stats and public calls only (Figma
/// 258:407, "Profile — nara (private account)").
class PrivateProfile {
  const PrivateProfile({required this.followers, required this.bio});

  final String followers;
  final String bio;
}

/// Private accounts without a market. Opening one of these profiles shows
/// the private layout instead of the full profile.
const privateProfiles = {
  'nara': PrivateProfile(
    followers: '212',
    bio: 'Swing trades on the majors. I post calls, not positions.',
  ),
};
