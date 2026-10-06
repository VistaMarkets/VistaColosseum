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
    this.sizeCents,
    this.provenance = Scenario.fixtureVersion,
  });

  final String id;
  final String author;
  final String asset;
  final TradeSide? side;

  /// Entry price as a fixed-decimal string, e.g. r'$2,927.00'.
  final String? entryPrice;

  /// Entry and settlement times as the fixture states them ("Thu 14:32").
  /// `Scenario.record` reads a settlement time in the "Sep 12" form only, to
  /// place the verdict against the clock; a verdict whose settlement time is
  /// missing or in another form counts as unavailable.
  final String? entryAt;
  final String? settledAt;

  /// The event rule or declared claim, e.g. r'ETH reaches $4,000 by Oct 10'.
  final String? rule;

  /// How the call settled; [CallOutcome.open] until it does.
  final CallOutcome? result;

  /// Implied odds when the call was made, e.g. "22%".
  final String? odds;

  /// The paper trade the author put behind the call, in int cents. Shown
  /// on the receipt; a trader's record never reads it (`Scenario.record`).
  final int? sizeCents;

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
    this.kind = FeeKind.credit,
    this.sourceCallId,
    this.counterparty,
    this.asset,
  });

  final String id;

  /// The market that earned it (its ticker, as `Scenario.marketId`).
  final String marketId;
  final String eventTitle;

  /// The credit, in int cents.
  final int amountCents;
  final DateTime at;
  final FeeKind kind;

  /// A copy fee's call, who copied it, and on which asset.
  final String? sourceCallId;
  final String? counterparty;
  final String? asset;
}

/// A market's fee share, or a flat fee a copier paid to copy a call.
enum FeeKind { credit, copyFee }

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

  /// The creator's share of trading fees: the video's 40% (O-05). A demo
  /// assumption, not TPX economics; every place showing it says so.
  static const creatorSharePct = 40;
  static const shareLabel = '$creatorSharePct% share is a demo assumption';

  /// When the seeded market (`HAS_MARKET`) was listed: a week before the
  /// fixture's now, so this week's seeded credits all follow it.
  static final listedAt = TradeMock.chartEnd.subtract(const Duration(days: 7));

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

