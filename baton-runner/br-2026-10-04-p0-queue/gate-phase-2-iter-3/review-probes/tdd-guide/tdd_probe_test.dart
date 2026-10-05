// Review-only probe (tdd-guide, phase 2 review iter 3). Not part of the suite.
// ignore_for_file: avoid_print
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vista_colosseum/design_system/design_system.dart';
import 'package:vista_colosseum/features/trade/asset_trade_screen.dart';
import 'package:vista_colosseum/main.dart';
import 'package:vista_colosseum/scenario/scenario.dart';

OrderIntent eth(String id, double units, int lev) => OrderIntent(
  actionId: id, symbol: 'ETH', name: 'Ethereum', side: TradeSide.long,
  units: units, price: 2968.40, leverage: lev,
);

String drain(WidgetTester t) {
  final out = <String>[];
  Object? e;
  while ((e = t.takeException()) != null) {
    final str = e.toString();
    final loc = RegExp(r'(order_ticket|feed_order_ticket)\.dart:\d+').allMatches(str).map((m) => m.group(0)).toSet();
    out.add('${str.split('\n').first} at $loc');
  }
  return out.isEmpty ? 'none' : out.join(' | ');
}

List<String> texts(WidgetTester t, bool Function(String) keep) => t
    .widgetList<Text>(find.byType(Text))
    .map((w) => w.data)
    .whereType<String>()
    .where(keep)
    .toList();

