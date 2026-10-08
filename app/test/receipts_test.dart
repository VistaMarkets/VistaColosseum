import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vista_colosseum/design_system/design_system.dart';
import 'package:vista_colosseum/features/account/account_state.dart';
import 'package:vista_colosseum/features/live/live_feed.dart';
import 'package:vista_colosseum/features/make_market/make_market_flow.dart';
import 'package:vista_colosseum/features/market/market_mock.dart';
import 'package:vista_colosseum/features/market/receipt_screens.dart';
import 'package:vista_colosseum/features/market/trader_market_screen.dart';
import 'package:vista_colosseum/features/market/your_market_screen.dart';
import 'package:vista_colosseum/features/portfolio/portfolio_mock.dart';
import 'package:vista_colosseum/features/profile/holdings_table.dart';
import 'package:vista_colosseum/features/profile/profile_mock.dart';
import 'package:vista_colosseum/features/profile/profile_screen.dart';
import 'package:vista_colosseum/features/settings/settings_state.dart';
import 'package:vista_colosseum/main.dart';
import 'package:vista_colosseum/scenario/scenario.dart';

import 'home_screen_test.dart' show expectPillClear, pill;
import 'scenario_test.dart' show ethLong;

/// The app's font, so text measures as on a device.
Future<void> _loadFonts() async {
  final loader = FontLoader('OpenRunde');
  for (final w in ['Regular', 'Medium', 'Semibold', 'Bold']) {
    final bytes = File('assets/fonts/OpenRunde-$w.otf').readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
}

/// Pumps the app (or [home] inside the real app builder) on a phone of
/// [size]; the default is tall enough that whole screens build.
Future<void> pumpApp(
  WidgetTester tester, {
  Widget? home,
  Size size = const Size(402, 1600),
}) async {
  tester.view
    ..physicalSize = size * 3
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    home == null ? const VistaColosseumApp() : VistaColosseumApp(home: home),
  );
  await tester.pumpAndSettle();
}

