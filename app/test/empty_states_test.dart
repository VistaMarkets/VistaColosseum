import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vista_colosseum/app_shell.dart';
import 'package:vista_colosseum/design_system/design_system.dart';
import 'package:vista_colosseum/features/home/home_screen.dart';
import 'package:vista_colosseum/features/home/trade_idea_card.dart';
import 'package:vista_colosseum/features/market/receipt_screens.dart';
import 'package:vista_colosseum/features/people/follow_list_screen.dart';
import 'package:vista_colosseum/features/portfolio/portfolio_mock.dart';
import 'package:vista_colosseum/features/profile/profile_screen.dart';
import 'package:vista_colosseum/features/settings/settings_state.dart';
import 'package:vista_colosseum/scenario/scenario.dart';

import 'home_screen_test.dart' show expectPillClear, phones;
import 'trader_record_test.dart' show pumpApp;

/// The app's font, so text measures as on a device.
Future<void> _loadFonts() async {
  final loader = FontLoader('OpenRunde');
  for (final w in ['Regular', 'Medium', 'Semibold', 'Bold']) {
    final bytes = File('assets/fonts/OpenRunde-$w.otf').readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
}

/// The phones the simulation strip is tightest on (360x640, 375x667).
final small = {
  for (final e in phones.entries)
    if (e.value.$1.width <= 375) e.key: e.value,
};

/// The screen's scrolling list (text fields scroll sideways).
Finder get list => find
    .byWidgetPredicate(
      (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
    )
    .first;

const loadFailed = "Couldn't load markets";

Finder get failureSwitch => find.byWidgetPredicate(
  (w) => w is VistaSwitch && w.semanticLabel == 'Simulate load failure',
);

/// Every core list emptied: no positions, open orders, paper or call
/// receipts, follows, favourites or fee credits, and an Ask no battle
/// matches.
void emptyScenario() {
  Scenario.positions.value = const [];
  Scenario.openOrders.value = const [];
  Scenario.receipts.value = const [];
  Scenario.followers.value = const [];
  Scenario.following.value = const [];
  Scenario.followed.value = const {};
  Scenario.favoriteAssets.value = const [];
  Scenario.favoriteTraders.value = const [];
  Scenario.feeEntries.value = const [];
  Scenario.callReceipts.value = const [];
  Scenario.setArena(query: 'doge');
}

/// At the end of the screen's list, [line] shows with its one [action],
/// both drawn by the shared [VistaEmptyState], the action on screen and
/// clear of the simulation pill; nothing threw or overflowed.
Future<void> expectEmpty(
  WidgetTester tester,
  String line,
  String action, {
  required String reason,
}) async {
  if (list.evaluate().isNotEmpty) {
    await tester.drag(list, const Offset(0, -2000));
    await tester.pumpAndSettle();
  }
  expect(tester.takeException(), isNull, reason: reason);
  final state = find.byType(VistaEmptyState);
  expect(
    find.descendant(of: state, matching: find.text(line)),
    findsOneWidget,
    reason: reason,
  );
  final button = find.descendant(
    of: state,
    matching: find.widgetWithText(VistaPillButton, action),
  );
  expect(button.hitTestable(), findsWidgets, reason: reason);
  expectPillClear(tester, button);
}

void main() {
  setUpAll(_loadFonts);
  setUp(() {
    Scenario.reset();
    SettingsState.reset();
  });

  for (final MapEntry(key: name, value: (size, padding)) in small.entries) {
    testWidgets('every core list renders an emptied scenario without '
        'overflow or exception on $name at 1.3x', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      emptyScenario();
      Future<void> open({Widget? home, int? tab}) async {
        await pumpApp(tester, home: home, size: size, padding: padding);
        if (tab != null) {
          AppShell.tab.value = tab;
          await tester.pumpAndSettle();
        }
      }

      await open(
        home: const Scaffold(body: HomeScreen(feed: [])),
      );
      await expectEmpty(
        tester,
        'No calls to show',
        'Explore markets',
        reason: '$name Home feed',
      );

      await open(tab: 2);
      await expectEmpty(
        tester,
        'No battles on “doge”',
        'Clear search',
        reason: '$name Arena',
      );

      await open(tab: AppShell.wallet);
      await expectEmpty(
        tester,
        'No positions yet',
        'Explore markets',
        reason: '$name Positions',
      );
      await tester.ensureVisible(find.text('Open orders'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open orders'));
      await tester.pumpAndSettle();
      await expectEmpty(
        tester,
        'No open orders',
        'Explore markets',
        reason: '$name Open orders',
      );

      await open(home: const ReceiptsScreen(author: PortfolioMock.handle));
      await expectEmpty(
        tester,
        'No call receipts for ${PortfolioMock.handle} in fixture-v1',
        'Explore markets',
        reason: '$name Receipts',
      );
      expect(find.text('No paper orders yet'), findsOneWidget, reason: name);

      await open(home: const LedgerScreen());
      await expectEmpty(
        tester,
        'No fee credits yet',
        'Explore markets',
        reason: '$name Ledger',
      );

      await open(home: const FollowListScreen());
      await expectEmpty(
        tester,
        'No followers yet',
        'Explore markets',
        reason: '$name Followers',
      );
      await tester.tap(find.text('Following').first);
      await tester.pumpAndSettle();
      await expectEmpty(
        tester,
        'Not following anyone yet',
        'Explore markets',
        reason: '$name Following',
      );

      await open(home: const ProfileScreen(handle: 'kilo.sol'));
      await expectEmpty(
        tester,
        'No calls from kilo.sol yet',
        'Explore markets',
        reason: '$name Profile calls',
      );

      // The seeded failure's Retry keeps clear of the pill too.
      Scenario.marketsLoadFails.value = true;
      await open(tab: 1);
      await expectEmpty(tester, loadFailed, 'Retry', reason: '$name Explore');
    });
  }

  testWidgets('Explore markets leads to Explore, from a tab or a pushed list', (
    tester,
  ) async {
    emptyScenario();
    await pumpApp(tester);
    AppShell.tab.value = AppShell.wallet;
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Explore markets'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Explore markets'));
    await tester.pumpAndSettle();
    expect(AppShell.tab.value, 1);
    expect(find.text('ALL MARKETS'), findsOneWidget);

    // From a pushed list it closes the list first.
    AppShell.tab.value = AppShell.wallet;
    await tester.pumpAndSettle();
    await tester.tap(find.text('Followers'));
    await tester.pumpAndSettle();
    expect(find.byType(FollowListScreen), findsOneWidget);
    await tester.tap(find.text('Explore markets'));
    await tester.pumpAndSettle();
    expect(find.byType(FollowListScreen), findsNothing);
    expect(AppShell.tab.value, 1);
    expect(find.text('ALL MARKETS'), findsOneWidget);
  });

  testWidgets('Clear search brings back an emptied Ask or follow search', (
    tester,
  ) async {
    Scenario.setArena(query: 'doge');
    await pumpApp(tester);
    AppShell.tab.value = 2;
    await tester.pumpAndSettle();
    expect(find.byType(VistaBattleCard), findsNothing);
    await tester.tap(find.text('Clear search'));
    await tester.pumpAndSettle();
    expect(Scenario.arena.value.query, isEmpty);
    expect(find.byType(VistaBattleCard), findsWidgets);

    await pumpApp(tester, home: const FollowListScreen());
    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pumpAndSettle();
    expect(find.byType(VistaPersonRow), findsNothing);
    expect(find.text('No matches'), findsOneWidget);
    await tester.tap(find.text('Clear search'));
    await tester.pumpAndSettle();
    expect(find.byType(VistaPersonRow), findsWidgets);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, isEmpty);
  });

  testWidgets('Simulate load failure: only the Explore list fails; Retry '
      'clears the toggle and loads it', (tester) async {
    await pumpApp(tester);
    Future<void> openSettings() async {
      AppShell.tab.value = AppShell.wallet;
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Settings'));
      await tester.pumpAndSettle();
      // Presenter-only, beside Reset demo.
      await tester.scrollUntilVisible(failureSwitch, 200, scrollable: list);
      await tester.pumpAndSettle();
      expect(find.text('Reset demo'), findsOneWidget);
    }

    await openSettings();
    expect(tester.widget<VistaSwitch>(failureSwitch).value, isFalse);
    await tester.tap(failureSwitch);
    await tester.pumpAndSettle();
    expect(tester.widget<VistaSwitch>(failureSwitch).value, isTrue);
    await tester.tap(find.bySemanticsLabel('Back'));
    await tester.pumpAndSettle();

    // No other screen depends on it.
    for (final (tab, loaded) in [
      (0, TradeIdeaCard),
      (2, VistaBattleCard),
      (AppShell.wallet, VistaListRow),
    ]) {
      AppShell.tab.value = tab;
      await tester.pumpAndSettle();
      expect(find.byType(loaded), findsWidgets, reason: 'tab $tab');
      expect(find.text(loadFailed), findsNothing, reason: 'tab $tab');
    }

    AppShell.tab.value = 1;
    await tester.pumpAndSettle();
    expect(find.text(loadFailed), findsOneWidget);
    expect(find.byType(VistaMarketRow), findsNothing);
    expect(find.text('ALL MARKETS'), findsNothing);

    await tester.tap(find.widgetWithText(VistaPillButton, 'Retry'));
    await tester.pumpAndSettle();
    expect(find.text(loadFailed), findsNothing);
    expect(find.text('ALL MARKETS'), findsOneWidget);
    expect(find.byType(VistaMarketRow), findsWidgets);

    // Retry turned the toggle off.
    await openSettings();
    expect(tester.widget<VistaSwitch>(failureSwitch).value, isFalse);
  });
}
