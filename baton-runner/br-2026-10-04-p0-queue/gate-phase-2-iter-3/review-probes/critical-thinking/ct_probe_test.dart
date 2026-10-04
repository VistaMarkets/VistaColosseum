// Review-only probe (phase 2 review iter 3, critical-thinking). Not part of the suite.
// ignore_for_file: avoid_print
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vista_colosseum/design_system/design_system.dart';
import 'package:vista_colosseum/features/account/account_state.dart';
import 'package:vista_colosseum/features/live/live_feed.dart';
import 'package:vista_colosseum/features/live/market_prices.dart';
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

void phone(WidgetTester t, [Size s = const Size(402, 874), double top = 0]) {
  t.view
    ..physicalSize = s * 3
    ..devicePixelRatio = 3
    ..padding = FakeViewPadding(top: top * 3);
  addTearDown(t.view.reset);
}

int drain(WidgetTester t) {
  var n = 0;
  Object? e;
  while ((e = t.takeException()) != null) {
    n++;
    print('  exception: ${e.toString().split('\n').first}');
  }
  return n;
}

List<String> texts(WidgetTester t, bool Function(String) keep) => t
    .widgetList<Text>(find.byType(Text))
    .map((w) => w.data)
    .whereType<String>()
    .where(keep)
    .toList();

Future<void> openOT(WidgetTester t, String ticker) async {
  await t.pumpWidget(MaterialApp(
      theme: VistaTheme.dark(), home: AssetTradeScreen(ticker: ticker)));
  await t.pumpAndSettle();
  await t.tap(find.text('Long').last);
  await t.pumpAndSettle();
}

