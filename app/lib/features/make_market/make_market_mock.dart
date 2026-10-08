/// Mock content for the make-a-market flow (Figma 338:102, 329:102,
/// 348:624). Simulated: nothing is listed, minted or signed.
abstract final class MakeMarketMock {
  static const name = 'maya.eth';
  static const defaultTicker = 'MAYA';
  static const suggestions = ['MAYA', 'MAYAETH', 'MYA', 'MACRO'];
  static const maxTicker = 8;
  static const defaultPitch =
      'Macro-first. Mostly BTC and SOL, rarely past 5x.';
  static const maxPitch = 140;

  /// Tickers already listed (assets and other traders' markets).
  static const taken = {
    'BTC',
    'ETH',
    'SOL',
    'ARB',
    'AVAX',
    'LUNAQ',
    'KAITO',
    'DELTA',
    'MIRIN',
    'KILO',
  };

  static const supply = '100M · nothing minted';

  /// A fresh listing's market cap: $10,000 in int cents
  /// (`Scenario.ownCapCents`).
  static const startingCapCents = 1000000;

  static const consents = [
    'I understand people can short my market',
    "My calls are graded in public, and delisting doesn't delete them",
    "I'm 18+ and not a US person or resident",
  ];
}
