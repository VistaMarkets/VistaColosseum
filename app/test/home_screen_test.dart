import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vista_colosseum/features/trade/order_filled_sheet.dart';
import 'package:vista_colosseum/features/notifications/notifications_screen.dart';
import 'package:vista_colosseum/features/profile/edit_profile_screen.dart';
import 'package:vista_colosseum/features/arena/trending_calls_screen.dart';
import 'package:vista_colosseum/features/arena/hub_call_card.dart';
import 'package:vista_colosseum/features/arena/room_screen.dart';
import 'package:vista_colosseum/features/arena/arena_screen.dart';
import 'package:vista_colosseum/features/markets/market_chart_card.dart';
import 'package:vista_colosseum/charting/charting.dart';
import 'package:vista_colosseum/design_system/design_system.dart';
import 'package:vista_colosseum/features/account/account_state.dart';
import 'package:vista_colosseum/features/account/account_top_bar.dart';
import 'package:vista_colosseum/features/home/home_screen.dart';
import 'package:vista_colosseum/features/home/mock_trade_idea.dart';
import 'package:vista_colosseum/features/portfolio/portfolio_pager.dart';
import 'package:vista_colosseum/features/portfolio/portfolio_screen.dart';
import 'package:vista_colosseum/features/arena/settlement_item.dart';
import 'package:vista_colosseum/features/arena/take_card.dart';
import 'package:vista_colosseum/features/arena/arena_mock.dart';
import 'package:vista_colosseum/features/arena/pick_position_screen.dart';
import 'package:vista_colosseum/features/arena/compose_take_screen.dart';
import 'package:vista_colosseum/features/arena/battle_builder.dart';
import 'package:vista_colosseum/features/calls/calls_store.dart';
import 'package:vista_colosseum/features/home/home_feed.dart';
import 'package:vista_colosseum/features/live/live_feed.dart';
import 'package:vista_colosseum/features/portfolio/series_chart.dart';
import 'package:vista_colosseum/features/profile/profile_screen.dart';
import 'package:vista_colosseum/features/profile/trader_profile.dart';
import 'package:vista_colosseum/features/portfolio/trade_history.dart';
import 'package:vista_colosseum/features/invite/invite_sheet.dart';
import 'package:vista_colosseum/features/arena/battle_result_sheet.dart';
import 'package:vista_colosseum/features/profile/receipts_screen.dart';
import 'package:vista_colosseum/features/profile/holdings_table.dart';
import 'package:vista_colosseum/features/portfolio/position_sheet.dart';
import 'package:vista_colosseum/features/portfolio/positions_state.dart';
import 'package:vista_colosseum/features/people/follow_state.dart';
import 'package:vista_colosseum/features/profile/private_profile_screen.dart';
import 'package:vista_colosseum/features/settings/settings_screen.dart';
import 'package:vista_colosseum/features/settings/settings_state.dart';
import 'package:vista_colosseum/features/watchlist/edit_favorites_screen.dart';
import 'package:vista_colosseum/features/watchlist/watchlist_state.dart';
import 'package:vista_colosseum/features/trade/asset_trade_screen.dart';
import 'package:vista_colosseum/features/trade/candle_chart.dart';
import 'package:vista_colosseum/features/live/market_prices.dart';
import 'package:vista_colosseum/features/home/replay_script.dart';
import 'package:vista_colosseum/features/markets/markets_mock.dart';
import 'package:vista_colosseum/features/market/trader_market_screen.dart';
import 'package:vista_colosseum/features/markets/markets_screen.dart';
import 'package:vista_colosseum/features/arena/battle_screen.dart';
import 'package:vista_colosseum/features/markets/explore_sections.dart';
import 'package:vista_colosseum/features/markets/trader_standing.dart';
import 'package:vista_colosseum/features/trade/trade_mock.dart';
import 'package:vista_colosseum/features/arena/challenge_sheet.dart';
import 'package:vista_colosseum/features/portfolio/portfolio_mock.dart';
import 'package:vista_colosseum/features/portfolio/orders_state.dart';
import 'package:vista_colosseum/features/trade/order_ticket.dart';
import 'package:vista_colosseum/features/trade/caller_play_screen.dart';
import 'package:vista_colosseum/features/home/trade_idea_card.dart';
import 'package:vista_colosseum/features/home/likes_state.dart';
import 'package:vista_colosseum/features/home/people_in_sheet.dart';
import 'package:vista_colosseum/features/share/share_call_sheet.dart';
import 'package:vista_colosseum/main.dart';

/// Portfolio balance in the swipeable pager (the top bar repeats it).
Finder get pagerBalance => find.descendant(
  of: find.byType(PortfolioPager),
  matching: find.text(r'$12,480'),
);

/// The breakout label is the last event the trace reaches.
Finder get breakoutLabel => find.text(r'Broke $2,950');

/// Phone sizes (logical px) and safe-area insets the Home screen must fit.
const phones = <String, (Size, EdgeInsets)>{
  'small Android 360x640': (Size(360, 640), EdgeInsets.only(top: 24)),
  'iPhone SE 375x667': (Size(375, 667), EdgeInsets.only(top: 20)),
  'iPhone 15 393x852': (Size(393, 852), EdgeInsets.only(top: 59, bottom: 34)),
  'Pixel 7 412x915': (Size(412, 915), EdgeInsets.only(top: 24, bottom: 24)),
  'iPhone 15 Pro Max 430x932': (
    Size(430, 932),
    EdgeInsets.only(top: 59, bottom: 34),
  ),
};

Future<void> _loadFonts() async {
  // The text face and its fixed-width-digit twin for numbers.
  for (final family in ['OpenRunde', 'OpenRundeTabular']) {
    final loader = FontLoader(family);
    for (final w in ['Regular', 'Medium', 'Semibold', 'Bold']) {
      final bytes = File('assets/fonts/$family-$w.otf').readAsBytesSync();
      loader.addFont(Future.value(ByteData.sublistView(bytes)));
    }
    await loader.load();
  }
}

/// Fields outlined in red (a refused order pointing at them) inside [of].
Finder redFields(Type of) => find.descendant(
  of: find.byType(of),
  matching: find.byWidgetPredicate(
    (w) =>
        w is AnimatedContainer &&
        w.decoration is BoxDecoration &&
        ((w.decoration! as BoxDecoration).border as Border?)?.top.color ==
            VistaColors.short,
  ),
);

/// From the Arena hub, Trending calls › See all: every call
/// (`TrendingCallsScreen`).
Future<void> openAllCalls(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.text('Trending calls'),
    300,
    scrollable: find
        .descendant(
          of: find.byType(ArenaScreen),
          matching: find.byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
          ),
        )
        .first,
  );
  await tester.pumpAndSettle();
  await tester.tap(
    find.descendant(
      of: find
          .ancestor(of: find.text('Trending calls'), matching: find.byType(Row))
          .first,
      matching: find.text('See all'),
    ),
  );
  await tester.pumpAndSettle();
}

/// The Live battles page on its own (every live debate, sortable).
/// Explore's full list sits under the sideways sections: scroll to it.
Future<void> scrollToAllMarkets(WidgetTester tester) async {
  final list = find
      .descendant(
        of: find.byType(MarketsScreen),
        matching: find.byType(Scrollable),
      )
      .first;
  await tester.scrollUntilVisible(
    find.text('ALL MARKETS'),
    300,
    scrollable: list,
  );
  await tester.ensureVisible(find.text('ALL MARKETS'));
  await tester.pumpAndSettle();
}

