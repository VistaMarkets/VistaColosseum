// Phase 7 review iter 1 probe (reviewer-owned, not product code). Copied into
// mut-app/test/ and run there; never part of the app's suite.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vista_colosseum/features/market/market_mock.dart';
import 'package:vista_colosseum/features/market/receipt_screens.dart';
import 'package:vista_colosseum/features/market/trader_market_screen.dart';
import 'package:vista_colosseum/features/market/your_market_screen.dart';
import 'package:vista_colosseum/features/profile/private_profile_screen.dart';
import 'package:vista_colosseum/features/profile/profile_screen.dart';
import 'package:vista_colosseum/features/settings/settings_state.dart';
import 'package:vista_colosseum/features/simulation/simulation_indicator.dart';
import 'package:vista_colosseum/scenario/scenario.dart';

import 'home_screen_test.dart' show expectPillClear, phones, pill;
import 'trader_record_test.dart'
    show pumpApp, tapAndSettle, toRecord, inPanel, callsBy, pairCaption;

void p(String s) => debugPrint('PROBE $s');

List<CallReceipt> flipFirst(String author, CallOutcome to) {
  var done = false;
  return [
    for (final c in Scenario.callReceipts.value)
      if (!done && c.author == author && c.result != CallOutcome.open)
        (() {
          done = true;
          return CallReceipt(
            id: c.id, author: c.author, asset: c.asset, side: c.side,
            entryPrice: c.entryPrice, entryAt: c.entryAt, rule: c.rule,
            result: to, settledAt: c.settledAt, odds: c.odds,
            sizeCents: c.sizeCents,
          );
        })()
      else
        c,
  ];
}

