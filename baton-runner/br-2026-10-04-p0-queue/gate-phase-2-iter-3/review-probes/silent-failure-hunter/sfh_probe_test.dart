// Review-only probe (silent-failure-hunter, phase 2 iter 3). Not part of the suite.
// ignore_for_file: avoid_print
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vista_colosseum/design_system/design_system.dart';
import 'package:vista_colosseum/features/account/account_state.dart';
import 'package:vista_colosseum/features/live/market_prices.dart';
import 'package:vista_colosseum/features/trade/asset_trade_screen.dart';
import 'package:vista_colosseum/main.dart';
import 'package:vista_colosseum/scenario/scenario.dart';

List<Object?> snap() => [
  Scenario.cashCents.value,
  Scenario.positions.value,
  Scenario.receipts.value,
  Scenario.openOrders.value,
  Scenario.stalePrices.value,
];

void phone(WidgetTester t) {
  t.view
    ..physicalSize = const Size(402, 874) * 3
    ..devicePixelRatio = 3;
  addTearDown(t.view.reset);
}

Finder inSheet(Finder f) =>
    find.descendant(of: find.byType(BottomSheet), matching: f);

List<String> sheetTexts(WidgetTester t) => t
    .widgetList<Text>(inSheet(find.byType(Text)))
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

Future<void> openBtc(WidgetTester t, String ticker) async {
  phone(t);
  await t.pumpWidget(MaterialApp(
    theme: VistaTheme.dark(),
    home: AssetTradeScreen(ticker: ticker),
  ));
  await t.pumpAndSettle();
  await t.tap(find.text('Long').last);
  await t.pumpAndSettle();
}

