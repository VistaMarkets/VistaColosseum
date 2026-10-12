import '../../scenario/scenario.dart';
import '../portfolio/portfolio_mock.dart';
import 'market_mock.dart';

/// Mock content from Figma 236:102, 237:373, 241:102, 237:530 and 237:694.
/// Simulated; not market data.
abstract final class TraderMarketMock {
  static const marketCap = r'$44.0M';
  static const capChange = r'+$1.8M';
  static const change24h = '+4.27%';

  /// Units in every trader market; cap = unit price × supply.
  static const supply = 100e6;

  /// "$44.0M" for a unit price of $0.44, "$10,000" for $0.0001.
  static String capFor(double unitPrice) =>
      formatCap((unitPrice * supply * 100).round());

  /// The user's trader market, which is their listed market (VC-MKT-001,
  /// ruled 2026-10-09). Explore, Trader market, Profile, Arena and
  /// `MarketPrices` read it here: the listing's cap once listed, and the
  /// seed's before any listing, so the default demo keeps its market.
  static const own = PortfolioMock.handle;
  static int get ownCapCents =>
      Scenario.ownCapCents ?? YourMarketMock.seededCapCents;

  /// Whether [own] has the seed's history: false only for a fresh listing.
  static bool get ownHasHistory =>
      Scenario.ownCapCents == null || Scenario.ownCapHasHistory;

  /// [own]'s 24h move in int cents: the seed's 1D move, or 0 when fresh.
  static int get ownDayMoveCents => ownHasHistory
      ? YourMarketMock.seededCapMovesCents[PortfolioMock.spans.indexOf('1D')]
      : 0;

  /// [own]'s unit price in dollars: $0.44 seeded, $0.0001 fresh.
  static double get ownUnitPrice =>
      ownCapCents / 100 / YourMarketMock.supplyUnits;

  /// [own]'s 24h change in hundredths of a percent, half-up (seed: 427).
  static int get ownDayChangeBp {
    final move = ownDayMoveCents;
    final start = ownCapCents - move;
    final p = (move.abs() * 20000 + start) ~/ (2 * start);
    return move < 0 ? -p : p;
  }

  /// [ownDayChangeBp] in tenths, as Explore and Arena print it (4.3).
  static double get ownDayChangePct =>
      ((ownDayChangeBp.abs() + 5) ~/ 10) * ownDayChangeBp.sign / 10;

  /// The header's cap move and 24h change for [handle]: [own]'s derived
  /// figures, the Figma fixture for every other trader.
  static String capChangeOf(String handle) {
    if (handle != own) return capChange;
    final move = ownDayMoveCents;
    return '${move < 0 ? '−' : '+'}${formatCap(move.abs())}';
  }

  static String change24hOf(String handle) {
    if (handle != own) return change24h;
    final p = ownDayChangeBp;
    final a = p.abs();
    return '${p < 0 ? '−' : '+'}${a ~/ 100}.${(a % 100).toString().padLeft(2, '0')}%';
  }

  static const intervals = ['1m', '5m', '15m', '1h', '4h', '1D'];
  static const defaultInterval = 2; // 15m

  // Market.
  static const longShare = 0.58;
  static const longOi = r'$1,820';
  static const shortOi = r'$1,320';
  static const openInterest = r'Open interest $3,140';
  static const fundingRate = '0.01% / 8h';
  static const fundingNext = 'Next in 3h 12m';
  static const stats = [
    [('24h high', r'$0.4460'), ('24h low', r'$0.4175')],
    [('24h volume', r'$1,880'), ('7d volume', r'$14,200')],
    [('Trades today', '214'), ('Traders this week', '96')],
    [
      ('All-time high', r'$0.5120 · Aug 30'),
      ('Since listing Mar 12', '+46.7%'),
    ],
  ];
}