/// Other traders' published calls in fixture-v1. kilo.sol and lunaq have
/// the same outcomes, call for call, behind very different paper sizes, so
/// their records match (VC-MKT-002). kestrel has an open call and nothing
/// settled. nara's are the private profile's graded calls. Simulated.
const traderCalls = [
  CallReceipt(
    id: 'kilo-sol-180-sep12',
    author: 'kilo.sol',
    asset: 'SOL',
    side: TradeSide.long,
    entryPrice: r'$184.60',
    entryAt: 'Sep 8',
    rule: r'SOL holds $180 to Sep 12',
    result: CallOutcome.right,
    settledAt: 'Sep 12',
    odds: '62%',
    sizeCents: 50000,
  ),
  CallReceipt(
    id: 'kilo-btc-64k-sep18',
    author: 'kilo.sol',
    asset: 'BTC',
    side: TradeSide.short,
    entryPrice: r'$65,380.00',
    entryAt: 'Sep 14',
    rule: r'BTC loses $64,000 by Sep 18',
    result: CallOutcome.wrong,
    settledAt: 'Sep 18',
    odds: '35%',
    sizeCents: 120000,
  ),
  CallReceipt(
    id: 'kilo-eth-2800-sep24',
    author: 'kilo.sol',
    asset: 'ETH',
    side: TradeSide.long,
    entryPrice: r'$2,712.40',
    entryAt: 'Sep 19',
    rule: r'ETH reaches $2,800 by Sep 24',
    result: CallOutcome.right,
    settledAt: 'Sep 24',
    odds: '44%',
    sizeCents: 80000,
  ),
  CallReceipt(
    id: 'kilo-eth-3200-oct5',
    author: 'kilo.sol',
    asset: 'ETH',
    side: TradeSide.long,
    entryPrice: r'$2,941.10',
    entryAt: 'Sep 25',
    rule: r'ETH reaches $3,200 by Oct 5',
    result: CallOutcome.open,
    odds: '28%',
    sizeCents: 50000,
  ),
  CallReceipt(
    id: 'lunaq-btc-62k-sep9',
    author: 'lunaq',
    asset: 'BTC',
    side: TradeSide.long,
    entryPrice: r'$60,940.00',
    entryAt: 'Sep 5',
    rule: r'BTC reaches $62,000 by Sep 9',
    result: CallOutcome.right,
    settledAt: 'Sep 9',
    odds: '47%',
    sizeCents: 4000000,
  ),
  CallReceipt(
    id: 'lunaq-sol-170-sep17',
    author: 'lunaq',
    asset: 'SOL',
    side: TradeSide.short,
    entryPrice: r'$176.30',
    entryAt: 'Sep 13',
    rule: r'SOL loses $170 by Sep 17',
    result: CallOutcome.wrong,
    settledAt: 'Sep 17',
    odds: '29%',
    sizeCents: 9000000,
  ),
  CallReceipt(
    id: 'lunaq-eth-3000-sep23',
    author: 'lunaq',
    asset: 'ETH',
    side: TradeSide.short,
    entryPrice: r'$2,884.00',
    entryAt: 'Sep 18',
    rule: r'ETH stays under $3,000 to Sep 23',
    result: CallOutcome.right,
    settledAt: 'Sep 23',
    odds: '66%',
    sizeCents: 100000,
  ),
  CallReceipt(
    id: 'lunaq-eth-3200-oct5',
    author: 'lunaq',
    asset: 'ETH',
    side: TradeSide.short,
    entryPrice: r'$2,941.10',
    entryAt: 'Sep 25',
    rule: r'ETH stays under $3,200 to Oct 5',
    result: CallOutcome.open,
    odds: '72%',
    sizeCents: 2500000,
  ),
  CallReceipt(
    id: 'kestrel-btc-72k-oct3',
    author: 'kestrel',
    asset: 'BTC',
    side: TradeSide.long,
    entryPrice: r'$67,120.00',
    entryAt: 'Sep 26',
    rule: r'BTC reaches $72,000 by Oct 3',
    result: CallOutcome.open,
    odds: '19%',
    sizeCents: 300000,
  ),
  CallReceipt(
    id: 'nara-btc-64k-oct3',
    author: 'nara',
    asset: 'BTC',
    side: TradeSide.long,
    entryAt: 'Sep 25',
    rule: r'BTC holds $64,000 to Oct 3',
    result: CallOutcome.open,
    odds: '71%',
  ),
  CallReceipt(
    id: 'nara-sol-200-oct10',
    author: 'nara',
    asset: 'SOL',
    side: TradeSide.short,
    entryAt: 'Sep 25',
    rule: r'SOL loses $200 by Oct 10',
    result: CallOutcome.open,
    odds: '34%',
  ),
  CallReceipt(
    id: 'nara-btc-66k-tue',
    author: 'nara',
    asset: 'BTC',
    side: TradeSide.long,
    entryAt: 'Sep 19',
    rule: r'BTC reclaims $66,000 by Tue',
    result: CallOutcome.right,
    settledAt: 'Tue 16:00',
    odds: '29%',
  ),
  CallReceipt(
    id: 'nara-eth-3300-sep22',
    author: 'nara',
    asset: 'ETH',
    side: TradeSide.long,
    entryAt: 'Sep 17',
    rule: r'ETH reaches $3,300 by Sep 22',
    result: CallOutcome.wrong,
    settledAt: 'Sep 22',
    odds: '38%',
  ),
];

/// The call receipts' seed: the user's record, then other traders' calls.
final seedCalls = List<CallReceipt>.unmodifiable([
  ...YourMarketMock.record,
  ...traderCalls,
]);
