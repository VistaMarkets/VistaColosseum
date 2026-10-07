import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vista_colosseum/features/markets/market_chart_card.dart';
import 'package:vista_colosseum/charting/charting.dart';
import 'package:vista_colosseum/design_system/design_system.dart';
import 'package:vista_colosseum/features/account/account_state.dart';
import 'package:vista_colosseum/features/account/account_top_bar.dart';
import 'package:vista_colosseum/features/home/home_screen.dart';
import 'package:vista_colosseum/features/home/mock_trade_idea.dart';
import 'package:vista_colosseum/features/portfolio/portfolio_pager.dart';
import 'package:vista_colosseum/features/portfolio/portfolio_screen.dart';
import 'package:vista_colosseum/features/arena/opinions_screen.dart';
import 'package:vista_colosseum/features/arena/take_card.dart';
import 'package:vista_colosseum/features/arena/arena_mock.dart';
import 'package:vista_colosseum/features/arena/live_battles_screen.dart';
import 'package:vista_colosseum/features/arena/pick_position_screen.dart';
import 'package:vista_colosseum/features/arena/compose_take_screen.dart';
import 'package:vista_colosseum/features/arena/battle_builder.dart';
import 'package:vista_colosseum/features/calls/calls_store.dart';
import 'package:vista_colosseum/features/home/home_feed.dart';
import 'package:vista_colosseum/features/trade/caller_thread.dart';
import 'package:vista_colosseum/features/live/live_feed.dart';
import 'package:vista_colosseum/features/portfolio/series_chart.dart';
import 'package:vista_colosseum/features/profile/profile_screen.dart';
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

      // Filters: Arena shows only arena receipts.
      final arenaChip = find.text('Debates 14');
      await tester.scrollUntilVisible(
        arenaChip,
        200,
        scrollable: profileList(),
      );
      await tester.pumpAndSettle();
      await tester.tap(arenaChip);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text(r'SOL loses $190 by Sep 15'),
        200,
        scrollable: profileList(),
      );
      expect(find.text(r'BTC reclaims $66,000 by Tue'), findsNothing);
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
        final last = find.text(r'SOL loses $190 by Sep 15');
        await tester.scrollUntilVisible(last, 200, scrollable: profileList());
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(last.hitTestable(), findsOneWidget);
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
      // Home caller → profile → market.
      await tester.tap(find.text('kaito.eth'));
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

      for (final next in ['Shared live by kaito.eth', 'Record']) {
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

    testWidgets('Explore shows markets; sort, search and favourites work', (
      tester,
    ) async {
      await openMarkets(tester, tall);
      expect(find.text('ALL MARKETS'), findsOneWidget);
      expect(rowNames(tester), ['BTC', 'ETH', 'SOL', 'ARB', 'AVAX']);

      await tester.tap(find.text('Change'));
      await tester.pumpAndSettle();
      expect(rowNames(tester).first, 'SOL'); // ▲ 3.8% is the biggest move

      await tester.enterText(find.byType(TextField), 'av');
      await tester.pumpAndSettle();
      expect(rowNames(tester), ['AVAX']);
      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();

      // Starring ARB adds it to the favourites rail.
      expect(find.byType(VistaMarketCard), findsNWidgets(3));
      final arb = find.ancestor(
        of: find.text('ARB'),
        matching: find.byType(AssetMarketCard),
      );
      await tester.tap(
        find.descendant(of: arb, matching: find.byType(VistaStarButton)),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widgetList(find.byType(VistaMarketCard)).length,
        greaterThanOrEqualTo(3),
      );
      expect(tester.widget<AssetMarketCard>(arb).starred, isTrue);
    });

    testWidgets('Traders tab lists trader markets and opens one', (
      tester,
    ) async {
      await openMarkets(tester);
      await tester.tap(find.text('Traders'));
      await tester.pumpAndSettle();
      expect(find.text('ALL TRADER MARKETS'), findsOneWidget);
      // Each trader market is a chart card; the Favorites rail is unchanged.
      expect(find.byType(VistaMarketRow), findsNothing);
      expect(find.byType(VistaMarketCard), findsNWidgets(3));
      final maya = find.byType(TraderMarketCard).first;
      expect(tester.widget<TraderMarketCard>(maya).name, 'maya.eth');
      expect(
        find.descendant(of: maya, matching: find.byType(SeriesChart)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: maya, matching: find.text('MAYA')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: maya,
          matching: find.textContaining('3 open calls', findRichText: true),
        ),
        findsOneWidget,
      );

      final xreal = find.ancestor(
        of: find.text('0xreal'),
        matching: find.byType(TraderMarketCard),
      );
      await tester.ensureVisible(xreal);
      await tester.pumpAndSettle();
      await tester.tap(xreal);
      await tester.pumpAndSettle();
      expect(find.byType(VistaIntervalSelector), findsOneWidget);
    });

    Future<void> railShows(WidgetTester tester, String name) =>
        tester.scrollUntilVisible(
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
      final btc = find.ancestor(
        of: find.text('BTC').last,
        matching: find.byType(AssetMarketCard),
      );
      await tester.tap(
        find.descendant(of: btc, matching: find.byType(VistaStarButton)),
      );
      await tester.pumpAndSettle();
      expect(railNames(tester).first, 'ETH');
      expect(WatchlistState.assets.value, ['ETH', 'SOL', 'ARB']);
      expect(WatchlistState.isAsset('BTC'), isFalse);
    });

    testWidgets('trader page star updates the Traders favourites', (
      tester,
    ) async {
      await openMarkets(tester);
      await tester.tap(find.text('Traders'));
      await tester.pumpAndSettle();
      expect(railNames(tester), ['maya.eth', 'lunaq', 'deltaone']);
      final xreal = find.ancestor(
        of: find.text('0xreal'),
        matching: find.byType(TraderMarketCard),
      );
      await tester.ensureVisible(xreal);
      await tester.pumpAndSettle();
      await tester.tap(xreal);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(VistaWatchButton));
      await tester.pump();
      expect(WatchlistState.isTrader('0xreal'), isTrue);
      await tester.tap(find.bySemanticsLabel('Back').last);
      await tester.pumpAndSettle();
      expect(WatchlistState.traders.value.last, '0xreal');
      // Back to the top, where the rail is.
      await tester.drag(find.byType(ListView).first, const Offset(0, 2000));
      await tester.pumpAndSettle();
      await railShows(tester, '0xreal');
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
        await tester.tap(find.text('Traders'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
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
    }

    // The feed's vertical list (the carousel and chips scroll sideways).
    final feed = find.byWidgetPredicate(
      (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
    );
    Future<void> scrollTo(WidgetTester tester, Finder f) async {
      await tester.scrollUntilVisible(f, 200, scrollable: feed);
      await tester.pumpAndSettle();
    }

    testWidgets('Arena tab is a feed: live battles, then takes', (
      tester,
    ) async {
      await openArena(tester);
      expect(find.text('Live debates'), findsOneWidget);
      expect(find.byType(BattleTile), findsWidgets);
      expect(find.text('Calls'), findsOneWidget);
      expect(find.byType(TakeItem), findsWidgets);
      expect(find.byType(VistaBattleCard), findsNothing);
      // The account bar on top (with settings), the composer at the bottom.
      expect(find.bySemanticsLabel('Settings'), findsOneWidget);
      expect(find.bySemanticsLabel('Make a call'), findsOneWidget);
    });

    testWidgets('sort chips stay fixed while the feed scrolls', (tester) async {
      await openArena(tester);
      final before = tester.getTopLeft(find.text('Volume'));
      final take = tester.getTopLeft(find.byType(TakeItem).first);
      await tester.drag(find.byType(ListView).last, const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.text('Volume')), before);
      // Left-aligned with the page gutter, not centred.
      expect(
        tester.getTopLeft(find.byType(VistaFilterChip).first).dx,
        closeTo(VistaSpace.gutter, 1),
      );
      expect(
        tester.getTopLeft(find.byType(TakeItem).first).dy,
        lessThan(take.dy),
      );
    });

    testWidgets('takes on a battle link it; plain calls show no chip', (
      tester,
    ) async {
      await openArena(tester);
      // kilo.sol's is a plain call: nothing between the header and the text.
      await scrollTo(tester, find.text('kilo.sol'));
      final call = find.ancestor(
        of: find.text('kilo.sol'),
        matching: find.byType(TakeItem),
      );
      expect(
        find.descendant(of: call, matching: find.textContaining(' · ')),
        findsOneWidget, // the position's levels (the age is "· 25m")
      );
      expect(find.descendant(of: call, matching: find.text('›')), findsNothing);
      expect(
        find.descendant(of: call, matching: find.text('SHORT SOL')),
        findsOneWidget,
      );
      // renatafx's take is on the BTC battle and backed; every take names
      // its asset next to the side.
      await scrollTo(tester, find.text('renatafx'));
      expect(find.text(r'Reclaims $72,000 by Fri'), findsWidgets);
      expect(find.text('LONG BTC'), findsWidgets);
      expect(find.text('SHORT BTC'), findsWidgets);
      expect(find.text('✓ Backed'), findsNothing);
      expect(find.byType(BackedPositionCard), findsWidgets);
      // The battle chip opens the battle.
      await tester.tap(find.text(r'Reclaims $72,000 by Fri').first);
      await tester.pumpAndSettle();
      expect(find.byType(OpinionsScreen), findsOneWidget);
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
      await scrollTo(tester, find.text('voskov'));
      final card = find.ancestor(
        of: find.text('voskov'),
        matching: find.byType(TakeItem),
      );
      // Followed callers (kilo.sol) get no button.
      expect(find.bySemanticsLabel('Follow kilo.sol'), findsNothing);
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
      await tester.tap(find.text('voskov').first);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<VistaFollowButton>(find.byType(VistaFollowButton).first)
            .following,
        isTrue,
      );
    });

    testWidgets('call headers show the caller\'s market, not accuracy', (
      tester,
    ) async {
      await openArena(tester);
      await scrollTo(tester, find.text('kilo.sol'));
      final call = find.ancestor(
        of: find.text('kilo.sol'),
        matching: find.byType(TakeItem),
      );
      // kilo.sol has a market: its live price and day change.
      expect(
        find.descendant(of: call, matching: find.textContaining(r'$0.172')),
        findsOneWidget,
      );
      expect(find.textContaining('% right'), findsNothing);
      // Tapping it opens their market.
      await tester.tap(
        find.descendant(of: call, matching: find.textContaining(r'$0.172')),
      );
      await tester.pumpAndSettle();
      expect(find.byType(TraderMarketScreen), findsOneWidget);
    });

    testWidgets('See all opens Live battles; sorts; a row opens it', (
      tester,
    ) async {
      await openArena(tester);
      expect(find.byType(BattleTile), findsNWidgets(3)); // carousel: top 3
      await tester.tap(find.text('See all'));
      await tester.pumpAndSettle();
      expect(find.byType(LiveBattlesScreen), findsOneWidget);
      expect(find.text('6 live'), findsOneWidget);
      String firstQuestion() => tester
          .widgetList<BattleTile>(find.byType(BattleTile))
          .first
          .battle
          .question;
      expect(firstQuestion(), r"Reclaims $72,000 before Friday's expiry");
      await tester.tap(find.text('Closing soon'));
      await tester.pumpAndSettle();
      expect(firstQuestion(), r'Breaks $1.20 this week'); // 45m left
      await tester.tap(find.text('Closest split'));
      await tester.pumpAndSettle();
      expect(firstQuestion(), r'Breaks $1.20 this week'); // 48 / 52
      await tester.tap(find.byType(BattleTile).first);
      await tester.pumpAndSettle();
      expect(find.byType(OpinionsScreen), findsOneWidget);
    });

    for (final MapEntry(key: name, value: (size, padding)) in phones.entries) {
      testWidgets('Live battles renders without overflow on $name', (
        tester,
      ) async {
        await openArena(tester, size, padding);
        await tester.tap(find.text('See all'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('+ → pick a position → write → post: it tops the feed', (
      tester,
    ) async {
      await openArena(tester);
      await tester.tap(find.bySemanticsLabel('Make a call'));
      await tester.pumpAndSettle();
      expect(find.byType(PickPositionScreen), findsOneWidget);
      expect(find.text('What are you calling?'), findsOneWidget);
      expect(find.text('YOUR POSITIONS · 3'), findsOneWidget);
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
      final first = find.byType(TakeItem).first;
      await tester.ensureVisible(first);
      expect(
        find.descendant(of: first, matching: find.text('ETH/BTC bottomed.')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: first, matching: find.text('maya.eth')),
        findsOneWidget,
      );
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
      ]);
    });

    testWidgets('Make it a battle opens a page set to the position\'s side', (
      tester,
    ) async {
      await openArena(tester);
      await tester.tap(find.bySemanticsLabel('Make a call'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ethereum')); // LONG 5x
      await tester.pumpAndSettle();
      // A call by default.
      expect(find.text('Post'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Magnet at 3.2k.');
      await tester.tap(find.bySemanticsLabel('Make it a debate'));
      await tester.pumpAndSettle();

      // Its own page; a long gets the upside statements, the first picked.
      expect(find.byType(BattleSetupScreen), findsOneWidget);
      expect(find.text('Closes above'), findsOneWidget);
      expect(find.text('Stays above'), findsOneWidget);
      expect(find.text('Ends higher'), findsOneWidget);
      expect(find.text('Closes below'), findsNothing);
      expect(find.textContaining('LONG ETH'), findsWidgets);
      // The sentence: ETH [closes above] [$…] by [Fri 16:00].
      expect(find.text('closes above'), findsOneWidget);
      expect(find.text(r'$…'), findsOneWidget);
      expect(find.text('Fri 16:00'), findsOneWidget);
      // The level is typed (grouped as you type); Add waits for it.
      await tester.tap(find.text('Add debate'));
      await tester.pumpAndSettle();
      expect(find.byType(BattleSetupScreen), findsOneWidget);
      await tester.enterText(find.byType(TextField), '3200');
      await tester.pump();
      expect(find.text('3,200'), findsOneWidget);
      expect(find.text(r'$3,200'), findsOneWidget);
      // A shortcut fills it; then back to a typed level.
      await tester.tap(find.text('+10%'));
      await tester.pump();
      expect(find.text('3,265'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '3200');
      await tester.pump();
      // Tapping the deadline part moves to the next deadline.
      await tester.tap(find.text('Fri 16:00'));
      await tester.pump();
      expect(find.text('next Fri'), findsOneWidget);
      await tester.tap(find.text('Fri'));
      await tester.pump();
      await tester.tap(find.text('Touches'));
      await tester.pump();
      expect(find.text('touches'), findsOneWidget);
      expect(find.text('before'), findsOneWidget);
      await tester.ensureVisible(find.text('Add debate'));
      await tester.tap(find.text('Add debate'));
      await tester.pumpAndSettle();
      // ETH already has a live battle: it's offered first.
      expect(find.text('ETH debates already live'), findsOneWidget);
      await tester.tap(find.text('Start my debate anyway'));
      await tester.pumpAndSettle();

      // Back in the composer: a summary, and Post becomes Start battle.
      expect(find.byType(BattleSetupScreen), findsNothing);
      expect(find.byType(BattleSummaryCard), findsOneWidget);
      expect(find.text('Start debate'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.bySemanticsLabel('Start debate'));
      await tester.pumpAndSettle();
      expect(
        BattlesStore.all.value.first.question,
        r'ETH touches $3,200 before Friday',
      );
      expect(
        CallsStore.all.value.first.battle,
        r'ETH touches $3,200 before Friday',
      );
      expect(
        tester
            .widgetList<BattleTile>(find.byType(BattleTile))
            .first
            .battle
            .question,
        r'ETH touches $3,200 before Friday',
      );
    });

    testWidgets('a live battle on the market can take the call instead', (
      tester,
    ) async {
      await openArena(tester);
      await tester.tap(find.bySemanticsLabel('Make a call'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ethereum')); // LONG
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Joining the longs.');
      await tester.tap(find.bySemanticsLabel('Make it a debate'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '3200');
      await tester.pump();
      await tester.tap(find.text('Add debate'));
      await tester.pumpAndSettle();
      final live = BattlesStore.all.value.firstWhere((b) => b.ticker == 'ETH');
      await tester.tap(find.text(live.question).last);
      await tester.pumpAndSettle();
      // Joining keeps Post; nothing new starts.
      expect(find.text('LIVE DEBATE'), findsOneWidget);
      expect(find.text('Post'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 300));
      final count = BattlesStore.all.value.length;
      await tester.tap(find.bySemanticsLabel('Post'));
      await tester.pumpAndSettle();
      expect(BattlesStore.all.value, hasLength(count));
      final after = BattlesStore.all.value.firstWhere(
        (b) => b.question == live.question,
      );
      expect(after.takes, live.takes + 1);
      expect(after.longShare, greaterThan(live.longShare));
      expect(CallsStore.all.value.first.battle, live.question);
    });

    testWidgets('a short gets the downside statements; Remove undoes it', (
      tester,
    ) async {
      await openArena(tester);
      await tester.tap(find.bySemanticsLabel('Make a call'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Solana')); // SHORT 10x
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Make it a debate'));
      await tester.pumpAndSettle();
      expect(find.text('Closes below'), findsOneWidget);
      expect(find.text('Stays below'), findsOneWidget);
      expect(find.text('Ends lower'), findsOneWidget);
      expect(find.text('Closes above'), findsNothing);
      expect(find.textContaining('SHORT SOL'), findsWidgets);
      // The options sit on one line.
      expect(
        tester.getTopLeft(find.text('Stays below')).dy,
        tester.getTopLeft(find.text('Closes below')).dy,
      );
      // No "close battle is live" card.
      expect(find.text('A close battle is live'), findsNothing);
      // The statement in the sentence isn't a button.
      await tester.tap(find.text('closes below'));
      await tester.pump();
      expect(find.text('closes below'), findsOneWidget);
      // One sideways-scrolling line: the last option starts off-screen.
      await tester.ensureVisible(find.text('Ends lower'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ends lower')); // no level needed
      await tester.pump();
      await tester.tap(find.text('Add debate'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start my debate anyway'));
      await tester.pumpAndSettle();
      expect(find.text('SOL ends lower than now by Friday'), findsOneWidget);
      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();
      expect(find.byType(BattleSummaryCard), findsNothing);
      expect(find.text('Post'), findsOneWidget);
    });

    for (final MapEntry(key: name, value: (size, padding)) in phones.entries) {
      testWidgets('battle page renders without overflow on $name', (
        tester,
      ) async {
        await openArena(tester, size, padding);
        await tester.tap(find.bySemanticsLabel('Make a call'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('0xreal'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.bySemanticsLabel('Make it a debate'));
        await tester.tap(find.bySemanticsLabel('Make it a debate'));
        await tester.pumpAndSettle();
        expect(find.byType(BattleSetupScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

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
      await scrollTo(tester, find.text('voskov'));
      await tester.tap(find.text('voskov').first);
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

  group('opinions', () {
    Future<void> openOpinions(
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
      await tester.tap(find.byType(BattleTile).first);
      await tester.pumpAndSettle();
    }

    List<String> handles(WidgetTester tester) => tester
        .widgetList<VistaSideDetail>(find.byType(VistaSideDetail))
        .map((d) => d.handle)
        .toList();

    testWidgets('a battle tile opens the clash detail; filters and back', (
      tester,
    ) async {
      await openOpinions(tester);
      expect(find.text('23 opinions'), findsOneWidget);
      expect(find.text('Join longs'), findsOneWidget);
      expect(handles(tester).first, '@renatafx');

      await tester.tap(find.text('Bull thesis'));
      await tester.pumpAndSettle();
      expect(handles(tester), ['@renatafx']);

      await tester.tap(find.text('Bear thesis'));
      await tester.pumpAndSettle();
      expect(handles(tester), isNot(contains('@renatafx')));
      expect(handles(tester).first, '@voskov');

      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pumpAndSettle();
      expect(find.byType(BattleTile), findsWidgets);
    });

    for (final MapEntry(key: name, value: (size, padding)) in phones.entries) {
      testWidgets('renders without overflow on $name', (tester) async {
        await openOpinions(tester, size, padding);
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

      // The settings gear on every tab's bar, right of Deposit.
      final settings = find.descendant(
        of: bar,
        matching: find.byType(VistaIconButton),
      );
      final deposit = tester.getRect(inBar('Deposit'));
      expect(settings, findsOneWidget);
      expect(tester.getRect(settings).left, greaterThan(deposit.left));
      await tester.tap(settings);
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);
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
      // Both pages (balance and market cap) cover the chosen span.
      expect(find.text('Last 24 hours'), findsNWidgets(2));
      final day = tester.widget<SeriesChart>(find.byType(SeriesChart)).focus;
      await tester.tap(find.text('1W'));
      await tester.pumpAndSettle();
      expect(find.text(r'+$412 (3.41%)'), findsOneWidget);
      expect(find.text('Past week'), findsNWidgets(2));
      final week = tester.widget<SeriesChart>(find.byType(SeriesChart)).focus;
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
      final chart = tester.widget<SeriesChart>(find.byType(SeriesChart));
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
        scrollable: find.byType(Scrollable).last,
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
      final tab = find.text('Open orders');
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
      expect(find.text('Open orders · 3'), findsOneWidget);
      Finder rich(String text) => find.textContaining(text, findRichText: true);
      expect(rich(r'Fills at $2,850.00 · 4.0% below mark'), findsOneWidget);
      expect(find.text(r'Size $2,138 · 0.75 ETH'), findsOneWidget);
      expect(find.text(r'TP $3,060.00'), findsOneWidget);
      // Only what the order needs: no venue, age or source call.
      expect(find.textContaining('Jupiter'), findsNothing);
      expect(find.textContaining("'s call"), findsNothing);

      await reveal(tester, find.text('1.2 / 4.5 SOL filled'));
      expect(rich(r'Fills at $222.50 · 3.5% above mark'), findsOneWidget);
      await reveal(tester, find.text('Reduce only'));

      await tester.tap(find.bySemanticsLabel('Cancel SOL order'));
      await tester.pumpAndSettle();
      expect(find.text('Open orders · 2'), findsOneWidget);
      expect(find.text('1.2 / 4.5 SOL filled'), findsNothing);
      expect(
        find.text('SOL limit order cancelled (simulated)'),
        findsOneWidget,
      );

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(find.text('Open orders · 3'), findsOneWidget);
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
      final markets = [
        for (final m in [...MarketsMock.assets, ...MarketsMock.traders]) m.id,
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

    testWidgets('Home + makes a call and shows it first', (tester) async {
      tester.view
        ..physicalSize = const Size(402, 874) * 3
        ..devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const VistaColosseumApp());
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Make a call'));
      await tester.pumpAndSettle();
      expect(find.byType(PickPositionScreen), findsOneWidget);
      await tester.tap(find.text('Solana'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Fading the unlock.');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.bySemanticsLabel('Post'));
      await tester.pumpAndSettle();
      // Back on Home, with the new call first.
      expect(find.byType(PickPositionScreen), findsNothing);
      final first = tester.widget<TradeIdeaCard>(
        find.byType(TradeIdeaCard).first,
      );
      expect(first.idea.callerHandle, 'maya.eth');
      expect(first.idea.ticker, 'SOL');
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
          home: const ProfileScreen(handle: 'kaito.eth'),
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
      expect(find.text("kaito.eth's record"), findsOneWidget);
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
      await tester.tap(find.text(r'Long $200 · 2x'));
      await tester.pump(VistaMotion.confirmHold);
      await tester.pumpAndSettle();
      expect(find.textContaining('in Positions'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Wallet'));
      await tester.pumpAndSettle();
      expect(PositionsState.open.value, hasLength(4));
      // The new one first: the card's market, long at 2x.
      final first = PositionsState.open.value.first;
      expect(first.tag, 'LONG 2x');
      expect(first.detail.opened, 'just now');
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
      expect(find.text('Cross · 10x'), findsOneWidget);
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
        find.text('Limit long placed · in Open orders (simulated)'),
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
      expect(find.text(r'Long $200 · 2x'), findsOneWidget);
      Navigator.of(tester.element(find.byType(FeedOrderTicket))).pop();
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel('Arena'));
      await tester.pumpAndSettle();
      // Bring voskov's take clear of the floating composer first.
      await tester.drag(find.byType(ListView).last, const Offset(0, -400));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Join short').first);
      await tester.pumpAndSettle();
      expect(find.text('Place market short'), findsOneWidget);
    });

    testWidgets('leverage is picked on a horizontal slider', (tester) async {
      await pumpBtc(tester);
      await tester.tap(find.text('Long').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cross · 10x'));
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
      expect(find.text('Cross · ${cap - 1}x'), findsOneWidget);
    });

    for (final MapEntry(key: name, value: (size, padding)) in phones.entries) {
      testWidgets('ticket renders without overflow on $name', (tester) async {
        await pumpBtc(tester, size, padding);
        await tester.tap(find.text('Long').last);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Cross · 10x'));
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
        inTicket(find.text(r'You pay $200 → $400 position (2x) · 0.1348 ETH')),
        findsOneWidget,
      );
      // The worst case, in words: liquidation, what's lost, and the stop.
      expect(
        inTicket(
          find.textContaining(
            r'If ETH falls to $1,499, the position is closed and you lose '
            r'the $200 you put in.',
            findRichText: true,
          ),
        ),
        findsOneWidget,
      );
      expect(
        inTicket(find.textContaining(r'Your stop-loss at $2,906')),
        findsOneWidget,
      );
      // TP/SL opens on, with the track at the design's defaults.
      expect(inTicket(find.text('STOP LOSS')), findsOneWidget);
      expect(inTicket(find.text('ENTRY')), findsOneWidget);
      expect(inTicket(find.text(r'$2,906')), findsOneWidget);
      expect(inTicket(find.text(r'$3,176')), findsOneWidget);
      expect(inTicket(find.text(r'−2.1% · −$8.40')), findsOneWidget);
      expect(inTicket(find.text(r'+7.0% · +$28.00')), findsOneWidget);

      // Dragging the stop's thumb left widens the stop.
      await tester.drag(
        find.bySemanticsLabel('Stop loss').last,
        const Offset(-30, 0),
      );
      await tester.pumpAndSettle();
      expect(inTicket(find.text(r'−2.1% · −$8.40')), findsNothing);

      // 5x updates what it buys and where it liquidates.
      await tester.tap(inTicket(find.text('5x')));
      await tester.pumpAndSettle();
      expect(inTicket(find.text(r'Long $200 · 5x')), findsOneWidget);
      expect(
        inTicket(
          find.text(r'You pay $200 → $1,000 position (5x) · 0.3369 ETH'),
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
      expect(inTicket(find.text(r'Long $200 · 3x')), findsOneWidget);
    });

    testWidgets('a limit order lands in Open orders', (tester) async {
      await openFeedTicket(tester);
      await tester.tap(inTicket(find.text('Limit')));
      await tester.pumpAndSettle();
      expect(inTicket(find.text('Limit price')), findsOneWidget);
      final before = OrdersState.open.value.length;
      await tester.tap(inTicket(find.text(r'Long $200 · 2x')));
      await tester.pump();
      expect(inTicket(find.text('Placed ✓')), findsOneWidget);
      await tester.pump(VistaMotion.confirmHold);
      await tester.pumpAndSettle();
      expect(find.byType(FeedOrderTicket), findsNothing);
      expect(OrdersState.open.value.length, before + 1);
      expect(OrdersState.open.value.first.leverage, 2);
      expect(
        find.text('Limit long placed · in Open orders (simulated)'),
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
      expect(inTicket(find.text(r'Long $400 · 2x')), findsOneWidget);
      // Dragging to the far right snaps to Max.
      await tester.drag(slider, const Offset(600, 0));
      await tester.pumpAndSettle();
      expect(inTicket(find.text(r'Long $1,000 · 2x')), findsOneWidget);
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
        home: const ProfileScreen(handle: 'kaito.eth'),
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

  testWidgets('each Arena opinion carries its call, like a trade page caller', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(402, 874) * 3
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(theme: VistaTheme.dark(), home: const OpinionsScreen()),
    );
    await tester.pumpAndSettle();
    expect(find.byType(CallOrderCard), findsWidgets);
    expect(find.text('LONG 10x'), findsOneWidget); // @renatafx's call
    await tester.tap(find.byType(CallOrderCard).first);
    await tester.pumpAndSettle();
    expect(find.byType(CallerPlayScreen), findsOneWidget);
  });
}
