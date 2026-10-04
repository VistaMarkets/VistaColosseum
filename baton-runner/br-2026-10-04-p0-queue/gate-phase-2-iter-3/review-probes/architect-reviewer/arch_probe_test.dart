// Review-only probe (architect-reviewer, phase 2 iter 3). Not part of the suite.
// ignore_for_file: avoid_print
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vista_colosseum/design_system/design_system.dart';
import 'package:vista_colosseum/features/account/account_state.dart';
import 'package:vista_colosseum/features/live/live_feed.dart';
import 'package:vista_colosseum/features/settings/settings_state.dart';
import 'package:vista_colosseum/features/trade/asset_trade_screen.dart';
import 'package:vista_colosseum/main.dart';
import 'package:vista_colosseum/scenario/scenario.dart';

Future<void> _loadFonts() async {
  final loader = FontLoader('OpenRunde');
  for (final w in ['Regular', 'Medium', 'Semibold', 'Bold']) {
    final bytes = File('assets/fonts/OpenRunde-$w.otf').readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
}

List<Object?> snap() => [
  Scenario.cashCents.value,
  Scenario.positions.value,
  Scenario.receipts.value,
  Scenario.openOrders.value,
];

void phone(WidgetTester t) {
  t.view
    ..physicalSize = const Size(402, 874) * 3
    ..devicePixelRatio = 3;
  addTearDown(t.view.reset);
}

List<String> texts(WidgetTester t) => t
    .widgetList<Text>(find.byType(Text))
    .map((w) => w.data)
    .whereType<String>()
    .toList();

Future<void> openFeed(WidgetTester t) async {
  phone(t);
  await t.pumpWidget(const VistaColosseumApp());
  await t.pumpAndSettle();
  await t.tap(find.widgetWithText(VistaPillButton, 'Long').first);
  await t.pumpAndSettle();
}

void main() {
  setUpAll(_loadFonts);
  setUp(() {
    Scenario.reset();
    AccountState.listMarket('MAYA');
    SettingsState.reset();
  });

  test('store: infinite product and wrong-side exits', () {
    final inf = OrderIntent(actionId: 'i', symbol: 'BTC', name: 'Bitcoin',
        side: TradeSide.long, units: 1e305, price: 67412, leverage: 1);
    print('ARCH infProduct units.isFinite=${inf.units.isFinite} notional=${inf.notionalCents} problem=${Scenario.problem(inf)}');
    final wrong = OrderIntent(actionId: 'w', symbol: 'ETH', name: 'Ethereum',
        side: TradeSide.long, units: 0.1, price: 2968.40, leverage: 10,
        takeProfit: 2000, stopLoss: 3500);
    print('ARCH wrongSideExits problem=${Scenario.problem(wrong)}');
    final r = Scenario.placeOrder(wrong);
    print('ARCH wrongSideExits result=${r.runtimeType} tp=${Scenario.positions.value.first.detail.takeProfit} sl=${Scenario.positions.value.first.detail.stopLoss} entry=${Scenario.positions.value.first.detail.entry}');
  });

  for (final typed in [
    '184467440737095517',
    '99999999999999999',
    '92233720368547759',
    '50000000000000000',
    '1.2.3',
    '12480',
  ]) {
    testWidgets('feed amount "$typed" with fonts', (t) async {
      await openFeed(t);
      final before = snap();
      await t.enterText(find.widgetWithText(TextField, '200'), typed);
      await t.pumpAndSettle();
      final ex = t.takeException();
      final labels = texts(t).where((s) => s.startsWith('Long ') ||
          s.contains('funds') || s.contains('Enter') || s.contains('Size') ||
          s.startsWith('you lose')).toList();
      final field = t.widget<TextField>(find.byType(TextField).first).controller?.text;
      print('ARCH feed typed=$typed field=$field labels=$labels exception=${ex == null ? 'none' : ex.toString().split('\n').first}');
      expect(snap(), equals(before));
    });
  }

  for (final typed in ['1370000000000', '1${'0' * 305}']) {
    testWidgets('OrderTicket size ${typed.length} digits with fonts', (t) async {
      phone(t);
      await t.pumpWidget(MaterialApp(theme: VistaTheme.dark(),
          home: const AssetTradeScreen(ticker: 'BTC')));
      await t.pumpAndSettle();
      await t.tap(find.text('Long').last);
      await t.pumpAndSettle();
      final before = snap();
      await t.enterText(find.byType(TextField).first, typed);
      await t.pump();
      final ex = t.takeException();
      final labels = texts(t).where((s) => s.contains('funds') ||
          s.startsWith('Place') || s.contains('Size too') || s.startsWith(r'$')).toList();
      print('ARCH OT digits=${typed.length} labels=$labels exception=${ex == null ? 'none' : ex.toString().split('\n').first}');
      expect(snap(), equals(before));
    });
  }

  testWidgets('Wallet headline vs change line after a live tick', (t) async {
    phone(t);
    await t.pumpWidget(const VistaColosseumApp());
    await t.pumpAndSettle();
    await t.tap(find.bySemanticsLabel('Wallet'));
    await t.pumpAndSettle();
    String change() => texts(t).firstWhere((s) => RegExp(r'^[+−]\$[0-9,]+ \(').hasMatch(s));
    print('ARCH wallet seed headline=${find.text(r'$12,480.00').evaluate().length}x change=${change()}');
    final feed = LiveFeed.watch('portfolio', Scenario.cashCents.value / 100, 9) as ValueNotifier<double>;
    feed.value += 9;
    await t.pump();
    print('ARCH wallet tick headline=${find.text(r'$12,480.00').evaluate().length}x change=${change()}');
  });
}