Future<void> openFeed(WidgetTester t) async {
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

  testWidgets('P1 OrderTicket overflow: default vs 13-digit size, fonts loaded',
      (t) async {
    phone(t);
    await openOT(t, 'BTC');
    print('P1 after open: exceptions=${drain(t)}');
    final size = find.byWidgetPredicate((w) =>
        w is TextField && (w.controller?.text.contains('.') ?? false));
    await t.enterText(size.first, '1370000000000');
    await t.pump();
    print('P1 after 13 digits: exceptions=${drain(t)} '
        'labels=${texts(t, (s) => s.contains('funds') || s.startsWith('Place'))}');
  });

  testWidgets('P2 Feed overflow: default vs 18-digit amount, fonts loaded',
      (t) async {
    phone(t);
    await openFeed(t);
    print('P2 after open: exceptions=${drain(t)}');
    await t.enterText(find.widgetWithText(TextField, '200'), '184467440737095517');
    await t.pump();
    print('P2 after 18 digits: exceptions=${drain(t)} '
        'labels=${texts(t, (s) => s.startsWith('Long '))}');
  });

  testWidgets('P3 Feed: an 18-digit amount that wraps to exactly 200 dollars',
      (t) async {
    phone(t);
    await openFeed(t);
    const typed = '184467440737095716.16';
    await t.enterText(find.widgetWithText(TextField, '200'), typed);
    await t.pump();
    final field = t
        .widgetList<TextField>(find.byType(TextField))
        .map((f) => f.controller?.text)
        .toList();
    print('P3 field texts=$field labels=${texts(t, (s) => s.startsWith('Long '))}');
    await t.tap(find.text(r'Long $200 · 2x'));
    await t.pumpAndSettle();
    await t.tap(find.text('Confirm'));
    await t.pumpAndSettle();
    final r = Scenario.receipts.value.single;
    print('P3 receipt margin=${r.marginCents} total=${r.totalCents} '
        'cash=${Scenario.cashCents.value} exceptions=${drain(t)}');
  });

  testWidgets('P4 smallest phone: reduce-only and empty-TP refusal labels',
      (t) async {
    phone(t, const Size(360, 640), 24);
    await openOT(t, 'BTC');
    print('P4 open exceptions=${drain(t)}');
    await t.tap(find.text('Reduce only'));
    await t.pump();
    print('P4 reduce-only labels='
        '${texts(t, (s) => s.contains('Reduce only'))} exceptions=${drain(t)}');
    final btn = find.text('Reduce only — not in the demo yet');
    if (t.widgetList(btn).isNotEmpty) {
      print('P4 reduce-only button rect=${t.getRect(btn)}');
    }
    await t.tap(find.text('Reduce only'));
    await t.pump();
    await t.tap(find.text('Take profit / Stop loss'));
    await t.pump();
    final tp = t
        .widgetList<TextField>(find.byType(TextField))
        .map((f) => f.controller?.text)
        .toList();
    print('P4 fields with exits on=$tp');
    await t.enterText(find.byType(TextField).at(1), '');
    await t.pump();
    print('P4 empty TP labels=${texts(t, (s) => s.startsWith('Enter') || s.startsWith('Place'))} '
        'exceptions=${drain(t)}');
  });

  testWidgets('P5 Retry at a moved price keeps absolute exits; review hides '
      'them', (t) async {
    final avax = MarketPrices.of('AVAX') as ValueNotifier<double>;
    addTearDown(() => avax.value = MarketPrices.base('AVAX'));
    phone(t);
    await openOT(t, 'AVAX');
    await t.tap(find.text('Take profit / Stop loss'));
    await t.pump();
    print('P5 fields=${t.widgetList<TextField>(find.byType(TextField)).map((f) => f.controller?.text).toList()}');
    await t.tap(find.text('Place market long'));
    await t.pumpAndSettle();
    print('P5 review rows mentioning exits='
        '${texts(t, (s) => s.contains('profit') || s.contains('loss') || s.contains('40.87'))}');
    await t.tap(find.text('Confirm'));
    await t.pumpAndSettle();
    avax.value = 45;
    await t.tap(find.text('Retry'));
    await t.pumpAndSettle();
    print('P5 re-review rows mentioning exits='
        '${texts(t, (s) => s.contains('profit') || s.contains('loss') || s.contains('40.87'))}');
    await t.tap(find.text('Confirm'));
    await t.pumpAndSettle();
    final p = Scenario.positions.value.first;
    print('P5 filled ${p.title} ${p.side} entry=${p.detail.entry} '
        'tp=${p.detail.takeProfit} sl=${p.detail.stopLoss} '
        'tpBelowEntryOnLong=${p.detail.takeProfit < p.detail.entry}');
  });

  testWidgets('P6 Retry then Cancel: the store moved on a cancelled flow',
      (t) async {
    final avax = MarketPrices.of('AVAX') as ValueNotifier<double>;
    addTearDown(() => avax.value = MarketPrices.base('AVAX'));
    phone(t);
    await openOT(t, 'AVAX');
    await t.tap(find.text('Place market long'));
    await t.pumpAndSettle();
    await t.tap(find.text('Confirm'));
    await t.pumpAndSettle();
    final stale = Scenario.stalePrices.value;
    avax.value = 39;
    await t.tap(find.text('Retry'));
    await t.pumpAndSettle();
    await t.tap(find.text('Cancel'));
    await t.pumpAndSettle();
    print('P6 stalePrices before Retry=$stale after Cancel=${Scenario.stalePrices.value} '
        'receipts=${Scenario.receipts.value.length}');
  });

  testWidgets('P7 Feed: a 16-digit amount and the slider semantics',
      (t) async {
    phone(t);
    await openFeed(t);
    await t.enterText(find.widgetWithText(TextField, '200'), '1000000000000000');
    await t.pump();
    final s = t.getSemantics(find.bySemanticsLabel('Amount').last);
    print('P7 slider value="${s.value}" labels=${texts(t, (x) => x.startsWith('Long ') || x.contains('funds'))} '
        'exceptions=${drain(t)}');
  });

  test('P8 store: product overflows to +inf -> message', () {
    final i = OrderIntent(actionId: 'x', symbol: 'BTC', name: 'Bitcoin',
        side: TradeSide.long, units: 1e305, price: 67412, leverage: 10);
    print('P8 problem=${Scenario.problem(i)} formatCents(max)=${formatCents(OrderIntent.maxNotionalCents)}');
  });
}
