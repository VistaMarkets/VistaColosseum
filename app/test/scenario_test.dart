import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vista_colosseum/design_system/design_system.dart';
import 'package:vista_colosseum/features/account/account_state.dart';
import 'package:vista_colosseum/features/account/account_top_bar.dart';
import 'package:vista_colosseum/features/arena/arena_screen.dart';
import 'package:vista_colosseum/features/home/likes_state.dart';
import 'package:vista_colosseum/features/home/mock_trade_idea.dart';
import 'package:vista_colosseum/features/people/follow_list_screen.dart';
import 'package:vista_colosseum/features/people/follow_mock.dart';
import 'package:vista_colosseum/features/portfolio/orders_state.dart';
import 'package:vista_colosseum/features/portfolio/portfolio_mock.dart';
import 'package:vista_colosseum/features/profile/private_profile_screen.dart';
import 'package:vista_colosseum/features/profile/profile_screen.dart';
import 'package:vista_colosseum/features/settings/settings_screen.dart';
import 'package:vista_colosseum/features/settings/settings_state.dart';
import 'package:vista_colosseum/features/watchlist/watchlist_state.dart';
import 'package:vista_colosseum/main.dart';
import 'package:vista_colosseum/scenario/scenario.dart';

/// Every value the store holds, in a fixed order, for deep comparison.
/// A field added to [Scenario] must be added here and to [mutateEverything].
List<Object?> state() => [
  Scenario.cashCents.value,
  Scenario.positions.value,
  Scenario.openOrders.value,
  Scenario.hasMarket.value,
  Scenario.ticker.value,
  Scenario.marketId.value,
  Scenario.liked.value,
  Scenario.favoriteAssets.value,
  Scenario.favoriteTraders.value,
  Scenario.followers.value,
  Scenario.following.value,
  Scenario.followed.value,
  Scenario.clock.value,
];

/// Changes every field, through the app's own helpers where they exist.
void mutateEverything() {
  Scenario.cashCents.value -= 1000;
  Scenario.positions.value = Scenario.positions.value.sublist(1);
  OrdersState.remove(OrdersState.open.value.first);
  // Flips the listing from its seed, whichever way HAS_MARKET started it.
  final listed = Scenario.hasMarket.value;
  AccountState.listMarket('ZED');
  Scenario.hasMarket.value = !listed;
  LikesState.toggle(mockFeed.first);
  WatchlistState.toggleAsset('ZED');
  WatchlistState.toggleTrader('zed');
  Scenario.followers.value = const [];
  Scenario.following.value = const [];
  Scenario.followed.value = {...Scenario.followed.value, 'zed'};
  Scenario.clock.value = Scenario.clock.value.add(const Duration(hours: 1));
}

