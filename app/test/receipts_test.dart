import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vista_colosseum/features/live/live_feed.dart';
import 'package:vista_colosseum/features/make_market/make_market_flow.dart';
import 'package:vista_colosseum/features/market/market_mock.dart';
import 'package:vista_colosseum/features/market/receipt_screens.dart';
import 'package:vista_colosseum/features/market/trader_market_screen.dart';
import 'package:vista_colosseum/features/market/your_market_screen.dart';
import 'package:vista_colosseum/features/portfolio/portfolio_mock.dart';
import 'package:vista_colosseum/features/profile/holdings_table.dart';
import 'package:vista_colosseum/features/profile/profile_screen.dart';
import 'package:vista_colosseum/features/settings/settings_state.dart';
import 'package:vista_colosseum/main.dart';
import 'package:vista_colosseum/scenario/scenario.dart';

import 'home_screen_test.dart' show expectPillClear;
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

Finder holding(String ticker) => find.descendant(
  of: find.byType(HoldingsTable),
  matching: find.text(ticker),
);

const noCall = 'No call in fixture-v1 backs this holding';

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
    // Seeded from Your market's record entries, with fixture provenance.
    expect(calls.map((c) => c.rule), [
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
    expect(find.textContaining(PortfolioMock.marketSymbol), findsWidgets);
    expect(find.text('Total'), findsOneWidget);
    expect(find.text(total), findsOneWidget);

    // The total is summed from the entries, never stored: drop one and
    // both the ledger and the Wallet row follow.
    final rest = entries.sublist(1);
    Scenario.feeEntries.value = rest;
    await tester.pumpAndSettle();
    expect(find.text(entries.first.eventTitle), findsNothing);
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
    for (final e in Scenario.feeEntries.value) {
      expect(find.text(e.eventTitle), findsNothing);
    }
    expect(find.text(formatCents(0)), findsOneWidget);
  });

  testWidgets('the 40% share is labelled a demo assumption, with one worked '
      'example, in the ledger and the listing flow', (tester) async {
    await pumpApp(tester, home: const LedgerScreen());
    expect(
      find.text('Illustrative demo ledger · 40% share is a demo assumption'),
      findsOneWidget,
    );
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
    expect(find.text('40% share is a demo assumption'), findsOneWidget);
  });

  testWidgets('the ledger total stays above the simulation pill on a small '
      'phone at 1.3x text', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pumpApp(
      tester,
      home: const LedgerScreen(),
      size: const Size(360, 640),
    );
    expectPillClear(
      tester,
      find.text(formatCents(sum(Scenario.feeEntries.value))),
    );
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
      expect(onReceipt(find.text(c.status)), findsOneWidget);
      expect(onReceipt(find.text(Scenario.fixtureVersion)), findsOneWidget);
      // The record states no entry price: shown as unavailable, not blank.
      expect(c.entryPrice, isNull);
      expect(onReceipt(find.text('unavailable')), findsWidgets);
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
    await back(tester, CallReceiptScreen);
    await tapAndSettle(tester, holding('BTC'));
    expect(onReceipt(find.text('BTC')), findsOneWidget);
    expect(onReceipt(find.text(noCall)), findsOneWidget);
    // Direction, entry price and time, rule, result, settlement and odds.
    expect(onReceipt(find.text('unavailable')), findsNWidgets(7));
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

  testWidgets('every All receipts link opens the receipts list', (
    tester,
  ) async {
    await pumpApp(tester, home: const YourMarketScreen());
    await tapAndSettle(tester, find.text('All receipts ›'));
    expect(find.byType(ReceiptsScreen), findsOneWidget);
    expect(find.text('No paper orders yet'), findsOneWidget);
    await back(tester, ReceiptsScreen);

    // Another trader's lists: their calls only, never the user's orders.
    await pumpApp(tester, home: const ProfileScreen(handle: 'kaito.eth'));
    await tapAndSettle(tester, find.text('All receipts ›'));
    expect(find.byType(ReceiptsScreen), findsOneWidget);
    expect(
      find.text('No call receipts for kaito.eth in fixture-v1'),
      findsOneWidget,
    );
    expect(find.text('PAPER ORDER RECEIPTS'), findsNothing);
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
  });
}
