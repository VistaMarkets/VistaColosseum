/// Mock content from Figma 236:102, 237:373, 241:102, 237:530 and 237:694.
/// Simulated; not market data.
abstract final class TraderMarketMock {
  static const marketCap = r'$44.0M';
  static const capChange = r'+$1.8M';
  static const change24h = '+4.27%';

  /// Units in every trader market; cap = unit price × supply.
  static const supply = 100e6;

  /// "$44.0M" for a unit price of $0.44.
  static String capFor(double unitPrice) =>
      '\$${(unitPrice * supply / 1e6).toStringAsFixed(1)}M';

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