/// The app's font, so text measures as on a device.
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

  // Read before any test touches the store: the values the app starts with.
  final seed = state();

  setUp(Scenario.reset);

  test('seed → mutate everything → reset equals the fresh seed', () {
    mutateEverything();
    final mutated = state();
    for (var i = 0; i < seed.length; i++) {
      expect(mutated[i], isNot(equals(seed[i])), reason: 'field $i unchanged');
    }
    Scenario.reset();
    expect(state(), equals(seed));
  });

  test('reset twice yields equal state', () {
    mutateEverything();
    Scenario.reset();
    final once = state();
    Scenario.reset();
    expect(state(), equals(once));
    expect(once, equals(seed));
  });

  testWidgets('Reset demo in Settings restores the fixture and says so', (
    tester,
  ) async {
    mutateEverything();
    SettingsState.tradingPermission.value = false;
    DisplayPrefs.longOnRight.value = true;
    await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Reset demo'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Reset demo'));
    await tester.pump();
    expect(find.text('Demo reset to fixture-v1'), findsOneWidget);
    expect(state(), equals(seed));
    // "Demo reset" covers the simulated Settings too.
    expect(SettingsState.tradingPermission.value, isTrue);
    expect(DisplayPrefs.longOnRight.value, isFalse);
  });

  testWidgets('Wallet lists the positions held in Scenario', (tester) async {
    tester.view
      ..physicalSize = const Size(402, 874) * 3
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    Scenario.positions.value = [PortfolioMock.positions.last];
    await tester.pumpWidget(const VistaColosseumApp());
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Wallet'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Positions · '), findsOneWidget);
    expect(find.text('Positions · 1'), findsOneWidget);
    expect(find.text('Ethereum'), findsNothing);
  });

  testWidgets(
    'Home, detail, Arena and Wallet read one position from Scenario',
    (tester) async {
      tester.view
        ..physicalSize = const Size(402, 874) * 3
        ..devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      // One set of values, written only to the store.
      Scenario.cashCents.value = 1000000; // $10,000
      Scenario.positions.value = [PortfolioMock.positions.last];
      AccountState.listMarket('ZED');
      LikesState.toggle(mockFeed.first);
      Scenario.favoriteAssets.value = const [
        'BTC',
      ]; // ETH, the first call, unstarred
      final topBar = find.byType(AccountTopBar);
      await tester.pumpWidget(const VistaColosseumApp());
      await tester.pumpAndSettle();

      // Home: the top-bar cash and the first call's like.
      expect(
        find.descendant(of: topBar, matching: find.text(r'$10,000')),
        findsOneWidget,
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Like, 4.4k').first),
        isSemantics(isToggled: true),
      );

      // Cash moves while the app is up; what is shown follows it.
      Scenario.cashCents.value = 1234500;
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: topBar, matching: find.text(r'$12,345')),
        findsOneWidget,
      );

      // Detail: the star is the store's favourite.
      await tester.tap(find.text('Details').first);
      await tester.pumpAndSettle();
      expect(
        tester.widget<VistaWatchButton>(find.byType(VistaWatchButton)).watched,
        isFalse,
      );
      Navigator.of(tester.element(find.byType(VistaWatchButton))).pop();
      await tester.pumpAndSettle();

      // Arena: on screen, and its battles (const fixtures) carry no cash,
      // star, like, position or listing, so none can disagree with the store.
      await tester.tap(find.bySemanticsLabel('Arena'));
      await tester.pumpAndSettle();
      expect(find.byType(ArenaScreen), findsOneWidget);
      for (final shown in [
        topBar,
        find.byType(VistaWatchButton),
        find.bySemanticsLabel(RegExp('^Like')),
        find.textContaining('Positions'),
        find.textContaining('ZED'),
        find.textContaining(r'$12,'),
      ]) {
        expect(shown, findsNothing);
      }

      // Wallet: cash in the top bar and the pager, the one position, the
      // listed market.
      await tester.tap(find.bySemanticsLabel('Wallet'));
      await tester.pumpAndSettle();
      expect(find.text(r'$12,345'), findsNWidgets(2));
      expect(find.text(r'$12,480'), findsNothing);
      expect(find.text('Positions · 1'), findsOneWidget);
      expect(find.text('Ethereum'), findsNothing);
      expect(find.text(r'$ZED market cap'), findsOneWidget);

      // Your market: the listed ticker, not the fixture's.
      await tester.ensureVisible(find.text('Your market'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Your market'));
      await tester.pumpAndSettle();
      expect(find.text('ZED'), findsOneWidget);
      expect(find.text('MAYA'), findsNothing);
    },
  );

  testWidgets('Follow buttons read and write the follows in Scenario', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(402, 874) * 3
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    Scenario.followers.value = FollowMock.followers.take(2).toList();
    Scenario.followed.value = const {}; // not even lunaq, followed in the seed
    await tester.pumpWidget(const MaterialApp(home: FollowListScreen()));
    await tester.pumpAndSettle();

    bool following(String handle) => tester
        .widget<VistaFollowButton>(
          find.descendant(
            of: find.ancestor(
              of: find.text(handle),
              matching: find.byType(VistaPersonRow),
            ),
            matching: find.byType(VistaFollowButton),
          ),
        )
        .following;

    // The list and the buttons are the store's.
    expect(find.text('sam.sol'), findsNothing);
    expect(following('lunaq'), isFalse);

    // Following someone in the list writes the store; their profile agrees.
    await tester.tap(
      find.descendant(
        of: find.ancestor(
          of: find.text('0xreal'),
          matching: find.byType(VistaPersonRow),
        ),
        matching: find.byType(VistaFollowButton),
      ),
    );
    await tester.pump();
    expect(Scenario.followed.value, contains('0xreal'));
    await tester.tap(find.text('0xreal'));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileScreen), findsOneWidget);
    final profileButton = find.byType(VistaFollowButton);
    expect(tester.widget<VistaFollowButton>(profileButton).following, isTrue);

    // Unfollowing on the profile writes the store too.
    await tester.tap(profileButton);
    await tester.pump();
    expect(Scenario.followed.value, isNot(contains('0xreal')));

    // A private profile reads the same follows.
    Scenario.followed.value = const {'nara'};
    await tester.pumpWidget(
      const MaterialApp(
        key: ValueKey('fresh app'), // a new navigator, not the list's
        home: PrivateProfileScreen(handle: 'nara'),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<VistaFollowButton>(find.byType(VistaFollowButton))
          .following,
      isTrue,
    );
  });
}
