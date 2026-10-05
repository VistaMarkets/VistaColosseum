// Phase 6 review iter 1 probe (reviewer-owned, not product code). Copied into
// mut-app/test/ and run there; never part of the app's suite.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vista_colosseum/features/live/live_feed.dart';
import 'package:vista_colosseum/features/market/market_mock.dart';
import 'package:vista_colosseum/features/market/receipt_screens.dart';
import 'package:vista_colosseum/features/portfolio/portfolio_mock.dart';
import 'package:vista_colosseum/features/profile/holdings_table.dart';
import 'package:vista_colosseum/features/profile/profile_screen.dart';
import 'package:vista_colosseum/features/settings/settings_state.dart';
import 'package:vista_colosseum/scenario/scenario.dart';

import 'home_screen_test.dart' show expectPillClear, pill;
import 'receipts_test.dart' show pumpApp, tapAndSettle, sum;

int total() => sum(Scenario.marketFees);

Future<void> _loadFonts() async {
  final loader = FontLoader('OpenRunde');
  for (final w in ['Regular', 'Medium', 'Semibold', 'Bold']) {
    final bytes = File('assets/fonts/OpenRunde-$w.otf').readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
}

void main() {
  setUpAll(_loadFonts);
  setUp(() {
    Scenario.reset(withMarket: true);
    SettingsState.reset();
  });

  for (final (name, size) in [
    ('360x640', const Size(360, 640)),
    ('375x667', const Size(375, 667)),
  ]) {
    testWidgets('PROBE ledger footer clear of pill $name 1.3x', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      // Many entries, so the list is longer than the screen.
      Scenario.feeEntries.value = [
        for (var i = 0; i < 4; i++) ...YourMarketMock.fees,
      ];
      await pumpApp(tester, home: const LedgerScreen(), size: size);
      final t = find.text(formatCents(total()));
      final label = find.text('Total');
      expectPillClear(tester, t);
      expectPillClear(tester, label);
      final p = tester.getRect(find.bySemanticsLabel(pill));
      final r = tester.getRect(t);
      // ignore: avoid_print
      print('PROBE $name total=${formatCents(total())} totalRect=$r '
          'labelRect=${tester.getRect(label)} pill=$p gap=${p.top - r.bottom} '
          'onScreen=${r.top >= 0 && r.bottom <= size.height} '
          'hit=${t.hitTestable().evaluate().length} '
          'exception=${tester.takeException()}');
      expect(r.bottom, lessThanOrEqualTo(p.top));
    });
  }

  testWidgets('PROBE changing one amount changes ledger and Wallet totals', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.bySemanticsLabel('Wallet'));
    await tester.pumpAndSettle();
    await tapAndSettle(tester, find.text('Fees from your market'));
    final before = formatCents(total());
    final seed = Scenario.feeEntries.value;
    final e = seed[2];
    Scenario.feeEntries.value = [
      ...seed.take(2),
      FeeEntry(
        id: e.id,
        marketId: e.marketId,
        eventTitle: e.eventTitle,
        amountCents: e.amountCents + 101,
        at: e.at,
      ),
      ...seed.skip(3),
    ];
    await tester.pumpAndSettle();
    final after = formatCents(total());
    // ignore: avoid_print
    print('PROBE amount-change before=$before after=$after');
    expect(after, isNot(before));
    expect(find.text(before), findsNothing);
    expect(find.text(after), findsOneWidget);
    expect(find.text(formatCents(e.amountCents + 101)), findsOneWidget);
    Navigator.of(tester.element(find.byType(LedgerScreen))).pop();
    await tester.pumpAndSettle();
    expect(find.text(after), findsOneWidget);
  });

  testWidgets('PROBE a receipt with missing fields renders unavailable', (
    tester,
  ) async {
    await pumpApp(
      tester,
      home: const CallReceiptScreen(
        receipt: CallReceipt(
          id: 'p',
          author: 'kaito.eth',
          asset: 'SOL',
          rule: 'probe rule',
          result: CallOutcome.right,
        ),
      ),
    );
    // Direction, Entry price, Entered, Settled, Market said.
    final n = find.text(unavailable).evaluate().length;
    // ignore: avoid_print
    print('PROBE missing-fields unavailable=$n');
    expect(n, 5);
    expect(find.text(''), findsNothing);
  });

  testWidgets('PROBE kaito.eth profile ETH holding does not open maya call', (
    tester,
  ) async {
    await pumpApp(tester, home: const ProfileScreen(handle: 'kaito.eth'));
    await tapAndSettle(
      tester,
      find.descendant(of: find.byType(HoldingsTable), matching: find.text('ETH')),
    );
    expect(find.byType(CallReceiptScreen), findsOneWidget);
    expect(find.text('No call in fixture-v1 backs this holding'), findsOneWidget);
    expect(find.text(r'ETH reaches $4,000 by Oct 10'), findsNothing);
    expect(find.text(PortfolioMock.handle), findsNothing);
  });
}
