// Review-only probe (phase 2 review iter 3). Not part of the suite.
// ignore_for_file: avoid_print
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vista_colosseum/design_system/design_system.dart';
import 'package:vista_colosseum/features/live/live_feed.dart';
import 'package:vista_colosseum/features/trade/asset_trade_screen.dart';
import 'package:vista_colosseum/main.dart';
import 'package:vista_colosseum/scenario/scenario.dart';

List<Object?> snap() => [
  Scenario.cashCents.value,
  Scenario.positions.value,
  Scenario.receipts.value,
  Scenario.openOrders.value,
];

OrderIntent btc(String id, double units, int lev) => OrderIntent(
  actionId: id, symbol: 'BTC', name: 'Bitcoin', side: TradeSide.long,
  units: units, price: 67412, leverage: lev,
);

void phone(WidgetTester t) {
  t.view
    ..physicalSize = const Size(402, 874) * 3
    ..devicePixelRatio = 3;
  addTearDown(t.view.reset);
}

void main() {
  setUp(Scenario.reset);

  test('H-1 reviewer repro: BTC 1.37e12 units at 1x', () {
    final before = snap();
    final i = btc('ovf', 1.37e12, 1);
    print('H1 notional=${i.notionalCents} margin=${i.marginCents} fee=${i.feeCents} total=${i.totalCents} problem=${Scenario.problem(i)}');
    final r = Scenario.placeOrder(i);
    print('H1 result=${r.runtimeType} reason=${r is OrderFailed ? r.reason : '-'} cash=${Scenario.cashCents.value}');
    expect(r, isA<OrderFailed>().having((f) => f.reason, 'reason', notEnoughFunds));
    expect(snap(), equals(before));
    // Same at the short side and at every leverage 1..100.
    for (var lev = 1; lev <= 100; lev++) {
      final x = Scenario.placeOrder(btc('ovf-$lev', 1.37e12, lev));
      expect(x, isA<OrderFailed>(), reason: 'lev $lev');
      expect(x is OrderFailed && x.reason.startsWith('-'), isFalse);
    }
    expect(snap(), equals(before));
  });

  test('H-1 edges: max notional, infinite product, huge leverage', () {
    final before = snap();
    final atMax = OrderIntent(actionId: 'm', symbol: 'BTC', name: 'Bitcoin',
        side: TradeSide.long, units: OrderIntent.maxNotionalCents / 100 / 67412,
        price: 67412, leverage: 1000000);
    print('EDGE atMax notional=${atMax.notionalCents} margin=${atMax.marginCents} fee=${atMax.feeCents} total=${atMax.totalCents} problem=${Scenario.problem(atMax)}');
    final inf = btc('inf', 1e305, 1);
    print('EDGE infProduct notional=${inf.notionalCents} margin=${inf.marginCents} problem=${Scenario.problem(inf)}');
    final inf2 = btc('inf2', 1e305, 1 << 62);
    print('EDGE infProduct hugeLev problem=${Scenario.problem(inf2)}');
    final big = btc('big', 1.37e12, 1 << 62);
    print('EDGE hugeLev notional=${big.notionalCents} margin=${big.marginCents} total=${big.totalCents} problem=${Scenario.problem(big)}');
    for (final i in [atMax, inf, inf2, big]) {
      expect(Scenario.placeOrder(i), isA<OrderFailed>());
    }
    print('EDGE maxMarginCents(1,5)=${Scenario.maxMarginCents(1, 5)}');
    expect(snap(), equals(before));
  });

  testWidgets('H-1 via OrderTicket: 13-digit BTC size shows a truthful refusal', (t) async {
    phone(t);
    await t.pumpWidget(MaterialApp(theme: VistaTheme.dark(), home: const AssetTradeScreen(ticker: 'BTC')));
    await t.pumpAndSettle();
    await t.tap(find.text('Long').last);
    await t.pumpAndSettle();
    final fields = t.widgetList<TextField>(find.byType(TextField)).toList();
    print('OT fields=${fields.map((f) => f.controller?.text).toList()}');
    final before = snap();
    // The size field is the one holding the quarter-of-max size in BTC units.
    final sizeField = find.byWidgetPredicate((w) => w is TextField && (w.controller?.text.contains('.') ?? false) && !(w.controller!.text.contains(',')));
    print('OT size candidates=${t.widgetList(sizeField).length}');
    await t.enterText(sizeField.first, '1370000000000');
    await t.pump();
    final texts = t.widgetList<Text>(find.byType(Text)).map((w) => w.data).whereType<String>().where((s) => s.contains('funds') || s.contains('Place') || s.contains('large') || s.contains('\$') && s.contains('-')).toList();
    print('OT texts=$texts');
    expect(find.text('Place market long'), findsNothing);
    expect(find.text(notEnoughFunds), findsWidgets);
    expect(snap(), equals(before));
  });

  testWidgets('H-2: Wallet shows exact store cents after a fill, and after reset, with no drift', (t) async {
    phone(t);
    await t.pumpWidget(const VistaColosseumApp());
    await t.pumpAndSettle();
    await t.tap(find.bySemanticsLabel('Wallet'));
    await t.pumpAndSettle();
    expect(find.text(r'$12,480.00'), findsNWidgets(2));
    final r = Scenario.placeOrder(OrderIntent(actionId: 'a-1', symbol: 'ETH', name: 'Ethereum',
        side: TradeSide.long, units: 0.12345, price: 2968.40, leverage: 10)) as OrderFilled;
    await t.pumpAndSettle();
    print('H2 total=${r.receipt.totalCents} cash=${Scenario.cashCents.value} fmt=${formatCents(Scenario.cashCents.value)}');
    expect(find.text(r'$12,443.17'), findsNWidgets(2));
    final feed = LiveFeed.watch('portfolio', Scenario.cashCents.value / 100, 9) as ValueNotifier<double>;
    for (var k = 0; k < 5; k++) {
      feed.value += 9;
      await t.pump();
      expect(find.text(r'$12,443.17'), findsNWidgets(2));
    }
    Scenario.reset();
    await t.pumpAndSettle();
    expect(find.text(r'$12,480.00'), findsNWidgets(2));
    for (var k = 0; k < 5; k++) {
      feed.value -= 9;
      await t.pump();
      expect(find.text(r'$12,480.00'), findsNWidgets(2));
    }
    print('H2 after reset ok');
  });

  testWidgets('Feed ticket: an 18-digit typed amount (int wrap in _parseCents)', (t) async {
    phone(t);
    await t.pumpWidget(const VistaColosseumApp());
    await t.pumpAndSettle();
    await t.tap(find.widgetWithText(VistaPillButton, 'Long').first);
    await t.pumpAndSettle();
    final amount = find.widgetWithText(TextField, '200');
    print('FEED amount fields=${t.widgetList(amount).length}');
    await t.enterText(amount, '184467440737095517');
    await t.pumpAndSettle();
    final labels = t.widgetList<Text>(find.byType(Text)).map((w) => w.data).whereType<String>().where((s) => s.startsWith('Long ') || s.contains('funds') || s.contains('Enter')).toList();
    print('FEED labels=$labels');
    final place = find.textContaining(RegExp(r'^Long \$'));
    if (t.widgetList(place).isNotEmpty) {
      await t.tap(place.first);
      await t.pumpAndSettle();
      final rev = t.widgetList<Text>(find.byType(Text)).map((w) => w.data).whereType<String>().where((s) => s.startsWith(r'$')).toList();
      print('FEED review dollar texts=$rev');
      if (t.widgetList(find.text('Confirm')).isNotEmpty) {
        await t.tap(find.text('Confirm'));
        await t.pumpAndSettle();
      }
    }
    print('FEED receipts=${Scenario.receipts.value.map((r) => [r.marginCents, r.feeCents, r.totalCents]).toList()} cash=${Scenario.cashCents.value}');
  });
}
