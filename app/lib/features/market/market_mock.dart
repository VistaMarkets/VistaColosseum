import 'package:flutter/painting.dart';

import '../../design_system/design_system.dart';
import '../../scenario/scenario.dart';
import '../portfolio/portfolio_mock.dart';
import '../portfolio/series_chart.dart';
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

  /// How the fixture's own [result] shows, ignoring the clock. A verdict
  /// that settles after the clock, or whose settlement date
  /// `Scenario.outcomeAt` cannot read, shows differently at the clock: to
  /// show a call as a record counts it, pass the outcome at the clock,
  /// `outcomeStatus(Scenario.outcomeAt(c, Scenario.clock.value))`, and the
  /// same to [outcomeColor] and [outcomeRail]; [outcomeDetail] also takes
  /// `c.odds`.
  String get status => outcomeStatus(result);

  /// Like [status]: the raw [result]'s colour, ignoring the clock.
  Color get color => outcomeColor(result);

  /// Like [status]: the raw [result]'s timeline rail, ignoring the clock.
  String get rail => outcomeRail(result);

  /// Like [status]: the raw [result]'s detail line, ignoring the clock.
  String get detail => outcomeDetail(result, odds);
}

/// A call's detail line: "published" while [o] is open, then its odds.
/// Called like [outcomeStatus], with the raw result or the outcome at the
/// clock (`Scenario.outcomeAt`).
String outcomeDetail(CallOutcome? o, String? odds) => o == CallOutcome.open
    ? 'published · at ${odds ?? unavailable}'
    : 'at ${odds ?? unavailable}';

/// How a call's outcome shows: its word, colour and timeline rail. Called
/// with the raw [CallReceipt.result], or with the outcome at the clock
/// (`Scenario.outcomeAt`) where a record counts it.
String outcomeStatus(CallOutcome? o) => switch (o) {
  CallOutcome.right => 'Right',
  CallOutcome.wrong => 'Wrong',
  CallOutcome.open => 'Open',
  null => unavailable,
};

/// [o]'s colour; called like [outcomeStatus].
Color outcomeColor(CallOutcome? o) => switch (o) {
  CallOutcome.right => VistaColors.long,
  CallOutcome.wrong => VistaColors.short,
  CallOutcome.open => VistaColors.fees,
  null => VistaColors.textMuted,
};

/// The design system has no rail for an unavailable outcome
/// (`VistaAssets` ships right, wrong and open only), so null shares the
/// Open rail; its status word and muted colour say "unavailable".
String outcomeRail(CallOutcome? o) => switch (o) {
  CallOutcome.right => VistaAssets.timelineRight,
  CallOutcome.wrong => VistaAssets.timelineWrong,
  CallOutcome.open || null => VistaAssets.timelineOpen,
};

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
  static const skew = '58% long';
  static const openInterest = r'$3,140';
  static const funding = 'Longs pay shorts 0.01% in 3h 12m';
  static const holders = '142 holders';
  static const holderSplit = '82 long · 60 short';
  static const holdersChange = '+9 this week';

  /// The creator's share of trading fees: the video's 40% (O-05, the
  /// video's economic copy, with no demo-assumption label).
  static const creatorSharePct = 40;
  static const shareLabel = '$creatorSharePct% creator share';

  /// The seeded market's (`HAS_MARKET`) cap: $44.0M in int cents, and what
  /// it moved by over each of `PortfolioMock.spans` (1h, 4h, 1D, 1W, 1M,
  /// All), in cents. A fresh listing has its own starting cap and no moves
  /// (`Scenario.ownCapCents`). The moves are fixture history, not a
  /// listing's start: the 1W line begins at $38.4M a week back, at
  /// [listedAt], and the 1M and All lines reach before it.
  static const seededCapCents = 4400000000;
  static const seededCapMovesCents = [
    -21000000,
    35000000,
    180000000,
    560000000,
    -230000000,
    3120000000,
  ];

  /// The market's supply in units: 100M, whole millions.
  static const supplyUnits = 100000000;

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
  /// call receipts' seed). The record states no entry prices. Each verdict
  /// settles at the start of its rule's deadline day (`Scenario.outcomeAt`
  /// reads whole days): Friday Sep 25, before the clock, and Oct 2, after
  /// it, so that call counts as open at the clock. Its entry
  /// date (Oct 2) is also after the clock, a fixture-v1 date left as is:
  /// the record never reads entry dates.
  static const record = [
    CallReceipt(
      id: 'maya-sol-300-fri',
      author: PortfolioMock.handle,
      asset: 'SOL',
      side: TradeSide.long,
      entryAt: 'Thu 14:32',
      rule: r'SOL reaches $300 by Fri',
      result: CallOutcome.right,
      settledAt: 'Sep 25',
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
      settledAt: 'Oct 2',
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

/// The user's own market cap in int cents, as every screen prints it:
/// tenths of a million from $1M ("$44.0M"), whole dollars below
/// ("$10,000"). Rounds half-up, so it takes non-negative cents only, and
/// caps from $999.95M up are out of the demo's range.
String formatCap(int cents) {
  assert(cents >= 0 && cents < 99995000000);
  if (cents >= 100000000) {
    final t = (cents + 5000000) ~/ 10000000;
    return '\$${t ~/ 10}.${t % 10}M';
  }
  final whole = ((cents + 50) ~/ 100).toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  return '\$$whole';
}

/// The cap's move from [startCents] to [endCents]: "+" for a rise or no
/// move, "−" for a fall, the move through [formatCap], then its share of
/// [startCents] in hundredths of a percent, half-up ("+$1.8M (4.27%)").
/// No percentage from a start of zero or less. The sign comes from the
/// exact move in cents, not the rounded amount, so a fall under 50 cents
/// prints "−$0"; no cap reaches it, since every cap and move is whole
/// dollars.
String formatCapChange(int startCents, int endCents) {
  final move = endCents - startCents;
  final sign = move < 0 ? '−' : '+';
  final amount = '$sign${formatCap(move.abs())}';
  if (startCents <= 0) return amount;
  final p = (move.abs() * 20000 + startCents) ~/ (2 * startCents);
  return '$amount (${p ~/ 100}.${(p % 100).toString().padLeft(2, '0')}%)';
}

/// One unit's price, the cap over [supplyUnits], in ten-thousandths of a
/// dollar, half-up ("$0.4400").
String formatUnitPrice(int capCents, int supplyUnits) {
  assert(capCents >= 0 && supplyUnits > 0);
  final t = (capCents * 100 + supplyUnits ~/ 2) ~/ supplyUnits;
  return '\$${t ~/ 10000}.${(t % 10000).toString().padLeft(4, '0')}';
}

/// The user's own cap over [span] (an index of `PortfolioMock.spans`), in
/// dollars for display only, ending at `Scenario.ownCapCents`; null with
/// no cap. The seed walks from cap − move to cap; a fresh listing has no
/// history, so its line is flat at the cap (not [bridgeSeries], which
/// wiggles even a zero move). Its 48 points repeat [bridgeSeries]'s
/// default `n` (spec 12); change both together.
List<double>? ownCapSeries(int span) {
  RangeError.checkValidIndex(span, PortfolioMock.spans);
  final cap = Scenario.ownCapCents;
  if (cap == null) return null;
  if (!Scenario.ownCapHasHistory) return List.filled(48, cap / 100);
  final move = Scenario.ownCapMoveCents(span);
  return bridgeSeries('cap/$span', (cap - move) / 100, cap / 100);
}
