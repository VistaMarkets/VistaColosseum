// Review iter 2 probe (read-only evidence, not part of the suite).
// Re-checks H1 by hand: open the leverage sheet from both tickets at
// 360x640 and 375x667 with 1.3x text, report every control's rect against the
// simulated pill and its strip, then tap "Set Nx" and check it applied.
// Run from app/: flutter test <abs path to this file>
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vista_colosseum/design_system/design_system.dart';
import 'package:vista_colosseum/features/account/account_state.dart';
import 'package:vista_colosseum/features/settings/settings_state.dart';
import 'package:vista_colosseum/features/simulation/simulation_indicator.dart';
import 'package:vista_colosseum/features/trade/asset_trade_screen.dart';
import 'package:vista_colosseum/features/trade/order_ticket.dart';
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

void setView(WidgetTester tester, Size size, EdgeInsets pad, double scale) {
  tester.view
    ..physicalSize = size * 3
    ..devicePixelRatio = 3
    ..padding = FakeViewPadding(top: pad.top * 3, bottom: pad.bottom * 3)
    ..viewPadding = FakeViewPadding(top: pad.top * 3, bottom: pad.bottom * 3);
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

/// Prints and returns the number of sheet controls the pill or its strip
/// touches, plus whether Set's whole rect is on screen and hit-testable.
int audit(WidgetTester tester, String tag, String setLabel, Size size) {
  final pillRect = tester.getRect(find.bySemanticsLabel(pill));
  final strip = Rect.fromLTRB(
    0,
    pillRect.top,
    size.width,
    pillRect.top + SimulationIndicator.slot,
  );
  final sheet = find.byType(BottomSheet).last;
  final scroll = tester.state<ScrollableState>(
    find.descendant(of: sheet, matching: find.byType(Scrollable)).first,
  );
  final controls = <String, Finder>{
    'Set': find.ancestor(
      of: find.text(setLabel),
      matching: find.byType(VistaPrimaryButton),
    ),
    'Lower': find.bySemanticsLabel('Lower leverage'),
    'Raise': find.bySemanticsLabel('Raise leverage'),
  };
  final detectors = find.descendant(
    of: sheet,
    matching: find.byType(GestureDetector),
  );
  var hits = 0;
  void check(String name, Rect r) {
    final onScreen = r.top >= 0 && r.bottom <= size.height;
    final coversPill = r.overlaps(pillRect);
    final coversStrip = r.overlaps(strip);
    if (coversPill || coversStrip || !onScreen) hits++;
    // ignore: avoid_print
    print(
      '$tag $name rect=$r onScreen=$onScreen '
      'pillOverlap=$coversPill stripOverlap=$coversStrip',
    );
  }

  // ignore: avoid_print
  print(
    '$tag pill=$pillRect strip=$strip sheet=${tester.getRect(sheet)} '
    'maxScroll=${scroll.position.maxScrollExtent}',
  );
  for (final e in controls.entries) {
    expect(e.value, findsOneWidget, reason: '$tag ${e.key}');
    check(e.key, tester.getRect(e.value));
  }
  for (var i = 0; i < detectors.evaluate().length; i++) {
    check('detector#$i', tester.getRect(detectors.at(i)));
  }
  expect(find.text(setLabel).hitTestable(), findsOneWidget, reason: tag);
  return hits;
}

void main() {
  setUpAll(_loadFonts);
  setUp(() {
    Scenario.reset();
    AccountState.listMarket('MAYA');
    SettingsState.reset();
  });

  for (final scale in [1.3, 1.0]) {
    for (final MapEntry(key: name, value: (size, pad)) in phones.entries) {
      testWidgets('H1 probe OrderTicket leverage sheet $name @${scale}x', (
        tester,
      ) async {
        setView(tester, size, pad, scale);
        await tester.pumpWidget(
          const VistaColosseumApp(home: AssetTradeScreen(ticker: 'BTC')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Long').last);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'ticket open');
        await tester.ensureVisible(find.text('Cross · 10x'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Cross · 10x'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'sheet open');
        await tester.tap(find.bySemanticsLabel('Raise leverage'));
        await tester.pumpAndSettle();
        final hits = audit(tester, 'OT $name @$scale', 'Set 11x', size);
        expect(hits, 0, reason: 'controls touching pill/strip or off screen');
        await tester.tap(find.text('Set 11x'));
        await tester.pumpAndSettle();
        expect(find.text('Cross · 11x'), findsOneWidget);
        expect(find.text('Set 11x'), findsNothing); // sheet closed
        expect(tester.takeException(), isNull, reason: 'after Set');
      });

      testWidgets('H1 probe FeedOrderTicket leverage sheet $name @${scale}x', (
        tester,
      ) async {
        setView(tester, size, pad, scale);
        await tester.pumpWidget(const VistaColosseumApp());
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(VistaPillButton, 'Long').first);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'ticket open');
        Finder inTicket(Finder f) =>
            find.descendant(of: find.byType(FeedOrderTicket), matching: f);
        await tester.ensureVisible(inTicket(find.text('custom')));
        await tester.pumpAndSettle();
        await tester.tap(inTicket(find.text('custom')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'sheet open');
        await tester.tap(find.bySemanticsLabel('Raise leverage'));
        await tester.pumpAndSettle();
        final hits = audit(tester, 'FT $name @$scale', 'Set 3x', size);
        expect(hits, 0, reason: 'controls touching pill/strip or off screen');
        await tester.tap(find.text('Set 3x'));
        await tester.pumpAndSettle();
        expect(inTicket(find.text(r'Long $200 · 3x')), findsOneWidget);
        expect(find.text('Set 3x'), findsNothing);
        expect(tester.takeException(), isNull, reason: 'after Set');
      });
    }
  }
}
