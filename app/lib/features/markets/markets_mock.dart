import '../../design_system/design_system.dart';

/// One market in the Markets lists (an asset perp or a trader market).
class MarketItem {
  const MarketItem({
    required this.id,
    required this.name,
    required this.rowIcon,
    required this.railIcon,
    required this.subline,
    required this.price,
    required this.changePct,
    required this.third,
    required this.sortValues,
    required this.spark,
    required this.footLeft,
    required this.footRight,
    this.badge,
  });

  final String id;
  final String name;
  final String rowIcon;
  final String railIcon;
  final String? badge;
  final String subline;
  final String price;
  final double changePct;

  /// Last row column: funding (assets) or market cap (traders).
  final String third;

  /// Values each sort chip orders by (descending), keyed by chip label.
  final Map<String, double> sortValues;

  /// Favourite-card spark and footnotes.
  final String spark;
  final String footLeft;
  final String footRight;
}

/// Mock content from Figma 185:110 (Assets) and 222:110 (Traders).
/// Simulated; not market data.
abstract final class MarketsMock {
  /// Full names under the tickers on the asset cards.
  static const assetNames = {
    'BTC': 'Bitcoin',
    'ETH': 'Ethereum',
    'SOL': 'Solana',
    'ARB': 'Arbitrum',
    'AVAX': 'Avalanche',
  };

  /// Ticker, holders and avatar colour for the trader market cards (Figma
  /// 546:300), plus this week's P&L, holders gained this week and how many
  /// days the market has been open (for Leaderboard and Up and coming).
  /// maya.eth's ticker matches the one picked in Make a market.
  static const traderCards =
      <
        String,
        ({
          String symbol,
          int holders,
          int avatar,
          double weekPnl,
          int newHolders,
          int days,
        })
      >{
        'maya.eth': (
          symbol: 'MAYA',
          holders: 214,
          avatar: 0xFF3A3550,
          weekPnl: 12400,
          newHolders: 18,
          days: 140,
        ),
        '0xreal': (
          symbol: 'REAL',
          holders: 640,
          avatar: 0xFF2B4A3F,
          weekPnl: 8100,
          newHolders: 22,
          days: 300,
        ),
        'lunaq': (
          symbol: 'LUNQ',
          holders: 388,
          avatar: 0xFF4A3B2B,
          weekPnl: -2300,
          newHolders: 4,
          days: 210,
        ),
        'deltaone': (
          symbol: 'DELTA',
          holders: 1180,
          avatar: 0xFF2B3D4A,
          weekPnl: 15800,
          newHolders: 31,
          days: 400,
        ),
        'kestrel': (
          symbol: 'KSTRL',
          holders: 132,
          avatar: 0xFF333333,
          weekPnl: -900,
          newHolders: 2,
          days: 90,
        ),
        'kilo.sol': (
          symbol: 'KILO',
          holders: 96,
          avatar: 0xFF4A2B36,
          weekPnl: 3400,
          newHolders: 14,
          days: 24,
        ),
        'nara': (
          symbol: 'NARA',
          holders: 58,
          avatar: 0xFF33363D,
          weekPnl: 1200,
          newHolders: 11,
          days: 19,
        ),
        'pip.eth': (
          symbol: 'PIP',
          holders: 41,
          avatar: 0xFF2B3F4A,
          weekPnl: 2100,
          newHolders: 41,
          days: 3,
        ),
        'vexa': (
          symbol: 'VEXA',
          holders: 73,
          avatar: 0xFF44324A,
          weekPnl: 4600,
          newHolders: 52,
          days: 6,
        ),
        'orca.sol': (
          symbol: 'ORCA',
          holders: 29,
          avatar: 0xFF2E3A33,
          weekPnl: 700,
          newHolders: 29,
          days: 11,
        ),
      };

  /// Up and coming: trader markets younger than this, by holders gained.
  static const newMarketDays = 30;

  static const assetSorts = ['Volume', 'Change', 'Funding'];

  /// Leaderboard chips; Up and coming narrows the board to new markets.
  static const traderSorts = [
    'Most right',
    'Top P&L',
    'Up and coming',
    'Market cap',
    'Change',
  ];

  /// Favourites as designed. The Assets rail shows SOL although its row is
  /// unstarred in Figma; favourites here are one list, so SOL is starred.
  static const assetFavorites = ['BTC', 'ETH', 'SOL'];
  static const traderFavorites = ['maya.eth', 'lunaq', 'deltaone'];

