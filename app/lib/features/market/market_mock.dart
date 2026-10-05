import 'package:flutter/painting.dart';

import '../../design_system/design_system.dart';

enum CallOutcome { right, wrong, open }

/// One published call in the market's record.
class RecordEntry {
  const RecordEntry({
    required this.time,
    required this.title,
    required this.outcome,
    required this.odds,
  });

  final String time;
  final String title;
  final CallOutcome outcome;

  /// Implied odds when the call was made, e.g. "22%".
  final String odds;

  String get status => switch (outcome) {
    CallOutcome.right => 'Right',
    CallOutcome.wrong => 'Wrong',
    CallOutcome.open => 'Open',
  };

  Color get color => switch (outcome) {
    CallOutcome.right => VistaColors.long,
    CallOutcome.wrong => VistaColors.short,
    CallOutcome.open => VistaColors.fees,
  };

  String get rail => switch (outcome) {
    CallOutcome.right => VistaAssets.timelineRight,
    CallOutcome.wrong => VistaAssets.timelineWrong,
    CallOutcome.open => VistaAssets.timelineOpen,
  };

  String get detail =>
      outcome == CallOutcome.open ? 'published · at $odds' : 'at $odds';
}

/// Mock content from the Figma frame (168:110). Simulated; not market data.
abstract final class YourMarketMock {
  static const change24h = r'+$1.8M (4.27%)';
  static const unitLine = r'$0.4400 / unit · 100M supply';
  static const feesThisWeek = r'$42.80';
  static const price = r'$0.4400';
  static const skew = '58% long';
  static const openInterest = r'$3,140';
  static const funding = 'Longs pay shorts 0.01% in 3h 12m';
  static const holders = '142 holders';
  static const holderSplit = '82 long · 60 short';
  static const holdersChange = '+9 this week';
  static const recordSummary = '62 settled · 36 right · 26 wrong · 9 open';

  static const record = [
    RecordEntry(
      time: 'Thu 14:32',
      title: r'SOL reaches $300 by Fri',
      outcome: CallOutcome.right,
      odds: '22%',
    ),
    RecordEntry(
      time: 'Oct 2',
      title: r'ETH reaches $4,000 by Oct 2',
      outcome: CallOutcome.wrong,
      odds: '31%',
    ),
    RecordEntry(
      time: 'Mon 09:10',
      title: r'ETH reaches $4,000 by Oct 10',
      outcome: CallOutcome.open,
      odds: '31%',
    ),
  ];
}
