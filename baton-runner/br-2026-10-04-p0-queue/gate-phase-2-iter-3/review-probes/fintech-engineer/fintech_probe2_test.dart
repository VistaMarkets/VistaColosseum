// Review-only probe 2 (fintech-engineer, phase 2 iter 3). Not part of the suite.
// ignore_for_file: avoid_print
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vista_colosseum/design_system/design_system.dart';
import 'package:vista_colosseum/features/trade/asset_trade_screen.dart';
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

List<String> texts(WidgetTester t, bool Function(String) keep) => t
    .widgetList<Text>(find.byType(Text))
    .map((w) => w.data)
    .whereType<String>()
    .where(keep)
    .toList();

Future<void> otSize(WidgetTester t, String typed) async {
  t.view
    ..physicalSize = const Size(402, 874) * 3
    ..devicePixelRatio = 3;
  addTearDown(t.view.reset);
  await t.pumpWidget(MaterialApp(theme: VistaTheme.dark(), home: const AssetTradeScreen(ticker: 'BTC')));
  await t.pumpAndSettle();
  await t.tap(find.text('Long').last);
  await t.pumpAndSettle();
  final size = find.byWidgetPredicate((w) => w is TextField && (w.controller?.text.contains('.') ?? false) && !(w.controller!.text.contains(',')));
  final errors = <String>[];
  final old = FlutterError.onError;
  FlutterError.onError = (d) => errors.add(d.exceptionAsString().split('\n').first);
  try {
    await t.enterText(size.first, typed);
    await t.pump();
  } finally {
    FlutterError.onError = old;
  }
  print('OT[${typed.length} chars] shown=${texts(t, (s) => s.startsWith(r'$') || s.contains('funds') || s.contains('Size') || s.startsWith('Place') || s.startsWith('Enter'))} errors=$errors');
}

void main() {
  setUpAll(loadFonts);
  setUp(Scenario.reset);

  testWidgets('OT 13 digits', (t) => otSize(t, '1370000000000'));
  testWidgets('OT 306 digits (finite units, infinite cost)', (t) => otSize(t, '1${'0' * 305}'));

  test('STORE wrong-side exits are accepted', () {
    final r = Scenario.placeOrder(OrderIntent(actionId: 'ws', symbol: 'ETH', name: 'Ethereum',
        side: TradeSide.long, units: 0.1, price: 2968.40, leverage: 10, takeProfit: 1, stopLoss: 9999));
    print('STORE wrong-side long TP=1 SL=9999 -> ${r.runtimeType}');
  });

  test('STORE fee fraction >= .5 rounds down; margin half rounds away', () {
    final i = OrderIntent(actionId: 'f', symbol: 'ETH', name: 'Ethereum', side: TradeSide.long,
        units: 399.99 / 2968.40, price: 2968.40, leverage: 2);
    print('STORE n=${i.notionalCents} m=${i.marginCents} f=${i.feeCents} t=${i.totalCents}');
  });

  test('STORE sweep: every leverage 1..50 x many sizes, total <= cash iff filled, cash = seed - total', () {
    var fills = 0, refusals = 0, bad = 0;
    for (var lev = 1; lev <= 50; lev++) {
      for (final usd in [0.004, 0.01, 0.5, 1, 99.99, 1000, 12479.99, 12480, 24960, 1e6, 1e9, 9.007199254e9, 1e10, 1e13, 1e300]) {
        Scenario.reset();
        final i = OrderIntent(actionId: 's-$lev-$usd', symbol: 'ETH', name: 'Ethereum',
            side: TradeSide.long, units: usd / 2968.40, price: 2968.40, leverage: lev);
        final r = Scenario.placeOrder(i);
        final cash = Scenario.cashCents.value;
        if (r is OrderFilled) {
          fills++;
          final ok = r.receipt.totalCents == i.totalCents && cash == 1248000 - i.totalCents && cash >= 0 && i.totalCents > 0;
          if (!ok) { bad++; print('BAD fill lev=$lev usd=$usd total=${i.totalCents} cash=$cash'); }
        } else {
          refusals++;
          if (cash != 1248000) { bad++; print('BAD refusal moved cash lev=$lev usd=$usd'); }
        }
      }
    }
    print('SWEEP fills=$fills refusals=$refusals bad=$bad');
  });
}
