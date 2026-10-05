// Phase 4 review iter 1 probe (read-only evidence, not part of the suite).
// At 1.3x text on 360x640 and 375x667: the Arena's crowd panel, the last
// card's side buttons, the empty state's "Show all" and Ask's hint must be
// on screen, hit-testable and clear of the simulated pill; no overflow.
// Also the opinions dock (ETH battle) at the same sizes.
// Run from a copy of app/: flutter test test/arena_layout_probe_test.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vista_colosseum/design_system/design_system.dart';
import 'package:vista_colosseum/features/account/account_state.dart';
import 'package:vista_colosseum/features/arena/arena_screen.dart';
import 'package:vista_colosseum/features/settings/settings_state.dart';
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

void clear(WidgetTester tester, Finder target, String what) {
  final badge = find.bySemanticsLabel(pill);
  expect(badge.hitTestable(), findsOneWidget, reason: 'pill $what');
  expect(target, findsWidgets, reason: what);
  final p = tester.getRect(badge);
  for (var i = 0; i < target.evaluate().length; i++) {
    final r = tester.getRect(target.at(i));
    // ignore: avoid_print
    print('PROBE $what rect=$r pill=$p overlaps=${p.overlaps(r)}');
    expect(p.overlaps(r), isFalse, reason: '$what $r under pill $p');
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
    Future<void> launch(WidgetTester tester) async {
      tester.view
        ..physicalSize = size * 3
        ..devicePixelRatio = 3
        ..padding = FakeViewPadding(top: pad.top * 3, bottom: pad.bottom * 3)
        ..viewPadding =
            FakeViewPadding(top: pad.top * 3, bottom: pad.bottom * 3);
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(const VistaColosseumApp());
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Arena'));
      await tester.pumpAndSettle();
    }

    Finder list() => find.descendant(
      of: find.byType(ArenaScreen),
      matching: find.byType(ListView),
    );

    testWidgets('arena panel, last card, Show all, Ask hint on $name', (
      tester,
    ) async {
      await launch(tester);
      expect(tester.takeException(), isNull);
      // ignore: avoid_print
      print('PROBE $name list viewport=${tester.getRect(list())}');
      clear(tester, find.byType(RangeSlider), '$name slider');
      clear(tester, find.text('3 battles'), '$name count');
      clear(tester, find.byType(VistaBottomNav), '$name nav');

      // Last card's side buttons, scrolled to the end of the list.
      await tester.drag(list(), const Offset(0, -4000));
      await tester.pumpAndSettle();
      final bear = find.widgetWithText(VistaPillButton, "I'm with Bear").last;
      clear(tester, bear, '$name last card Bear');
      expect(bear.hitTestable(), findsOneWidget, reason: 'last Bear reachable');
      final view = tester.getRect(list());
      expect(tester.getRect(bear).bottom, lessThanOrEqualTo(view.bottom));

      // Empty crowd split: Show all is reachable and clear of the pill.
      final r = tester.getRect(find.byType(RangeSlider));
      final w = r.width - 24;
      await tester.dragFrom(
        Offset(r.left + 12 + w, r.center.dy),
        Offset(-0.8 * w, 0),
      );
      await tester.pumpAndSettle();
      expect(find.text('0 battles'), findsOneWidget);
      final showAll = find.widgetWithText(VistaPillButton, 'Show all');
      clear(tester, showAll, '$name Show all');
      expect(showAll.hitTestable(), findsOneWidget);
      await tester.tap(showAll);
      await tester.pumpAndSettle();
      expect(find.text('3 battles'), findsOneWidget);

      // Ask with no match: the hint shows, clear of the pill.
      final ask = find.descendant(
        of: find.byType(ArenaScreen),
        matching: find.byType(TextField),
      );
      await tester.enterText(ask, 'doge');
      await tester.pumpAndSettle();
      clear(tester, find.text('Try BTC, ETH, SOL'), '$name Ask hint');
      expect(tester.takeException(), isNull);
    });

    testWidgets('ETH opinions dock and header on $name', (tester) async {
      await launch(tester);
      await tester.scrollUntilVisible(
        find.text('+7 more opinions'),
        200,
        scrollable: find
            .descendant(of: list(), matching: find.byType(Scrollable))
            .first,
      );
      // scrollUntilVisible stops with the pill half in view; centre it.
      await tester.ensureVisible(find.text('+7 more opinions'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('+7 more opinions'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      for (final e in find.textContaining('Crowd split').evaluate()) {
        // ignore: avoid_print
        print('PROBE $name text: ${(e.widget as Text).data}');
      }
      // ignore: avoid_print
      print('PROBE $name on opinions: ${find.text('Follow Bear').evaluate().length}');
      expect(find.text('Crowd split 28% bull'), findsOneWidget);
      clear(tester, find.text('Follow Bear'), '$name Follow Bear');
      clear(tester, find.text('Crowd split · 9 opinions'), '$name dock label');
      // The dock label must not be ellipsized away at 1.3x.
      final label = tester.renderObject<RenderParagraph>(
        find.text('Crowd split · 9 opinions'),
      );
      // ignore: avoid_print
      print('PROBE $name dock label overflow=${label.didExceedMaxLines}');
    });
  }
}
