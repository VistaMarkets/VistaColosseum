// Phase 5 review iter 1 probe (read-only evidence, not part of the suite).
// Run from a copy of app/: flutter test test/maker_probe_test.dart
// 1. Each phone at 1.3x: card, button, nav and pill rects; button hit-testable;
//    card inside the page; no overflow.
// 2. Expiry follows Scenario.clock: advance it, the live card flips to Expired;
//    Scenario.reset() flips it back.
// 3. Semantics: live button is its own enabled button node with a tap action;
//    expired has no tap action; badge is a separate non-button node.
// 4. The expired test's BottomSheet finder is not vacuous (live tap finds one).
import 'dart:io';
import 'dart:ui' show SemanticsFlag;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vista_colosseum/design_system/design_system.dart';
import 'package:vista_colosseum/features/account/account_state.dart';
import 'package:vista_colosseum/features/home/home_screen.dart';
import 'package:vista_colosseum/features/home/maker_suggestion.dart';
import 'package:vista_colosseum/features/settings/settings_state.dart';
import 'package:vista_colosseum/features/trade/order_ticket.dart';
import 'package:vista_colosseum/features/trade/trade_mock.dart';
import 'package:vista_colosseum/main.dart';
import 'package:vista_colosseum/scenario/scenario.dart';

import 'home_screen_test.dart' as h show phones;
import 'scenario_test.dart' show state;

const pill = 'Simulated · fixture-v1';

void main() {
  // Reuse the suite's setUpAll(_loadFonts) by running nothing from it: load fonts here.
  setUpAll(() async {
    // h.main registers the suite's own tests; we only want its font loader,
    // so load OpenRunde the same way.
    final loader = FontLoader('OpenRunde');
    for (final w in ['Regular', 'Medium', 'Semibold', 'Bold']) {
      final bytes = File('assets/fonts/OpenRunde-$w.otf').readAsBytesSync();
      loader.addFont(Future.value(ByteData.sublistView(bytes)));
    }
    await loader.load();
  });
  setUp(() {
    Scenario.reset();
    AccountState.listMarket('MAYA');
    SettingsState.reset();
  });
  final [live, expired] = makerSuggestions;

  Future<void> launch(WidgetTester tester, Size size, EdgeInsets pad) async {
    tester.view
      ..physicalSize = size * 3
      ..devicePixelRatio = 3
      ..padding = FakeViewPadding(top: pad.top * 3, bottom: pad.bottom * 3);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const VistaColosseumApp());
    await tester.pumpAndSettle();
  }

  Future<void> turnTo(WidgetTester tester, Suggestion s) async {
    final feed = tester.widget<PageView>(find.byType(PageView).first);
    feed.controller!.jumpToPage(homeFeed.indexOf(s));
    await tester.pumpAndSettle();
  }

  for (final MapEntry(key: name, value: (size, pad)) in h.phones.entries) {
    testWidgets('PROBE layout $name 1.3x', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await launch(tester, size, pad);
      for (final (s, label) in [(live, 'Trade this'), (expired, 'Expired')]) {
        await turnTo(tester, s);
        final ex = tester.takeException();
        final card = tester.getRect(find.byType(MakerSuggestionCard));
        final page = tester.getRect(find.byType(PageView).first);
        final btn = tester.getRect(find.widgetWithText(VistaPrimaryButton, label));
        final nav = tester.getRect(find.byType(VistaBottomNav));
        final p = tester.getRect(find.bySemanticsLabel(pill));
        final hit = find.text(label).hitTestable().evaluate().length;
        final ref = find.textContaining('Reference ').hitTestable().evaluate().length;
        // ignore: avoid_print
        print('PROBE $name ${s.asset} exception=$ex card=$card page=$page '
            'btn=$btn nav=$nav pill=$p btnHit=$hit refHit=$ref '
            'cardInPage=${page.contains(card.topLeft) && page.contains(card.bottomRight - const Offset(0.01, 0.01))} '
            'btnOverNav=${btn.overlaps(nav)} btnOverPill=${btn.overlaps(p)}');
        expect(ex, isNull);
        expect(hit, 1);
      }
    });
  }

  testWidgets('PROBE expiry follows Scenario.clock and reset', (tester) async {
    await launch(tester, const Size(402, 874), EdgeInsets.zero);
    await turnTo(tester, live);
    expect(find.text('Trade this'), findsOneWidget);
    Scenario.clock.value = TradeMock.chartEnd.add(const Duration(hours: 5));
    await tester.pumpAndSettle();
    final flipped = find.text('Trade this').evaluate().length;
    final exp = find.widgetWithText(VistaPrimaryButton, 'Expired');
    final enabled = exp.evaluate().isEmpty
        ? null
        : tester.widget<VistaPrimaryButton>(exp).enabled;
    final meta = find.textContaining('expired 1h ago').evaluate().length;
    // ignore: avoid_print
    print('PROBE clock+5h: TradeThis=$flipped expiredEnabled=$enabled "expired 1h ago"=$meta');
    expect(flipped, 0);
    expect(enabled, isFalse);
    Scenario.reset();
    AccountState.listMarket('MAYA');
    await tester.pumpAndSettle();
    final back = find.text('Trade this').evaluate().length;
    // ignore: avoid_print
    print('PROBE after Scenario.reset(): TradeThis=$back');
    expect(back, 1);
  });

  testWidgets('PROBE semantics and BottomSheet finder', (tester) async {
    final handle = tester.ensureSemantics();
    await launch(tester, const Size(402, 874), EdgeInsets.zero);
    await turnTo(tester, live);
    final t = tester.getSemantics(find.bySemanticsLabel('Trade this')).getSemanticsData();
    final badge = tester
        .getSemantics(find.bySemanticsLabel(RegExp('Maker suggestion')))
        .getSemanticsData();
    // ignore: avoid_print
    print('PROBE live node label="${t.label}" button=${t.hasFlag(SemanticsFlag.isButton)} '
        'enabled=${t.hasFlag(SemanticsFlag.isEnabled)} tap=${t.hasAction(SemanticsAction.tap)}');
    // ignore: avoid_print
    print('PROBE badge node label="${badge.label}" button=${badge.hasFlag(SemanticsFlag.isButton)}');
    final before = state();
    await tester.tap(find.text('Trade this'));
    await tester.pumpAndSettle();
    // ignore: avoid_print
    print('PROBE live tap: BottomSheet=${find.byType(BottomSheet).evaluate().length} '
        'ticket=${tester.widget<FeedOrderTicket>(find.byType(FeedOrderTicket)).symbol}/'
        '${tester.widget<FeedOrderTicket>(find.byType(FeedOrderTicket)).side}');
    expect(find.byType(BottomSheet), findsOneWidget);
    Navigator.of(tester.element(find.byType(FeedOrderTicket))).pop();
    await tester.pumpAndSettle();
    await turnTo(tester, expired);
    final e = tester.getSemantics(find.bySemanticsLabel('Expired')).getSemanticsData();
    // ignore: avoid_print
    print('PROBE expired node label="${e.label}" button=${e.hasFlag(SemanticsFlag.isButton)} '
        'enabled=${e.hasFlag(SemanticsFlag.isEnabled)} tap=${e.hasAction(SemanticsAction.tap)}');
    expect(e.hasAction(SemanticsAction.tap), isFalse);
    expect(state(), equals(before));
    handle.dispose();
  });
}