Future<void> _loadFonts() async {
  final loader = FontLoader('OpenRunde');
  for (final w in ['Regular', 'Medium', 'Semibold', 'Bold']) {
    final bytes = File('assets/fonts/OpenRunde-$w.otf').readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
}

void main() {
  setUpAll(_loadFonts);
  setUp(() {
    Scenario.reset();
    SettingsState.reset();
  });

  testWidgets('P1 outcome change changes metrics live; pair diverges', (t) async {
    await pumpApp(t, home: const ProfileScreen(handle: 'kilo.sol'),
        size: const Size(402, 2400));
    expect(inPanel('kilo.sol', find.text('Hit rate 67%')), findsOneWidget);
    Scenario.callReceipts.value = flipFirst('kilo.sol', CallOutcome.wrong);
    await t.pumpAndSettle();
    p('kilo after flip ${Scenario.record('kilo.sol')}');
    p('lunaq after flip ${Scenario.record('lunaq')}');
    expect(Scenario.record('kilo.sol') == Scenario.record('lunaq'), isFalse);
    expect(inPanel('kilo.sol', find.text('Hit rate 33%')), findsOneWidget);
    expect(inPanel('kilo.sol', find.text('1 right')), findsOneWidget);
    // Header stats (Settled / Right) follow too.
    final rightStat = find.text('1');
    p('header "1" widgets=${rightStat.evaluate().length}');
  });

  testWidgets('P2 caption N and clock come from Scenario, live', (t) async {
    await pumpApp(t, home: const ProfileScreen(handle: 'lunaq'),
        size: const Size(402, 2400));
    expect(find.text(pairCaption), findsOneWidget);
    Scenario.clock.value = DateTime(2026, 10, 1, 9, 5);
    await t.pumpAndSettle();
    final cap = find.textContaining('Illustrative index');
    p('after clock move: ${(t.widget<Text>(cap)).data}');
    expect(find.text('Illustrative index · based on 3 settled calls · as of 1 Oct 09:05'), findsOneWidget);
    Scenario.callReceipts.value = [
      for (final c in Scenario.callReceipts.value)
        if (c.author != 'lunaq' || c.result == CallOutcome.right) c,
    ];
    await t.pumpAndSettle();
    p('lunaq rights only: ${(t.widget<Text>(cap)).data} | ${Scenario.record('lunaq')}');
    // chart vs caption order (test name says "above the index chart")
    Scenario.reset();
    await t.pumpAndSettle();
    final chartY = t.getRect(find.byType(ProfileIndexChart)).top;
    final capY = t.getRect(find.textContaining('Illustrative index')).top;
    p('chart.top=$chartY caption.top=$capY captionAboveChart=${capY < chartY}');
  });

  testWidgets('P3 trader with no calls at all (Arena mirin) and kaito', (t) async {
    for (final h in ['mirin', '0xreal', 'renatafx', 'kaito.eth']) {
      await pumpApp(t, home: ProfileScreen(handle: h), size: const Size(402, 2400));
      p('$h exception=${t.takeException()} note=${find.text(TraderRecordPanel.unavailableNote).evaluate().length} chart=${find.byType(ProfileIndexChart).evaluate().length} items=${find.byType(CallRecordItem).evaluate().length}');
    }
  });

  testWidgets('P4 Arena accuracy vs derived record', (t) async {
    await pumpApp(t, size: const Size(402, 2400));
    await t.tap(find.bySemanticsLabel('Arena'));
    await t.pumpAndSettle();
    for (final s in ['71% accuracy', '77% accuracy', '82% accuracy', '79% accuracy']) {
      p('arena "$s" shown=${find.text(s).evaluate().length}');
    }
    for (final h in ['kilo.sol', 'lunaq', 'maya.eth', 'mirin', '0xreal', 'renatafx']) {
      p('record $h = ${Scenario.record(h).hitRatePct}');
    }
    await tapAndSettle(t, find.text('kilo.sol').hitTestable());
    p('after tap kilo.sol: profile=${find.byType(ProfileScreen).evaluate().length} hit67=${find.text('Hit rate 67%').evaluate().length}');
  });

  testWidgets('P5 trader-market Record: every item opens its own receipt', (t) async {
    const h = 'lunaq';
    await pumpApp(t, home: const TraderMarketScreen(handle: h), size: const Size(402, 1600));
    await toRecord(t);
    for (final c in callsBy(h)) {
      await tapAndSettle(t, find.text(c.rule!));
      expect(find.descendant(of: find.byType(CallReceiptScreen), matching: find.text(c.rule!)), findsOneWidget);
      expect(find.descendant(of: find.byType(CallReceiptScreen), matching: find.text(c.status)), findsOneWidget);
      Navigator.of(t.element(find.byType(CallReceiptScreen))).pop();
      await t.pumpAndSettle();
    }
    p('trader-market lunaq all ${callsBy(h).length} items open own receipt');
  });

  testWidgets('P6 resetDemo restores receipts, clock and panel', (t) async {
    await pumpApp(t, size: const Size(402, 2400));
    final nav = t.state<NavigatorState>(find.byType(Navigator).first);
    nav.push(ProfileScreen.route('kilo.sol'));
    await t.pumpAndSettle();
    Scenario.callReceipts.value = flipFirst('kilo.sol', CallOutcome.wrong);
    Scenario.clock.value = DateTime(2026, 10, 1, 9, 5);
    await t.pumpAndSettle();
    expect(find.text('Hit rate 33%'), findsOneWidget);
    resetDemo(t.element(find.byType(ProfileScreen)));
    await t.pumpAndSettle();
    p('after reset: same(seedCalls)=${identical(Scenario.callReceipts.value, seedCalls)} clock=${Scenario.clock.value} rec=${Scenario.record('kilo.sol')}');
    nav.push(ProfileScreen.route('kilo.sol'));
    await t.pumpAndSettle();
    expect(find.text(pairCaption), findsOneWidget);
    expect(find.text('Hit rate 67%'), findsOneWidget);
    p('reset restores panel: ok');
  });

  testWidgets('P7 pill clearance at 1.3x: trader-market Record, Your market, nara', (t) async {
    t.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
    Scenario.reset(withMarket: true);
    for (final name in phones.keys) {
      final (size, padding) = phones[name]!;
      Future<void> check(String what, String author) async {
        final rule = find.text(callsBy(author).last.rule!);
        if (rule.evaluate().isEmpty) {
          await t.scrollUntilVisible(rule, 100,
              scrollable: find.byWidgetPredicate((w) =>
                  w is Scrollable && w.axisDirection == AxisDirection.down).first);
        }
        final last = find.ancestor(of: rule, matching: find.byType(CallRecordItem));
        await t.ensureVisible(last);
        await t.pumpAndSettle();
        final ex = t.takeException();
        final r = t.getRect(last);
        final pr = t.getRect(find.bySemanticsLabel(pill));
        p('$name $what last=$r pill=$pr overlap=${r.overlaps(pr)} ex=$ex');
        expectPillClear(t, last);
      }
      await pumpApp(t, home: const TraderMarketScreen(handle: 'kilo.sol'), size: size, padding: padding);
      await toRecord(t);
      await check('trader-market Record', 'kilo.sol');
      await pumpApp(t, home: const YourMarketScreen(), size: size, padding: padding);
      await check('Your market RECORD', 'maya.eth');
      p('$name your-market caption=${find.textContaining('Illustrative index').evaluate().map((e) => (e.widget as Text).data).toList()}');
      await pumpApp(t, home: const PrivateProfileScreen(handle: 'nara'), size: size, padding: padding);
      p('$name nara caption=${find.textContaining('Illustrative index').evaluate().map((e) => (e.widget as Text).data).toList()}');
      await check('nara private', 'nara');
    }
  });
}
