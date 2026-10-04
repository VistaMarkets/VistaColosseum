import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vista_colosseum/design_system/design_system.dart';
import 'package:vista_colosseum/features/account/account_state.dart';
import 'package:vista_colosseum/features/live/live_feed.dart';
import 'package:vista_colosseum/features/portfolio/portfolio_mock.dart';
import 'package:vista_colosseum/features/settings/settings_state.dart';
import 'package:vista_colosseum/features/trade/asset_trade_screen.dart';
import 'package:vista_colosseum/features/trade/order_ticket.dart';
import 'package:vista_colosseum/main.dart';
import 'package:vista_colosseum/scenario/scenario.dart';

import 'home_screen_test.dart' show phones;
import 'scenario_test.dart' show state;

/// The app's font, so text measures as on a device.
Future<void> _loadFonts() async {
  final loader = FontLoader('OpenRunde');
  for (final w in ['Regular', 'Medium', 'Semibold', 'Bold']) {
    final bytes = File('assets/fonts/OpenRunde-$w.otf').readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
}

void _phone(WidgetTester tester) {
  tester.view
    ..physicalSize = const Size(402, 874) * 3
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

/// [ticker]'s trade page with its order ticket open on Long.
Future<void> openTicket(WidgetTester tester, String ticker) async {
  _phone(tester);
  await tester.pumpWidget(
    MaterialApp(
      theme: VistaTheme.dark(),
      home: AssetTradeScreen(ticker: ticker),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Long').last);
  await tester.pumpAndSettle();
}

/// From the open ticket to its review.
Future<void> review(WidgetTester tester) async {
  await tester.tap(find.text('Place market long'));
  await tester.pumpAndSettle();
}

Finder inSheet(Finder f) =>
    find.descendant(of: find.byType(BottomSheet), matching: f);

void main() {
  setUpAll(_loadFonts);
  setUp(() {
    Scenario.reset();
    AccountState.listMarket('MAYA');
    SettingsState.reset();
  });

  final seedPositions = PortfolioMock.positions.length;

  testWidgets('double tap confirm places one position', (tester) async {
    await openTicket(tester, 'BTC');
    await review(tester);
    // The review shows what the store will take, before it takes it.
    expect(inSheet(find.text('Review order')), findsOneWidget);
    expect(inSheet(find.text('Bitcoin · BTC')), findsOneWidget);
    expect(inSheet(find.text('Long 10x')), findsOneWidget);
    expect(inSheet(find.text(r'$67,412.00')), findsOneWidget);
    expect(inSheet(find.text('Simulated — no real order')), findsOneWidget);
    final required = tester
        .widget<Text>(
          find.descendant(
            of: find.byKey(const ValueKey('Paper funds required')),
            matching: find.textContaining(r'$'),
          ),
        )
        .data!;
    expect(Scenario.positions.value, hasLength(seedPositions));

    await tester.tap(find.text('Confirm'));
    await tester.tap(find.text('Confirm'));
    await tester.pump();

    expect(Scenario.positions.value, hasLength(seedPositions + 1));
    expect(Scenario.receipts.value, hasLength(1));
    final receipt = Scenario.receipts.value.single;
    expect(
      Scenario.cashCents.value,
      PortfolioMock.cashCents - receipt.totalCents,
    );
    // Review, receipt and toast agree to the cent.
    expect(required, formatCents(receipt.totalCents));
    expect(inSheet(find.text('Order filled')), findsOneWidget);
    expect(inSheet(find.text(required)), findsOneWidget);
    expect(find.textContaining('Bitcoin long filled'), findsOneWidget);
    expect(find.text('View in Wallet'), findsWidgets);
  });

  testWidgets('cancel from review leaves the store unchanged', (tester) async {
    final before = state();
    await openTicket(tester, 'BTC');
    expect(state(), equals(before)); // opening changes nothing
    await review(tester);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.byType(OrderTicket), findsNothing);
    expect(state(), equals(before));
  });

  testWidgets('a stale price fails with no position; Retry fills once', (
    tester,
  ) async {
    await openTicket(tester, 'AVAX');
    await review(tester);
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(inSheet(find.text('Price expired')), findsOneWidget);
    expect(Scenario.positions.value, hasLength(seedPositions));
    expect(Scenario.cashCents.value, PortfolioMock.cashCents);
    expect(Scenario.receipts.value, isEmpty);

    await tester.tap(find.text('Retry'));
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(inSheet(find.text('Order filled')), findsOneWidget);
    expect(Scenario.positions.value, hasLength(seedPositions + 1));
    expect(Scenario.receipts.value, hasLength(1));
    expect(Scenario.positions.value.first.title, 'Avalanche');
  });

  testWidgets('feed ticket confirm adds a position and View in Wallet shows '
      'it', (tester) async {
    _phone(tester);
    await tester.pumpWidget(const VistaColosseumApp());
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(VistaPillButton, 'Long').first);
    await tester.pumpAndSettle();
    final before = state();
    await tester.tap(find.text(r'Long $200 · 2x'));
    await tester.pumpAndSettle();
    expect(inSheet(find.text('Review order')), findsOneWidget);
    expect(state(), equals(before)); // review changes nothing
    // $200 margin at 2x: $400 of ETH, a 5 bps fee of $0.20.
    expect(inSheet(find.text(r'$200.20')), findsOneWidget);
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(Scenario.positions.value, hasLength(seedPositions + 1));
    expect(Scenario.cashCents.value, PortfolioMock.cashCents - 20020);
    expect(Scenario.positions.value.first.marginCents, 20000);

    await tester.tap(inSheet(find.text('View in Wallet')));
    await tester.pumpAndSettle();
    expect(find.text('Positions · ${seedPositions + 1}'), findsOneWidget);
  });

  for (final MapEntry(key: name, value: (size, padding)) in phones.entries) {
    testWidgets('review and receipt render without overflow on $name', (
      tester,
    ) async {
      tester.view
        ..physicalSize = size * 3
        ..devicePixelRatio = 3
        ..padding = FakeViewPadding(
          top: padding.top * 3,
          bottom: padding.bottom * 3,
        );
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: VistaTheme.dark(),
          home: const AssetTradeScreen(ticker: 'BTC'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Long').last);
      await tester.pumpAndSettle();
      await review(tester);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      expect(inSheet(find.text('Order filled')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('a trader-index ticket says so and creates nothing', (
    tester,
  ) async {
    _phone(tester);
    await tester.pumpWidget(const VistaColosseumApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('kaito.eth'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('market'));
    await tester.pumpAndSettle();
    final before = state();
    await tester.tap(find.text('Long').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Place market long'));
    await tester.pumpAndSettle();
    expect(
      find.text('Trader-index ticket — not in the demo yet'),
      findsOneWidget,
    );
    expect(find.byType(OrderTicket), findsNothing);
    expect(state(), equals(before));
  });
}
