import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vista_colosseum/design_system/design_system.dart';
import 'package:vista_colosseum/features/home/home_screen.dart';
import 'package:vista_colosseum/features/home/mock_trade_idea.dart';
import 'package:vista_colosseum/features/live/live_feed.dart';
import 'package:vista_colosseum/features/market/market_mock.dart';
import 'package:vista_colosseum/features/market/receipt_screens.dart';
import 'package:vista_colosseum/features/market/trader_market_screen.dart';
import 'package:vista_colosseum/features/market/your_market_screen.dart';
import 'package:vista_colosseum/features/portfolio/portfolio_mock.dart';
import 'package:vista_colosseum/features/profile/private_profile_screen.dart';
import 'package:vista_colosseum/features/profile/profile_screen.dart';
import 'package:vista_colosseum/features/settings/settings_state.dart';
import 'package:vista_colosseum/main.dart';
import 'package:vista_colosseum/scenario/scenario.dart';

import 'home_screen_test.dart' show expectPillClear, phones;

/// The app's font, so text measures as on a device.
Future<void> _loadFonts() async {
  final loader = FontLoader('OpenRunde');
  for (final w in ['Regular', 'Medium', 'Semibold', 'Bold']) {
    final bytes = File('assets/fonts/OpenRunde-$w.otf').readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
}

/// The seeded pair: the same call outcomes behind different paper sizes.
const pair = ('kilo.sol', 'lunaq');

/// Seeded with an open call and nothing settled.
const fresh = 'kestrel';

const unavailableNote = 'No settled calls yet — record unavailable';

/// Any verdicts strip, whatever its count.
final verdicts = RegExp(r'^Last \d+ verdicts$');
const pairCaption =
    'Illustrative index · based on 3 settled calls · as of 26 Sep 14:45';

List<CallReceipt> callsBy(String author) => [
  for (final c in Scenario.callReceipts.value)
    if (c.author == author) c,
];

Finder panelFor(String handle) =>
    find.byWidgetPredicate((w) => w is TraderRecordPanel && w.handle == handle);

Finder inPanel(String handle, Finder f) =>
    find.descendant(of: panelFor(handle), matching: f);

/// The profile header's [label] count, showing [value].
Finder countStat(String label, String value) => find.byWidgetPredicate(
  (w) => w is VistaCountStat && w.label == label && w.value == value,
);

Finder onReceipt(Finder f) =>
    find.descendant(of: find.byType(CallReceiptScreen), matching: f);

/// The profile's scrolling list.
Finder get profileList => find
    .descendant(
      of: find.byType(ListView).last,
      matching: find.byType(Scrollable),
    )
    .first;

Future<void> pumpApp(
  WidgetTester tester, {
  Widget? home,
  Size size = const Size(402, 874),
  EdgeInsets padding = EdgeInsets.zero,
}) async {
  tester.view
    ..physicalSize = size * 3
    ..devicePixelRatio = 3
    ..padding = FakeViewPadding(
      top: padding.top * 3,
      bottom: padding.bottom * 3,
    );
  addTearDown(tester.view.reset);
  // A fresh tree each time: a re-pumped screen would keep the last one's
  // scroll offset.
  await tester.pumpWidget(const SizedBox());
  await tester.pumpWidget(
    home == null ? const VistaColosseumApp() : VistaColosseumApp(home: home),
  );
  await tester.pumpAndSettle();
}

Future<void> tapAndSettle(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

/// The trader market's panels, swiped to Record.
Future<void> toRecord(WidgetTester tester) async {
  for (var i = 0; i < 2; i++) {
    await tester.fling(find.byType(PageView), const Offset(-300, 0), 1500);
    await tester.pumpAndSettle();
  }
}

void main() {
  setUpAll(_loadFonts);

  setUp(() {
    Scenario.reset();
    SettingsState.reset();
  });

  test('two traders, same outcomes, different sizes → equal metrics', () {
    final a = callsBy(pair.$1);
    final b = callsBy(pair.$2);
    // The same outcomes, call for call...
    expect(a, isNotEmpty);
    expect(a.map((c) => c.result), b.map((c) => c.result));
    // ...behind different paper sizes, every one stated, so a record that
    // weighed calls by size would tell the two apart.
    final sizes = [
      for (final c in [...a, ...b]) c.sizeCents,
    ];
    expect(sizes, everyElement(isNotNull));
    expect(a.map((c) => c.sizeCents), isNot(b.map((c) => c.sizeCents)));
    int rightShareBySize(List<CallReceipt> calls) {
      var right = 0, settled = 0;
      for (final c in calls) {
        if (c.result == CallOutcome.open) continue;
        settled += c.sizeCents!;
        if (c.result == CallOutcome.right) right += c.sizeCents!;
      }
      return right * 100 ~/ settled;
    }

    expect(rightShareBySize(a), isNot(rightShareBySize(b)));

    expect(Scenario.record(pair.$1), Scenario.record(pair.$2));
    expect(Scenario.record(pair.$1), (
      settled: 3,
      right: 2,
      wrong: 1,
      open: 1,
      unavailable: 0,
      hitRatePct: 67,
      asOf: Scenario.clock.value,
    ));
  });

  test('the hit rate is an integer percent rounded half up, read from the '
      'call receipts and the clock at the time of asking', () {
    CallReceipt call(int i, CallOutcome? result) => CallReceipt(
      id: 'c$i',
      author: 'x',
      asset: 'BTC',
      result: result,
      settledAt: 'Sep 20',
    );
    // 1 right of 8 settled is 12.5%: half up gives 13, truncation 12. An
    // open call and one with no stated result do not count as settled.
    Scenario.callReceipts.value = [
      call(0, CallOutcome.right),
      for (var i = 1; i < 8; i++) call(i, CallOutcome.wrong),
      call(8, CallOutcome.open),
      call(9, null),
    ];
    final later = Scenario.clock.value.add(const Duration(hours: 2));
    Scenario.clock.value = later;
    expect(Scenario.record('x'), (
      settled: 8,
      right: 1,
      wrong: 7,
      open: 1,
      unavailable: 1,
      hitRatePct: 13,
      asOf: later,
    ));
    // 1 right of 3 is 33.3%: half up gives 33, ceiling 34.
    Scenario.callReceipts.value = [
      call(0, CallOutcome.right),
      call(1, CallOutcome.wrong),
      call(2, CallOutcome.wrong),
    ];
    expect(Scenario.record('x').hitRatePct, 33);
    // Nothing settled: no hit rate at all, not 0%.
    expect(Scenario.record('nobody').hitRatePct, isNull);
    expect(Scenario.record('nobody').settled, 0);
  });

  test('a call settled after the clock is open at the clock; a verdict '
      'with no settlement date is unavailable', () {
    final asOf = Scenario.clock.value;
    // maya.eth's Friday call settled Sep 25, before the 26 Sep clock; her
    // Oct 2 call is Wrong in the fixture but settles after the clock, so
    // it is still open there. One settled call gives her 100%.
    expect(Scenario.record(PortfolioMock.handle), (
      settled: 1,
      right: 1,
      wrong: 0,
      open: 2,
      unavailable: 0,
      hitRatePct: 100,
      asOf: asOf,
    ));
    CallReceipt wrongOn(String settledAt) => CallReceipt(
      id: settledAt,
      author: 'x',
      asset: 'BTC',
      result: CallOutcome.wrong,
      settledAt: settledAt,
    );
    Scenario.callReceipts.value = [
      wrongOn('Sep 26'),
      wrongOn('Sep 27'),
      wrongOn('Tue 16:00'),
    ];
    expect(Scenario.record('x'), (
      settled: 1,
      right: 0,
      wrong: 1,
      open: 1,
      unavailable: 1,
      hitRatePct: 0,
      asOf: asOf,
    ));
    // A day on, the Sep 27 call has settled too.
    Scenario.clock.value = asOf.add(const Duration(days: 1));
    expect(Scenario.record('x').settled, 2);
    expect(Scenario.record('x').open, 0);
  });

  test('a call\'s detail follows the outcome it is shown with', () {
    final oct2 = YourMarketMock.record.singleWhere(
      (c) => c.id == 'maya-eth-4000-oct2',
    );
    final at = Scenario.outcomeAt(oct2, Scenario.clock.value);
    expect(at, CallOutcome.open);
    expect(outcomeDetail(at, oct2.odds), 'published · at 31%');
    expect(outcomeDetail(CallOutcome.wrong, '31%'), 'at 31%');
    expect(outcomeDetail(null, null), 'at unavailable');
    expect(oct2.detail, 'at 31%');
  });

  testWidgets('both traders\' panels show the same sample size, hit rate and '
      'as-of time below the index chart', (tester) async {
    for (final handle in [pair.$1, pair.$2]) {
      await pumpApp(tester, home: ProfileScreen(handle: handle));
      expect(inPanel(handle, find.text(pairCaption)), findsOneWidget);
      expect(inPanel(handle, find.text('Hit rate 67%')), findsOneWidget);
      expect(inPanel(handle, find.text('3 settled')), findsOneWidget);
      // The header shows the same derived counts, not stored ones.
      expect(countStat('Settled', '3'), findsOneWidget);
      expect(countStat('Right', '2'), findsOneWidget);
      expect(find.byType(ProfileIndexChart), findsOneWidget);
      expect(
        tester.getRect(panelFor(handle)).top,
        greaterThanOrEqualTo(
          tester.getRect(find.byType(ProfileIndexChart)).bottom,
        ),
      );
      // Their three settled calls, not a stored ten.
      expect(find.bySemanticsLabel('Last 3 verdicts'), findsOneWidget);
    }
  });

  testWidgets('a call with no outcome shows in the panel as unavailable, '
      'never dropped', (tester) async {
    CallReceipt noOutcome(String author) =>
        CallReceipt(id: '$author-none', author: author, asset: 'SOL');
    Scenario.callReceipts.value = [
      ...Scenario.callReceipts.value,
      noOutcome(pair.$1),
      noOutcome(fresh),
    ];
    await pumpApp(tester, home: ProfileScreen(handle: pair.$1));
    expect(inPanel(pair.$1, find.text('1 unavailable')), findsOneWidget);
    expect(inPanel(pair.$1, find.text('3 settled')), findsOneWidget);
    await pumpApp(tester, home: const ProfileScreen(handle: fresh));
    expect(
      inPanel(fresh, find.text('$unavailableNote · 1 unavailable')),
      findsOneWidget,
    );
  });

  testWidgets('the verdicts strip shows the trader\'s last 10 settled calls, '
      'oldest to newest, and no open call', (tester) async {
    CallReceipt call(int i, CallOutcome result) => CallReceipt(
      id: 'v$i',
      author: 'x',
      asset: 'BTC',
      result: result,
      settledAt: result == CallOutcome.open ? null : 'Sep 20',
    );
    // Twelve settled calls and an open one, oldest first: the strip keeps
    // the last ten settled, in order.
    final calls = [
      call(0, CallOutcome.wrong),
      call(1, CallOutcome.wrong),
      for (var i = 2; i < 11; i++) call(i, CallOutcome.right),
      call(11, CallOutcome.open),
      call(12, CallOutcome.wrong),
    ];
    Scenario.callReceipts.value = calls;
    await pumpApp(tester, home: const ProfileScreen(handle: 'x'));
    expect(find.bySemanticsLabel('Last 10 verdicts'), findsOneWidget);
    final dots = tester.widgetList<DecoratedBox>(
      find.descendant(
        of: find.byType(VerdictStrip),
        matching: find.byType(DecoratedBox),
      ),
    );
    expect(
      [for (final d in dots) (d.decoration as BoxDecoration).color],
      [
        for (final c in [...calls.sublist(2, 11), calls[12]]) c.color,
      ],
    );
  });

  testWidgets('zero-history trader → unavailable state, no crash', (
    tester,
  ) async {
    expect(Scenario.record(fresh).settled, 0);
    expect(callsBy(fresh), isNotEmpty); // calls, none settled
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    for (final MapEntry(key: name, value: (size, padding)) in phones.entries) {
      await pumpApp(
        tester,
        home: const ProfileScreen(handle: fresh),
        size: size,
        padding: padding,
      );
      expect(tester.takeException(), isNull, reason: name);
      expect(inPanel(fresh, find.text(unavailableNote)), findsOneWidget);
      // The header counts what the store holds: nothing settled.
      expect(countStat('Settled', '0'), findsOneWidget, reason: name);
      expect(countStat('Right', '0'), findsOneWidget, reason: name);
      // No index chart and no index copy.
      expect(find.byType(ProfileIndexChart), findsNothing, reason: name);
      expect(find.bySemanticsLabel(verdicts), findsNothing, reason: name);
      expect(find.textContaining('Illustrative index'), findsNothing);
      expect(find.textContaining('Hit rate'), findsNothing);
      // The open call still lists, clear of the simulation pill.
      final call = find.byType(CallRecordItem);
      await tester.scrollUntilVisible(call, 200, scrollable: profileList);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: name);
      expectPillClear(tester, call);
    }

    // The trader market's Record panel says the same.
    await pumpApp(tester, home: const TraderMarketScreen(handle: fresh));
    await toRecord(tester);
    expect(tester.takeException(), isNull);
    expect(inPanel(fresh, find.text(unavailableNote)), findsOneWidget);
    expect(find.textContaining('Illustrative index'), findsNothing);
  });

  testWidgets('the record panel renders without overflow at 1.3x on every '
      'phone, its last call clear of the pill', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    for (final MapEntry(key: name, value: (size, padding)) in phones.entries) {
      await pumpApp(
        tester,
        home: ProfileScreen(handle: pair.$1),
        size: size,
        padding: padding,
      );
      final caption = find.text(pairCaption);
      await tester.scrollUntilVisible(caption, 200, scrollable: profileList);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: name);
      final last = find.text(callsBy(pair.$1).last.rule!);
      await tester.scrollUntilVisible(last, 200, scrollable: profileList);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: name);
      expectPillClear(tester, find.byType(CallRecordItem).last);

      // The trader market's Record panel, at the same scale.
      await pumpApp(
        tester,
        home: TraderMarketScreen(handle: pair.$1),
        size: size,
        padding: padding,
      );
      await toRecord(tester);
      expect(tester.takeException(), isNull, reason: name);
      expect(inPanel(pair.$1, find.text(pairCaption)), findsOneWidget);
    }
  });

  testWidgets('a trader with no call receipts gets no CALLS heading', (
    tester,
  ) async {
    const none = 'kaito.eth';
    expect(callsBy(none), isEmpty);
    await pumpApp(
      tester,
      home: const ProfileScreen(handle: none),
      size: const Size(402, 2400),
    );
    expect(find.text('HOLDING NOW'), findsOneWidget);
    expect(find.text('CALLS'), findsNothing);
    expect(find.text('All receipts ›'), findsNothing);

    // A trader with calls keeps it, at the same size.
    await pumpApp(
      tester,
      home: const ProfileScreen(handle: 'lunaq'),
      size: const Size(402, 2400),
    );
    expect(find.text('CALLS'), findsOneWidget);
  });

  testWidgets('Profile CALLS lists the trader\'s own call receipts and each '
      'opens its receipt', (tester) async {
    const handle = 'lunaq';
    final calls = callsBy(handle);
    await pumpApp(
      tester,
      home: const ProfileScreen(handle: handle),
      size: const Size(402, 2400),
    );
    expect(find.byType(CallRecordItem), findsNWidgets(calls.length));
    // The one generic sample every profile used to show is gone.
    for (final sample in [
      r'SOL loses $190 by Sep 15',
      r'BTC reclaims $66,000 by Tue',
      'Arena 14',
    ]) {
      expect(find.text(sample), findsNothing);
    }
    for (final c in calls) {
      await tapAndSettle(tester, find.text(c.rule!));
      expect(onReceipt(find.text(c.rule!)), findsOneWidget);
      expect(onReceipt(find.text(handle)), findsOneWidget);
      expect(onReceipt(find.text(c.status)), findsOneWidget);
      expect(onReceipt(find.text(formatCents(c.sizeCents!))), findsOneWidget);
      Navigator.of(tester.element(find.byType(CallReceiptScreen))).pop();
      await tester.pumpAndSettle();
    }
  });

  testWidgets('the trader-market Record panel lists the trader\'s call '
      'receipts and an item opens its receipt', (tester) async {
    final handle = pair.$1;
    final calls = callsBy(handle);
    await pumpApp(
      tester,
      home: TraderMarketScreen(handle: handle),
      size: const Size(402, 1600),
    );
    await toRecord(tester);
    expect(inPanel(handle, find.text(pairCaption)), findsOneWidget);
    expect(find.byType(CallRecordItem), findsNWidgets(calls.length));
    for (final sample in [
      r'AVAX holds $40 to Sep 20',
      r'ARB reaches $1.40 by Oct 15',
    ]) {
      expect(find.text(sample), findsNothing);
    }
    await tapAndSettle(tester, find.text(calls.first.rule!));
    expect(onReceipt(find.text(calls.first.rule!)), findsOneWidget);
    expect(onReceipt(find.text(handle)), findsOneWidget);
  });

  testWidgets('Record since dates from the trader\'s first call, and a '
      'trader with no calls has no Record since line', (tester) async {
    expect(callsBy(pair.$1).first.entryAt, 'Sep 8');
    await pumpApp(tester, home: ProfileScreen(handle: pair.$1));
    expect(find.text('Record since Sep 8'), findsOneWidget);

    expect(callsBy('kaito.eth'), isEmpty);
    await pumpApp(tester, home: const ProfileScreen(handle: 'kaito.eth'));
    expect(find.textContaining('Record since'), findsNothing);
  });

  testWidgets('feed card trader link opens the record panel', (tester) async {
    await pumpApp(tester);
    final feed = tester.widget<PageView>(find.byType(PageView).first);
    feed.controller!.jumpToPage(
      homeFeed.indexWhere((i) => i is TradeIdea && i.callerHandle == pair.$1),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(pair.$1).hitTestable());
    await tester.pumpAndSettle();
    expect(find.byType(ProfileScreen), findsOneWidget);
    expect(inPanel(pair.$1, find.text(pairCaption)), findsOneWidget);
    expect(inPanel(pair.$1, find.text('Hit rate 67%')), findsOneWidget);
  });

  testWidgets('Arena card trader link opens the record panel', (tester) async {
    await pumpApp(tester, size: const Size(402, 2400));
    await tester.tap(find.bySemanticsLabel('Arena'));
    await tester.pumpAndSettle();
    // The tapped side's accuracy is the panel's hit rate, read from the
    // receipts at render time, never a stored figure.
    Finder side(String text) => find.descendant(
      of: find
          .ancestor(of: find.text(pair.$2), matching: find.byType(Column))
          .first,
      matching: find.text(text),
    );
    expect(side('67% accuracy'), findsOneWidget);
    await tapAndSettle(tester, find.text(pair.$2).hitTestable());
    expect(find.byType(ProfileScreen), findsOneWidget);
    expect(inPanel(pair.$2, find.text(pairCaption)), findsOneWidget);
    expect(inPanel(pair.$2, find.text('Hit rate 67%')), findsOneWidget);

    // Drop lunaq's wrong call: panel and card both follow, so a constant
    // that happens to match the seed fails here.
    Scenario.callReceipts.value = [
      for (final c in Scenario.callReceipts.value)
        if (c.author != pair.$2 || c.result != CallOutcome.wrong) c,
    ];
    await tester.pumpAndSettle();
    expect(inPanel(pair.$2, find.text('Hit rate 100%')), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Back').last);
    await tester.pumpAndSettle();
    expect(side('100% accuracy'), findsOneWidget);
  });

  testWidgets('each panel shows its own trader\'s record, right and wrong '
      'apart', (tester) async {
    // kilo.sol has 2 right and 1 wrong, so swapped labels would show.
    await pumpApp(
      tester,
      home: ProfileScreen(handle: pair.$1),
      size: const Size(402, 2400),
    );
    expect(inPanel(pair.$1, find.text('2 right')), findsOneWidget);
    expect(inPanel(pair.$1, find.text('1 wrong')), findsOneWidget);
    expect(inPanel(pair.$1, find.text('1 open')), findsOneWidget);

    // nara's record is not the pair's, so a panel that drew stored figures
    // or another trader's record would show the wrong numbers.
    final m = Scenario.record('nara');
    expect(m.hitRatePct, isNotNull);
    expect(m.settled, isNot(Scenario.record(pair.$1).settled));
    await pumpApp(
      tester,
      home: const PrivateProfileScreen(handle: 'nara'),
      size: const Size(402, 2400),
    );
    expect(
      inPanel(
        'nara',
        find.textContaining('based on ${m.settled} settled call'),
      ),
      findsOneWidget,
    );
    expect(inPanel('nara', find.text('${m.settled} settled')), findsOneWidget);
    expect(
      inPanel('nara', find.text('Hit rate ${m.hitRatePct}%')),
      findsOneWidget,
    );
    expect(inPanel('nara', find.text('${m.open} open')), findsOneWidget);

    // Your market's panel is the user's own.
    await pumpApp(
      tester,
      home: const YourMarketScreen(),
      size: const Size(402, 2400),
    );
    expect(panelFor(PortfolioMock.handle), findsOneWidget);
  });

  testWidgets('a mounted panel follows the demo clock', (tester) async {
    expect(Scenario.record('nara').hitRatePct, isNotNull);
    await pumpApp(
      tester,
      home: const PrivateProfileScreen(handle: 'nara'),
      size: const Size(402, 2400),
    );
    Scenario.clock.value = Scenario.clock.value.add(
      const Duration(days: 1, hours: 2),
    );
    await tester.pumpAndSettle();
    expect(
      inPanel('nara', find.textContaining('as of 27 Sep 16:45')),
      findsOneWidget,
    );
  });

  testWidgets('the trader market\'s open-calls chip counts the trader\'s '
      'open calls', (tester) async {
    // A second open call, so a fixed "1 open call" would show.
    Scenario.callReceipts.value = [
      ...Scenario.callReceipts.value,
      const CallReceipt(
        id: 'kilo-extra-open',
        author: 'kilo.sol',
        asset: 'BTC',
        result: CallOutcome.open,
      ),
    ];
    await pumpApp(tester, home: TraderMarketScreen(handle: pair.$1));
    expect(find.text('2 open calls'), findsOneWidget);
  });

  testWidgets('the user\'s own record and its items agree', (tester) async {
    const handle = PortfolioMock.handle;
    await pumpApp(
      tester,
      home: const YourMarketScreen(),
      size: const Size(402, 2400),
    );
    final m = Scenario.record(handle);
    expect(m.right, greaterThan(0));
    expect(inPanel(handle, find.text('${m.right} right')), findsOneWidget);
    expect(
      find.descendant(of: find.byType(CallRecordItem), matching: find.text('Right')),
      findsNWidgets(m.right),
    );
  });
}