void main() {
  setUp(() {
    Scenario.reset();
    AccountState.listMarket('MAYA');
  });

  for (final typed in [
    '184467440737095717', // 18 digits, wraps to +20084 cents
    '184467440737095517', // manager's case, wraps to 84 cents
    '92233720368547759', // 17 digits, wraps negative
    '99999999999999999999', // 20 digits, tryParse null
    '1.2.3',
    '1,5',
  ]) {
    testWidgets('FEED typed=$typed', (t) async {
      await openFeed(t);
      final field = inSheet(find.byType(TextField)).first;
      await t.enterText(field, typed);
      await t.pumpAndSettle();
      t.takeException();
      final labels = sheetTexts(t)
          .where((s) =>
              s.startsWith(r'Long $') ||
              s.contains('Enter') ||
              s.contains('funds') ||
              s.contains(' of ETH at '))
          .toList();
      final shownField = t.widget<TextField>(field).controller!.text;
      print('FEED typed=$typed field="$shownField" labels=$labels');
      final place = inSheet(find.textContaining(RegExp(r'^Long \$')));
      if (t.widgetList(place).isNotEmpty) {
        await t.tap(place.first, warnIfMissed: false);
        await t.pumpAndSettle();
        t.takeException();
        if (t.widgetList(find.text('Confirm')).isNotEmpty) {
          await t.ensureVisible(find.text('Confirm'));
          await t.pumpAndSettle();
          await t.tap(find.text('Confirm'));
          await t.pumpAndSettle();
          t.takeException();
        }
      }
      print('FEED typed=$typed receipts=${Scenario.receipts.value.map((r) => [r.marginCents, r.feeCents, r.totalCents]).toList()} cash=${Scenario.cashCents.value}');
    });
  }

  testWidgets('OT 200000 BTC: margin/fee rows vs true cents', (t) async {
    await openBtc(t, 'BTC');
    final size = inSheet(find.byType(TextField)).first;
    await t.enterText(size, '200000');
    await t.pumpAndSettle();
    t.takeException();
    final money = sheetTexts(t)
        .where((s) => s.contains(r'$') || s.contains('funds') || s.contains('large'))
        .toList();
    final i = OrderIntent(actionId: 'x', symbol: 'BTC', name: 'Bitcoin',
        side: TradeSide.long, units: 200000, price: 67412, leverage: 10);
    print('OT200k shown=$money');
    print('OT200k intent notional=${i.notionalCents} margin=${i.marginCents} fee=${i.feeCents} '
        'true notional=${200000 * 67412 * 100} trueMargin=${200000 * 67412 * 100 ~/ 10} '
        'trueFee=${200000 * 67412 * 100 * 5 ~/ 10000}');
  });

  testWidgets('OT 306-digit BTC size: infinite product', (t) async {
    await openBtc(t, 'BTC');
    final size = inSheet(find.byType(TextField)).first;
    await t.enterText(size, '1${'0' * 305}');
    await t.pumpAndSettle();
    t.takeException();
    final msgs = sheetTexts(t)
        .where((s) => s.contains('Size') || s.contains('Enter') || s.contains('funds') || s.startsWith('Place'))
        .toList();
    print('OTINF shown=$msgs');
  });

  test('store: wrong-side TP/SL on a long fills', () {
    final r = Scenario.placeOrder(OrderIntent(
      actionId: 'ws', symbol: 'ETH', name: 'Ethereum', side: TradeSide.long,
      units: 0.1, price: 2968.40, leverage: 10, takeProfit: 2000, stopLoss: 3500,
    ));
    final p = Scenario.positions.value.first;
    print('WRONGSIDE result=${r.runtimeType} entry=${p.detail.entry} tp=${p.detail.takeProfit} sl=${p.detail.stopLoss}');
  });

  testWidgets('Retry at moved price, then Cancel: stale flag consumed', (t) async {
    final avax = MarketPrices.of('AVAX') as ValueNotifier<double>;
    addTearDown(() => avax.value = MarketPrices.base('AVAX'));
    final before = snap();
    await openBtc(t, 'AVAX');
    await t.tap(find.text('Place market long'));
    await t.pumpAndSettle();
    await t.tap(find.text('Confirm'));
    await t.pumpAndSettle();
    avax.value = 40;
    await t.tap(find.text('Retry'));
    await t.pumpAndSettle();
    await t.tap(inSheet(find.text('Cancel')));
    await t.pumpAndSettle();
    final after = snap();
    print('RETRYCANCEL stale before=${before[4]} after=${after[4]} equal=${const DeepCollectionEqualityShim().eq(before, after)} '
        'cash=${after[0]} receipts=${(after[2] as List).length}');
  });

  testWidgets('Wallet change line after a fill', (t) async {
    phone(t);
    await t.pumpWidget(const VistaColosseumApp());
    await t.pumpAndSettle();
    await t.tap(find.bySemanticsLabel('Wallet'));
    await t.pumpAndSettle();
    List<String> pager() => t.widgetList<Text>(find.byType(Text)).map((w) => w.data).whereType<String>()
        .where((s) => s.contains('(') && s.contains('%') || s.startsWith(r'$12,')).toList();
    print('CHANGE before=${pager()}');
    Scenario.placeOrder(OrderIntent(actionId: 'c1', symbol: 'ETH', name: 'Ethereum',
        side: TradeSide.long, units: 2, price: 2968.40, leverage: 1));
    await t.pumpAndSettle();
    print('CHANGE after 1x 2 ETH fill (cash ${Scenario.cashCents.value})=${pager()}');
  });
}

class DeepCollectionEqualityShim {
  const DeepCollectionEqualityShim();
  bool eq(List<Object?> a, List<Object?> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      final x = a[i], y = b[i];
      if (x is Set && y is Set) {
        if (x.length != y.length || !x.containsAll(y)) return false;
      } else if (x is List && y is List) {
        if (x.length != y.length) return false;
        for (var j = 0; j < x.length; j++) {
          if (!identical(x[j], y[j]) && x[j] != y[j]) return false;
        }
      } else if (x != y) {
        return false;
      }
    }
    return true;
  }
}
