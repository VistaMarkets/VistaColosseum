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
  static const assetSorts = ['Volume', 'Change', 'Funding'];
  static const traderSorts = ['Market cap', 'Change', 'Open calls', 'New'];

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
  ];
}
