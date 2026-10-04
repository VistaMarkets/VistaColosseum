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
  Scenario.receipts.value,
  Scenario.stalePrices.value,
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
  Scenario.refreshPrice('AVAX');
  Scenario.placeOrder(ethLong('mutate', units: 0.01));
}

/// A market long on ETH at its session price, 10x unless told otherwise.
OrderIntent ethLong(String actionId, {double units = 0.12345, int lev = 10}) =>
    OrderIntent(
      actionId: actionId,
      symbol: 'ETH',
      name: 'Ethereum',
      side: TradeSide.long,
      units: units,
      price: 2968.40,
      leverage: lev,
    );

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

  testWidgets('placeOrder rounds once and review, receipt and Wallet totals '
      'reconcile', (tester) async {
    tester.view
      ..physicalSize = const Size(402, 874) * 3
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final seedPositions = Scenario.positions.value.length;
    // 0.12345 ETH at $2,968.40 is $366.44898: rounds to 36645 cents. Margin
    // comes from those rounded cents (3664.5 → 3665), not the raw 3664.49.
    final intent = ethLong('a-1');
    // What the review sheet shows, before anything is placed.
    expect(intent.notionalCents, 36645);
    expect(intent.marginCents, 3665);
    expect(intent.feeCents, 18); // 36645 × 5 bps, rounded down
    expect(intent.totalCents, 3683);
    expect(Scenario.cashCents.value, PortfolioMock.cashCents);

    final result = Scenario.placeOrder(intent);
    final receipt = (result as OrderFilled).receipt;
    expect(
      [receipt.notionalCents, receipt.marginCents, receipt.feeCents],
      [36645, 3665, 18],
    );
    expect(receipt.totalCents, intent.totalCents);
    expect(Scenario.receipts.value, [receipt]);
    expect(Scenario.cashCents.value, PortfolioMock.cashCents - 3683);
    expect(Scenario.positions.value, hasLength(seedPositions + 1));
    final position = Scenario.positions.value.first;
    expect(position.id, 'a-1');
    expect([position.notionalCents, position.marginCents], [36645, 3665]);

    // Wallet: one more position, its size the stored cents.
    await tester.pumpWidget(const VistaColosseumApp());
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Wallet'));
    await tester.pumpAndSettle();
    expect(find.text('Positions · ${seedPositions + 1}'), findsOneWidget);
    await tester.ensureVisible(find.text('Ethereum').first);
    await tester.tap(find.text('Ethereum').first);
    await tester.pumpAndSettle();
    expect(find.text(r'$366.45 position'), findsOneWidget);
  });

  test('placeOrder with a repeated actionId returns the first result', () {
    final seedPositions = Scenario.positions.value.length;
    final first = Scenario.placeOrder(ethLong('a-1')) as OrderFilled;
    final cash = Scenario.cashCents.value;
    final second = Scenario.placeOrder(ethLong('a-1'));
    expect((second as OrderFilled).receipt, same(first.receipt));
    expect(Scenario.positions.value, hasLength(seedPositions + 1));
    expect(Scenario.receipts.value, hasLength(1));
    expect(Scenario.cashCents.value, cash);
  });

  test(
    'a stale price fails with no change; refreshed, the action fills once',
    () {
      final avax = OrderIntent(
        actionId: 'a-avax',
        symbol: 'AVAX',
        name: 'Avalanche',
        side: TradeSide.long,
        units: 10,
        price: 38.20,
        leverage: 5,
      );
      final before = state();
      expect(
        Scenario.placeOrder(avax),
        isA<OrderFailed>().having((f) => f.reason, 'reason', 'Price expired'),
      );
      expect(state(), equals(before));
      Scenario.refreshPrice('AVAX');
      expect(Scenario.placeOrder(avax), isA<OrderFilled>());
      expect(Scenario.placeOrder(avax), isA<OrderFilled>());
      expect(Scenario.receipts.value, hasLength(1));
      expect(
        Scenario.positions.value,
        hasLength((before[1]! as List).length + 1),
      );
    },
  );

  test('more than cash covers fails and changes nothing', () {
    final before = state();
    final big = ethLong('a-big', units: 100); // $296,840 at 10x: $29,684
    expect(
      Scenario.placeOrder(big),
      isA<OrderFailed>().having((f) => f.reason, 'reason', notEnoughFunds),
    );
    expect(state(), equals(before));
  });

  test('a trader-index intent is refused on every order kind and changes '
      'nothing', () {
    final before = state();
    for (final kind in OrderKind.values) {
      // maya.eth has a price, so only the trader-index rule can refuse it.
      final maya = OrderIntent(
        actionId: 'a-maya-${kind.name}',
        symbol: 'maya.eth',
        name: 'maya.eth',
        side: TradeSide.long,
        units: 1000,
        price: 0.44,
        leverage: 2,
        kind: kind,
      );
      expect(
        Scenario.placeOrder(maya),
        isA<OrderFailed>().having(
          (f) => f.reason,
          'reason',
          'Trader-index ticket — not in the demo yet',
        ),
        reason: kind.name,
      );
    }
    expect(state(), equals(before));
  });

  test('a dust, non-finite or unlevered order fails and changes nothing', () {
    final before = state();
    final cases = <(OrderIntent, String)>[
      // 4 cents of ETH at 10x: the margin rounds to 0 cents.
      (ethLong('a-dust', units: 0.04 / 2968.40), 'Enter a size'),
      (ethLong('a-inf', units: double.infinity), 'Enter a size'),
      (ethLong('a-nan', units: double.nan), 'Enter a size'),
      (
        OrderIntent(
          actionId: 'a-inf-price',
          symbol: 'ETH',
          name: 'Ethereum',
          side: TradeSide.long,
          units: 1,
          price: double.infinity,
          leverage: 10,
        ),
        'Enter a price',
      ),
      (ethLong('a-lev0', lev: 0), 'Choose a leverage'),
    ];
    for (final (intent, reason) in cases) {
      expect(
        () => Scenario.placeOrder(intent),
        returnsNormally,
        reason: intent.actionId,
      );
      expect(
        Scenario.placeOrder(intent),
        isA<OrderFailed>().having((f) => f.reason, 'reason', reason),
        reason: intent.actionId,
      );
    }
    expect(state(), equals(before));
  });

  test('a limit intent rests in Open orders and moves no cash', () {
    final limit = OrderIntent(
      actionId: 'a-limit',
      symbol: 'ETH',
      name: 'Ethereum',
      side: TradeSide.long,
      units: 0.5,
      price: 2900,
      leverage: 5,
      kind: OrderKind.limit,
    );
    final result = Scenario.placeOrder(limit) as OrderResting;
    expect(result.order.id, 'a-limit');
    expect(Scenario.openOrders.value.first, same(result.order));
    expect(Scenario.cashCents.value, PortfolioMock.cashCents);
    expect(Scenario.positions.value, PortfolioMock.positions);
    expect(Scenario.placeOrder(limit), isA<OrderResting>());
    expect(
      Scenario.openOrders.value,
      hasLength(OpenOrdersMock.orders.length + 1),
    );
  });

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
