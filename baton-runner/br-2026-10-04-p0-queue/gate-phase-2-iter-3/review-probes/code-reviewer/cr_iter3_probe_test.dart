// Review-only probe (code-reviewer, phase 2 iter 3). Not part of the suite.
// ignore_for_file: avoid_print
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vista_colosseum/design_system/design_system.dart';
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

Future<void> feedAmount(WidgetTester t, String typed) async {
  phone(t);
  await t.pumpWidget(const VistaColosseumApp());
  await t.pumpAndSettle();
  await t.tap(find.widgetWithText(VistaPillButton, 'Long').first);
  await t.pumpAndSettle();
  await t.enterText(find.widgetWithText(TextField, '200'), typed);
  await t.pumpAndSettle();
}

void main() {
  setUpAll(_loadFonts);
  setUp(Scenario.reset);

  for (final typed in ['184467440737095517', '4611686018427388104']) {
    testWidgets('FEED wrap with real fonts: $typed', (t) async {
      await feedAmount(t, typed);
      final ex1 = t.takeException();
      final field = t
          .widgetList<TextField>(find.byType(TextField))
          .map((f) => f.controller?.text)
          .toList();
      final labels = texts(t)
          .where((s) => s.startsWith('Long ') || s.contains('you lose') || s.contains('of ETH') || s.contains('funds'))
          .toList();
      final pct = t
          .widgetList<Semantics>(find.byType(Semantics))
          .map((s) => s.properties.value)
          .whereType<String>()
          .where((v) => v.contains('available'))
          .toList();
      print('FEED[$typed] field=$field labels=$labels pct=$pct exception=${ex1 != null}');
      final place = find.textContaining(RegExp(r'^Long \$'));
      if (t.widgetList(place).isEmpty) return;
      await t.tap(place.first);
      await t.pumpAndSettle();
      print('FEED[$typed] review=${texts(t).where((s) => s.startsWith(r'$') || s.contains('ETH')).toList()} exception=${t.takeException() != null}');
      await t.tap(find.text('Confirm'));
      await t.pumpAndSettle();
      final r = Scenario.receipts.value.single;
      print('FEED[$typed] receipt margin=${r.marginCents} fee=${r.feeCents} total=${r.totalCents} cash=${Scenario.cashCents.value}');
      print('FEED[$typed] toast=${texts(t).where((s) => s.contains('filled')).toList()} exception=${t.takeException() != null}');
    });
  }

  testWidgets('OT 13-digit BTC size with real fonts', (t) async {
    phone(t);
    await t.pumpWidget(MaterialApp(theme: VistaTheme.dark(), home: const AssetTradeScreen(ticker: 'BTC')));
    await t.pumpAndSettle();
    await t.tap(find.text('Long').last);
    await t.pumpAndSettle();
    final before = snap();
    final size = find.byWidgetPredicate((w) => w is TextField && (w.controller?.text.contains('.') ?? false) && !(w.controller!.text.contains(',')));
    await t.enterText(size.first, '1370000000000');
    await t.pump();
    final ex = t.takeException();
    print('OT texts=${texts(t).where((s) => s.contains('funds') || s.contains('Place') || s.contains(r'$') ).toList()} exception=${ex != null} ${ex ?? ''}');
    expect(snap(), equals(before));
  });

  test('STORE wrong-side exits and infinite product', () {
    final wrong = OrderIntent(
      actionId: 'w', symbol: 'ETH', name: 'Ethereum', side: TradeSide.long,
      units: 0.1, price: 2968.40, leverage: 10, takeProfit: 100, stopLoss: 5000,
    );
    print('STORE wrongSide problem=${Scenario.problem(wrong)} result=${Scenario.placeOrder(wrong).runtimeType}');
    final inf = OrderIntent(
      actionId: 'i', symbol: 'BTC', name: 'Bitcoin', side: TradeSide.long,
      units: 1e305, price: 67412, leverage: 10,
    );
    print('STORE infProduct notional=${inf.notionalCents} problem=${Scenario.problem(inf)}');
    final atMax = OrderIntent(
      actionId: 'm', symbol: 'BTC', name: 'Bitcoin', side: TradeSide.long,
      units: 1.37e12, price: 67412, leverage: 20,
    );
    print('STORE 1.37e12@20x notional=${atMax.notionalCents} margin=${atMax.marginCents} fee=${atMax.feeCents} problem=${Scenario.problem(atMax)}');
  });
}
