// Review iter 2 probe (read-only evidence, not part of the suite).
// At 1.3x text on 360x640 and 375x667: each ticket's main action, its
// visible fields, the make-market CTA and the pill's own note button must be
// on screen, hit-testable, and clear of the pill; no overflow anywhere.
// Run from app/: flutter test <abs path to this file>
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vista_colosseum/design_system/design_system.dart';
import 'package:vista_colosseum/features/account/account_state.dart';
import 'package:vista_colosseum/features/settings/settings_state.dart';
import 'package:vista_colosseum/features/trade/asset_trade_screen.dart';
import 'package:vista_colosseum/main.dart';
import 'package:vista_colosseum/scenario/scenario.dart';

const pill = 'Simulated · fixture-v1';
const phones = <String, (Size, EdgeInsets)>{
  '360x640': (Size(360, 640), EdgeInsets.only(top: 24)),
  '375x667': (Size(375, 667), EdgeInsets.only(top: 20)),
};

Future<void> _loadFonts() async {
  final loader = FontLoader('OpenRunde');
  for (final w in ['Regular', 'Medium', 'Semibold', 'Bold']) {
    final bytes = File('assets/fonts/OpenRunde-$w.otf').readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
}

Future<void> launch(WidgetTester tester, Size size, EdgeInsets pad,
    [Widget home = const VistaColosseumApp()]) async {
  tester.view
    ..physicalSize = size * 3
    ..devicePixelRatio = 3
    ..padding = FakeViewPadding(top: pad.top * 3, bottom: pad.bottom * 3)
    ..viewPadding = FakeViewPadding(top: pad.top * 3, bottom: pad.bottom * 3);
  tester.platformDispatcher.textScaleFactorTestValue = 1.3;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpWidget(home);
  await tester.pumpAndSettle();
}

Finder button(String label) => find
    .ancestor(of: find.text(label), matching: find.byType(GestureDetector))
    .first;

/// Every target is on screen and none touches the pill. Unlike the suite's
/// `expectPillClear`, targets are NOT pre-filtered by hitTestable().
void clear(WidgetTester tester, String tag, Finder targets, Size size) {
  final p = tester.getRect(find.bySemanticsLabel(pill));
  expect(targets, findsWidgets, reason: tag);
  for (var i = 0; i < targets.evaluate().length; i++) {
    final r = tester.getRect(targets.at(i));
    // ignore: avoid_print
    print('$tag #$i rect=$r pill=$p overlap=${r.overlaps(p)}');
    expect(r.overlaps(p), isFalse, reason: '$tag #$i $r vs pill $p');
  }
}

void main() {
  setUpAll(_loadFonts);
  setUp(() {
    Scenario.reset();
    AccountState.listMarket('MAYA');
    SettingsState.reset();
  });

  for (final MapEntry(key: name, value: (size, pad)) in phones.entries) {
    testWidgets('CTA probe OrderTicket Place + fields @1.3x $name', (t) async {
      await launch(t, size, pad,
          const VistaColosseumApp(home: AssetTradeScreen(ticker: 'BTC')));
      await t.tap(find.text('Long').last);
      await t.pumpAndSettle();
      final place = button('Place market long');
      await t.ensureVisible(place);
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      clear(t, 'OT place $name', place, size);
      expect(find.text('Place market long').hitTestable(), findsOneWidget);
      // Fields currently on screen (not pre-filtered by hit testing).
      final fields = find.byType(TextField);
      for (var i = 0; i < fields.evaluate().length; i++) {
        final r = t.getRect(fields.at(i));
        if (r.bottom > 0 && r.top < size.height) {
          clear(t, 'OT field $name', fields.at(i), size);
        }
      }
    });

    testWidgets('CTA probe FeedOrderTicket CTA + fields @1.3x $name', (t) async {
      await launch(t, size, pad);
      await t.tap(find.widgetWithText(VistaPillButton, 'Long').first);
      await t.pumpAndSettle();
      final cta = button(r'Long $200 · 2x');
      await t.ensureVisible(cta);
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      clear(t, 'FT cta $name', cta, size);
      expect(find.text(r'Long $200 · 2x').hitTestable(), findsOneWidget);
      final fields = find.byType(TextField);
      for (var i = 0; i < fields.evaluate().length; i++) {
        final r = t.getRect(fields.at(i));
        if (r.bottom > 0 && r.top < size.height) {
          clear(t, 'FT field $name', fields.at(i), size);
        }
      }
    });

    testWidgets('CTA probe make-market step 1 @1.3x $name', (t) async {
      Scenario.reset(withMarket: false);
      await launch(t, size, pad);
      await t.tap(find.bySemanticsLabel('Wallet'));
      await t.pumpAndSettle();
      await t.tap(find.bySemanticsLabel('Make a market'));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      clear(t, 'MM cta $name', find.byType(VistaPrimaryButton), size);
    });

    testWidgets('CTA probe pill note Reset button @1.3x $name', (t) async {
      await launch(t, size, pad);
      await t.tap(find.bySemanticsLabel(pill));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      clear(t, 'note reset $name', button('Reset demo'), size);
      expect(find.text('Reset demo').hitTestable(), findsOneWidget);
    });
  }
}