Future<void> _loadFonts() async {
  final loader = FontLoader('OpenRunde');
  for (final w in ['Regular', 'Medium', 'Semibold', 'Bold']) {
    final bytes = File('assets/fonts/OpenRunde-$w.otf').readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
}

void main() {
  if (Platform.environment['PROBE_FONTS'] == '1') setUpAll(_loadFonts);
  setUp(Scenario.reset);

  test('B1 exact funds boundary: total == cash fills, cash+1 fails', () {
    OrderIntent at(String id, int n) => eth(id, n / 100 / 2968.40, 1);
    final exact = at('exact', 1247377);
    final over = at('over', 1247378);
    print('B1 exact n=${exact.notionalCents} m=${exact.marginCents} f=${exact.feeCents} t=${exact.totalCents} p=${Scenario.problem(exact)}');
    print('B1 over n=${over.notionalCents} m=${over.marginCents} f=${over.feeCents} t=${over.totalCents} p=${Scenario.problem(over)}');
    final ro = Scenario.placeOrder(over);
    print('B1 over result=${ro.runtimeType}');
    final r = Scenario.placeOrder(exact);
    print('B1 exact result=${r.runtimeType} cash=${Scenario.cashCents.value}');
    Scenario.reset();
    final m = eth('m', 1248000 / 100 / 2968.40, 1);
    print('B1 marginEqCash m=${m.marginCents} t=${m.totalCents} p=${Scenario.problem(m)}');
  });

  test('B2 message accuracy at the extremes', () {
    final inf = OrderIntent(actionId: 'i', symbol: 'BTC', name: 'Bitcoin',
        side: TradeSide.long, units: 1e305, price: 67412, leverage: 1);
    print('B2 1e305 BTC finite=${inf.units.isFinite} n=${inf.notionalCents} p=${Scenario.problem(inf)}');
    final hugeLev = eth('h', 0.1, 1 << 40);
    print('B2 0.1 ETH at 2^40x m=${hugeLev.marginCents} p=${Scenario.problem(hugeLev)}');
    final c = OrderIntent(actionId: 'c', symbol: 'BTC', name: 'Bitcoin',
        side: TradeSide.long, units: 1.37e12, price: 67412, leverage: 10);
    print('B2 1.37e12 BTC 10x margin=${c.marginCents} true~${(1.37e12 * 67412 * 100 / 10).toStringAsExponential(3)} p=${Scenario.problem(c)}');
    print('B2 doc: (max+1)*10000=${(OrderIntent.maxNotionalCents + 1) * 10000} 2^53-1=${(1 << 53) - 1}');
  });

  testWidgets('W1 OrderTicket: a 306-digit size', (t) async {
    t.view..physicalSize = const Size(402, 874) * 3..devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(MaterialApp(theme: VistaTheme.dark(), home: const AssetTradeScreen(ticker: 'BTC')));
    await t.pumpAndSettle();
    await t.tap(find.text('Long').last);
    await t.pumpAndSettle();
    final size = find.byWidgetPredicate((w) => w is TextField && (w.controller?.text.contains('.') ?? false) && !(w.controller!.text.contains(',')));
    final field = t.widget<TextField>(size.first);
    final s = '1${'0' * 305}';
    field.controller!.text = s;
    field.onChanged!(s);
    await t.pump();
    print('W1 btn=${texts(t, (x) => x.startsWith('Place') || x.startsWith('Size') || x.contains('funds'))} exceptions=${drain(t)}');
  });

  testWidgets('W2 OrderTicket on 360x640: overflow threshold by size', (t) async {
    t.view..physicalSize = const Size(360, 640) * 3..devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(MaterialApp(theme: VistaTheme.dark(), home: const AssetTradeScreen(ticker: 'BTC')));
    await t.pumpAndSettle();
    await t.tap(find.text('Long').last);
    await t.pumpAndSettle();
    print('W2 open exceptions=${drain(t)}');
    final size = find.byWidgetPredicate((w) => w is TextField && (w.controller?.text.contains('.') ?? false) && !(w.controller!.text.contains(',')));
    final field = t.widget<TextField>(size.first);
    for (final s in ['1', '100', '10000', '1000000', '100000000', '10000000000', '1370000000000']) {
      field.controller!.text = s;
      field.onChanged!(s);
      await t.pump();
      print('W2 size=$s btn=${texts(t, (x) => x.startsWith('Place') || x.contains('funds') || x.startsWith('Size'))} margin=${texts(t, (x) => x.contains(' · \$'))} exceptions=${drain(t)}');
    }
  });

  testWidgets('W3 feed: typed amounts through _parseCents', (t) async {
    t.view..physicalSize = const Size(402, 874) * 3..devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(const VistaColosseumApp());
    await t.pumpAndSettle();
    await t.tap(find.widgetWithText(VistaPillButton, 'Long').first);
    await t.pumpAndSettle();
    print('W3 open exceptions=${drain(t)}');
    final field = t.widget<TextField>(find.widgetWithText(TextField, '200'));
    for (final s in ['1.999', '1,000.5', '99999999999999999', '184467440737095517', '184467440737095518', '9999999999999999999.50', '99999999999999999999']) {
      field.controller!.text = s;
      field.onChanged!(s);
      await t.pump();
      print('W3 typed=$s btn=${texts(t, (x) => x.startsWith('Long ') || x.contains('funds') || x.startsWith('Enter'))} exceptions=${drain(t)}');
    }
    print('W3 cash=${Scenario.cashCents.value}');
  });

  testWidgets('W4 feed on 360x640: long amounts', (t) async {
    t.view..physicalSize = const Size(360, 640) * 3..devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(const VistaColosseumApp());
    await t.pumpAndSettle();
    await t.tap(find.widgetWithText(VistaPillButton, 'Long').first);
    await t.pumpAndSettle();
    print('W4 open exceptions=${drain(t)}');
    final field = t.widget<TextField>(find.widgetWithText(TextField, '200'));
    for (final s in ['12467.53', '99999999.99', '184467440737095517', '9999999999999999.99']) {
      field.controller!.text = s;
      field.onChanged!(s);
      await t.pump();
      print('W4 typed=$s btn=${texts(t, (x) => x.startsWith('Long ') || x.contains('funds') || x.startsWith('Enter') || x.startsWith('you lose'))} exceptions=${drain(t)}');
    }
  });

  testWidgets('W5 feed on 360x640 exits off: which row overflows', (t) async {
    t.view..physicalSize = const Size(360, 640) * 3..devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(const VistaColosseumApp());
    await t.pumpAndSettle();
    await t.tap(find.widgetWithText(VistaPillButton, 'Long').first);
    await t.pumpAndSettle();
    await t.tap(find.bySemanticsLabel('Take profit / Stop loss').last);
    await t.pumpAndSettle();
    print('W5 exits now=${t.widgetList(find.text('STOP LOSS')).length}');
    final field = t.widget<TextField>(find.widgetWithText(TextField, '200'));
    for (final s in ['99999999.99', '9999999999999999.99']) {
      field.controller!.text = s;
      field.onChanged!(s);
      await t.pump();
      print('W5 typed=$s exceptions=${drain(t)}');
    }
  });
}
