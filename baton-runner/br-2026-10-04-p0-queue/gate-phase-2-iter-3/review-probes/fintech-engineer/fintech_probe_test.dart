// Review-only probe (fintech-engineer, phase 2 iter 3). Not part of the suite.
// ignore_for_file: avoid_print
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vista_colosseum/design_system/design_system.dart';
import 'package:vista_colosseum/features/trade/asset_trade_screen.dart';
import 'package:vista_colosseum/main.dart';
import 'package:vista_colosseum/scenario/scenario.dart';

const appDir = '/home/alex/VistaColosseum/.worktrees/br-2026-10-04-p0-queue/app';

Future<void> loadFonts() async {
  final loader = FontLoader('OpenRunde');
  for (final w in ['Regular', 'Medium', 'Semibold', 'Bold']) {
    final bytes = File('$appDir/assets/fonts/OpenRunde-$w.otf').readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
}

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

/// Collects layout errors instead of failing; restore before the test ends.
List<String> collectErrors() {
  final errors = <String>[];
  final old = FlutterError.onError;
  FlutterError.onError = (d) => errors.add(d.exceptionAsString().split('\n').first +
      ' @ ' + (d.informationCollector?.call().map((e) => e.toString()).firstWhere(
          (s) => s.contains('.dart:'), orElse: () => '?') ?? '?'));
  addTearDown(() => FlutterError.onError = old);
  return errors;
}

List<String> texts(WidgetTester t, bool Function(String) keep) => t
    .widgetList<Text>(find.byType(Text))
    .map((w) => w.data)
    .whereType<String>()
    .where(keep)
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
  setUpAll(loadFonts);
  setUp(Scenario.reset);

  for (final typed in ['184467440737095517', '10000000000000000000.84', '99999999999999999']) {
    testWidgets('FEED typed $typed (fonts loaded)', (t) async {
      final errors = collectErrors();
      await feedAmount(t, typed);
      final field = t.widget<TextField>(find.byType(TextField).first).controller!.text;
      print('FEED[$typed] field="$field" button=${texts(t, (s) => s.startsWith('Long ') || s.contains('funds') || s.startsWith('Enter'))}');
      final place = find.textContaining(RegExp(r'^Long \$'));
      if (t.widgetList(place).isNotEmpty) {
        await t.tap(place.first);
        await t.pumpAndSettle();
        print('FEED[$typed] review=${texts(t, (s) => s.startsWith(r'$') || s.contains('ETH'))}');
        await t.tap(find.text('Confirm'));
        await t.pumpAndSettle();
        print('FEED[$typed] toast=${texts(t, (s) => s.contains('filled'))}');
      }
      print('FEED[$typed] receipts=${Scenario.receipts.value.map((r) => [r.marginCents, r.feeCents, r.totalCents]).toList()} cash=${Scenario.cashCents.value}');
      print('FEED[$typed] layoutErrors=${errors.length} $errors');
      FlutterError.onError = FlutterError.dumpErrorToConsole; // restored by tearDown
    });
  }

  testWidgets('OT 13-digit BTC size: button and summary (fonts loaded)', (t) async {
    final errors = collectErrors();
    phone(t);
    await t.pumpWidget(MaterialApp(theme: VistaTheme.dark(), home: const AssetTradeScreen(ticker: 'BTC')));
    await t.pumpAndSettle();
    await t.tap(find.text('Long').last);
    await t.pumpAndSettle();
    final before = snap();
    final size = find.byWidgetPredicate((w) => w is TextField && (w.controller?.text.contains('.') ?? false) && !(w.controller!.text.contains(',')));
    for (final typed in ['1370000000000', '1${'0' * 305}', '13360']) {
      await t.enterText(size.first, typed);
      await t.pump();
      print('OT[${typed.length} digits] shown=${texts(t, (s) => s.startsWith(r'$') || s.contains('funds') || s.contains('Size') || s.startsWith('Place'))}');
    }
    expect(snap(), equals(before));
    print('OT layoutErrors=${errors.length} $errors');
  });

  test('STORE wrong-side exits are accepted', () {
    final r = Scenario.placeOrder(OrderIntent(actionId: 'ws', symbol: 'ETH', name: 'Ethereum',
        side: TradeSide.long, units: 0.1, price: 2968.40, leverage: 10, takeProfit: 1, stopLoss: 9999));
    print('STORE wrong-side long TP=1 SL=9999 -> ${r.runtimeType}');
  });

  test('STORE fee fraction >= .5 rounds down; margin half rounds away', () {
    // notional 39999 cents: fee 19.9995 -> 19; margin at 2x 19999.5 -> 20000.
    final i = OrderIntent(actionId: 'f', symbol: 'ETH', name: 'Ethereum', side: TradeSide.long,
        units: 399.99 / 2968.40, price: 2968.40, leverage: 2);
    print('STORE n=${i.notionalCents} m=${i.marginCents} f=${i.feeCents} t=${i.totalCents}');
  });
}
