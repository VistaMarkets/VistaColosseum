import 'package:flutter/painting.dart';

import '../../design_system/design_system.dart';

/// A followed trader's position in this market (Holders panel).
class FollowedHolder {
  const FollowedHolder({
    required this.handle,
    required this.side,
    required this.from,
    required this.pnl,
  });

  final String handle;
  final TradeSide side;
  final String from;
  final String pnl;

  bool get inProfit => !pnl.startsWith('−');
  String get avatar => side == TradeSide.long
      ? VistaAssets.holderAvatarLong
      : VistaAssets.holderAvatarShort;
}

/// One entry in the Record panel.
class RecordCall {
  const RecordCall(
    this.rail,
    this.title,
    this.lead,
    this.leadColor,
    this.detail,
  );

  final String rail;
  final String title;
  final String lead;
  final Color leadColor;
  final String detail;
}

/// Mock content from Figma 236:102, 237:373, 241:102, 237:530 and 237:694.
/// Simulated; not market data.
abstract final class TraderMarketMock {
  static const openCalls = '3 open calls';
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

  // Record.
  static const recordSummary = [
    ('62 settled', VistaColors.textPrimary),
    ('36 right', VistaColors.long),
    ('26 wrong', VistaColors.short),
    ('3 open', VistaColors.textMuted),
  ];
  static const record = [
    RecordCall(
      VistaAssets.railRecordOpen,
      r'SOL reaches $300 by Fri',
      '2d left',
      VistaColors.textMuted,
      'Market said 22% · 39.6% away',
    ),
    RecordCall(
      VistaAssets.railRecordOpen,
      r'ETH holds $3,000 to Oct 1',
      '6d left',
      VistaColors.textMuted,
      'Market said 64% · 5.7% cushion',
    ),
    RecordCall(
      VistaAssets.railRecordOpen,
      r'ARB reaches $1.40 by Oct 15',
      '20d left',
      VistaColors.textMuted,
      'Market said 18% · 34.6% away',
    ),
    RecordCall(
      VistaAssets.railRecordRight,
      r'BTC reclaims $66,000 by Tue',
      'Right at 31%',
      VistaColors.long,
      'Settled Tue 16:00',
    ),
    RecordCall(
      VistaAssets.railRecordWrong,
      r'AVAX holds $40 to Sep 20',
      'Wrong at 58%',
      VistaColors.short,
      'Settled Sep 20',
    ),
  ];

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

  // Holders.
  static const holders = '142';
  static const holdersLong = 82;
  static const holdersShort = 60;
  static const holdersChange = '+9 this week';
  static const followed = [
    FollowedHolder(
      handle: '0xreal',
      side: TradeSide.short,
      from: r'$0.4520',
      pnl: '+2.7%',
    ),
    FollowedHolder(
      handle: 'lunaq',
      side: TradeSide.long,
      from: r'$0.4310',
      pnl: '+2.1%',
    ),
    FollowedHolder(
      handle: 'kilo.sol',
      side: TradeSide.long,
      from: r'$0.4460',
      pnl: '−1.3%',
    ),
  ];
}
