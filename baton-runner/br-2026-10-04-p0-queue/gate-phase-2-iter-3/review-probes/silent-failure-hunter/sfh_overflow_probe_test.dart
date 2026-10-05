// Review-only probe (silent-failure-hunter): are the reported overflows real
// with the app font loaded (the suite loads it; Ahem is much wider)?
// ignore_for_file: avoid_print
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vista_colosseum/design_system/design_system.dart';
import 'package:vista_colosseum/features/account/account_state.dart';
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

void phone(WidgetTester t) {
  t.view
    ..physicalSize = const Size(402, 874) * 3
    ..devicePixelRatio = 3;
  addTearDown(t.view.reset);
}

Finder inSheet(Finder f) =>
    find.descendant(of: find.byType(BottomSheet), matching: f);

String exc(WidgetTester t) {
  final e = t.takeException();
  return e == null ? 'none' : e.toString().split('\n').first;
}

void main() {
  setUpAll(_loadFonts);
  setUp(() {
    Scenario.reset();
    AccountState.listMarket('MAYA');
  });

  for (final (ticker, size) in [('AVAX', null), ('BTC', '1370000000000'), ('BTC', '200000')]) {
    testWidgets('OT $ticker size=$size', (t) async {
      phone(t);
      await t.pumpWidget(MaterialApp(theme: VistaTheme.dark(), home: AssetTradeScreen(ticker: ticker)));
      await t.pumpAndSettle();
      await t.tap(find.text('Long').last);
      await t.pumpAndSettle();
      print('OTF $ticker open exc=${exc(t)}');
      if (size != null) {
        await t.enterText(inSheet(find.byType(TextField)).first, size);
        await t.pumpAndSettle();
        print('OTF $ticker size=$size exc=${exc(t)}');
      }
    });
  }

  for (final typed in ['184467440737095517', '184467440737095717', '200']) {
    testWidgets('FEEDF typed=$typed', (t) async {
      phone(t);
      await t.pumpWidget(const VistaColosseumApp());
      await t.pumpAndSettle();
      await t.tap(find.widgetWithText(VistaPillButton, 'Long').first);
      await t.pumpAndSettle();
      print('FEEDF open exc=${exc(t)}');
      await t.enterText(inSheet(find.byType(TextField)).first, typed);
      await t.pumpAndSettle();
      print('FEEDF typed=$typed exc=${exc(t)}');
      final place = inSheet(find.textContaining(RegExp(r'^Long \$')));
      await t.ensureVisible(place.first);
      await t.pumpAndSettle();
      await t.tap(place.first);
      await t.pumpAndSettle();
      final rev = t.widgetList<Text>(inSheet(find.byType(Text))).map((w) => w.data).whereType<String>().where((s) => s.contains(r'$')).toList();
      print('FEEDF typed=$typed review=$rev exc=${exc(t)}');
      await t.ensureVisible(find.text('Confirm'));
      await t.pumpAndSettle();
      await t.tap(find.text('Confirm'));
      await t.pumpAndSettle();
      final toast = t.widgetList<Text>(find.byType(Text)).map((w) => w.data).whereType<String>().where((s) => s.contains('filled')).toList();
      print('FEEDF typed=$typed toast=$toast receipt=${Scenario.receipts.value.map((r) => [r.marginCents, r.feeCents, r.totalCents]).toList()} exc=${exc(t)}');
    });
  }
}