  static const assets = [
    MarketItem(
      id: 'BTC',
      name: 'BTC',
      rowIcon: VistaAssets.coinBtcRow,
      railIcon: VistaAssets.coinBtcRail,
      badge: '50x',
      subline: r'OI $412M',
      price: r'$67,412',
      changePct: 1.2,
      third: '+0.009%',
      sortValues: {'Volume': 412, 'Change': 1.2, 'Funding': 0.009},
      spark: VistaAssets.spark24UpA,
      footLeft: 'Funding +0.009%',
      footRight: r'OI $412M',
    ),
    MarketItem(
      id: 'ETH',
      name: 'ETH',
      rowIcon: VistaAssets.coinEthRow,
      railIcon: VistaAssets.coinEthRail,
      badge: '50x',
      subline: r'OI $290M',
      price: r'$2,968',
      changePct: -0.4,
      third: '−0.004%',
      sortValues: {'Volume': 290, 'Change': -0.4, 'Funding': -0.004},
      spark: VistaAssets.spark24Down,
      footLeft: 'Funding −0.004%',
      footRight: r'OI $290M',
    ),
    MarketItem(
      id: 'SOL',
      name: 'SOL',
      rowIcon: VistaAssets.coinSolRow,
      railIcon: VistaAssets.coinSolRail,
      badge: '20x',
      subline: r'OI $180M',
      price: r'$214.90',
      changePct: 3.8,
      third: '+0.012%',
      sortValues: {'Volume': 180, 'Change': 3.8, 'Funding': 0.012},
      spark: VistaAssets.spark24UpB,
      footLeft: 'Funding +0.012%',
      footRight: r'OI $180M',
    ),
    MarketItem(
      id: 'ARB',
      name: 'ARB',
      rowIcon: VistaAssets.coinArbRow,
      railIcon: VistaAssets.coinArbRow,
      badge: '10x',
      subline: r'OI $41M',
      price: r'$1.04',
      changePct: 0.9,
      third: '+0.007%',
      sortValues: {'Volume': 41, 'Change': 0.9, 'Funding': 0.007},
      spark: VistaAssets.spark24UpA,
      footLeft: 'Funding +0.007%',
      footRight: r'OI $41M',
    ),
    MarketItem(
      id: 'AVAX',
      name: 'AVAX',
      rowIcon: VistaAssets.coinAvaxRow,
      railIcon: VistaAssets.coinAvaxRow,
      badge: '10x',
      subline: r'OI $30M',
      price: r'$38.20',
      changePct: -1.1,
      third: '−0.002%',
      sortValues: {'Volume': 30, 'Change': -1.1, 'Funding': -0.002},
      spark: VistaAssets.spark24Down,
      footLeft: 'Funding −0.002%',
      footRight: r'OI $30M',
    ),
  ];

  static MarketItem _trader(
    String handle,
    int calls,
    int open,
    String price,
    double change,
    String cap,
    double capM,
    String spark,
  ) => MarketItem(
    id: handle,
    name: handle,
    rowIcon: VistaAssets.traderAvatarRow,
    railIcon: VistaAssets.traderAvatarRail,
    badge: open > 0 ? '$open open' : null,
    subline: '$calls calls',
    price: price,
    changePct: change,
    third: cap,
    sortValues: {
      'Market cap': capM,
      'Change': change,
      'Open calls': open.toDouble(),
    },
    spark: spark,
    footLeft: 'Cap $cap',
    footRight: '$calls calls',
  );

  static final traders = [
    _trader(
      'maya.eth',
      62,
      3,
      r'$0.4400',
      4.3,
      r'$44.0M',
      44.0,
      VistaAssets.spark24UpA,
    ),
    _trader(
      '0xreal',
      240,
      0,
      r'$0.3820',
      1.1,
      r'$38.2M',
      38.2,
      VistaAssets.spark24UpB,
    ),
    _trader(
      'lunaq',
      118,
      1,
      r'$0.3145',
      -2.4,
      r'$31.5M',
      31.5,
      VistaAssets.spark24Down,
    ),
    _trader(
      'deltaone',
      402,
      2,
      r'$0.2610',
      0.7,
      r'$26.1M',
      26.1,
      VistaAssets.spark24UpB,
    ),
    _trader(
      'kestrel',
      87,
      0,
      r'$0.1980',
      -3.1,
      r'$19.8M',
      19.8,
      VistaAssets.spark24Down,
    ),
    _trader(
      'kilo.sol',
      54,
      1,
      r'$0.1720',
      2.2,
      r'$17.2M',
      17.2,
      VistaAssets.spark24UpA,
    ),
    _trader(
      'nara',
      31,
      0,
      r'$0.1410',
      -0.9,
      r'$14.1M',
      14.1,
      VistaAssets.spark24Down,
    ),
    _trader(
      'vexa',
      14,
      2,
      r'$0.0880',
      11.2,
      r'$8.8M',
      8.8,
      VistaAssets.spark24UpA,
    ),
    _trader(
      'pip.eth',
      9,
      1,
      r'$0.0620',
      18.4,
      r'$6.2M',
      6.2,
      VistaAssets.spark24UpB,
    ),
    _trader(
      'orca.sol',
      6,
      0,
      r'$0.0470',
      7.6,
      r'$4.7M',
      4.7,
      VistaAssets.spark24UpA,
    ),
  ];
}
