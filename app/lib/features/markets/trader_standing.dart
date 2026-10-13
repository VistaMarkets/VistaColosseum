import '../account/account_state.dart';
import '../portfolio/portfolio_mock.dart';
import 'markets_mock.dart';

/// How good a trader is, measured one way across the app: their market's
/// cap. Traders without a market show nothing. Mock caps.
abstract final class TraderStanding {
  /// [handle]'s market (ticker, cap as shown, cap in $M), or null if they
  /// have none. Yours counts once you've made it.
  static ({String symbol, String cap, double capM})? of(String handle) {
    if (handle == PortfolioMock.handle && !AccountState.hasMarket.value) {
      return null;
    }
    final m = MarketsMock.traders.where((m) => m.id == handle).firstOrNull;
    if (m == null) return null;
    final symbol = handle == PortfolioMock.handle
        ? AccountState.ticker.value
        : MarketsMock.traderCards[handle]?.symbol ?? handle;
    return (
      symbol: symbol,
      cap: m.third,
      capM: m.sortValues['Market cap'] ?? 0,
    );
  }

  /// Ranks by market cap, biggest first; no market last.
  static int compare(String a, String b) =>
      (of(b)?.capM ?? -1).compareTo(of(a)?.capM ?? -1);
}