Future<void> tapAndSettle(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

/// Closes the top route, [screen].
Future<void> back(WidgetTester tester, Type screen) async {
  Navigator.of(tester.element(find.byType(screen))).pop();
  await tester.pumpAndSettle();
}

int sum(Iterable<FeeEntry> entries) =>
    entries.fold(0, (total, e) => total + e.amountCents);

/// The user's own call receipts, as the store holds them.
List<CallReceipt> get myCalls => [
  for (final c in Scenario.callReceipts.value)
    if (c.author == PortfolioMock.handle) c,
];

Finder onReceipt(Finder f) =>
    find.descendant(of: find.byType(CallReceiptScreen), matching: f);

Finder onList(Finder f) =>
    find.descendant(of: find.byType(ReceiptsScreen), matching: f);

Finder holding(String ticker) => find.descendant(
  of: find.byType(HoldingsTable),
  matching: find.text(ticker),
);

const noCall = 'No open call in fixture-v1 backs this holding';

void main() {
  setUpAll(_loadFonts);

  setUp(() {
    Scenario.reset(withMarket: true);
    SettingsState.reset();
  });

  test('the store seeds 4-6 fee entries and the record\'s call receipts; '
      'reset restores both', () {
    final fees = Scenario.feeEntries.value;
    final calls = Scenario.callReceipts.value;
    expect(fees.length, inInclusiveRange(4, 6));
    for (final e in fees) {
      expect(e.marketId, PortfolioMock.marketSymbol);
      expect(e.amountCents, isPositive);
      expect(e.eventTitle, isNotEmpty);
    }
    // The user's are Your market's record entries; every call has fixture
    // provenance.
    expect(myCalls.map((c) => c.rule), [
      r'SOL reaches $300 by Fri',
      r'ETH reaches $4,000 by Oct 2',
      r'ETH reaches $4,000 by Oct 10',
    ]);
    expect(calls.map((c) => c.provenance).toSet(), {Scenario.fixtureVersion});

    Scenario.feeEntries.value = const [];
    Scenario.callReceipts.value = const [];
    Scenario.reset(withMarket: true);
    expect(Scenario.feeEntries.value, same(fees));
    expect(Scenario.callReceipts.value, same(calls));
  });

  testWidgets('ledger total equals the sum of listed entries', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.bySemanticsLabel('Wallet'));
    await tester.pumpAndSettle();
    final entries = Scenario.feeEntries.value;
    final total = formatCents(sum(entries));
    expect(find.text(total), findsOneWidget);

    await tapAndSettle(tester, find.text('Fees from your market'));
    expect(find.byType(LedgerScreen), findsOneWidget);
    for (final e in entries) {
      expect(find.text(e.eventTitle), findsOneWidget);
      expect(find.text(formatCents(e.amountCents)), findsOneWidget);
    }
    // Each row names its market; the worked example's "on MAYA" is not
    // a row.
    expect(
      find.textContaining('${PortfolioMock.marketSymbol} · '),
      findsNWidgets(entries.length),
    );
    expect(find.text('Total'), findsOneWidget);
    expect(find.text(total), findsOneWidget);

    // The total is summed from the entries, never stored: drop one and
    // both the ledger and the Wallet row follow.
    final rest = entries.sublist(1);
    Scenario.feeEntries.value = rest;
    await tester.pumpAndSettle();
    expect(find.text(entries.first.eventTitle), findsNothing);
    // The worked example follows: it now works the newest listed credit.
    expect(find.text(LedgerScreen.example(entries.first)), findsNothing);
    expect(find.text(LedgerScreen.example(rest.first)), findsOneWidget);
    expect(find.text(total), findsNothing);
    expect(find.text(formatCents(sum(rest))), findsOneWidget);
    await back(tester, LedgerScreen);
    expect(find.text(formatCents(sum(rest))), findsOneWidget);
  });

  testWidgets('Your market fee chip shows the ledger sum and opens the '
      'ledger', (tester) async {
    await pumpApp(tester, home: const YourMarketScreen());
    final total = formatCents(sum(Scenario.feeEntries.value));
    expect(find.text('earned in fees this week'), findsOneWidget);
    expect(find.text(total), findsOneWidget);
    await tapAndSettle(tester, find.text(total));
    expect(find.byType(LedgerScreen), findsOneWidget);
    expect(find.text('Total'), findsOneWidget);
  });

  testWidgets('a market with no credits shows an empty ledger and zero', (
    tester,
  ) async {
    // Credits belong to the market that earned them, not a new listing.
    Scenario.marketId.value = 'ZED';
    await pumpApp(tester, home: const YourMarketScreen());
    await tapAndSettle(tester, find.text(formatCents(0)));
    expect(find.byType(LedgerScreen), findsOneWidget);
    // Neither as a row nor as the worked example.
    for (final e in Scenario.feeEntries.value) {
      expect(find.text(e.eventTitle), findsNothing);
      expect(find.text(LedgerScreen.example(e)), findsNothing);
    }
    expect(find.text(formatCents(0)), findsOneWidget);
  });

  testWidgets('a copy fee with no market credits shows no empty state and '
      'is the total', (tester) async {
    // Listed fresh at the demo's now: every seeded credit predates it, so
    // the copy row below is the only entry listed.
    Scenario.reset(withMarket: false);
    AccountState.listMarket(PortfolioMock.marketSymbol);
    expect(Scenario.marketFees, isEmpty);
    final copy = FeeEntry(
      id: 'copy-test',
      marketId: PortfolioMock.marketSymbol,
      eventTitle: 'Copy fee',
      amountCents: kCopyFeeCents,
      at: Scenario.clock.value,
      kind: FeeKind.copyFee,
      counterparty: PortfolioMock.copierHandle,
      asset: 'ETH',
    );
    Scenario.feeEntries.value = [copy, ...Scenario.feeEntries.value];
    await pumpApp(tester, home: const LedgerScreen());
    expect(find.text('No fee credits yet'), findsNothing);
    expect(find.text('COPY FEES'), findsOneWidget);
    expect(
      find.text('Copy fee · @${PortfolioMock.copierHandle} · ETH'),
      findsOneWidget,
    );
    // The row and the Total agree; the Wallet row and chip stay at the
    // market credits (spec 06), here none.
    expect(find.text(formatCents(kCopyFeeCents)), findsNWidgets(2));
    expect(Scenario.marketFeesCents, 0);
  });

  test('a fresh listing earns nothing until a credit lands after it; the '
      'HAS_MARKET seed counts its week; reset restores both', () {
    // The HAS_MARKET seed: listed before every seeded credit.
    final seeded = sum(Scenario.feeEntries.value);
    expect(Scenario.marketFeesCents, seeded);

    // Listed fresh at the demo's now: every seeded credit predates it.
    Scenario.reset(withMarket: false);
    AccountState.listMarket(PortfolioMock.marketSymbol);
    expect(Scenario.marketFees, isEmpty);
    expect(Scenario.marketFeesCents, 0);

    // A credit dated at the listing instant counts.
    final credit = FeeEntry(
      id: 'fee-new',
      marketId: PortfolioMock.marketSymbol,
      eventTitle: 'New session',
      amountCents: 300,
      at: Scenario.clock.value,
    );
    Scenario.feeEntries.value = [credit, ...Scenario.feeEntries.value];
    expect(Scenario.marketFees, [credit]);
    expect(Scenario.marketFeesCents, 300);

    Scenario.reset(withMarket: true);
    expect(Scenario.marketFeesCents, seeded);
    Scenario.reset(withMarket: false);
    AccountState.listMarket(PortfolioMock.marketSymbol);
    expect(Scenario.marketFeesCents, 0);
  });

  testWidgets('the 40% share shows with one worked example and no '
      'demo-assumption label, in the ledger and the listing flow', (
    tester,
  ) async {
    await pumpApp(tester, home: const LedgerScreen());
    expect(
      find.text('Illustrative demo ledger · 40% creator share'),
      findsOneWidget,
    );
    expect(find.textContaining('demo assumption'), findsNothing);
    // The example works the newest credit back from its fee: fee × 40%.
    final first = Scenario.feeEntries.value.first;
    final fee = first.amountCents * 100 ~/ 40;
    expect(
      find.textContaining(
        '40% of ${formatCents(fee)} = ${formatCents(first.amountCents)}',
      ),
      findsOneWidget,
    );

    Scenario.reset(withMarket: false);
    await pumpApp(tester, home: const MakeMarketFlow());
    await tapAndSettle(tester, find.text(r'Continue with $MAYA'));
    expect(find.text('You earn 40% of the fees from both'), findsOneWidget);
    expect(find.textContaining('demo assumption'), findsNothing);
    expect(find.text(YourMarketMock.shareLabel), findsNothing);
  });

  test('the worked example prints the listed credit for an odd-cent '
      'entry', () {
    final odd = FeeEntry(
      id: 'fee-odd',
      marketId: PortfolioMock.marketSymbol,
      eventTitle: 'Odd session',
      amountCents: 1241,
      at: DateTime(2026, 9, 26),
    );
    // 1241 ÷ 40%, rounded half up, is a $31.03 fee; the result is the
    // listed $12.41 credit, not one recomputed from the fee.
    expect(
      LedgerScreen.example(odd),
      contains(r'traders paid $31.03 in fees. 40% of $31.03 = $12.41,'),
    );
  });

  testWidgets('the ledger total stays above the simulation pill on a small '
      'phone at 1.3x text', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    for (final size in const [Size(360, 640), Size(375, 667)]) {
      await pumpApp(tester, home: const LedgerScreen(), size: size);
      final total = find.text(formatCents(sum(Scenario.feeEntries.value)));
      expectPillClear(tester, total);
      // Above the pill's strip, not merely beside the pill.
      final pillTop = tester.getRect(find.bySemanticsLabel(pill)).top;
      for (final row in [total, find.text('Total')]) {
        expect(tester.getRect(row).bottom, lessThanOrEqualTo(pillTop));
      }
    }
  });

  testWidgets('each record item opens its call receipt', (tester) async {
    await pumpApp(tester, home: const YourMarketScreen());
    expect(myCalls, hasLength(YourMarketMock.record.length));
    for (final c in myCalls) {
      await tapAndSettle(tester, find.text(c.rule!));
      expect(find.byType(CallReceiptScreen), findsOneWidget);
      expect(onReceipt(find.text(c.rule!)), findsOneWidget);
      expect(onReceipt(find.text(c.author)), findsOneWidget);
      expect(onReceipt(find.text(c.asset)), findsOneWidget);
      final o = Scenario.outcomeAt(c, Scenario.clock.value);
      expect(onReceipt(find.text(outcomeStatus(o))), findsOneWidget);
      expect(onReceipt(find.text(noCall)), findsNothing);
      expect(
        onReceipt(find.text('A published call, not an order fill')),
        findsOneWidget,
      );
      expect(onReceipt(find.text(Scenario.fixtureVersion)), findsOneWidget);
      expect(onReceipt(find.text(c.side!.label)), findsOneWidget);
      final open = o == CallOutcome.open;
      final dates = [c.entryAt!, if (!open) c.settledAt!];
      for (final d in dates.toSet()) {
        expect(
          onReceipt(find.text(d)),
          findsNWidgets(dates.where((x) => x == d).length),
        );
      }
      expect(onReceipt(find.text(c.odds!)), findsOneWidget);
      // The record states no entry price or paper size: shown as
      // unavailable, not blank.
      expect(c.entryPrice, isNull);
      expect(
        onReceipt(find.text('Not settled yet')),
        open ? findsOneWidget : findsNothing,
      );
      expect(onReceipt(find.text('Paper size')), findsOneWidget);
      expect(c.sizeCents, isNull);
      expect(onReceipt(find.text('unavailable')), findsNWidgets(2));
      await back(tester, CallReceiptScreen);
    }

    // Call details: maya.eth's open ETH long call backs her ETH holding;
    // nothing in the fixture backs the BTC short.
    final eth = myCalls.singleWhere(
      (c) => c.asset == 'ETH' && c.result == CallOutcome.open,
    );
    await pumpApp(
      tester,
      home: const ProfileScreen(handle: PortfolioMock.handle),
    );
    await tapAndSettle(tester, holding('ETH'));
    expect(onReceipt(find.text(eth.rule!)), findsOneWidget);
    expect(onReceipt(find.text(noCall)), findsNothing);
    expect(
      onReceipt(find.text('A published call, not an order fill')),
      findsOneWidget,
    );
    await back(tester, CallReceiptScreen);
    await tapAndSettle(tester, holding('BTC'));
    expect(onReceipt(find.text('BTC')), findsOneWidget);
    expect(onReceipt(find.text(noCall)), findsOneWidget);
    // Direction, entry price, paper size, entry time, rule, result,
    // settlement and odds.
    expect(onReceipt(find.text('unavailable')), findsNWidgets(8));
    await back(tester, CallReceiptScreen);
    // Her SOL call settled Right, so no open call backs the SOL holding.
    final sol = myCalls.singleWhere((c) => c.asset == 'SOL');
    expect(sol.result, CallOutcome.right);
    await tapAndSettle(tester, holding('SOL'));
    expect(onReceipt(find.text(noCall)), findsOneWidget);
    expect(onReceipt(find.text(sol.rule!)), findsNothing);
    await back(tester, CallReceiptScreen);

    // Another trader's profile: maya.eth's ETH call backs only her own.
    await pumpApp(tester, home: const ProfileScreen(handle: 'kaito.eth'));
    await tapAndSettle(tester, holding('ETH'));
    expect(onReceipt(find.text('kaito.eth')), findsOneWidget);
    expect(onReceipt(find.text(noCall)), findsOneWidget);
    expect(onReceipt(find.text(eth.rule!)), findsNothing);
    await back(tester, CallReceiptScreen);

    // The trader market's Portfolio panel: another trader, no seeded calls.
    await pumpApp(tester, home: const TraderMarketScreen(handle: 'kaito.eth'));
    await tester.fling(find.byType(PageView), const Offset(-300, 0), 1500);
    await tester.pumpAndSettle();
    await tapAndSettle(tester, holding('SOL'));
    expect(onReceipt(find.text('kaito.eth')), findsOneWidget);
    expect(onReceipt(find.text('SOL')), findsOneWidget);
    expect(onReceipt(find.text(noCall)), findsOneWidget);
    await back(tester, CallReceiptScreen);
    // maya.eth's open ETH call backs only her own ETH holding.
    await tapAndSettle(tester, holding('ETH'));
    expect(onReceipt(find.text(noCall)), findsOneWidget);
    expect(onReceipt(find.text(eth.rule!)), findsNothing);
  });

  testWidgets('Call details match the holding side: a short ETH holding is '
      'not backed by an open ETH long', (tester) async {
    await tester.pumpWidget(const SizedBox());
    final context = tester.element(find.byType(SizedBox));
    String backingId(TradeSide side) {
      final eth = Holding(
        ticker: 'ETH',
        side: side,
        leverage: 3,
        entry: r'$2,927',
        current: r'$2,968',
        pnl: '+4.2%',
      );
      final route = CallReceiptScreen.forHolding(PortfolioMock.handle, eth);
      final screen = (route as MaterialPageRoute<void>).builder(context);
      return (screen as CallReceiptScreen).receipt.id;
    }

    final open = myCalls.singleWhere(
      (c) => c.asset == 'ETH' && c.result == CallOutcome.open,
    );
    expect(open.side, TradeSide.long);
    expect(backingId(TradeSide.long), open.id);
    expect(backingId(TradeSide.short), 'none');
  });

  testWidgets('order receipts and call receipts render in separate sections', (
    tester,
  ) async {
    final fill = Scenario.placeOrder(ethLong('r-1')) as OrderFilled;
    await pumpApp(tester, home: const YourMarketScreen());
    await tapAndSettle(tester, find.text('All receipts ›'));
    expect(find.byType(ReceiptsScreen), findsOneWidget);

    final calls = tester.getRect(find.text('CALL RECEIPTS'));
    final orders = tester.getRect(find.text('PAPER ORDER RECEIPTS'));
    expect(calls.top, lessThan(orders.top));
    for (final c in myCalls) {
      final y = tester.getRect(find.text(c.rule!)).top;
      expect(y, greaterThan(calls.bottom));
      expect(y, lessThan(orders.top));
    }
    final order = find.text('Long ETH 10x');
    expect(tester.getRect(order).top, greaterThan(orders.bottom));
    expect(
      find.textContaining(formatCents(fill.receipt.notionalCents)),
      findsOneWidget,
    );
    // An order receipt is not a call: tapping it opens no call receipt.
    await tapAndSettle(tester, order);
    expect(find.byType(CallReceiptScreen), findsNothing);
    // A call still opens its own receipt from the list.
    await tapAndSettle(tester, find.text(myCalls.first.rule!));
    expect(find.byType(CallReceiptScreen), findsOneWidget);
  });

  testWidgets('the record and receipts lists read the call receipt store', (
    tester,
  ) async {
    final dropped = myCalls.first;
    Scenario.callReceipts.value = myCalls.sublist(1);
    await pumpApp(tester, home: const YourMarketScreen());
    expect(find.text(dropped.rule!), findsNothing);
    for (final c in myCalls) {
      expect(find.text(c.rule!), findsOneWidget);
    }
    await tapAndSettle(tester, find.text('All receipts ›'));
    expect(onList(find.text(dropped.rule!)), findsNothing);
    for (final c in myCalls) {
      expect(onList(find.text(c.rule!)), findsOneWidget);
    }
  });

  testWidgets('every All receipts link opens the receipts list', (
    tester,
  ) async {
    await pumpApp(tester, home: const YourMarketScreen());
    await tapAndSettle(tester, find.text('All receipts ›'));
    expect(find.byType(ReceiptsScreen), findsOneWidget);
    expect(find.text('No paper orders yet'), findsOneWidget);
    await back(tester, ReceiptsScreen);

    // Another trader's lists: their calls only, never the user's orders,
    // with a paper order in state to leak.
    Scenario.placeOrder(ethLong('r-2'));
    expect(Scenario.receipts.value, isNotEmpty);
    // A profile with no calls has no CALLS heading to link from; the empty
    // list is reached from the trader market below.
    await pumpApp(tester, home: const ProfileScreen(handle: 'kestrel'));
    await tapAndSettle(tester, find.text('All receipts ›'));
    expect(find.byType(ReceiptsScreen), findsOneWidget);
    expect(onList(find.text(r'BTC reaches $72,000 by Oct 3')), findsOneWidget);
    expect(find.text('PAPER ORDER RECEIPTS'), findsNothing);
    expect(onList(find.text('Long ETH 10x')), findsNothing);
    expect(onList(find.textContaining('Paper fill')), findsNothing);
    for (final c in myCalls) {
      expect(find.text(c.rule!), findsNothing);
    }
    await back(tester, ReceiptsScreen);

    await pumpApp(tester, home: const TraderMarketScreen(handle: 'kaito.eth'));
    for (var i = 0; i < 2; i++) {
      await tester.fling(find.byType(PageView), const Offset(-300, 0), 1500);
      await tester.pumpAndSettle();
    }
    await tapAndSettle(tester, find.text('All receipts ›'));
    expect(find.byType(ReceiptsScreen), findsOneWidget);
    expect(
      find.text('No call receipts for kaito.eth in fixture-v1'),
      findsOneWidget,
    );
    expect(onList(find.text('Long ETH 10x')), findsNothing);
    expect(onList(find.textContaining('Paper fill')), findsNothing);
  });
}