/// Back to the top of Explore (search, tabs, Favorites).
Future<void> scrollExploreToTop(WidgetTester tester) async {
  await tester.drag(
    find
        .descendant(
          of: find.byType(MarketsScreen),
          matching: find.byType(Scrollable),
        )
        .first,
    const Offset(0, 4000),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(_loadFonts);
  // Most screens assume the user already has a market; the make-a-market
  // group below starts without one.
  setUp(() {
    AccountState.reset(withMarket: true);
    LikesState.reset();
    TakeLikes.reset();
    CallsStore.reset();
    PositionsState.reset();
    FollowState.reset();
    BattlesStore.reset();
    SettingsState.reset();
    WatchlistState.reset();
    OrdersState.reset();
    ProfileEdits.reset();
    Notifications.reset();
    TradeHistory.reset();
    DemoClock.reset();
  });

  for (final MapEntry(key: name, value: (size, padding)) in phones.entries) {
    testWidgets('Home renders without overflow on $name', (tester) async {
      tester.view
        ..physicalSize = size * 3
        ..devicePixelRatio = 3
        ..padding = FakeViewPadding(
          top: padding.top * 3,
          bottom: padding.bottom * 3,
        );
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const VistaColosseumApp());
      await tester.pumpAndSettle();

      // Layout overflows surface as exceptions in widget tests.
      expect(tester.takeException(), isNull);
      expect(find.text('Following'), findsOneWidget);
      expect(find.text('Details'), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
    });
  }

  for (final MapEntry(key: name, value: (size, padding)) in phones.entries) {
    testWidgets('Portfolio renders without overflow on $name', (tester) async {
      tester.view
        ..physicalSize = size * 3
        ..devicePixelRatio = 3
        ..padding = FakeViewPadding(
          top: padding.top * 3,
          bottom: padding.bottom * 3,
        );
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const VistaColosseumApp());
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Wallet'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(pagerBalance, findsOneWidget);
      // Last position is reachable by scrolling on short phones.
      await tester.ensureVisible(find.text('0xreal'));
      await tester.pumpAndSettle();
      expect(find.text('0xreal').hitTestable(), findsOneWidget);
    });
  }

  testWidgets('Portfolio survives 1.3x text scaling on the smallest phone', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(360, 640) * 3
      ..devicePixelRatio = 3;
    tester.platformDispatcher.textScaleFactorTestValue = 2.0; // clamped to 1.3
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(const VistaColosseumApp());
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Wallet'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('Home survives 1.3x text scaling on the smallest phone', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(360, 640) * 3
      ..devicePixelRatio = 3;
    tester.platformDispatcher.textScaleFactorTestValue = 2.0; // clamped to 1.3
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(const VistaColosseumApp());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  group('chart replay', () {
    Future<void> pumpPhone(WidgetTester tester) async {
      tester.view
        ..physicalSize = const Size(402, 874) * 3
        ..devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const VistaColosseumApp());
    }

    testWidgets('traces on open, then holds the finished design', (
      tester,
    ) async {
      await pumpPhone(tester);
      await tester.pump(const Duration(milliseconds: 300));
      expect(breakoutLabel, findsNothing); // tip hasn't reached it yet

      await tester.pumpAndSettle();
      expect(breakoutLabel, findsOneWidget);
      expect(find.text('Funding flipped +'), findsOneWidget);
    });

    testWidgets('replays when the next card is swiped into view', (
      tester,
    ) async {
      await pumpPhone(tester);
      await tester.pumpAndSettle();

      await tester.fling(
        find.text('Details').first,
        const Offset(0, -600),
        2000,
      );
      final feed = tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position;
      // Step frames until the swipe comes to rest on the next card.
      await tester.pump();
      while (feed.isScrollingNotifier.value) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      await tester.pump(const Duration(milliseconds: 16));
      expect(feed.pixels, closeTo(feed.viewportDimension, 1));
      // The next card is another market, with its own replay story.
      final ranked = HomeFeed.following(CallsStore.all.value);
      final next = HomeFeed.ideaOf(ranked[1]);
      expect(next.ticker, isNot(HomeFeed.ideaOf(ranked.first).ticker));
      final payoff = find.text(next.script.events.last.label);
      // Swipe has settled; the new card has only just started tracing.
      expect(payoff.hitTestable(), findsNothing);

      await tester.pumpAndSettle();
      expect(payoff.hitTestable(), findsOneWidget);
    });

    testWidgets('fills arrive oldest first and settle at design opacity', (
      tester,
    ) async {
      await pumpPhone(tester);
      await tester.pump();

      Finder opacityAbove(String text) =>
          find.ancestor(of: find.text(text), matching: find.byType(Opacity));
      double opacityOf(String text) =>
          tester.widget<Opacity>(opacityAbove(text).first).opacity;
      // Rows yet to arrive are laid out but invisible, with no Opacity.
      bool shown(String text) =>
          opacityAbove(text).evaluate().isNotEmpty && opacityOf(text) > 0;

      // Before the first arrival nothing is visible.
      expect(shown('3 people joined'), isFalse);

      // Mid-stream: the oldest has arrived, the newest has not.
      await tester.pump(const Duration(milliseconds: 700));
      expect(shown('3 people joined'), isTrue);
      expect(shown('kilo.sol went long'), isFalse);

      await tester.pumpAndSettle();
      expect(opacityOf('3 people joined'), closeTo(0.35, 0.001));
      expect(opacityOf('0xreal shorted'), closeTo(0.65, 0.001));
      expect(opacityOf('kilo.sol went long'), closeTo(1, 0.001));
    });

    testWidgets('reduced motion shows the finished chart immediately', (
      tester,
    ) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await pumpPhone(tester);
      await tester.pump();
      expect(breakoutLabel, findsOneWidget);
    });
  });

  group('portfolio pager', () {
    Future<void> openWallet(WidgetTester tester) async {
      tester.view
        ..physicalSize = const Size(402, 874) * 3
        ..devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const VistaColosseumApp());
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Wallet'));
      await tester.pumpAndSettle();
    }

    double opacityOf(WidgetTester tester, String text) => tester
        .widget<Opacity>(
          find
              .ancestor(of: find.text(text), matching: find.byType(Opacity))
              .first,
        )
        .opacity;

    const portfolio = r'$12,480';
    const market = r'$44.0M';

    testWidgets('swiping the chart moves to the market cap and back', (
      tester,
    ) async {
      await openWallet(tester);
      expect(opacityOf(tester, portfolio), 1);
      expect(opacityOf(tester, market), 0);
      expect(find.text(r'$MAYA market cap'), findsOneWidget);

      // Mid-drag: both pages partly visible, following the finger.
      final chart = tester.getCenter(pagerBalance) + const Offset(0, 150);
      final gesture = await tester.startGesture(chart);
      await gesture.moveBy(const Offset(-40, 0));
      await gesture.moveBy(const Offset(-100, 0));
      await tester.pump();
      expect(opacityOf(tester, portfolio), inExclusiveRange(0, 1));
      expect(opacityOf(tester, market), inExclusiveRange(0, 1));

      // Released past halfway: settles on the market.
      await gesture.moveBy(const Offset(-120, 0));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(opacityOf(tester, portfolio), 0);
      expect(opacityOf(tester, market), 1);

      // Swipe back.
      await tester.flingFrom(chart, const Offset(200, 0), 1000);
      await tester.pumpAndSettle();
      expect(opacityOf(tester, portfolio), 1);
      expect(opacityOf(tester, market), 0);
    });

    testWidgets('a short drag snaps back to where it started', (tester) async {
      await openWallet(tester);
      final chart = tester.getCenter(pagerBalance) + const Offset(0, 150);
      final gesture = await tester.startGesture(chart);
      await gesture.moveBy(const Offset(-30, 0));
      await gesture.moveBy(const Offset(-30, 0));
      await tester.pump(const Duration(milliseconds: 500));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(opacityOf(tester, portfolio), 1);
    });
  });

  group('your market', () {
    Future<void> openMarket(
      WidgetTester tester,
      Size size,
      EdgeInsets pad,
    ) async {
      tester.view
        ..physicalSize = size * 3
        ..devicePixelRatio = 3
        ..padding = FakeViewPadding(top: pad.top * 3, bottom: pad.bottom * 3);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const VistaColosseumApp());
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Wallet'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Your market'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Your market'));
      await tester.pumpAndSettle();
    }

    testWidgets('opens from Portfolio and goes back', (tester) async {
      await openMarket(tester, const Size(402, 874), EdgeInsets.zero);
      expect(find.text('Market cap'), findsOneWidget);
      expect(find.text('Make a call'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pumpAndSettle();
      expect(find.text('Market cap'), findsNothing);
      expect(pagerBalance, findsOneWidget);
    });

    for (final MapEntry(key: name, value: (size, padding)) in phones.entries) {
      testWidgets('renders without overflow on $name', (tester) async {
        await openMarket(tester, size, padding);
        expect(tester.takeException(), isNull);
        // Last record entry is reachable by scrolling.
        final last = find.text(r'ETH reaches $4,000 by Oct 10');
        await tester.scrollUntilVisible(
          last,
          200,
          scrollable: find
              .descendant(
                of: find.byType(ListView).last,
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.ensureVisible(last);
        await tester.pumpAndSettle();
        expect(
          find.text(r'ETH reaches $4,000 by Oct 10').hitTestable(),
          findsOneWidget,
        );
      });
    }
  });

  group('follow list', () {
    Future<void> openWallet(
      WidgetTester tester, [
      Size size = const Size(402, 874),
      EdgeInsets pad = EdgeInsets.zero,
    ]) async {
      tester.view
        ..physicalSize = size * 3
        ..devicePixelRatio = 3
        ..padding = FakeViewPadding(top: pad.top * 3, bottom: pad.bottom * 3);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const VistaColosseumApp());
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Wallet'));
      await tester.pumpAndSettle();
    }

    testWidgets('Followers chip opens Followers; tabs, search, follow', (
      tester,
    ) async {
      await openWallet(tester);
      await tester.tap(find.text('Followers'));
      await tester.pumpAndSettle();
      expect(find.text('Search followers'), findsOneWidget);
      expect(find.text('sam.sol'), findsOneWidget);

      // Follow toggles locally.
      final zeroReal = find.ancestor(
        of: find.text('0xreal'),
        matching: find.byType(VistaPersonRow),
      );
      await tester.tap(
        find.descendant(of: zeroReal, matching: find.byType(VistaFollowButton)),
      );
      await tester.pump();
      expect(
        tester
            .widget<VistaFollowButton>(
              find.descendant(
                of: zeroReal,
                matching: find.byType(VistaFollowButton),
              ),
            )
            .following,
        isTrue,
      );

      // Search filters by handle.
      await tester.enterText(find.byType(TextField), 'kai');
      await tester.pump();
      expect(find.text('kaito.eth'), findsOneWidget);
      expect(find.text('lunaq'), findsNothing);

      // Switching tab clears the search and shows Following.
      await tester.tap(find.text('Following').first);
      await tester.pumpAndSettle();
      expect(find.text('Search following'), findsOneWidget);
      expect(find.text('orbit.eth'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pumpAndSettle();
      expect(pagerBalance, findsOneWidget);
    });

    testWidgets('Following chip opens on the Following tab', (tester) async {
      await openWallet(tester);
      await tester.tap(find.text('Following'));
      await tester.pumpAndSettle();
      expect(find.text('Search following'), findsOneWidget);
    });

    for (final MapEntry(key: name, value: (size, padding)) in phones.entries) {
      testWidgets('renders without overflow on $name', (tester) async {
        await openWallet(tester, size, padding);
        await tester.tap(find.text('Followers'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('profile', () {
    Future<void> setView(
      WidgetTester tester, [
      Size size = const Size(402, 874),
      EdgeInsets pad = EdgeInsets.zero,
    ]) async {
      tester.view
        ..physicalSize = size * 3
        ..devicePixelRatio = 3
        ..padding = FakeViewPadding(top: pad.top * 3, bottom: pad.bottom * 3);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const VistaColosseumApp());
      await tester.pumpAndSettle();
    }

    Future<void> openFromFollowers(WidgetTester tester, String handle) async {
      await tester.tap(find.bySemanticsLabel('Wallet'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Followers'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(handle));
      await tester.pumpAndSettle();
    }

    Finder profileList() => find
        .descendant(
          of: find.byType(ListView).last,
          matching: find.byType(Scrollable),
        )
        .first;

    testWidgets('opens from a follower row with their handle', (tester) async {
      await setView(tester);
      await openFromFollowers(tester, 'lunaq');
      expect(find.text('HOLDING NOW'), findsOneWidget);
      expect(find.text('L'), findsOneWidget); // avatar initial
      // lunaq is on your Following list, so their profile says so.
      expect(find.text('Following'), findsOneWidget);

      // Their own figures, not the designed profile's.
      final p = TraderProfile.of('lunaq');
      expect(find.text('${p.settled}'), findsOneWidget);
      expect(find.text('${p.right}'), findsOneWidget);
      expect(find.text(p.market!.cap), findsOneWidget);
      expect(find.text(r'BTC reclaims $66,000 by Tue'), findsNothing);
      // Their calls are their receipts.
      final first = find.text(p.receipts.first.title);
      await tester.scrollUntilVisible(first, 200, scrollable: profileList());
      expect(first, findsWidgets);
    });

    testWidgets('a private account without a market opens the private layout', (
      tester,
    ) async {
      await setView(tester);
      await openFromFollowers(tester, 'nara');
      expect(find.byType(PrivateProfileScreen), findsOneWidget);
      expect(find.text('Private account'), findsOneWidget);
      expect(find.text('Positions are private'), findsOneWidget);
      expect(find.text('Open calls'), findsOneWidget);
      // No market or holdings for a private account.
      expect(find.text('HOLDING NOW'), findsNothing);
      expect(find.text('market'), findsNothing);
      expect(find.text(r'BTC holds $64,000 to Oct 3'), findsOneWidget);
    });

    for (final MapEntry(key: name, value: (size, padding)) in phones.entries) {
      testWidgets('private profile renders without overflow on $name', (
        tester,
      ) async {
        await setView(tester, size, padding);
        await openFromFollowers(tester, 'nara');
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('Home caller name opens their profile', (tester) async {
      await setView(tester);
      await tester.tap(find.text('kaito.eth'));
      await tester.pumpAndSettle();
      expect(find.text('HOLDING NOW'), findsOneWidget);
      expect(find.text('kaito.eth'), findsWidgets);
    });

    for (final MapEntry(key: name, value: (size, padding)) in phones.entries) {
      testWidgets('renders without overflow on $name', (tester) async {
        await setView(tester, size, padding);
        await openFromFollowers(tester, 'lunaq');
        expect(tester.takeException(), isNull);
        final last = find.text(TraderProfile.of('lunaq').receipts.last.title);
        await tester.scrollUntilVisible(last, 200, scrollable: profileList());
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(last.hitTestable(), findsWidgets);
      });
    }
  });

  group('trader market', () {
    Future<void> openMarket(
      WidgetTester tester, [
      Size size = const Size(402, 874),
      EdgeInsets pad = EdgeInsets.zero,
    ]) async {
      tester.view
        ..physicalSize = size * 3
        ..devicePixelRatio = 3
        ..padding = FakeViewPadding(top: pad.top * 3, bottom: pad.bottom * 3);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const VistaColosseumApp());
      await tester.pumpAndSettle();
      // A trader's profile → their market.
      Navigator.of(tester.element(find.byType(Scaffold).first))
          .push(ProfileScreen.route('0xreal'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('market'));
      await tester.pumpAndSettle();
    }

    Finder visible(String text) => find.text(text).hitTestable();

    testWidgets('opens on the Market panel, then Portfolio and Record', (
      tester,
    ) async {
      await openMarket(tester);
      expect(visible('Longs pay shorts'), findsOneWidget);

      for (final next in ['Shared live by 0xreal', 'Record']) {
        await tester.fling(find.byType(PageView), const Offset(-300, 0), 1500);
        await tester.pumpAndSettle();
        expect(visible(next), findsWidgets); // Record: its tab and its title
      }
      // No Holders panel after Record.
      await tester.fling(find.byType(PageView), const Offset(-300, 0), 1500);
      await tester.pumpAndSettle();
      expect(find.text('Holders'), findsNothing);
    });

    testWidgets('dragging the handle down opens the chart, up brings panels', (
      tester,
    ) async {
      await openMarket(tester);
      await tester.fling(
        find.byType(VistaDragHandle),
        const Offset(0, 400),
        1500,
      );
      await tester.pumpAndSettle();
      expect(visible('Longs pay shorts'), findsNothing);
      expect(visible('Market cap'), findsOneWidget);

      await tester.fling(
        find.byType(VistaDragHandle),
        const Offset(0, -400),
        1500,
      );
      await tester.pumpAndSettle();
      expect(visible('Longs pay shorts'), findsOneWidget);
    });

    for (final MapEntry(key: name, value: (size, padding)) in phones.entries) {
      testWidgets('renders without overflow on $name', (tester) async {
        await openMarket(tester, size, padding);
        expect(tester.takeException(), isNull);
        await tester.fling(
          find.byType(VistaDragHandle),
          const Offset(0, 400),
          1500,
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('markets', () {
    Future<void> openMarkets(
      WidgetTester tester, [
      Size size = const Size(402, 874),
      EdgeInsets pad = EdgeInsets.zero,
    ]) async {
      tester.view
        ..physicalSize = size * 3
        ..devicePixelRatio = 3
        ..padding = FakeViewPadding(top: pad.top * 3, bottom: pad.bottom * 3);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const VistaColosseumApp());
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Explore'));
      await tester.pumpAndSettle();
    }

    List<String> rowNames(WidgetTester tester) => tester
        .widgetList<AssetMarketCard>(find.byType(AssetMarketCard))
        .map((r) => r.name)
        .toList();

    // Tall enough that every asset card is built (the list is lazy).
    const tall = Size(402, 1600);

    testWidgets('Explore shows markets; search and favourites work', (
      tester,
    ) async {
      await openMarkets(tester, tall);
      await scrollToAllMarkets(tester);
      expect(find.text('ALL MARKETS'), findsOneWidget);
      // By volume; no sort chips on All markets.
      expect(rowNames(tester), ['BTC', 'ETH', 'SOL', 'ARB', 'AVAX']);
      expect(find.widgetWithText(VistaFilterChip, 'Change'), findsNothing);

      await scrollExploreToTop(tester);
      await tester.enterText(find.byType(TextField), 'av');
      await tester.pumpAndSettle();
      expect(rowNames(tester), ['AVAX']);
      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();
      // Cancel leaves search; Favorites and the sections come back.
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Starring ARB adds it to the favourites rail.
      expect(find.byType(VistaMarketCard), findsNWidgets(3));
      await scrollToAllMarkets(tester);
      final arb = find.ancestor(
        of: find.text('ARB'),
        matching: find.byType(AssetMarketCard),
      );
      await tester.scrollUntilVisible(
        arb,
        200,
        scrollable: find
            .descendant(
              of: find.byType(MarketsScreen),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.tap(
        find.descendant(of: arb, matching: find.byType(VistaStarButton)),
      );
      await tester.pumpAndSettle();
      expect(WatchlistState.isAsset('ARB'), isTrue);
      expect(tester.widget<AssetMarketCard>(arb).starred, isTrue);
    });

    testWidgets('Leaderboard ranks trader markets and opens one', (
      tester,
    ) async {
      await openMarkets(tester);
      await tester.tap(find.text('Leaderboard'));
      await tester.pumpAndSettle();
      // By market cap: you (maya.eth, $44.0M) first, then 0xreal.
      expect(find.textContaining('#1', findRichText: true), findsOneWidget);
      expect(find.widgetWithText(VistaFilterChip, 'Most right'), findsNothing);
      // Each trader is a slim card with a small chart, unlike the Assets
      // cards, and there's no Favorites rail.
      expect(find.text('Favorites'), findsNothing);
      expect(find.byType(VistaMarketCard), findsNothing);
      expect(find.byType(AssetMarketCard), findsNothing);
      final rows = find.byType(LeaderboardCard);
      final maya = rows.first;
      expect(
        (
          tester.widget<LeaderboardCard>(maya).name,
          tester.widget<LeaderboardCard>(maya).rank,
        ),
        ('maya.eth', 1),
      );
      expect(tester.widget<LeaderboardCard>(rows.at(1)).name, '0xreal');
      expect(
        find.descendant(of: maya, matching: find.byType(SeriesChart)),
        findsOneWidget,
      );
      for (final text in ['MAYA', 'You']) {
        expect(
          find.descendant(of: maya, matching: find.text(text)),
          findsOneWidget,
        );
      }
      // Every chip: market cap over its 24h change; no star.
      expect(
        find.descendant(of: maya, matching: find.byType(VistaStarButton)),
        findsNothing,
      );
      for (final text in [r'$44.0M']) {
        expect(
          find.descendant(of: maya, matching: find.text(text)),
          findsOneWidget,
        );
      }
      expect(find.textContaining('% right'), findsNothing);

      await tester.scrollUntilVisible(
        find.text('0xreal'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      final xreal = find.ancestor(
        of: find.text('0xreal'),
        matching: find.byType(LeaderboardCard),
      );
      await tester.ensureVisible(xreal);
      await tester.pumpAndSettle();
      await tester.tap(xreal);
      await tester.pumpAndSettle();
      // A card opens the trader's profile, not their market.
      final profile = tester.widget<ProfileScreen>(find.byType(ProfileScreen));
      expect(profile.handle, '0xreal');
      expect(find.byType(TraderMarketScreen), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a new trader on the board opens their profile', (
      tester,
    ) async {
      await openMarkets(tester);
      await tester.tap(find.text('Leaderboard'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.widgetWithText(VistaFilterChip, 'Up and coming'),
      );
      await tester.tap(find.widgetWithText(VistaFilterChip, 'Up and coming'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(LeaderboardCard).first);
      await tester.pumpAndSettle();
      expect(
        tester.widget<ProfileScreen>(find.byType(ProfileScreen)).handle,
        'vexa',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('Change reranks the Leaderboard; no Top P&L', (tester) async {
      await openMarkets(tester);
      await tester.tap(find.text('Leaderboard'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(VistaFilterChip, 'Top P&L'), findsNothing);
      await tester.ensureVisible(
        find.widgetWithText(VistaFilterChip, 'Change'),
      );
      await tester.tap(find.widgetWithText(VistaFilterChip, 'Change'));
      await tester.pumpAndSettle();
      final first = tester.widget<LeaderboardCard>(
        find.byType(LeaderboardCard).first,
      );
      expect((first.name, first.rank), ('pip.eth', 1));
      expect(find.text(r'$6.2M'), findsOneWidget); // same card, cap
    });

    testWidgets('Up and coming narrows the board to new markets', (
      tester,
    ) async {
      await openMarkets(tester);
      await tester.tap(find.text('Leaderboard'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(VistaFilterChip, 'Up and coming'));
      await tester.pumpAndSettle();
      expect(find.text('UNDER 30 DAYS OLD'), findsOneWidget);
      final rows = tester
          .widgetList<LeaderboardCard>(find.byType(LeaderboardCard))
          .toList();
      // By holders gained: vexa (+52) then pip.eth (+41); nothing older
      // than 30 days, so you (maya.eth) aren't on it.
      expect(rows.map((r) => r.name).take(2), ['vexa', 'pip.eth']);
      expect(rows.map((r) => r.name), isNot(contains('maya.eth')));
      expect(find.text('vexa'), findsOneWidget);
      expect(find.text(r'$8.8M'), findsOneWidget);
      expect(find.textContaining('You', findRichText: true), findsNothing);
    });

    Future<void> railShows(WidgetTester tester, String name) async {
      await scrollExploreToTop(tester);
      await tester.scrollUntilVisible(
        find.descendant(
          of: find.byType(VistaMarketCard),
          matching: find.text(name),
        ),
        150,
        scrollable: find
            .ancestor(
              of: find.byType(VistaMarketCard).first,
              matching: find.byType(Scrollable),
            )
            .first,
      );
    }

    List<String> railNames(WidgetTester tester) => tester
        .widgetList<VistaMarketCard>(find.byType(VistaMarketCard))
        .map((c) => c.name)
        .toList();

    testWidgets('asset page star and Explore stars share one watchlist', (
      tester,
    ) async {
      await openMarkets(tester, tall);
      expect(railNames(tester), ['BTC', 'ETH', 'SOL']);

      // Star ARB from its trade page; it joins the end of the rail.
      await scrollToAllMarkets(tester);
      await tester.tap(
        find.descendant(
          of: find.byType(AssetMarketCard),
          matching: find.text('ARB'),
        ),
      );
      await tester.pumpAndSettle();
      final star = find.byType(VistaWatchButton);
      expect(tester.widget<VistaWatchButton>(star).watched, isFalse);
      await tester.tap(star);
      await tester.pump();
      expect(tester.widget<VistaWatchButton>(star).watched, isTrue);
      expect(find.text('Added ARB to Favorites'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Back').last);
      await tester.pumpAndSettle();
      expect(WatchlistState.assets.value, ['BTC', 'ETH', 'SOL', 'ARB']);
      await railShows(tester, 'ARB');

      // Unstar BTC in Explore; its trade page shows it unwatched.
      await scrollToAllMarkets(tester);
      final btc = find.ancestor(
        of: find.text('BTC').last,
        matching: find.byType(AssetMarketCard),
      );
      await tester.tap(
        find.descendant(of: btc, matching: find.byType(VistaStarButton)),
      );
      await tester.pumpAndSettle();
      await scrollExploreToTop(tester);
      expect(railNames(tester).first, 'ETH');
      expect(WatchlistState.assets.value, ['ETH', 'SOL', 'ARB']);
      expect(WatchlistState.isAsset('BTC'), isFalse);
    });

    testWidgets('trader page star updates the Traders favourites', (
      tester,
    ) async {
      await openMarkets(tester);
      await tester.tap(find.text('Leaderboard'));
      await tester.pumpAndSettle();
      // The board opens profiles; the market page is a step further.
      Navigator.of(tester.element(find.byType(MarketsScreen)))
          .push(TraderMarketScreen.route('0xreal'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(VistaWatchButton));
      await tester.pump();
      expect(WatchlistState.isTrader('0xreal'), isTrue);
      await tester.tap(find.bySemanticsLabel('Back').last);
      await tester.pumpAndSettle();
      expect(WatchlistState.traders.value.last, '0xreal');
      // The Leaderboard has no Favorites rail.
      expect(find.text('Favorites'), findsNothing);
    });

    testWidgets('Edit favorites removes with undo, and order drives the rail', (
      tester,
    ) async {
      await openMarkets(tester);
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      expect(find.byType(EditFavoritesScreen), findsOneWidget);
      expect(find.text('Favorite markets'), findsOneWidget);

      await tester.tap(find.byType(VistaStarButton).first);
      await tester.pumpAndSettle();
      expect(WatchlistState.assets.value, ['ETH', 'SOL']);
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(WatchlistState.assets.value, ['BTC', 'ETH', 'SOL']);

      WatchlistState.move(WatchlistState.assets, 2, 0);
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Back').last);
      await tester.pumpAndSettle();
      expect(railNames(tester), ['SOL', 'BTC', 'ETH']);
    });

    for (final MapEntry(key: name, value: (size, padding)) in phones.entries) {
      testWidgets('Edit favorites renders without overflow on $name', (
        tester,
      ) async {
        await openMarkets(tester, size, padding);
        await tester.tap(find.text('Edit'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }

    for (final MapEntry(key: name, value: (size, padding)) in phones.entries) {
      testWidgets('renders without overflow on $name', (tester) async {
        await openMarkets(tester, size, padding);
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Leaderboard'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(find.widgetWithText(VistaFilterChip, 'Up and coming'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  });

  testWidgets('Arena: Live battles swipe sideways and open a battle', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(402, 874) * 3
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const VistaColosseumApp());
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Arena'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Live battles'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    // Busiest live battle first, as a card on a sideways row.
    final busiest = ([
      for (final b in BattlesStore.all.value)
        if (!b.settled) b,
    ]..sort((a, b) => b.takes.compareTo(a.takes))).first;
    expect(find.text('BATTLE   ${busiest.ticker}'), findsWidgets);
    expect(find.textContaining('read both sides'), findsWidgets);
    await tester.tap(find.text(busiest.question).first);
    await tester.pumpAndSettle();
    // The battle page (Figma 599:222): who to follow, every call, join.
    expect(
      tester.widget<BattleScreen>(find.byType(BattleScreen)).battle.id,
      busiest.id,
    );
    expect(find.text('Top traders in this battle'), findsOneWidget);
    expect(find.textContaining('% right'), findsNothing);
    expect(find.byType(VistaFollowButton), findsWidgets);
    expect(find.text('All ${busiest.takes}'), findsOneWidget);
    expect(find.text('Join longs'), findsOneWidget);
    expect(find.text('Join shorts'), findsOneWidget);
    expect(tester.takeException(), isNull);
    // The old Live battles list is gone: no See all on the section.
    Navigator.of(tester.element(find.byType(BattleScreen))).pop();
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.ancestor(
          of: find.text('Live battles'),
          matching: find.byType(Row),
        ),
        matching: find.text('See all'),
      ),
      findsNothing,
    );
  });

  testWidgets('Join on a battle: ticket without that side, post page with it', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(402, 874) * 3
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const VistaColosseumApp());
    await tester.pumpAndSettle();
    LiveBattle live(String ticker) => BattlesStore.all.value.firstWhere(
      (b) => b.ticker == ticker && !b.settled,
    );
    final nav = Navigator.of(tester.element(find.byType(Scaffold).first));
    // No BTC position: the order ticket, on the long side.
    nav.push(BattleScreen.route(live('BTC')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Join longs'));
    await tester.pumpAndSettle();
    expect(find.byType(PickPositionScreen), findsNothing);
    final ticket = tester.widget<OrderTicket>(find.byType(OrderTicket));
    expect((ticket.symbol, ticket.side), ('BTC', TradeSide.long));
    Navigator.of(tester.element(find.byType(OrderTicket))).pop();
    await tester.pumpAndSettle();
    nav.pop();
    await tester.pumpAndSettle();
    // An ETH long: straight to the post page with the battle attached.
    final eth = live('ETH');
    nav.push(BattleScreen.route(eth));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Join longs'));
    await tester.pumpAndSettle();
    expect(find.byType(PickPositionScreen), findsNothing);
    expect(find.byType(ComposeTakeScreen), findsOneWidget);
    expect(find.text('LIVE DEBATE'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Holding the long.');
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('Post'));
    await tester.pumpAndSettle();
    expect(find.byType(BattleScreen), findsOneWidget);
    expect(
      BattlesStore.all.value.firstWhere((b) => b.id == eth.id).takes,
      eth.takes + 1,
    );
  });

  testWidgets('call cards: no TP/SL; the exit and its P/L once closed', (
    tester,
  ) async {
    CallerPost post({double? exit}) => CallerPost(
      handle: 'lunaq',
      age: '40m',
      side: TradeSide.long,
      leverage: 10,
      entryRatio: 1,
      size: 600,
      takeProfit: 1.012,
      stopLoss: 0.994,
      message: '',
      exitRatio: exit,
    );
    Future<void> pump(CallerPost p) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BackedPositionCard(post: p, ticker: 'ETH'),
        ),
      ),
    );
    await pump(post());
    expect(find.textContaining('TP'), findsNothing);
    expect(find.textContaining('SL'), findsNothing);
    expect(find.textContaining('Exit'), findsNothing);
    // Closed 1% up at 10x: +10.0%, fixed, with the exit price.
    await pump(post(exit: 1.01));
    expect(find.text('Exited +10.0%'), findsOneWidget);
    expect(find.textContaining('   Exit '), findsOneWidget);
    expect(find.textContaining('TP'), findsNothing);
  });

  testWidgets('Explore Assets: Favorites, then four sideways sections', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(402, 874) * 3
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const VistaColosseumApp());
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Explore'));
    await tester.pumpAndSettle();
    expect(find.text('Favorites'), findsOneWidget);
    for (final title in [
      'Moving now',
      'Most called',
      'Most battles',
      'Rising traders',
    ]) {
      await tester.scrollUntilVisible(
        find.text(title),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(title), findsOneWidget);
    }
    // Rising traders: most new holders first; a card opens their profile.
    final vexa = find.ancestor(
      of: find.text('+52 holders'),
      matching: find.byType(SlimMarketCard),
    );
    await tester.ensureVisible(vexa);
    await tester.pumpAndSettle();
    await tester.tap(vexa);
    await tester.pumpAndSettle();
    expect(
      tester.widget<ProfileScreen>(find.byType(ProfileScreen)).handle,
      'vexa',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Explore: tapping search shows just the full list; Cancel', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(402, 874) * 3
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const VistaColosseumApp());
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Explore'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    expect(find.text('Favorites'), findsNothing);
    expect(find.text('Moving now'), findsNothing);
    expect(find.text('ALL MARKETS'), findsNothing);
    expect(find.byType(AssetMarketCard), findsNWidgets(5));
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Favorites'), findsOneWidget);
    expect(find.text('Cancel'), findsNothing);
  });

  testWidgets('Leaderboard: Brand new chip lists new markets, newest first', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(402, 874) * 3
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const VistaColosseumApp());
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Explore'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Leaderboard'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(VistaFilterChip, 'Brand new'));
    await tester.pumpAndSettle();
    expect(find.text('JUST OPENED'), findsOneWidget);
    // No time window; the same card as every other chip.
    expect(find.text('NEW'), findsNothing);
    expect(find.bySemanticsLabel('7d'), findsNothing);
    final rows = tester
        .widgetList<LeaderboardCard>(find.byType(LeaderboardCard))
        .map((c) => c.name)
        .toList();
    expect(rows, ['pip.eth', 'vexa', 'orca.sol']); // 3, 6, 11 days
    expect(find.text(r'$6.2M'), findsOneWidget);
  });

  testWidgets('Wallet History: closing a position lists it with its P/L', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(402, 874) * 3
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const VistaColosseumApp());
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Wallet'));
    await tester.pumpAndSettle();
    final wallet = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('History'),
      200,
      scrollable: wallet,
    );
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(find.text('Closed   3'), findsOneWidget);
    // Close the ETH long from Positions; it heads History.
    final eth = PositionsState.open.value.firstWhere(
      (p) => p.detail.symbol == 'ETH',
    );
    PositionsState.remove(eth);
    TradeHistory.add(ClosedTrade.from(eth));
    await tester.pumpAndSettle();
    expect(find.text('Closed   4'), findsOneWidget);
    expect(TradeHistory.closed.value.first.symbol, 'ETH');
    await tester.scrollUntilVisible(
      find.text('Ethereum'),
      200,
      scrollable: wallet,
    );
    await tester.tap(find.text('Ethereum'));
    await tester.pumpAndSettle();
    expect(find.byType(ReceiptSheet), findsOneWidget);
    expect(find.text('Closed at'), findsOneWidget);
  });

  testWidgets('a battle you are in settles; the result sheet shows', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(402, 874) * 3
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const VistaColosseumApp());
    await tester.pumpAndSettle();
    const label = r'ETH holds $2,900 into the close';
    LiveBattle quick() =>
        BattlesStore.all.value.firstWhere((b) => b.label == label);
    expect(quick().settled, isFalse);
    expect(BattlesStore.yourSide(quick()), TradeSide.long);
    final before = Notifications.unread.value;
    // Three minutes on: it's due.
    DemoClock.now = () => DemoClock.start.add(const Duration(minutes: 3));
    await tester.pump(const Duration(seconds: 16));
    await tester.pumpAndSettle();
    expect(quick().settled, isTrue);
    expect(find.byType(BattleResultSheet), findsOneWidget);
    // ETH is well above $2,900: the statement held, so your long won.
    expect(quick().result!.longRight, isTrue);
    expect(find.text('You won the battle'), findsOneWidget);
    expect(
      BattlesStore.longWins(quick(), 2850),
      isFalse,
    ); // under the line, it wouldn't have
    expect(Notifications.unread.value, before + 1);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.byType(BattleResultSheet), findsNothing);
  });

  testWidgets('Invite: green pill on My portfolio and in Settings', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(402, 874) * 3
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const VistaColosseumApp());
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Wallet'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('+ Invite friends'));
    await tester.pumpAndSettle();
    expect(find.byType(InviteSheet), findsOneWidget);
    expect(find.text('vista.app/i/maya'), findsOneWidget);
    Navigator.of(tester.element(find.byType(InviteSheet))).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Invite friends'), findsOneWidget);
    await tester.tap(find.text('Invite friends'));
    await tester.pumpAndSettle();
    expect(find.byType(InviteSheet), findsOneWidget);
  });

  group('challenge', () {
    Future<void> toCalls(WidgetTester tester) async {
      tester.view
        ..physicalSize = const Size(402, 874) * 3
        ..devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const VistaColosseumApp());
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Arena'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Trending calls'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -200));
      await tester.pumpAndSettle();
    }

    testWidgets('holding the other side opens the sheet, then the composer;'
        ' posting starts the debate on their call', (tester) async {
      await toCalls(tester);
      // vega is short ETH and you hold an ETH long.
      await tester.tap(find.bySemanticsLabel('Challenge').first);
      await tester.pumpAndSettle();
      expect(find.byType(ChallengeSheet), findsOneWidget);
      expect(find.text('Challenge vega'), findsOneWidget);
      expect(find.text('24 hours'), findsOneWidget);
      expect(find.text('YOUR SIDE   LONG ETH'), findsOneWidget);
      expect(
        find.textContaining('ETH closes above', findRichText: true),
        findsOneWidget,
      );
      // Ready-made challenges: swipe to Touches and set its price.
      expect(find.text('CLOSES ABOVE'), findsOneWidget);
      await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
      await tester.pumpAndSettle();
      final touches = find.byKey(const ValueKey('challenge-card-1'));
      await tester.enterText(
        find.descendant(of: touches, matching: find.byType(TextField)),
        '3100',
      );
      await tester.pumpAndSettle();
      const statement = r'ETH touches $3,100 in 24 hours';
      expect(find.text(statement), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Next: make your case'));
      await tester.pumpAndSettle();
      expect(find.byType(ComposeTakeScreen), findsOneWidget);
      expect(find.text('LIVE DEBATE'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Breaks out by tomorrow.');
      await tester.pump();
      await tester.tap(find.bySemanticsLabel('Post'));
      await tester.pumpAndSettle();
      final debate = BattlesStore.all.value.first;
      expect(
        (debate.label, debate.takes, debate.longShare),
        (statement, 2, 0.5),
      );
      final vega = CallsStore.all.value.firstWhere(
        (t) => t.handle == 'vega' && t.ticker == 'ETH',
      );
      expect(vega.battle, statement);
      expect(
        CallsStore.all.value.where(
          (t) => t.handle == PortfolioMock.handle && t.battle == statement,
        ),
        hasLength(1),
      );
    });

    testWidgets('without that side, the ticket opens on it', (tester) async {
      await toCalls(tester);
      // kilo.sol is short SOL; you only hold a SOL short.
      await tester.tap(find.bySemanticsLabel('Challenge').last);
      await tester.pumpAndSettle();
      expect(find.byType(ChallengeSheet), findsNothing);
      final ticket = tester.widget<OrderTicket>(find.byType(OrderTicket));
      expect((ticket.symbol, ticket.side), ('SOL', TradeSide.long));
    });
  });

  group('arena', () {
    Future<void> openArena(
      WidgetTester tester, [
      Size size = const Size(402, 874),
      EdgeInsets pad = EdgeInsets.zero,
    ]) async {
      tester.view
        ..physicalSize = size * 3
        ..devicePixelRatio = 3
        ..padding = FakeViewPadding(top: pad.top * 3, bottom: pad.bottom * 3);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const VistaColosseumApp());
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Arena'));
      await tester.pumpAndSettle();
      // Most of these are about every call: Calls › See all on the hub.
      await openAllCalls(tester);
    }

    // The feed's vertical list (the carousel and chips scroll sideways).
    final feed = find.byWidgetPredicate(
      (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
    );
    Future<void> scrollTo(WidgetTester tester, Finder f) async {
      await tester.scrollUntilVisible(f, 200, scrollable: feed);
      await tester.pumpAndSettle();
    }

    testWidgets(
      'Arena hub: markets, trending, top calls; See all is every call',
      (tester) async {
        tester.view
          ..physicalSize = const Size(402, 874) * 3
          ..devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(const VistaColosseumApp());
        await tester.pumpAndSettle();
        await tester.tap(find.bySemanticsLabel('Arena'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        // The account bar (with notifications), search, your markets, the +.
        expect(find.bySemanticsLabel(RegExp('^Notifications')), findsOneWidget);
        expect(find.text(r'Search $tickers or @people'), findsOneWidget);
        expect(find.text('Your markets'), findsOneWidget);
        expect(find.bySemanticsLabel(RegExp('room')), findsWidgets);
        expect(find.bySemanticsLabel('Make a call'), findsOneWidget);
        // A market row opens that market's room in every call.
        // Your markets are the ones you hold: ETH, SOL and 0xreal's market.
        expect(find.bySemanticsLabel(RegExp('^ETH room')), findsOneWidget);
        expect(find.bySemanticsLabel(RegExp('^SOL room')), findsOneWidget);
        expect(find.bySemanticsLabel(RegExp('^REAL room')), findsOneWidget);
        expect(
          find.text('You: LONG 5x   7 calls today   2 debates'),
          findsOneWidget,
        );
        await tester.tap(find.bySemanticsLabel(RegExp('^ETH room')).first);
        await tester.pumpAndSettle();
        expect(find.byType(RoomScreen), findsOneWidget);
        expect(
          tester
              .widgetList<HubCallCard>(find.byType(HubCallCard))
              .every((c) => c.take.ticker == 'ETH'),
          isTrue,
        );
        await tester.tap(find.bySemanticsLabel('Back').last);
        await tester.pumpAndSettle();
        // Trending calls › See all: every call, nothing else.
        await openAllCalls(tester);
        expect(find.byType(TrendingCallsScreen), findsOneWidget);
        expect(find.byType(BattleTile), findsNothing);
        expect(find.byType(HubCallCard), findsWidgets);
      },
    );

    testWidgets(
      'a room: follow it, top traders, debates, post from a position',
      (tester) async {
        tester.view
          ..physicalSize = const Size(402, 874) * 3
          ..devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MaterialApp(
            theme: VistaTheme.dark(),
            home: const RoomScreen(roomKey: 'ARB'),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('ARB room'), findsOneWidget);
        expect(find.text('Top traders in ARB'), findsOneWidget);
        expect(find.textContaining('% right'), findsNothing);
        // Always three, by the cap of their own market.
        expect(find.textContaining(RegExp(r'\d+ ARB call')), findsNWidgets(3));
        // Follow room adds it to your markets (favourites).
        expect(WatchlistState.isAsset('ARB'), isFalse);
        await tester.tap(find.bySemanticsLabel('Follow room'));
        await tester.pumpAndSettle();
        expect(WatchlistState.isAsset('ARB'), isTrue);
        // Its debates.
        await tester.tap(find.textContaining('Debates ('));
        await tester.pumpAndSettle();
        expect(
          tester
              .widgetList<BattleTile>(find.byType(BattleTile))
              .every((b) => b.battle.ticker == 'ARB'),
          isTrue,
        );
        // Post a call: no ARB position yet, so open one first.
        await tester.tap(find.text('Post a call on ARB'));
        await tester.pumpAndSettle();
        expect(find.text('No ARB position open'), findsOneWidget);
        expect(find.text('Open a long'), findsOneWidget);
      },
    );

    testWidgets('Your markets follow Portfolio: close a position, it goes', (
      tester,
    ) async {
      tester.view
        ..physicalSize = const Size(402, 874) * 3
        ..devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const VistaColosseumApp());
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Arena'));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel(RegExp('^SOL room')), findsOneWidget);
      final sol = PositionsState.open.value.firstWhere(
        (p) => p.detail.symbol == 'SOL',
      );
      PositionsState.remove(sol);
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel(RegExp('^SOL room')), findsNothing);
      expect(find.bySemanticsLabel(RegExp('^ETH room')), findsOneWidget);
    });

    testWidgets('an ETH room posts from the ETH position', (tester) async {
      tester.view
        ..physicalSize = const Size(402, 874) * 3
        ..devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: VistaTheme.dark(),
          home: const RoomScreen(roomKey: 'ETH'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Post a call on ETH'));
      await tester.pumpAndSettle();
      expect(find.text('Ethereum'), findsOneWidget);
      expect(find.text('Solana'), findsNothing);
    });

    testWidgets('Trending calls is calls only; a debate badge opens it', (
      tester,
    ) async {
      await openArena(tester);
      expect(find.text('Trending calls'), findsOneWidget);
      expect(find.byType(BattleTile), findsNothing);
      // No room chips: just the three sorts.
      expect(
        tester
            .widgetList<VistaFilterChip>(find.byType(VistaFilterChip))
            .map((c) => c.label),
        ['Following', 'Trending', 'New'],
      );
      expect(find.byType(HubCallCard), findsWidgets);
      final renata = find.byWidgetPredicate(
        (w) => w is HubCallCard && w.take.handle == 'renatafx',
      );
      await scrollTo(tester, renata);
      await tester.tap(
        find.descendant(
          of: renata,
          matching: find.textContaining(r'Reclaims $72,000 by Fri'),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<BattleScreen>(find.byType(BattleScreen)).battle.ticker,
        'BTC',
      );
    });

    testWidgets('agree toggles; Join opens the ticket on the take\'s side', (
      tester,
    ) async {
      await openArena(tester);
      await scrollTo(tester, find.bySemanticsLabel('Agree, 48'));
      await tester.tap(find.bySemanticsLabel('Agree, 48'));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Agree, 49'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Join long').first);
      await tester.pumpAndSettle();
      expect(find.text('Place market long'), findsOneWidget);
    });

    testWidgets('Follow on a call card follows the caller everywhere', (
      tester,
    ) async {
      await openArena(tester);
      expect(FollowState.isFollowing('voskov'), isFalse);
      final card = find.byWidgetPredicate(
        (w) => w is HubCallCard && w.take.handle == 'voskov',
      );
      await scrollTo(tester, card);
      await tester.tap(
        find.descendant(of: card, matching: find.text('Follow')),
      );
      await tester.pumpAndSettle();
      expect(FollowState.isFollowing('voskov'), isTrue);
      expect(
        find.descendant(of: card, matching: find.text('Following')),
        findsOneWidget,
      );
      // The profile agrees.
      await tester.tap(
        find.descendant(of: card, matching: find.byType(PersonInitial)).first,
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<VistaFollowButton>(find.byType(VistaFollowButton).first)
            .following,
        isTrue,
      );
    });

    testWidgets('a call card shows the caller\'s market; it opens', (
      tester,
    ) async {
      await openArena(tester);
      final call = find.byWidgetPredicate(
        (w) =>
            w is HubCallCard &&
            w.take.handle == 'kilo.sol' &&
            w.take.ticker == 'SOL' &&
            w.take.backed,
      );
      await scrollTo(tester, call);
      final market = find.descendant(
        of: call,
        matching: find.textContaining(r'$0.1720', findRichText: true),
      );
      expect(market, findsOneWidget);
      await tester.tap(market);
      await tester.pumpAndSettle();
      expect(find.byType(TraderMarketScreen), findsOneWidget);
    });

    testWidgets('Following / Trending / New order the calls', (tester) async {
      await openArena(tester);
      // Sideways chips like Explore's sorts; Trending is on.
      bool on(String l) => tester
          .widget<VistaFilterChip>(find.widgetWithText(VistaFilterChip, l))
          .selected;
      expect(on('Trending'), isTrue);
      expect(find.byType(PopupMenuButton<int>), findsNothing);

      await tester.tap(find.widgetWithText(VistaFilterChip, 'New'));
      await tester.pumpAndSettle();
      expect(on('New'), isTrue);
      final newest = CallsStore.all.value
          .where((t) => t.backed)
          .map((t) => CallsStore.minutesAgo(t.age))
          .reduce((a, b) => a < b ? a : b);
      final first = tester.widget<HubCallCard>(find.byType(HubCallCard).first);
      expect(CallsStore.minutesAgo(first.take.age), newest);

      await tester.tap(find.widgetWithText(VistaFilterChip, 'Following'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widgetList<HubCallCard>(find.byType(HubCallCard))
            .every((c) => FollowState.isFollowing(c.take.handle)),
        isTrue,
      );
    });

    testWidgets('settled calls and debates post to the feed', (tester) async {
      await openArena(tester);
      await scrollTo(tester, find.text('SETTLED RIGHT'));
      final maya = find.ancestor(
        of: find.text('SETTLED RIGHT'),
        matching: find.byType(SettlementItem),
      );
      // The caller's own market as it settled.
      expect(
        find.descendant(of: maya, matching: find.textContaining('MAYA ▲2.1%')),
        findsOneWidget,
      );
      await tester.tap(
        find.descendant(of: maya, matching: find.text('maya.eth')),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ReceiptSheet), findsOneWidget);
      await tester.tapAt(const Offset(200, 60));
      await tester.pumpAndSettle();

      await scrollTo(tester, find.text('Debate settled'));
      await tester.tap(find.text('Read the thread ›'));
      await tester.pumpAndSettle();
      expect(find.byType(BattleScreen), findsOneWidget);
      expect(find.text('SETTLED   LONG SIDE RIGHT'), findsOneWidget);
      expect(find.text('Join longs'), findsNothing); // settled: closed
    });

    testWidgets('+ → pick a position → write → post: it tops the feed', (
      tester,
    ) async {
      await openArena(tester);
      await tester.tap(find.bySemanticsLabel('Make a call'));
      await tester.pumpAndSettle();
      expect(find.byType(PickPositionScreen), findsOneWidget);
      expect(find.text('What are you calling?'), findsOneWidget);
      expect(find.text('YOUR POSITIONS   3'), findsOneWidget);
      await tester.tap(find.text('Ethereum'));
      await tester.pumpAndSettle();

      // The composer: the position card sits under the text field.
      expect(find.byType(ComposeTakeScreen), findsOneWidget);
      expect(find.text('LONG ETH'), findsOneWidget);
      expect(find.text('LONG 5x'), findsOneWidget);
      expect(
        tester.getTopLeft(find.byType(BackedPositionCard)).dy,
        greaterThan(tester.getBottomLeft(find.byType(TextField)).dy),
      );
      // Post waits for text.
      await tester.tap(find.bySemanticsLabel('Post'));
      await tester.pumpAndSettle();
      expect(find.byType(ComposeTakeScreen), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'ETH/BTC bottomed.');
      await tester.pump();
      expect(find.text('263'), findsOneWidget); // characters left
      await tester.tap(find.bySemanticsLabel('Post'));
      await tester.pumpAndSettle();

      // Back on Arena with the new take first.
      expect(find.byType(ComposeTakeScreen), findsNothing);
      expect(find.byType(PickPositionScreen), findsNothing);
      final first = tester.widget<HubCallCard>(find.byType(HubCallCard).first);
      expect(first.take.body, 'ETH/BTC bottomed.');
      expect(first.take.handle, 'maya.eth');
    });

    testWidgets('a take posted in Arena shows in that asset\'s Callers', (
      tester,
    ) async {
      await openArena(tester);
      await tester.tap(find.bySemanticsLabel('Make a call'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Solana'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Fading the unlock.');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.bySemanticsLabel('Post'));
      await tester.pumpAndSettle();
      // The same list the trade pages read: SOL's callers now start with it.
      final sol = CallsStore.callersOn('SOL');
      expect(sol.first.handle, 'maya.eth');
      expect(sol.first.message, 'Fading the unlock.');
      expect(
        CallsStore.callersOn('ETH').map((p) => p.message),
        isNot(contains('Fading the unlock.')),
      );
      // Trade pages and Arena share the calls: ETH's are the ETH takes.
      expect(CallsStore.callersOn('ETH').map((p) => p.handle), [
        'vega',
        'lunaq',
        'maya.eth',
        'orbit.eth',
        'maya.eth', // your call on the battle that settles first
      ]);
    });

    testWidgets('the composer makes a call, not a debate', (tester) async {
      await openArena(tester);
      await tester.tap(find.bySemanticsLabel('Make a call'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ethereum'));
      await tester.pumpAndSettle();
      expect(find.byType(ComposeTakeScreen), findsOneWidget);
      expect(find.bySemanticsLabel('Make it a debate'), findsNothing);
      expect(find.byType(MakeBattleButton), findsNothing);
      expect(find.text('Start debate'), findsNothing);
    });

    testWidgets('Cancel leaves the composer without posting', (tester) async {
      await openArena(tester);
      await tester.tap(find.bySemanticsLabel('Make a call'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Solana'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Not yet.');
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.byType(PickPositionScreen), findsOneWidget);
      expect(CallsStore.all.value.where((t) => t.age == 'now'), isEmpty);
    });

    for (final MapEntry(key: name, value: (size, padding)) in phones.entries) {
      testWidgets('composer renders without overflow on $name', (tester) async {
        await openArena(tester, size, padding);
        await tester.tap(find.bySemanticsLabel('Make a call'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('0xreal'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }

    for (final MapEntry(key: name, value: (size, padding)) in phones.entries) {
      testWidgets('position picker renders without overflow on $name', (
        tester,
      ) async {
        await openArena(tester, size, padding);
        await tester.tap(find.bySemanticsLabel('Make a call'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('tapping a caller opens their profile', (tester) async {
      await openArena(tester);
      final card = find.byWidgetPredicate(
        (w) => w is HubCallCard && w.take.handle == 'voskov',
      );
      await scrollTo(tester, card);
      await tester.tap(
        find.descendant(of: card, matching: find.byType(PersonInitial)).first,
      );
      await tester.pumpAndSettle();
      expect(find.byType(ProfileScreen), findsOneWidget);
    });

    for (final MapEntry(key: name, value: (size, padding)) in phones.entries) {
      testWidgets('renders without overflow on $name', (tester) async {
        await openArena(tester, size, padding);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('battle page', () {
    Future<void> openDebate(
      WidgetTester tester, [
      Size size = const Size(402, 874),
      EdgeInsets pad = EdgeInsets.zero,
    ]) async {
      tester.view
        ..physicalSize = size * 3
        ..devicePixelRatio = 3
        ..padding = FakeViewPadding(top: pad.top * 3, bottom: pad.bottom * 3);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const VistaColosseumApp());
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Arena'));
      await tester.pumpAndSettle();
      // The busiest live battle's page.
      final busiest = ([
        for (final b in BattlesStore.all.value)
          if (!b.settled) b,
      ]..sort((a, b) => b.takes.compareTo(a.takes))).first;
      Navigator.of(tester.element(find.byType(Scaffold).first))
          .push(BattleScreen.route(busiest));
      await tester.pumpAndSettle();
    }

    testWidgets('a battle page: the question, its calls, and join', (
      tester,
    ) async {
      await openDebate(tester);
      expect(
        find.text(r"Reclaims $72,000 before Friday's expiry"),
        findsOneWidget,
      );
      expect(find.byType(HubCallCard), findsWidgets);
      expect(find.text('Join longs'), findsOneWidget);
    });

    for (final MapEntry(key: name, value: (size, padding)) in phones.entries) {
      testWidgets('renders without overflow on $name', (tester) async {
        await openDebate(tester, size, padding);
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Join shorts'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  });

  for (final tab in ['Home', 'Wallet']) {
    testWidgets('$tab top bar: handle over balance, Deposit on the right', (
      tester,
    ) async {
      tester.view
        ..physicalSize = const Size(402, 874) * 3
        ..devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const VistaColosseumApp());
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel(tab));
      await tester.pumpAndSettle();

      final wallet = tab == 'Wallet';
      final bar = find.descendant(
        of: find.byType(wallet ? PortfolioScreen : HomeScreen),
        matching: find.byType(AccountTopBar),
      );
      Finder inBar(String text) =>
          find.descendant(of: bar, matching: find.text(text));
      final handle = tester.getRect(inBar('maya.eth'));
      final balance = tester.getRect(inBar(r'$12,480'));
      expect(balance.top, greaterThanOrEqualTo(handle.bottom - 1));
      expect(balance.left, closeTo(handle.left, 1));

      // Right of Deposit: the settings gear on Wallet, the notifications
      // bell on the other tabs.
      final icon = find.descendant(
        of: bar,
        matching: find.byType(VistaIconButton),
      );
      final deposit = tester.getRect(inBar('Deposit'));
      expect(icon, findsOneWidget);
      expect(tester.getRect(icon).left, greaterThan(deposit.left));
      expect(
        tester.widget<VistaIconButton>(icon).semanticLabel,
        startsWith(wallet ? 'Settings' : 'Notifications'),
      );
      await tester.tap(icon);
      await tester.pumpAndSettle();
      expect(
        find.byType(SettingsScreen),
        wallet ? findsOneWidget : findsNothing,
      );
    });
  }

  group('asset trade', () {
    Future<void> launch(
      WidgetTester tester, [
      Size size = const Size(402, 874),
      EdgeInsets pad = EdgeInsets.zero,
    ]) async {
      tester.view
        ..physicalSize = size * 3
        ..devicePixelRatio = 3
        ..padding = FakeViewPadding(top: pad.top * 3, bottom: pad.bottom * 3);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const VistaColosseumApp());
      await tester.pumpAndSettle();
    }

    Finder visible(String text) => find.text(text).hitTestable();

    testWidgets('Home Details opens the asset on the Market panel', (
      tester,
    ) async {
      await launch(tester);
      await tester.tap(find.text('Details').first);
      await tester.pumpAndSettle();
      expect(find.byType(AssetTradeScreen), findsOneWidget);
      expect(visible('Ethereum'), findsOneWidget); // the card is ETH
      expect(visible('Longs pay shorts'), findsOneWidget);

      // One tap to any panel: the tabs, Book last.
      Future<void> panel(String name) async {
        await tester.tap(
          find.descendant(
            of: find.byType(VistaUnderlineTabs),
            matching: find.text(name),
          ),
        );
        await tester.pumpAndSettle();
      }

      final tabs = tester.widget<VistaUnderlineTabs>(
        find.byType(VistaUnderlineTabs),
      );
      expect(tabs.labels, ['Market', 'Callers', 'Alerts', 'Book']);
      await panel('Book');
      expect(visible('Spread 0.02'), findsOneWidget);
      // Just the book: no Trades tab, no market-buy slippage line.
      expect(find.text('Trades'), findsNothing);
      expect(find.text(r'Market buy $10,000'), findsNothing);
      expect(find.textContaining('Bids 11.58'), findsNothing);
      // ETH's own book, around its live price.
      expect(find.text('2,968.40'), findsOneWidget);
      expect(find.text('2,968.42'), findsOneWidget);
      expect(find.text('Spread 0.02'), findsOneWidget);
      expect(find.text('67,412.0'), findsNothing);
      await panel('Callers');
      expect(visible('Callers in ETH'), findsOneWidget);
      // No long/short tally or split bar over the thread.
      expect(find.text('8 long'), findsNothing);
      expect(find.text('4 short'), findsNothing);

      // Callers are a post thread: why they traded, over their order, in
      // this market's own prices; no like, repost or share.
      expect(find.textContaining('Reclaimed the range high'), findsOneWidget);
      expect(find.text(r'Entry $2,946'), findsOneWidget); // ETH, not BTC
      expect(
        find.descendant(
          of: find.byType(AssetTradeScreen),
          matching: find.bySemanticsLabel(RegExp('Like|Repost|Share')),
        ),
        findsNothing,
      );

      // Following shows people the user follows; Everyone adds the rest.
      expect(find.text('vega'), findsNothing);
      await tester.tap(find.text('Everyone'));
      await tester.pumpAndSettle();
      expect(find.text('vega'), findsOneWidget); // newest, first
      expect(
        find.textContaining('Third tap of the same ceiling'),
        findsOneWidget,
      );
      await tester.tap(find.text('Following'));
      await tester.pumpAndSettle();
      expect(find.text('vega'), findsNothing);
      // The Market panel has no funding bars or liquidation levels now.
      expect(find.text('Nearest liquidations'), findsNothing);

      // Tapping a caller's order card opens their play as a trade card.
      await tester.tap(find.bySemanticsLabel("Open lunaq's play"));
      await tester.pumpAndSettle();
      expect(find.byType(CallerPlayScreen), findsOneWidget);
      expect(find.text("lunaq's call"), findsOneWidget);
      expect(find.byType(TradeIdeaCard), findsWidgets);
      expect(find.textContaining('Does ETH reach'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Back').last);
      await tester.pumpAndSettle();
      expect(find.byType(CallerPlayScreen), findsNothing);

      // A caller opens their profile.
      await tester.dragUntilVisible(
        find.text('lunaq'),
        find.text('Callers in ETH'),
        const Offset(0, -150),
      );
      await tester.pumpAndSettle();
      await tester.tap(visible('lunaq'));
      await tester.pumpAndSettle();
      expect(find.text('HOLDING NOW'), findsOneWidget);
    });

    testWidgets('Explore asset row opens it; handle opens the chart', (
      tester,
    ) async {
      await launch(tester);
      await tester.tap(find.bySemanticsLabel('Explore'));
      await tester.pumpAndSettle();
      await scrollToAllMarkets(tester);
      await tester.tap(
        find.descendant(
          of: find.byType(AssetMarketCard),
          matching: find.text('SOL'),
        ),
      );
      await tester.pumpAndSettle();
      expect(visible('Solana'), findsOneWidget);

      await tester.fling(
        find.byType(VistaDragHandle),
        const Offset(0, 400),
        1500,
      );
      await tester.pumpAndSettle();
      expect(visible('Longs pay shorts'), findsNothing);
      expect(find.byType(CandleChart), findsOneWidget);
      // Generated SOL history ends on the quoted price.
      expect(find.text('214.90'), findsOneWidget);
      PlotMode mode() =>
          tester.widget<PriceChart>(find.byType(PriceChart)).mode;
      expect(mode(), PlotMode.candles);

      Finder toggle(String asset) =>
          find.byWidgetPredicate((w) => w is VistaIcon && w.asset == asset);
      await tester.tap(toggle(VistaAssets.chartTypeCandles));
      await tester.pump();
      expect(mode(), PlotMode.line);
      await tester.tap(toggle(VistaAssets.chartTypeToggle));
      await tester.pump();
      expect(mode(), PlotMode.candles);

      await tester.tap(find.text('1D'));
      await tester.pump();
      expect(
        tester.widget<PriceChart>(find.byType(PriceChart)).period,
        const Duration(days: 1),
      );
      expect(tester.takeException(), isNull);
    });

    for (final MapEntry(key: name, value: (size, padding)) in phones.entries) {
      testWidgets('renders without overflow on $name', (tester) async {
        await launch(tester, size, padding);
        await tester.tap(find.text('Details').first);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        for (var i = 0; i < 2; i++) {
          await tester.fling(
            find.byType(PageView),
            const Offset(-300, 0),
            1500,
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
        await tester.fling(
          find.byType(VistaDragHandle),
          const Offset(0, 400),
          1500,
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('position sheet', () {
    Future<void> openPosition(
      WidgetTester tester,
      String title, [
      Size size = const Size(402, 874),
      EdgeInsets pad = EdgeInsets.zero,
    ]) async {
      tester.view
        ..physicalSize = size * 3
        ..devicePixelRatio = 3
        ..padding = FakeViewPadding(top: pad.top * 3, bottom: pad.bottom * 3);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const VistaColosseumApp());
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Wallet'));
      await tester.pumpAndSettle();
      final row = find.descendant(
        of: find.byType(PortfolioScreen),
        matching: find.text(title),
      );
      await tester.ensureVisible(row);
      await tester.pumpAndSettle();
      await tester.tap(row);
      await tester.pumpAndSettle();
    }

    testWidgets('tapping a position slides its sheet up', (tester) async {
      await openPosition(tester, 'Ethereum');
      expect(find.byType(PositionSheet), findsOneWidget);
      expect(find.text('Unrealised P/L'), findsOneWidget);
      expect(find.text(r'+$90.00'), findsOneWidget);
      expect(find.text(r'ETH $2,968.40'), findsOneWidget);
      expect(find.text(r'$2,990'), findsOneWidget);
      expect(find.text('+3.0%'), findsOneWidget);

      // + nudges take profit up by 0.5% of entry, and its line moves up.
      final tpBefore = tester.getTopLeft(find.text(r'TP $2,990')).dy;
      await tester.tap(find.bySemanticsLabel('Raise Take profit'));
      await tester.pumpAndSettle();
      expect(find.text(r'$3,004'), findsOneWidget);
      expect(find.text('+3.5%'), findsOneWidget);
      expect(tester.getTopLeft(find.text(r'TP $3,004')).dy, lessThan(tpBefore));

      // An edited level turns Close into Save changes; saving confirms on
      // the button, then it reads Close again.
      expect(find.bySemanticsLabel('Close position'), findsNothing);
      expect(find.text('Save changes'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Save take profit and stop loss'));
      await tester.pump();
      expect(find.text('Saved ✓'), findsOneWidget);
      expect(find.bySemanticsLabel('Close position'), findsOneWidget);
      await tester.pump(VistaMotion.confirmHold * 2);
      await tester.pumpAndSettle();
      expect(find.text('Close'), findsOneWidget);

      // Nudging back and forth to the saved value also restores Close.
      await tester.tap(find.bySemanticsLabel('Lower Stop loss'));
      await tester.pump();
      expect(find.text('Save changes'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Raise Stop loss'));
      await tester.pumpAndSettle();
      expect(find.text('Close'), findsOneWidget);

      // Close dismisses the sheet and closes the position (simulated).
      await tester.tap(find.bySemanticsLabel('Close position'));
      await tester.pumpAndSettle();
      expect(find.byType(PositionSheet), findsNothing);
      expect(find.textContaining('Closed Ethereum'), findsOneWidget);
    });

    testWidgets('a short puts stop-loss above entry', (tester) async {
      await openPosition(tester, 'Solana');
      expect(find.text(r'−$30.00'), findsOneWidget);
      final sl = tester.getTopLeft(find.text(r'SL $217.90'));
      final tp = tester.getTopLeft(find.text(r'TP $210.77'));
      expect(sl.dy, lessThan(tp.dy));
      // Take profit can't cross to the losing side of entry.
      for (var i = 0; i < 10; i++) {
        await tester.tap(find.bySemanticsLabel('Raise Take profit'));
        await tester.pump();
      }
      expect(find.text(r'$213.62'), findsNWidgets(1)); // entry unchanged
    });

    for (final MapEntry(key: name, value: (size, padding)) in phones.entries) {
      testWidgets('renders without overflow on $name', (tester) async {
        await openPosition(tester, 'Ethereum', size, padding);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('make a market', () {
    setUp(() => AccountState.reset(withMarket: false));

    Future<void> openWallet(
      WidgetTester tester, [
      Size size = const Size(402, 874),
      EdgeInsets pad = EdgeInsets.zero,
    ]) async {
      tester.view
        ..physicalSize = size * 3
        ..devicePixelRatio = 3
        ..padding = FakeViewPadding(top: pad.top * 3, bottom: pad.bottom * 3);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const VistaColosseumApp());
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Wallet'));
      await tester.pumpAndSettle();
    }

    testWidgets('the span drives the portfolio chart and its change', (
      tester,
    ) async {
      await openWallet(tester);
      expect(find.text(r'+$91 (0.73%)'), findsOneWidget);
      // Both pages (balance and market cap) cover the chosen span. The
      // first chart is the portfolio's; position rows have their own.
      expect(find.text('Last 24 hours'), findsNWidgets(2));
      final day = tester
          .widget<SeriesChart>(find.byType(SeriesChart).first)
          .focus;
      await tester.tap(find.text('1W'));
      await tester.pumpAndSettle();
      expect(find.text(r'+$412 (3.41%)'), findsOneWidget);
      expect(find.text('Past week'), findsNWidgets(2));
      final week = tester
          .widget<SeriesChart>(find.byType(SeriesChart).first)
          .focus;
      // A different window, ending at the same balance.
      expect(week.first, isNot(day.first));
      expect(week.last, closeTo(12480, 0.01));
    });

    testWidgets('without a market Portfolio offers Make a market', (
      tester,
    ) async {
      await openWallet(tester);
      expect(find.bySemanticsLabel('Make a market'), findsOneWidget);
      expect(find.text('Your market'), findsNothing);
      // The chart has no muted market line behind the portfolio.
      final chart = tester.widget<SeriesChart>(find.byType(SeriesChart).first);
      expect(chart.muted, isNull);
      // No market-cap page to swipe to.
      final under = tester.getCenter(pagerBalance) + const Offset(0, 150);
      await tester.flingFrom(under, const Offset(-250, 0), 1000);
      await tester.pumpAndSettle();
      expect(find.text(r'$MAYA market cap').hitTestable(), findsNothing);
    });

    testWidgets('create → consent → live lists the market', (tester) async {
      await openWallet(tester);
      await tester.tap(find.bySemanticsLabel('Make a market'));
      await tester.pumpAndSettle();

      // 1 · Create: taken tickers block Continue; a suggestion fixes it.
      expect(find.text('✓ Available'), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, 'btc');
      await tester.pump();
      expect(find.text('× Taken'), findsOneWidget);
      expect(find.text(r'$BTC'), findsOneWidget); // uppercased
      await tester.tap(find.text(r'Continue with $BTC'));
      await tester.pump();
      expect(find.text('Before you list'), findsNothing);

      await tester.tap(find.bySemanticsLabel(r'Use $MACRO'));
      await tester.pump();
      await tester.tap(find.text(r'Continue with $MACRO'));
      await tester.pumpAndSettle();

      // 2 · Consent: every box is required.
      expect(find.text('Your market has two sides'), findsOneWidget);
      expect(find.text(r'Some will short $MACRO'), findsOneWidget);
      await tester.tap(find.text(r'Create $MACRO'));
      await tester.pump();
      expect(find.text('Your market is open'), findsNothing);
      for (var i = 0; i < 4; i++) {
        final box = find.byType(VistaCheckRow).at(i);
        await tester.tap(box);
        await tester.pump();
      }
      await tester.tap(find.text(r'Create $MACRO'));
      await tester.pumpAndSettle();

      // 3 · Live, with a check stamped on the market.
      expect(find.text('Your market is open'), findsOneWidget);
      expect(find.text(r'$10,000'), findsOneWidget);
      expect(AccountState.hasMarket.value, isTrue);

      // Back on Portfolio: fees row and the new market-cap page.
      await tester.tap(find.bySemanticsLabel('Close'));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Make a market'), findsNothing);
      expect(find.text('Your market'), findsOneWidget);
      expect(find.text(r'$MACRO market cap'), findsOneWidget);
    });

    for (final MapEntry(key: name, value: (size, padding)) in phones.entries) {
      testWidgets('flow renders without overflow on $name', (tester) async {
        await openWallet(tester, size, padding);
        expect(tester.takeException(), isNull);
        await tester.tap(find.bySemanticsLabel('Make a market'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(find.text(r'Continue with $MAYA'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        for (var i = 0; i < 4; i++) {
          final box = find.byType(VistaCheckRow).at(i);
          await tester.ensureVisible(box);
          await tester.tap(box);
          await tester.pump();
        }
        await tester.tap(find.text(r'Create $MAYA'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('settings', () {
    Future<void> openSettings(
      WidgetTester tester, [
      Size size = const Size(402, 874),
      EdgeInsets pad = EdgeInsets.zero,
    ]) async {
      tester.view
        ..physicalSize = size * 3
        ..devicePixelRatio = 3
        ..padding = FakeViewPadding(top: pad.top * 3, bottom: pad.bottom * 3);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const VistaColosseumApp());
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Wallet'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Settings'));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);
    }

    Future<void> open(WidgetTester tester, String section) async {
      final row = find.text(section);
      await tester.scrollUntilVisible(
        row,
        120,
        scrollable: find
            .descendant(
              of: find.byType(SettingsScreen),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.tap(row);
      await tester.pumpAndSettle();
    }

    testWidgets('gear opens Settings; notification switches update summary', (
      tester,
    ) async {
      await openSettings(tester);
      expect(find.text('maya.eth'), findsOneWidget);
      expect(find.text('All on'), findsOneWidget);
      expect(find.text('Calls'), findsNothing);

      await open(tester, 'Notifications');
      expect(find.text('Calls'), findsOneWidget);
      expect(find.text('WHO NOTIFIES YOU'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Flips notifications'));
      await tester.pumpAndSettle();
      expect(SettingsState.notify.value['flips'], isFalse);
      expect(find.text('3 of 4 on'), findsOneWidget);
      expect(SettingsState.notifyFrom.value['0xreal'], isFalse);
    });

    testWidgets('Deposit and Withdraw sit under the wallet (simulated)', (
      tester,
    ) async {
      await openSettings(tester);
      for (final label in ['Deposit', 'Withdraw']) {
        expect(find.widgetWithText(VistaPillButton, label), findsOneWidget);
      }
      await tester.tap(find.widgetWithText(VistaPillButton, 'Withdraw'));
      await tester.pump();
      expect(find.text('Withdraw — not in the demo yet'), findsOneWidget);
    });

    testWidgets('Display settings change the charts and the Long side', (
      tester,
    ) async {
      await openSettings(tester);
      await open(tester, 'Display');
      await tester.tap(find.text('Line'));
      await tester.tap(find.text('Right'));
      await tester.pumpAndSettle();
      expect(DisplayPrefs.chartMode.value, PlotMode.line);
      expect(DisplayPrefs.longOnRight.value, isTrue);

      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Home'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Details').first);
      await tester.pumpAndSettle();
      await tester.fling(
        find.byType(VistaDragHandle),
        const Offset(0, 400),
        1500,
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<PriceChart>(find.byType(PriceChart)).mode,
        PlotMode.line,
      );
      // Long now sits to the right of Short.
      final long = tester.getCenter(find.text('Long').last);
      final short = tester.getCenter(find.text('Short').last);
      expect(long.dx, greaterThan(short.dx));
    });

    for (final MapEntry(key: name, value: (size, padding)) in phones.entries) {
      testWidgets('renders every section without overflow on $name', (
        tester,
      ) async {
        await openSettings(tester, size, padding);
        for (final section in [
          'Notifications',
          'Display',
          'Security',
          'Legal and privacy',
          'Help and support',
        ]) {
          await open(tester, section);
          expect(tester.takeException(), isNull);
        }
        await tester.scrollUntilVisible(
          find.text('Log out'),
          200,
          scrollable: find.byType(Scrollable).last,
        );
        expect(tester.takeException(), isNull);
      });
    }
  });

  testWidgets('home card replay follows the Candles / Line setting', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(402, 874) * 3
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    Finder painted(String name) => find.byWidgetPredicate(
      (w) => w is CustomPaint && w.painter.runtimeType.toString() == name,
    );
    await tester.pumpWidget(const VistaColosseumApp());
    await tester.pumpAndSettle();
    expect(DisplayPrefs.chartMode.value, PlotMode.candles);
    expect(painted('_ReplayCandles'), findsWidgets);

    DisplayPrefs.chartMode.value = PlotMode.line;
    await tester.pumpAndSettle();
    expect(painted('_ReplayCandles'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('replay moves the header price with the chart, events get '
      'haptics, and it lands on the live figures', (tester) async {
    tester.view
      ..physicalSize = const Size(402, 874) * 3
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final haptics = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') {
          haptics.add(call.arguments as String);
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await tester.pumpWidget(const VistaColosseumApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    // Mid-replay: replayed figures, not the live ones, and no events yet.
    expect(find.textContaining('replaying 5h'), findsWidgets);
    expect(find.text('Whale long \$4.2M'), findsNothing);
    expect(haptics, isEmpty);

    await tester.pump(const Duration(milliseconds: 700)); // past funding
    expect(haptics, ['HapticFeedbackType.selectionClick']);
    await tester.pump(const Duration(milliseconds: 1600)); // past breakout
    expect(haptics, [
      'HapticFeedbackType.selectionClick',
      'HapticFeedbackType.selectionClick',
      'HapticFeedbackType.mediumImpact',
    ]);

    await tester.pumpAndSettle();
    expect(find.textContaining('replaying'), findsNothing);
    expect(find.text('+5.97% since call'), findsWidgets);
    expect(find.text('Broke \$2,950'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  group('open orders', () {
    Future<void> openOrders(
      WidgetTester tester, [
      Size size = const Size(402, 874),
      EdgeInsets pad = EdgeInsets.zero,
    ]) async {
      tester.view
        ..physicalSize = size * 3
        ..devicePixelRatio = 3
        ..padding = FakeViewPadding(top: pad.top * 3, bottom: pad.bottom * 3);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const VistaColosseumApp());
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Wallet'));
      await tester.pumpAndSettle();
      final tab = find.text('Orders');
      await tester.scrollUntilVisible(
        tab,
        120,
        scrollable: find
            .descendant(
              of: find.byType(PortfolioScreen),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.tap(tab);
      await tester.pumpAndSettle();
    }

    Future<void> reveal(WidgetTester tester, Finder f) =>
        tester.scrollUntilVisible(
          f,
          150,
          scrollable: find
              .descendant(
                of: find.byType(PortfolioScreen),
                matching: find.byType(Scrollable),
              )
              .first,
        );

    testWidgets('cards show the order details; Cancel removes, Undo restores', (
      tester,
    ) async {
      await openOrders(tester);
      expect(find.text('Open orders   3'), findsOneWidget);
      Finder rich(String text) => find.textContaining(text, findRichText: true);
      expect(rich(r'Fills at $2,850.00   4.0% below mark'), findsOneWidget);
      expect(find.text(r'Size $2,138   0.75 ETH'), findsOneWidget);
      expect(find.text(r'TP $3,060.00'), findsOneWidget);
      // Only what the order needs: no venue, age or source call.
      expect(find.textContaining('Jupiter'), findsNothing);
      expect(find.textContaining("'s call"), findsNothing);

      await reveal(tester, find.text('1.2 / 4.5 SOL filled'));
      expect(rich(r'Fills at $222.50   3.5% above mark'), findsOneWidget);
      await reveal(tester, find.text('Reduce only'));

      await tester.tap(find.bySemanticsLabel('Cancel SOL order'));
      await tester.pumpAndSettle();
      expect(find.text('Open orders   2'), findsOneWidget);
      expect(find.text('1.2 / 4.5 SOL filled'), findsNothing);
      expect(
        find.text('SOL limit order cancelled (simulated)'),
        findsOneWidget,
      );

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(find.text('Open orders   3'), findsOneWidget);
      expect(find.text('1.2 / 4.5 SOL filled'), findsOneWidget);
    });

    for (final MapEntry(key: name, value: (size, padding)) in phones.entries) {
      testWidgets('renders without overflow on $name', (tester) async {
        await openOrders(tester, size, padding);
        expect(tester.takeException(), isNull);
        await reveal(tester, find.text('Reduce only'));
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('markets everywhere', () {
    tearDown(() {
      final eth = MarketPrices.of('ETH') as ValueNotifier<double>;
      eth.value = MarketPrices.base('ETH');
    });

    testWidgets('one ETH price on Home, Explore and the trade page', (
      tester,
    ) async {
      tester.view
        ..physicalSize = const Size(402, 874) * 3
        ..devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const VistaColosseumApp());
      await tester.pumpAndSettle();
      expect(find.text(r'$2,968.40'), findsWidgets); // Home, ETH card

      // Move the one ETH price; every screen follows it.
      (MarketPrices.of('ETH') as ValueNotifier<double>).value = 3001.25;
      await tester.pumpAndSettle();
      expect(find.text(r'$3,001.25'), findsWidgets);

      await tester.tap(find.bySemanticsLabel('Explore'));
      await tester.pumpAndSettle();
      await scrollToAllMarkets(tester);
      expect(find.text(r'$3,001'), findsWidgets); // compact, in the list
      await tester.tap(
        find.descendant(
          of: find.byType(AssetMarketCard),
          matching: find.text('ETH'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(r'$3,001.25'), findsOneWidget);
    });

    test('the feed has one call on every market Explore offers', () {
      // Markets opened in the last two weeks have no call yet.
      final markets = [
        for (final m in [...MarketsMock.assets, ...MarketsMock.traders])
          if ((MarketsMock.traderCards[m.id]?.days ?? 999) > 14) m.id,
      ];
      expect(
        [for (final i in mockFeed) i.ticker],
        markets.toList()
          ..remove('ETH')
          ..insert(0, 'ETH'),
      );
      for (final i in mockFeed) {
        expect(
          i.traderMarket,
          MarketsMock.traders.any((m) => m.id == i.ticker),
        );
        expect(MarketPrices.base(i.ticker), greaterThan(0));
      }
    });

    test('generated replays are repeatable and fit the frame', () {
      for (final idea in mockFeed.skip(1)) {
        final s = idea.script;
        expect(s.path.length, 48);
        expect(s.entryY, inInclusiveRange(70, 330));
        for (final p in s.path) {
          expect(p.dy, inInclusiveRange(23.9, 379.1));
        }
        // Up to the whale the path stays below the live-activity rows.
        for (final p in s.path.take(37)) {
          expect(p.dy, greaterThanOrEqualTo(149.9));
        }
        expect(s.events.map((e) => e.vertex), [20, 33, 44]);
        final again = ReplayScript.generate(
          seed: idea.ticker,
          callPrice: idea.callPrice,
          nowPrice: MarketPrices.base(idea.ticker),
          side: idea.side,
          age: idea.age,
          whale: r'$1M',
        );
        expect(again.path, s.path);
      }
    });

    testWidgets('a trader-market card opens that trader market', (
      tester,
    ) async {
      tester.view
        ..physicalSize = const Size(402, 874) * 3
        ..devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const VistaColosseumApp());
      await tester.pumpAndSettle();
      final feed = tester.widget<PageView>(find.byType(PageView).first);
      // Home's default tab (Following), in its ranked order.
      final ideas = [
        for (final t in HomeFeed.following(CallsStore.all.value))
          HomeFeed.ideaOf(t),
      ];
      final index = ideas.indexWhere((i) => i.traderMarket);
      feed.controller!.jumpToPage(index);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Details').hitTestable());
      await tester.pumpAndSettle();
      expect(find.byType(TraderMarketScreen), findsOneWidget);
      expect(find.text(ideas[index].ticker), findsWidgets);
    });
  });

  group('home feed', () {
    test('Following is only people you follow; For You is everyone', () {
      final calls = CallsStore.all.value;
      final following = HomeFeed.following(calls);
      expect(
        following.every((t) => HomeFeed.followed.contains(t.handle)),
        isTrue,
      );
      final forYou = HomeFeed.forYou(calls);
      expect(forYou.length, calls.length);
      expect(forYou.any((t) => !HomeFeed.followed.contains(t.handle)), isTrue);
    });

    test('popularity and freshness rank; following boosts For You', () {
      const big = Take(
        handle: 'x',
        side: TradeSide.long,
        accuracy: '',
        age: '5h',
        ticker: 'BTC',
        body: '',
        likes: 4000,
        joined: 1000,
      );
      const small = Take(
        handle: 'y',
        side: TradeSide.long,
        accuracy: '',
        age: '5h',
        ticker: 'BTC',
        body: '',
        likes: 40,
      );
      const stale = Take(
        handle: 'x',
        side: TradeSide.long,
        accuracy: '',
        age: '3d',
        ticker: 'BTC',
        body: '',
        likes: 4000,
        joined: 1000,
      );
      expect(HomeFeed.score(big), greaterThan(HomeFeed.score(small)));
      expect(HomeFeed.score(big), greaterThan(HomeFeed.score(stale)));
      final followed = HomeFeed.followed.first;
      const base = Take(
        handle: 'nobody',
        side: TradeSide.long,
        accuracy: '',
        age: '1h',
        ticker: 'BTC',
        body: '',
        likes: 100,
      );
      final mine = Take(
        handle: followed,
        side: TradeSide.long,
        accuracy: '',
        age: '1h',
        ticker: 'BTC',
        body: '',
        likes: 100,
      );
      expect(HomeFeed.score(mine), closeTo(HomeFeed.score(base) * 1.5, 1e-9));
    });

    testWidgets('a call posted in Arena is the first card on Home', (
      tester,
    ) async {
      tester.view
        ..physicalSize = const Size(402, 874) * 3
        ..devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const VistaColosseumApp());
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Arena'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Make a call'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ethereum'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'ETH/BTC bottomed.');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.bySemanticsLabel('Post'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Home'));
      await tester.pumpAndSettle();
      final first = tester.widget<TradeIdeaCard>(
        find.byType(TradeIdeaCard).first,
      );
      expect(first.idea.callerHandle, 'maya.eth');
      expect(first.idea.ticker, 'ETH');
      // For You leads with it too.
      await tester.tap(find.text('For You'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TradeIdeaCard>(find.byType(TradeIdeaCard).first)
            .idea
            .callerHandle,
        'maya.eth',
      );
    });

    testWidgets('cards show the market cap (or nothing) before the age', (
      tester,
    ) async {
      tester.view
        ..physicalSize = const Size(402, 874) * 3
        ..devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const VistaColosseumApp());
      await tester.pumpAndSettle();
      // No + on Home.
      expect(find.bySemanticsLabel('Make a call'), findsNothing);
      // kaito.eth has no market: no measure, just "kaito.eth › · 5h".
      final card = find.byType(TradeIdeaCard).first;
      final handle = tester.widget<TradeIdeaCard>(card).idea.callerHandle;
      expect(TraderStanding.of(handle), isNull);
      expect(
        find.descendant(of: card, matching: find.textContaining('% right')),
        findsNothing,
      );
      // A trader with a market shows its cap: "MAYA $44.0M".
      expect(TraderStanding.of('maya.eth')?.cap, r'$44.0M');

      // A call made from Arena's + leads Home.
      await tester.tap(find.bySemanticsLabel('Arena'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Make a call'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Solana'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Fading the unlock.');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.bySemanticsLabel('Post'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Home'));
      await tester.pumpAndSettle();
      final first = tester.widget<TradeIdeaCard>(
        find.byType(TradeIdeaCard).first,
      );
      expect(first.idea.callerHandle, 'maya.eth');
      expect(first.idea.question, 'Fading the unlock.');
    });

    testWidgets('the tabs switch feeds and start at the top', (tester) async {
      tester.view
        ..physicalSize = const Size(402, 874) * 3
        ..devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const VistaColosseumApp());
      await tester.pumpAndSettle();
      String firstHandle() => tester
          .widget<TradeIdeaCard>(find.byType(TradeIdeaCard).first)
          .idea
          .callerHandle;
      expect(
        firstHandle(),
        HomeFeed.following(CallsStore.all.value).first.handle,
      );
      await tester.tap(find.text('For You'));
      await tester.pumpAndSettle();
      expect(firstHandle(), HomeFeed.forYou(CallsStore.all.value).first.handle);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('trade page Callers: Join opens the ticket on their side', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(402, 874) * 3
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: VistaTheme.dark(),
        home: const AssetTradeScreen(ticker: 'ETH'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find
          .descendant(
            of: find.byType(VistaUnderlineTabs),
            matching: find.text('Callers'),
          )
          .first,
    );
    await tester.pumpAndSettle();
    final join = find.byType(VistaJoinPill).first;
    await tester.ensureVisible(join);
    await tester.pumpAndSettle();
    final side = tester.widget<VistaJoinPill>(join).side;
    await tester.tap(join);
    await tester.pumpAndSettle();
    expect(
      find.text('Place market ${side.label.toLowerCase()}'),
      findsOneWidget,
    );
  });

  group('receipts', () {
    Future<void> openProfile(WidgetTester tester) async {
      tester.view
        ..physicalSize = const Size(402, 874) * 3
        ..devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: VistaTheme.dark(),
          home: const ProfileScreen(handle: 'maya.eth'),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('All receipts opens the record; a receipt opens its detail', (
      tester,
    ) async {
      await openProfile(tester);
      await tester.scrollUntilVisible(
        find.text('All receipts ›'),
        300,
        scrollable: find
            .byWidgetPredicate(
              (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
            )
            .first,
      );
      await tester.tap(find.text('All receipts ›'));
      await tester.pumpAndSettle();
      expect(find.byType(ReceiptsScreen), findsOneWidget);
      expect(find.text("maya.eth's record"), findsOneWidget);
      expect(find.text('58% right'), findsOneWidget);
      // Open filters to the live ones.
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Right at'), findsNothing);
      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(r'BTC reclaims $66,000 by Tue'));
      await tester.pumpAndSettle();
      expect(find.byType(ReceiptSheet), findsOneWidget);
      expect(find.text('Settled at'), findsOneWidget);
      expect(find.text(r'$66,340'), findsOneWidget);
      expect(find.text(r'$64,920'), findsOneWidget);
    });

    testWidgets('a holding row opens the call behind it', (tester) async {
      await openProfile(tester);
      final sol = find.descendant(
        of: find.byType(HoldingsTable),
        matching: find.text('SOL'),
      );
      await tester.scrollUntilVisible(
        sol,
        300,
        scrollable: find
            .byWidgetPredicate(
              (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
            )
            .first,
      );
      await tester.tap(sol);
      await tester.pumpAndSettle();
      expect(find.byType(ReceiptSheet), findsOneWidget);
      expect(find.text('sol long 5x'), findsNothing);
      expect(find.text('SOL long 5x'), findsOneWidget);
      expect(find.text('Now'), findsOneWidget);
    });
  });

  group('positions', () {
    Future<void> launch(WidgetTester tester) async {
      tester.view
        ..physicalSize = const Size(402, 874) * 3
        ..devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const VistaColosseumApp());
      await tester.pumpAndSettle();
    }

    testWidgets('a market order from Home lands in Portfolio', (tester) async {
      await launch(tester);
      await tester.tap(find.widgetWithText(VistaPillButton, 'Long').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(r'Long $200   2x'));
      await tester.pump(VistaMotion.confirmHold);
      await tester.pumpAndSettle();
      // The fill gets its own confirmation, burst on top.
      expect(find.byType(OrderFilledSheet), findsOneWidget);
      expect(find.byType(FillBurst), findsOneWidget);
      expect(find.text('Order filled'), findsOneWidget);
      expect(find.text('Filled at'), findsOneWidget);
      expect(find.text(r'$200.00'), findsOneWidget); // you paid
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(find.byType(OrderFilledSheet), findsNothing);
      await tester.tap(find.bySemanticsLabel('Wallet'));
      await tester.pumpAndSettle();
      expect(PositionsState.open.value, hasLength(4));
      // The new one first: the card's market, long at 2x.
      final first = PositionsState.open.value.first;
      expect(first.tag, 'LONG 2x');
      expect(first.detail.opened, 'just now');
    });

    testWidgets('Post a call from the filled popup opens the composer', (
      tester,
    ) async {
      await launch(tester);
      await tester.tap(find.widgetWithText(VistaPillButton, 'Long').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(r'Long $200   2x'));
      await tester.pump(VistaMotion.confirmHold);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Post a call'));
      await tester.pumpAndSettle();
      expect(find.byType(ComposeTakeScreen), findsOneWidget);
      expect(find.text('LONG 2x'), findsOneWidget); // the new position
    });

    testWidgets('Close removes the position; Undo puts it back', (
      tester,
    ) async {
      await launch(tester);
      await tester.tap(find.bySemanticsLabel('Wallet'));
      await tester.pumpAndSettle();
      final row = find.descendant(
        of: find.byType(PortfolioScreen),
        matching: find.text('Ethereum'),
      );
      await tester.ensureVisible(row);
      await tester.pumpAndSettle();
      await tester.tap(row);
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Close position'));
      await tester.pumpAndSettle();
      expect(
        PositionsState.open.value.map((p) => p.title),
        isNot(contains('Ethereum')),
      );
      expect(find.textContaining('Closed Ethereum'), findsOneWidget);
      expect(find.textContaining('realised'), findsOneWidget);
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(PositionsState.open.value.first.title, 'Ethereum');
    });

    testWidgets('no positions: the + picker points to Explore', (tester) async {
      await launch(tester);
      PositionsState.open.value = const [];
      await tester.tap(find.bySemanticsLabel('Arena'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Make a call'));
      await tester.pumpAndSettle();
      expect(find.text('No open positions yet'), findsOneWidget);
      await tester.tap(find.text('Find a market'));
      await tester.pumpAndSettle();
      expect(find.byType(MarketsScreen), findsOneWidget);
      await scrollToAllMarkets(tester);
      expect(find.text('ALL MARKETS'), findsOneWidget);
    });
  });

  group('order ticket', () {
    Future<void> pumpBtc(
      WidgetTester tester, [
      Size size = const Size(402, 874),
      EdgeInsets pad = EdgeInsets.zero,
    ]) async {
      tester.view
        ..physicalSize = size * 3
        ..devicePixelRatio = 3
        ..padding = FakeViewPadding(top: pad.top * 3, bottom: pad.bottom * 3);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: VistaTheme.dark(),
          home: const AssetTradeScreen(ticker: 'BTC'),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('Long opens the ticket; a limit order lands in Open orders', (
      tester,
    ) async {
      await pumpBtc(tester);
      await tester.tap(find.text('Long').last);
      await tester.pumpAndSettle();
      expect(find.byType(OrderTicket), findsOneWidget);
      // Opens as a market order with take profit / stop loss off.
      expect(find.text('Place market long'), findsOneWidget);
      expect(find.text('Take profit'), findsNothing);
      expect(find.text('Cross   10x'), findsOneWidget);
      expect(find.text('Fee (taker 0.05%)'), findsOneWidget);

      // Ticking TP/SL shows the exits.
      await tester.tap(find.text('Take profit / Stop loss'));
      await tester.pumpAndSettle();
      expect(find.text('Take profit'), findsOneWidget);

      // Short + Market re-labels the order and the fee.
      await tester.tap(find.bySemanticsLabel('Short').last);
      await tester.tap(find.bySemanticsLabel('Market').last);
      await tester.pumpAndSettle();
      expect(find.text('Place market short'), findsOneWidget);
      expect(find.text('Fee (taker 0.05%)'), findsOneWidget);

      // Back to a limit long and place it.
      await tester.tap(find.bySemanticsLabel('Long').last);
      await tester.tap(find.bySemanticsLabel('Limit').last);
      await tester.pumpAndSettle();
      final before = OrdersState.open.value.length;
      await tester.tap(find.text('Place limit long'));
      await tester.pump();
      // Confirmed on the button, then the sheet closes.
      expect(find.text('Placed ✓'), findsOneWidget);
      await tester.pump(VistaMotion.confirmHold);
      await tester.pumpAndSettle();
      expect(find.byType(OrderTicket), findsNothing);
      expect(OrdersState.open.value.length, before + 1);
      final placed = OrdersState.open.value.first;
      expect(placed.symbol, 'BTC');
      expect(placed.side, TradeSide.long);
      expect(placed.leverage, 10);
      expect(
        find.text('Limit long placed   in Open orders (simulated)'),
        findsOneWidget,
      );
    });

    testWidgets('a size beyond the margin blocks the order', (tester) async {
      await pumpBtc(tester);
      await tester.tap(find.text('Long').last);
      await tester.pumpAndSettle();
      final size = find.descendant(
        of: find.byType(OrderTicket),
        matching: find.byType(TextField),
      );
      await tester.enterText(size.at(0), '5'); // market: no price field
      await tester.pump();
      expect(find.text('Not enough margin'), findsOneWidget);
      final before = OrdersState.open.value.length;
      expect(redFields(OrderTicket), findsNothing);
      await tester.tap(find.text('Not enough margin'));
      await tester.pumpAndSettle();
      expect(OrdersState.open.value.length, before);
      // The size field is outlined until it's edited.
      expect(redFields(OrderTicket), findsOneWidget);
      await tester.enterText(size.at(0), '0.01');
      await tester.pumpAndSettle();
      expect(redFields(OrderTicket), findsNothing);
    });

    testWidgets('Arena Join short and Home Long open the ticket on that side', (
      tester,
    ) async {
      tester.view
        ..physicalSize = const Size(402, 874) * 3
        ..devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const VistaColosseumApp());
      await tester.pumpAndSettle();

      // Home's Long opens the first-time feed ticket.
      await tester.tap(find.widgetWithText(VistaPillButton, 'Long').first);
      await tester.pumpAndSettle();
      expect(find.byType(FeedOrderTicket), findsOneWidget);
      expect(find.text(r'Long $200   2x'), findsOneWidget);
      Navigator.of(tester.element(find.byType(FeedOrderTicket))).pop();
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel('Arena'));
      await tester.pumpAndSettle();
      // Bring the first call's Join clear of the floating composer.
      await tester.scrollUntilVisible(
        find.text('Join short'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.drag(find.byType(ListView).last, const Offset(0, -150));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Join short').first);
      await tester.pumpAndSettle();
      expect(find.text('Place market short'), findsOneWidget);
    });

    testWidgets('leverage is picked on a horizontal slider', (tester) async {
      await pumpBtc(tester);
      await tester.tap(find.text('Long').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cross   10x'));
      await tester.pumpAndSettle();
      expect(find.text('Leverage'), findsOneWidget);
      expect(find.text('Set 10x'), findsOneWidget);
      // Round stops under the track; tapping one jumps there.
      await tester.tap(find.text('20x').last); // the sheet's, over the page
      await tester.pumpAndSettle();
      expect(find.text('Set 20x'), findsOneWidget);
      // Drag the thumb to the far right: the market's cap.
      final slider = find.bySemanticsLabel('Leverage').last;
      await tester.drag(slider, const Offset(600, 0));
      await tester.pumpAndSettle();
      final max = RegExp(r'Set (\d+)x');
      final label = tester
          .widgetList<Text>(find.textContaining(max))
          .first
          .data!;
      final cap = int.parse(max.firstMatch(label)!.group(1)!);
      expect(cap, greaterThan(10));
      // − steps down by one; Set applies it to the ticket.
      await tester.tap(find.bySemanticsLabel('Lower leverage'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Set ${cap - 1}x'));
      await tester.pumpAndSettle();
      expect(find.text('Cross   ${cap - 1}x'), findsOneWidget);
    });

    for (final MapEntry(key: name, value: (size, padding)) in phones.entries) {
      testWidgets('ticket renders without overflow on $name', (tester) async {
        await pumpBtc(tester, size, padding);
        await tester.tap(find.text('Long').last);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Cross   10x'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('share call', () {
    Future<void> openShare(
      WidgetTester tester, [
      Size size = const Size(402, 874),
      EdgeInsets pad = EdgeInsets.zero,
    ]) async {
      tester.view
        ..physicalSize = size * 3
        ..devicePixelRatio = 3
        ..padding = FakeViewPadding(top: pad.top * 3, bottom: pad.bottom * 3);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const VistaColosseumApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Share').first);
      await tester.pumpAndSettle();
    }

    testWidgets('Share opens the sheet with what the recipient will see', (
      tester,
    ) async {
      final copied = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied.add((call.arguments as Map)['text'] as String);
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await openShare(tester);
      expect(find.byType(ShareCallSheet), findsOneWidget);
      expect(find.text("WHAT THEY'LL SEE"), findsOneWidget);
      expect(
        find.text("kaito.eth's ETH long is up 5.97% since the call"),
        findsOneWidget,
      );
      // Four targets, as designed; no options.
      for (final t in ['Messages', 'Telegram', 'X', 'Copy link']) {
        expect(find.text(t), findsOneWidget);
      }
      expect(find.text('WhatsApp'), findsNothing);
      expect(find.text('Include my referral link'), findsNothing);

      await tester.tap(find.text('Copy link'));
      await tester.pumpAndSettle();
      expect(find.byType(ShareCallSheet), findsNothing);
      expect(copied.single, startsWith('https://vistamarkets.xyz/c/'));
      expect(find.text('Link copied'), findsOneWidget);
    });

    for (final MapEntry(key: name, value: (size, padding)) in phones.entries) {
      testWidgets('sheet renders without overflow on $name', (tester) async {
        await openShare(tester, size, padding);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('people in', () {
    Future<void> openPeopleIn(
      WidgetTester tester, [
      Size size = const Size(402, 874),
      EdgeInsets pad = EdgeInsets.zero,
    ]) async {
      tester.view
        ..physicalSize = size * 3
        ..devicePixelRatio = 3
        ..padding = FakeViewPadding(top: pad.top * 3, bottom: pad.bottom * 3);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const VistaColosseumApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('1.2k in').first);
      await tester.pumpAndSettle();
    }

    testWidgets('the rail shows the people-in count and opens who is in', (
      tester,
    ) async {
      await openPeopleIn(tester);
      // No repost: the count replaces it, under like.
      expect(find.bySemanticsLabel(RegExp('Repost|Traders,')), findsNothing);
      expect(find.byType(PeopleInSheet), findsOneWidget);
      expect(find.text("People in kaito.eth's ETH call"), findsOneWidget);
      // No long/short split bar; people rows with their side.
      expect(find.textContaining('% long'), findsNothing);
      expect(
        find.descendant(
          of: find.byType(PeopleInSheet),
          matching: find.byType(VistaSplitBar),
        ),
        findsNothing,
      );
      expect(find.text('LATEST IN'), findsOneWidget);
      expect(find.text('Sizes stay private'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(PeopleInSheet),
          matching: find.byType(VistaPersonRow),
        ),
        findsWidgets,
      );
    });

    testWidgets('Like starts as an outline and turns red when pressed', (
      tester,
    ) async {
      await openPeopleIn(tester);
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      SvgPicture heart() => tester.widget<SvgPicture>(
        find.descendant(
          of: find.bySemanticsLabel(RegExp(r'^Like, 4\.4k')).first,
          matching: find.byType(SvgPicture),
        ),
      );
      String asset() => (heart().bytesLoader as SvgAssetLoader).assetName;
      expect(asset(), VistaAssets.likeOutline);
      await tester.tap(find.bySemanticsLabel(RegExp(r'^Like, ')).first);
      await tester.pumpAndSettle();
      expect(asset(), VistaAssets.like);
      await tester.tap(find.bySemanticsLabel(RegExp(r'^Like, ')).first);
      await tester.pumpAndSettle();
      expect(asset(), VistaAssets.likeOutline);
    });

    for (final MapEntry(key: name, value: (size, padding)) in phones.entries) {
      testWidgets('sheet renders without overflow on $name', (tester) async {
        await openPeopleIn(tester, size, padding);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('feed order ticket', () {
    Future<void> openFeedTicket(
      WidgetTester tester, [
      Size size = const Size(402, 874),
      EdgeInsets pad = EdgeInsets.zero,
    ]) async {
      tester.view
        ..physicalSize = size * 3
        ..devicePixelRatio = 3
        ..padding = FakeViewPadding(top: pad.top * 3, bottom: pad.bottom * 3);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const VistaColosseumApp());
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(VistaPillButton, 'Long').first);
      await tester.pumpAndSettle();
    }

    Finder inTicket(Finder f) =>
        find.descendant(of: find.byType(FeedOrderTicket), matching: f);

    testWidgets(r'opens simple: market, 2x, $200, TP/SL on', (tester) async {
      await openFeedTicket(tester);
      expect(inTicket(find.text('Market')), findsOneWidget);
      expect(inTicket(find.text('Limit')), findsOneWidget);
      expect(inTicket(find.text('Stop')), findsNothing);
      expect(inTicket(find.text('Short')), findsNothing); // the card's side
      for (final l in ['2x', '5x', '10x', 'custom']) {
        expect(inTicket(find.text(l)), findsOneWidget);
      }
      expect(
        inTicket(find.text(r'You pay $200 → $400 position (2x)   0.1348 ETH')),
        findsOneWidget,
      );
      // No worst-case box: the margin and liquidation line covers the risk.
      expect(inTicket(find.text('WORST CASE')), findsNothing);
      // TP/SL opens on, with the track at the design's defaults.
      expect(inTicket(find.text('STOP LOSS')), findsOneWidget);
      expect(inTicket(find.text('ENTRY')), findsOneWidget);
      expect(inTicket(find.text(r'$2,906')), findsOneWidget);
      expect(inTicket(find.text(r'$3,176')), findsOneWidget);
      expect(inTicket(find.text(r'−2.1%   −$8.40')), findsOneWidget);
      expect(inTicket(find.text(r'+7.0%   +$28.00')), findsOneWidget);

      // Dragging the stop's thumb left widens the stop.
      await tester.drag(
        find.bySemanticsLabel('Stop loss').last,
        const Offset(-30, 0),
      );
      await tester.pumpAndSettle();
      expect(inTicket(find.text(r'−2.1%   −$8.40')), findsNothing);

      // 5x updates what it buys and where it liquidates.
      await tester.tap(inTicket(find.text('5x')));
      await tester.pumpAndSettle();
      expect(inTicket(find.text(r'Long $200   5x')), findsOneWidget);
      expect(
        inTicket(
          find.text(r'You pay $200 → $1,000 position (5x)   0.3369 ETH'),
        ),
        findsOneWidget,
      );

      // Unticking hides the track.
      await tester.tap(inTicket(find.text('Take profit / Stop loss')));
      await tester.pumpAndSettle();
      expect(inTicket(find.text('STOP LOSS')), findsNothing);
    });

    testWidgets('custom opens the leverage slider', (tester) async {
      await openFeedTicket(tester);
      await tester.tap(inTicket(find.text('custom')));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Raise leverage'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Set 3x'));
      await tester.pumpAndSettle();
      expect(inTicket(find.text(r'Long $200   3x')), findsOneWidget);
    });

    testWidgets('a limit order lands in Open orders', (tester) async {
      await openFeedTicket(tester);
      await tester.tap(inTicket(find.text('Limit')));
      await tester.pumpAndSettle();
      expect(inTicket(find.text('Limit price')), findsOneWidget);
      final before = OrdersState.open.value.length;
      await tester.tap(inTicket(find.text(r'Long $200   2x')));
      await tester.pump();
      expect(inTicket(find.text('Placed ✓')), findsOneWidget);
      await tester.pump(VistaMotion.confirmHold);
      await tester.pumpAndSettle();
      expect(find.byType(FeedOrderTicket), findsNothing);
      expect(OrdersState.open.value.length, before + 1);
      expect(OrdersState.open.value.first.leverage, 2);
      expect(
        find.text('Limit long placed   in Open orders (simulated)'),
        findsOneWidget,
      );
    });

    testWidgets('the amount slider snaps to its 20% stops', (tester) async {
      await openFeedTicket(tester);
      final slider = find.bySemanticsLabel('Amount').last;
      final box = tester.getRect(slider);
      // A tap just past 40% lands on 40%: $400 of $1,000.
      await tester.tapAt(
        Offset(box.left + 12 + (box.width - 24) * 0.43, box.center.dy),
      );
      await tester.pumpAndSettle();
      expect(inTicket(find.text(r'Long $400   2x')), findsOneWidget);
      // Dragging to the far right snaps to Max.
      await tester.drag(slider, const Offset(600, 0));
      await tester.pumpAndSettle();
      expect(inTicket(find.text(r'Long $1,000   2x')), findsOneWidget);
    });

    testWidgets('an amount over the balance blocks the order', (tester) async {
      await openFeedTicket(tester);
      await tester.enterText(inTicket(find.byType(TextField)).first, '5000');
      await tester.pump();
      expect(inTicket(find.text('Not enough balance')), findsOneWidget);
      // Tapping it shakes instead of placing.
      final before = OrdersState.open.value.length;
      await tester.tap(inTicket(find.text('Not enough balance')));
      await tester.pumpAndSettle();
      expect(find.byType(FeedOrderTicket), findsOneWidget);
      expect(OrdersState.open.value.length, before);
      expect(redFields(FeedOrderTicket), findsOneWidget); // the amount
    });

    for (final MapEntry(key: name, value: (size, padding)) in phones.entries) {
      testWidgets('renders without overflow on $name', (tester) async {
        await openFeedTicket(tester, size, padding); // TP/SL on
        expect(tester.takeException(), isNull);
      });
    }
  });

  testWidgets('trade page Alerts lists the feed alerts on that market', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(402, 874) * 3
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: VistaTheme.dark(),
        home: const AssetTradeScreen(ticker: 'ETH'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(VistaUnderlineTabs),
        matching: find.text('Alerts'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Alerts on ETH'), findsOneWidget);
    // The ETH card's events, fills and call, newest first.
    for (final t in [
      '3 people joined',
      r'0xreal shorted $1.2k',
      r'Broke $2,950',
      r'Whale long $4.2M',
      'Funding flipped +',
      r'kaito.eth called long at $2,801.10',
    ]) {
      expect(find.text(t), findsOneWidget, reason: t);
    }
    final joined = tester.getTopLeft(find.text('3 people joined')).dy;
    final call = tester.getTopLeft(
      find.text(r'kaito.eth called long at $2,801.10'),
    );
    expect(joined, lessThan(call.dy));
    expect(tester.takeException(), isNull);
  });

  testWidgets('numbers use the fixed-width digit face', (tester) async {
    // Every digit is as wide as every other, so a ticking price keeps its
    // width: $1,111.11 sets as wide as $8,888.88.
    double widthOf(String text) {
      final p = TextPainter(
        text: TextSpan(text: text, style: VistaType.display),
        textDirection: TextDirection.ltr,
      )..layout();
      return p.width;
    }

    expect(VistaType.display.fontFamily, VistaType.numberFamily);
    expect(widthOf(r'$1,111.11'), closeTo(widthOf(r'$8,888.88'), 0.01));
    expect(widthOf(r'$2,968.40'), closeTo(widthOf(r'$2,971.15'), 0.01));
  });

  testWidgets('a profile pins its market price once it scrolls away', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(402, 874) * 3
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: VistaTheme.dark(),
        home: const ProfileScreen(handle: 'maya.eth'),
      ),
    );
    await tester.pumpAndSettle();
    double opacityOf() =>
        tester.widget<AnimatedOpacity>(find.byKey(pinnedPriceKey)).opacity;
    expect(opacityOf(), 0);
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(opacityOf(), 1);
    // Back to the top, it tucks away again.
    await tester.drag(find.byType(ListView), const Offset(0, 800));
    await tester.pumpAndSettle();
    expect(opacityOf(), 0);
  });

  testWidgets('the trade page puts the 24h change on a line under the price', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(402, 874) * 3
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: VistaTheme.dark(),
        home: const AssetTradeScreen(ticker: 'ETH'),
      ),
    );
    await tester.pumpAndSettle();
    // ETH is down 0.40% on the day: $11.92 below its 24h open.
    expect(
      find.bySemanticsLabel(r'Down $11.92, 0.40%, Past 24 hours'),
      findsOneWidget,
    );
    final price = tester.getBottomLeft(find.byType(LiveUsd).first);
    final change = tester.getTopLeft(find.byType(VistaChangeLine));
    expect(change.dy, greaterThan(price.dy)); // under, not beside
    expect(tester.takeException(), isNull);
  });

  testWidgets('each backed call in a debate opens its play', (tester) async {
    tester.view
      ..physicalSize = const Size(402, 874) * 3
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: VistaTheme.dark(),
        home: BattleScreen(battle: BattlesStore.all.value.first),
      ),
    );
    await tester.pumpAndSettle();
    // @renatafx: in Most right and on their call.
    expect(find.text('LONG 10x'), findsWidgets);
    await tester.tap(find.byType(BackedPositionCard).first);
    await tester.pumpAndSettle();
    expect(find.byType(CallerPlayScreen), findsOneWidget);
  });

  test('a new caller\'s backed call is boosted and seen early', () {
    expect(HomeFeed.isNewCaller('vega'), isTrue);
    expect(HomeFeed.isNewCaller('maya.eth'), isFalse);
    final ranked = HomeFeed.forYou(CallsStore.all.value);
    final i = ranked.indexWhere((t) => t.handle == 'vega' && t.backed);
    expect(i, lessThanOrEqualTo(HomeFeed.newCallerSlot));
  });

  testWidgets('Settings › Edit: change name and bio; your profile shows them', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(402, 874) * 3
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const VistaColosseumApp());
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Wallet'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Settings').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit').first);
    await tester.pumpAndSettle();
    expect(find.byType(EditProfileScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
    // Nothing changed yet: Save waits.
    await tester.tap(find.bySemanticsLabel('Save'));
    await tester.pumpAndSettle();
    expect(find.byType(EditProfileScreen), findsOneWidget);
    // Bios stop at 60 characters.
    await tester.enterText(find.byType(TextField).last, 'x' * 80);
    await tester.pump();
    expect(find.text('60/60'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'Maya');
    await tester.enterText(
      find.byType(TextField).last,
      'Swing trades, receipts.',
    );
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('Save'));
    await tester.pumpAndSettle();
    expect(find.byType(EditProfileScreen), findsNothing);
    expect(find.text('Profile updated'), findsOneWidget);
    expect(find.text('Swing trades, receipts.'), findsOneWidget); // settings
    // Your profile shows the name over the handle, and the bio.
    await tester.pumpWidget(
      MaterialApp(
        theme: VistaTheme.dark(),
        home: const ProfileScreen(handle: 'maya.eth'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Maya'), findsOneWidget);
    expect(find.text('Swing trades, receipts.'), findsOneWidget);
  });

  testWidgets('the bell: a dot while new, filters, a note opens, read after', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(402, 874) * 3
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const VistaColosseumApp());
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Notifications, 4 new'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Notifications, 4 new'));
    await tester.pumpAndSettle();
    expect(find.byType(NotificationsScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(find.text('TODAY'), findsOneWidget);
    expect(Notifications.unread.value, 0);
    // People: follows, with Follow back.
    await tester.tap(find.widgetWithText(VistaFilterChip, 'People'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('started following you', findRichText: true),
      findsWidgets,
    );
    expect(find.byType(VistaFollowButton), findsOneWidget);
    await tester.tap(find.byType(VistaFollowButton));
    await tester.pumpAndSettle();
    expect(FollowState.isFollowing('sam.sol'), isTrue);
    // Markets: your market's move opens it.
    await tester.tap(find.widgetWithText(VistaFilterChip, 'Markets'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.textContaining('MAYA ▲4.3% today', findRichText: true),
    );
    await tester.pumpAndSettle();
    expect(find.byType(TraderMarketScreen), findsOneWidget);
    // Back on Home: no dot.
    await tester.tap(find.bySemanticsLabel('Back').last);
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Back').last);
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Notifications'), findsOneWidget);
  });

  testWidgets(
    'a call from someone you follow shows in Notifications as a call card',
    (tester) async {
      tester.view
        ..physicalSize = const Size(402, 874) * 3
        ..devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: VistaTheme.dark(),
          home: const NotificationsScreen(),
        ),
      );
      await tester.pumpAndSettle();
      HubCallCard? voskov() => tester
          .widgetList<HubCallCard>(
            find.byType(HubCallCard, skipOffstage: false),
          )
          .where((c) => c.take.handle == 'voskov')
          .firstOrNull;
      // Not following voskov: no card for their call.
      expect(FollowState.isFollowing('voskov'), isFalse);
      expect(voskov(), isNull);
      FollowState.toggle('voskov');
      await tester.pumpAndSettle();
      // Following: voskov's call shows, as a call card.
      await tester.scrollUntilVisible(
        find.byWidgetPredicate(
          (w) => w is HubCallCard && w.take.handle == 'voskov',
        ),
        300,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      expect(voskov(), isNotNull);
      expect(voskov()!.take.ticker, 'BTC');
      // Join right from it.
      final card = find.byWidgetPredicate(
        (w) => w is HubCallCard && w.take.handle == 'voskov',
      );
      await tester.ensureVisible(card);
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(of: card, matching: find.byType(VistaJoinPill)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Place market short'), findsOneWidget);
    },
  );
}
