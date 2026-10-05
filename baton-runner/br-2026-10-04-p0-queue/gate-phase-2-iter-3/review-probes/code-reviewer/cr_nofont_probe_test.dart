// Review-only probe: same screens, default inputs, NO app font loaded
// (as in the manager's iter3_probe_test.dart). Not part of the suite.
// ignore_for_file: avoid_print
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vista_colosseum/design_system/design_system.dart';
import 'package:vista_colosseum/features/trade/asset_trade_screen.dart';
import 'package:vista_colosseum/main.dart';
import 'package:vista_colosseum/scenario/scenario.dart';

void phone(WidgetTester t) {
  t.view
    ..physicalSize = const Size(402, 874) * 3
    ..devicePixelRatio = 3;
  addTearDown(t.view.reset);
}

void main() {
  setUp(Scenario.reset);
  testWidgets('OT default size, no font', (t) async {
    phone(t);
    await t.pumpWidget(MaterialApp(theme: VistaTheme.dark(), home: const AssetTradeScreen(ticker: 'BTC')));
    await t.pumpAndSettle();
    await t.tap(find.text('Long').last);
    await t.pumpAndSettle();
    print('NOFONT OT default exception=${t.takeException()}');
  });
  testWidgets('FEED default amount, no font', (t) async {
    phone(t);
    await t.pumpWidget(const VistaColosseumApp());
    await t.pumpAndSettle();
    await t.tap(find.widgetWithText(VistaPillButton, 'Long').first);
    await t.pumpAndSettle();
    print('NOFONT FEED default exception=${t.takeException()}');
  });
}
