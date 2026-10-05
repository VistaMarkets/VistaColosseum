import 'package:flutter/painting.dart';

import '../../design_system/design_system.dart';
import '../../scenario/scenario.dart';
import '../portfolio/portfolio_mock.dart';
import '../trade/trade_mock.dart';

enum CallOutcome { right, wrong, open }

/// How a receipt shows a field the fixture doesn't state.
const unavailable = 'unavailable';

/// A published call's receipt (VC-REC-001): who called which asset, on
/// which side, from when, by what rule, and how it settled. A field the
/// fixture doesn't state is null and shows as [unavailable]. A call is not
/// an order: paper fills are `OrderReceipt`s, listed apart from these.
class CallReceipt {
  const CallReceipt({
    required this.id,
    required this.author,
    required this.asset,
    this.side,
    this.entryPrice,
    this.entryAt,
    this.rule,
    this.result,
    this.settledAt,
    this.odds,
    this.provenance = Scenario.fixtureVersion,
  });

  final String id;
  final String author;
  final String asset;
  final TradeSide? side;

  /// Entry price as a fixed-decimal string, e.g. r'$2,927.00'.
  final String? entryPrice;

  /// Entry and settlement times as the fixture states them ("Thu 14:32");
  /// nothing computes with them.
  final String? entryAt;
  final String? settledAt;

  /// The event rule or declared claim, e.g. r'ETH reaches $4,000 by Oct 10'.
  final String? rule;

  /// How the call settled; [CallOutcome.open] until it does.
  final CallOutcome? result;

  /// Implied odds when the call was made, e.g. "22%".
  final String? odds;

  /// The fixture the receipt comes from.
  final String provenance;

  String get status => switch (result) {
    CallOutcome.right => 'Right',
    CallOutcome.wrong => 'Wrong',
    CallOutcome.open => 'Open',
    null => unavailable,
  };

  Color get color => switch (result) {
    CallOutcome.right => VistaColors.long,
    CallOutcome.wrong => VistaColors.short,
    CallOutcome.open => VistaColors.fees,
    null => VistaColors.textMuted,
  };

  String get rail => switch (result) {
    CallOutcome.right => VistaAssets.timelineRight,
    CallOutcome.wrong => VistaAssets.timelineWrong,
    CallOutcome.open || null => VistaAssets.timelineOpen,
  };

  String get detail => result == CallOutcome.open
      ? 'published · at ${odds ?? unavailable}'
      : 'at ${odds ?? unavailable}';
}

/// One fee credit to a creator's market (VC-MKT-004): the creator's share
/// of what traders paid in fees during one demo market event.
class FeeEntry {
  const FeeEntry({
    required this.id,
    required this.marketId,
    required this.eventTitle,
    required this.amountCents,
    required this.at,
  });

  final String id;

  /// The market that earned it (its ticker, as `Scenario.marketId`).
  final String marketId;
  final String eventTitle;

  /// The credit, in int cents.
  final int amountCents;
  final DateTime at;
}

/// Mock content from the Figma frame (168:110). Simulated; not market data.
abstract final class YourMarketMock {
  static const change24h = r'+$1.8M (4.27%)';
  static const unitLine = r'$0.4400 / unit · 100M supply';
  static const price = r'$0.4400';
  static const skew = '58% long';
  static const openInterest = r'$3,140';
  static const funding = 'Longs pay shorts 0.01% in 3h 12m';
  static const holders = '142 holders';
  static const holderSplit = '82 long · 60 short';
  static const holdersChange = '+9 this week';
  static const recordSummary = '62 settled · 36 right · 26 wrong · 9 open';

  /// The creator's share of trading fees: the video's 40% (O-05). A demo
  /// assumption, not TPX economics; every place showing it says so.
  static const creatorSharePct = 40;
  static const shareLabel = '$creatorSharePct% share is a demo assumption';

  /// The ledger's seed, newest first: MAYA's credits this week, each the
  /// creator's share of one session's fees.
  static final fees = List<FeeEntry>.unmodifiable([
    for (final (i, day, hoursAgo, cents) in [
      (1, 'Saturday', 3, 1240),
      (2, 'Friday', 24, 860),
      (3, 'Thursday', 48, 1016),
      (4, 'Wednesday', 72, 640),
      (5, 'Tuesday', 96, 524),
    ])
      FeeEntry(
        id: 'fee-$i',
        marketId: PortfolioMock.marketSymbol,
        eventTitle: '$day trading session',
        amountCents: cents,
        at: TradeMock.chartEnd.subtract(Duration(hours: hoursAgo)),
      ),
  ]);

  /// The user's published calls, as Your market's record lists them (the
  /// call receipts' seed). The record states no entry prices or
  /// settlement times.
  static const record = [
    CallReceipt(
      id: 'maya-sol-300-fri',
      author: PortfolioMock.handle,
      asset: 'SOL',
      side: TradeSide.long,
      entryAt: 'Thu 14:32',
      rule: r'SOL reaches $300 by Fri',
      result: CallOutcome.right,
      odds: '22%',
    ),
    CallReceipt(
      id: 'maya-eth-4000-oct2',
      author: PortfolioMock.handle,
      asset: 'ETH',
      side: TradeSide.long,
      entryAt: 'Oct 2',
      rule: r'ETH reaches $4,000 by Oct 2',
      result: CallOutcome.wrong,
      odds: '31%',
    ),
    CallReceipt(
      id: 'maya-eth-4000-oct10',
      author: PortfolioMock.handle,
      asset: 'ETH',
      side: TradeSide.long,
      entryAt: 'Mon 09:10',
      rule: r'ETH reaches $4,000 by Oct 10',
      result: CallOutcome.open,
      odds: '31%',
    ),
  ];
}
