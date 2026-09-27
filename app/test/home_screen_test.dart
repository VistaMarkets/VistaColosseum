import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vista_colosseum/design_system/design_system.dart';
import 'package:vista_colosseum/main.dart';

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
  final loader = FontLoader('OpenRunde');
  for (final w in ['Regular', 'Medium', 'Semibold', 'Bold']) {
    final bytes = File('assets/fonts/OpenRunde-$w.otf').readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
}

void main() {
  setUpAll(_loadFonts);

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
      expect(find.text(r'$12,480'), findsOneWidget);
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
      // Swipe has settled; the new card has only just started tracing.
      expect(breakoutLabel.hitTestable(), findsNothing);

      await tester.pumpAndSettle();
      expect(breakoutLabel.hitTestable(), findsOneWidget);
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
      final chart =
          tester.getCenter(find.text(portfolio)) + const Offset(0, 150);
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
      final chart =
          tester.getCenter(find.text(portfolio)) + const Offset(0, 150);
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
      expect(find.text(r'$12,480'), findsOneWidget);
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
      expect(find.text(r'$12,480'), findsOneWidget);
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
      expect(find.text('Follow'), findsOneWidget);

      // Filters: Arena shows only arena receipts.
      final arenaChip = find.text('Arena 14');
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

    testWidgets('private accounts do not open a profile', (tester) async {
      await setView(tester);
      await openFromFollowers(tester, 'nara');
      expect(find.text('HOLDING NOW'), findsNothing);
      expect(
        find.text('Private profile — not in the demo yet'),
        findsOneWidget,
      );
    });

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

    testWidgets('opens on the Market panel, then Portfolio, Record, Holders', (
      tester,
    ) async {
      await openMarket(tester);
      expect(visible('Longs pay shorts'), findsOneWidget);

      for (final next in ['Shared live by kaito.eth', 'Record', 'Holders']) {
        await tester.fling(find.byType(PageView), const Offset(-300, 0), 1500);
        await tester.pumpAndSettle();
        expect(visible(next), findsOneWidget);
      }
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
        .widgetList<VistaMarketRow>(find.byType(VistaMarketRow))
        .map((r) => r.name)
        .toList();

    testWidgets('Explore shows markets; sort, search and favourites work', (
      tester,
    ) async {
      await openMarkets(tester);
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
        matching: find.byType(VistaMarketRow),
      );
      await tester.tap(
        find.descendant(of: arb, matching: find.byType(VistaStarButton)),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widgetList(find.byType(VistaMarketCard)).length,
        greaterThanOrEqualTo(3),
      );
      expect(tester.widget<VistaMarketRow>(arb).starred, isTrue);
    });

    testWidgets('Traders tab lists trader markets and opens one', (
      tester,
    ) async {
      await openMarkets(tester);
      await tester.tap(find.text('Traders'));
      await tester.pumpAndSettle();
      expect(find.text('ALL TRADER MARKETS'), findsOneWidget);
      expect(rowNames(tester).first, 'maya.eth');

      await tester.tap(
        find.descendant(
          of: find.byType(VistaMarketRow),
          matching: find.text('0xreal'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(VistaIntervalSelector), findsOneWidget);
    });

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
}
