import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vista_colosseum/design_system/design_system.dart';
import 'package:vista_colosseum/features/account/account_state.dart';
import 'package:vista_colosseum/features/arena/arena_mock.dart';
import 'package:vista_colosseum/features/home/home_screen.dart';
import 'package:vista_colosseum/features/home/mock_trade_idea.dart';
import 'package:vista_colosseum/features/live/market_prices.dart';
import 'package:vista_colosseum/features/market/trader_market_chart.dart';
import 'package:vista_colosseum/features/market/trader_market_screen.dart';
import 'package:vista_colosseum/features/markets/markets_mock.dart';
import 'package:vista_colosseum/features/profile/profile_screen.dart';
import 'package:vista_colosseum/features/make_market/make_market_mock.dart';
import 'package:vista_colosseum/features/market/market_mock.dart';
import 'package:vista_colosseum/features/market/your_market_screen.dart';
import 'package:vista_colosseum/features/portfolio/portfolio_mock.dart';
import 'package:vista_colosseum/features/portfolio/portfolio_pager.dart';
import 'package:vista_colosseum/features/portfolio/series_chart.dart';
import 'package:vista_colosseum/features/trade/trade_mock.dart';
import 'package:vista_colosseum/main.dart';
import 'package:vista_colosseum/scenario/scenario.dart';

/// Spans 0..5 of [PortfolioMock.spans].
final spans = [for (var i = 0; i < PortfolioMock.spans.length; i++) i];

Future<void> _loadFonts() async {
  final loader = FontLoader('OpenRunde');
  for (final w in ['Regular', 'Medium', 'Semibold', 'Bold']) {
    final bytes = File('assets/fonts/OpenRunde-$w.otf').readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
}

/// Pumps [home] (the app's shell unless given) on a 402x874 phone.
Future<void> pumpApp(WidgetTester tester, {Widget? home}) async {
  tester.view
    ..physicalSize = const Size(402, 874) * 3
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const SizedBox());
  await tester.pumpWidget(
    home == null ? const VistaColosseumApp() : VistaColosseumApp(home: home),
  );
  await tester.pumpAndSettle();
}

Future<void> openWallet(WidgetTester tester) async {
  await pumpApp(tester);
  await tester.tap(find.bySemanticsLabel('Wallet'));
  await tester.pumpAndSettle();
}

/// From the Wallet, opens Your market.
Future<void> openYourMarket(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Your market'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Your market'));
  await tester.pumpAndSettle();
}

/// Flings the Wallet chart left, onto the market-cap page.
Future<void> swipeToCap(WidgetTester tester) async {
  final chart =
      tester.getCenter(find.byType(PortfolioPager)) + const Offset(0, 40);
  await tester.flingFrom(chart, const Offset(-250, 0), 1000);
  await tester.pumpAndSettle();
}

/// Flings the Wallet chart right, back to My portfolio.
Future<void> swipeBack(WidgetTester tester) async {
  final chart =
      tester.getCenter(find.byType(PortfolioPager)) + const Offset(0, 40);
  await tester.flingFrom(chart, const Offset(250, 0), 1000);
  await tester.pumpAndSettle();
}

SeriesChart onlyChart(WidgetTester tester) =>
    tester.widget<SeriesChart>(find.byType(SeriesChart));

Color? colorOf(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style?.color;

void main() {
  setUpAll(_loadFonts);
  setUp(() => Scenario.reset(withMarket: false));

  test('no market, no cap', () {
    expect(Scenario.ownCapCents, isNull);
    expect(Scenario.ownCapHasHistory, isFalse);
    for (final s in spans) {
      expect(Scenario.ownCapMoveCents(s), 0);
      expect(ownCapSeries(s), isNull);
    }
    expect(() => Scenario.ownCapMoveCents(6), throwsRangeError);
    expect(() => Scenario.ownCapMoveCents(-1), throwsRangeError);
    expect(() => ownCapSeries(6), throwsRangeError);
  });

  test('a fresh listing starts at the 10,000 dollar starting cap in '
      'cents', () {
    AccountState.listMarket(PortfolioMock.marketSymbol);
    expect(MakeMarketMock.startingCapCents, 1000000);
    expect(Scenario.ownCapCents, 1000000);
    expect(Scenario.ownCapHasHistory, isFalse);
    for (final s in spans) {
      expect(Scenario.ownCapMoveCents(s), 0);
      // Flat at the cap: a market listed now has no history to draw.
      expect(ownCapSeries(s), List.filled(48, 10000.0));
    }
    expect(() => ownCapSeries(6), throwsRangeError);
  });

  test('moving the clock before or after a fresh listing keeps the '
      'starting cap', () {
    Scenario.clock.value = TradeMock.chartEnd.add(const Duration(hours: 1));
    AccountState.listMarket(PortfolioMock.marketSymbol);
    expect(Scenario.ownCapCents, 1000000);
    expect(Scenario.ownCapHasHistory, isFalse);
    Scenario.clock.value = TradeMock.chartEnd.add(const Duration(days: 1));
    expect(Scenario.ownCapCents, 1000000);
    expect(Scenario.ownCapMoveCents(PortfolioMock.defaultSpan), 0);
  });

  test("a listing at the seed's instant reads as the seed", () {
    Scenario.clock.value = YourMarketMock.listedAt;
    AccountState.listMarket(PortfolioMock.marketSymbol);
    expect(Scenario.ownCapCents, YourMarketMock.seededCapCents);
    expect(Scenario.ownCapHasHistory, isTrue);

    Scenario.reset(withMarket: false);
    Scenario.clock.value = YourMarketMock.listedAt;
    AccountState.listMarket('ZED');
    expect(Scenario.ownCapCents, MakeMarketMock.startingCapCents);
    expect(Scenario.ownCapHasHistory, isFalse);
  });

  test('a persona switch leaves the cap unchanged', () {
    void check() {
      final cap = Scenario.ownCapCents;
      final moves = [for (final s in spans) Scenario.ownCapMoveCents(s)];
      Scenario.switchPersona();
      expect(Scenario.activePersona.value, Persona.copier);
      expect(Scenario.ownCapCents, cap);
      expect([for (final s in spans) Scenario.ownCapMoveCents(s)], moves);
      Scenario.switchPersona();
      expect(Scenario.activePersona.value, Persona.creator);
      expect(Scenario.ownCapCents, cap);
      expect([for (final s in spans) Scenario.ownCapMoveCents(s)], moves);
    }

    Scenario.reset(withMarket: true);
    check();
    Scenario.reset(withMarket: false);
    AccountState.listMarket(PortfolioMock.marketSymbol);
    check();
  });

  test('the HAS_MARKET seed derives the 44.0M fixture cap in cents', () {
    Scenario.reset(withMarket: true);
    expect(YourMarketMock.seededCapCents, 4400000000);
    expect(Scenario.ownCapCents, 4400000000);
    expect(Scenario.ownCapHasHistory, isTrue);
    expect(YourMarketMock.seededCapMovesCents, [
      -21000000,
      35000000,
      180000000,
      560000000,
      -230000000,
      3120000000,
    ]);
    for (final s in spans) {
      final move = YourMarketMock.seededCapMovesCents[s];
      expect(Scenario.ownCapMoveCents(s), move);
      // The seed's series runs from cap - move to cap, in dollars.
      final series = ownCapSeries(s)!;
      expect(series.first, closeTo((4400000000 - move) / 100, 0.01));
      expect(series.last, closeTo(4400000000 / 100, 0.01));
    }
  });

  test("reset clears a fresh listing's cap", () {
    AccountState.listMarket(PortfolioMock.marketSymbol);
    expect(Scenario.ownCapCents, 1000000);
    Scenario.reset(withMarket: false);
    expect(Scenario.ownCapCents, isNull);

    AccountState.listMarket(PortfolioMock.marketSymbol);
    Scenario.reset(withMarket: true);
    expect(Scenario.ownCapCents, 4400000000);

    // From no market, a listener on hasMarket fires before listedAt is
    // written: it must read no cap, not the starting cap.
    Scenario.reset(withMarket: false);
    final seen = <int?>[];
    void listener() => seen.add(Scenario.ownCapCents);
    Scenario.hasMarket.addListener(listener);
    addTearDown(() => Scenario.hasMarket.removeListener(listener));
    Scenario.reset(withMarket: true);
    expect(seen, [null]);
    expect(Scenario.ownCapCents, 4400000000);
  });

  test('ownCap notifies when any value the cap derives from changes', () {
    var calls = 0;
    void listener() => calls++;
    Scenario.ownCap.addListener(listener);
    addTearDown(() => Scenario.ownCap.removeListener(listener));
    Scenario.listedAt.value = TradeMock.chartEnd;
    Scenario.marketId.value = 'ZED';
    Scenario.hasMarket.value = true;
    expect(calls, 3);
    expect(identical(Scenario.ownCap, Scenario.ownCap), isTrue);
  });

  test('formatCap and formatCapChange print the fixture strings', () {
    expect(formatCap(4400000000), r'$44.0M');
    expect(formatCap(1000000), r'$10,000');
    expect(formatCap(99999950), r'$1,000,000');
    expect(formatCap(100000000), r'$1.0M');
    expect(formatCap(0), r'$0');

    String seed(int span) {
      final move = YourMarketMock.seededCapMovesCents[span];
      return formatCapChange(4400000000 - move, 4400000000);
    }

    expect(seed(2), r'+$1.8M (4.27%)'); // 1D
    expect(seed(0), '−\$210,000 (0.48%)'); // 1h, a fall prints U+2212
    expect(seed(4), '−\$2.3M (4.97%)'); // 1M
    expect(seed(1), r'+$350,000 (0.80%)'); // 4h
    expect(formatCapChange(1000000, 1000000), r'+$0 (0.00%)');
    expect(formatCapChange(0, 1000000), r'+$10,000');
    expect(formatCapChange(1000000, 900000), startsWith('−'));
    expect(formatCapChange(1000000, 900000), isNot(contains('-')));
  });

  test('formatUnitPrice prints ten-thousandths half-up', () {
    expect(formatUnitPrice(4400000000, YourMarketMock.supplyUnits), r'$0.4400');
    expect(formatUnitPrice(1000000, YourMarketMock.supplyUnits), r'$0.0001');
    expect(formatUnitPrice(1500000, YourMarketMock.supplyUnits), r'$0.0002');
    expect(YourMarketMock.supplyUnits, 100000000);
  });

  testWidgets('a mounted Wallet updates when reset swaps a fresh listing '
      'for the seed', (tester) async {
    AccountState.listMarket(PortfolioMock.marketSymbol);
    await openWallet(tester);
    expect(find.text(r'$10,000'), findsOneWidget);
    expect(find.text(r'$44.0M'), findsNothing);

    Scenario.reset(withMarket: true);
    await tester.pumpAndSettle();
    expect(find.text(r'$44.0M'), findsOneWidget);
    expect(find.text(r'$10,000'), findsNothing);
  });

  testWidgets('success, Wallet and Your market show one cap after a fresh '
      'listing', (tester) async {
    await openWallet(tester);
    await tester.tap(find.bySemanticsLabel('Make a market'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(r'Continue with $MAYA'));
    await tester.pumpAndSettle();
    for (var i = 0; i < 4; i++) {
      final box = find.byType(VistaCheckRow).at(i);
      await tester.ensureVisible(box);
      await tester.tap(box);
      await tester.pump();
    }
    await tester.tap(find.text(r'Create $MAYA'));
    await tester.pumpAndSettle();

    // Success.
    expect(find.text('Your market is open'), findsOneWidget);
    expect(find.text(r'$10,000'), findsOneWidget);
    expect(find.text(r'$44.0M'), findsNothing);

    // Wallet: the cap page holds the listed cap (at opacity 0 until
    // swiped), and its change shows no move in the long colour.
    await tester.tap(find.bySemanticsLabel('Close'));
    await tester.pumpAndSettle();
    expect(find.text(r'$10,000'), findsOneWidget);
    expect(find.text(r'$44.0M'), findsNothing);
    expect(colorOf(tester, r'+$0 (0.00%)'), VistaColors.long);

    // Your market.
    await openYourMarket(tester);
    expect(find.byType(YourMarketScreen), findsOneWidget);
    expect(find.text(r'$10,000'), findsOneWidget);
    expect(find.text(r'$44.0M'), findsNothing);
    expect(colorOf(tester, r'+$0 (0.00%)'), VistaColors.long);
    expect(find.text(r'$0.0001 / unit · 100M supply'), findsOneWidget);
    expect(
      find.descendant(
        of: find.widgetWithText(VistaMetric, 'Price'),
        matching: find.text(r'$0.0001'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('the success step keeps the cap it read at listing', (
    tester,
  ) async {
    await openWallet(tester);
    await tester.tap(find.bySemanticsLabel('Make a market'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(r'Continue with $MAYA'));
    await tester.pumpAndSettle();
    for (var i = 0; i < 4; i++) {
      final box = find.byType(VistaCheckRow).at(i);
      await tester.ensureVisible(box);
      await tester.tap(box);
      await tester.pump();
    }
    await tester.tap(find.text(r'Create $MAYA'));
    await tester.pumpAndSettle();
    expect(find.text(r'$10,000'), findsOneWidget);

    // A reset swaps in the seed; a view change rebuilds the live step.
    Scenario.reset(withMarket: true);
    tester.view.padding = const FakeViewPadding(bottom: 102);
    await tester.pumpAndSettle();
    expect(find.text('Your market is open'), findsOneWidget);
    expect(find.text(r'$10,000'), findsOneWidget);
    expect(find.text(r'$44.0M'), findsNothing);
  });

  testWidgets('seeded mode shows 44.0M on Wallet and Your market', (
    tester,
  ) async {
    Scenario.reset(withMarket: true);
    await openWallet(tester);
    expect(find.text(r'$44.0M'), findsOneWidget);
    expect(find.text(r'+$1.8M (4.27%)'), findsOneWidget);

    await openYourMarket(tester);
    expect(find.text(r'$44.0M'), findsOneWidget);
    expect(find.text(r'+$1.8M (4.27%)'), findsOneWidget);
    expect(find.text(r'$0.4400 / unit · 100M supply'), findsOneWidget);
  });

  testWidgets('the Wallet cap page follows the span', (tester) async {
    Scenario.reset(withMarket: true);
    await openWallet(tester);
    await tester.tap(find.text('1h'));
    await tester.pumpAndSettle();
    await swipeToCap(tester);
    const change = '−\$210,000 (0.48%)';
    expect(colorOf(tester, change), VistaColors.short);
    expect(
      find.descendant(
        of: find.ancestor(of: find.text(change), matching: find.byType(Wrap)),
        matching: find.text('Past hour'),
      ),
      findsOneWidget,
    );
    expect(onlyChart(tester).focus, ownCapSeries(0));
  });

  testWidgets("the cap chart is flat for a fresh listing and spans the "
      "seed's move on Wallet and Your market", (tester) async {
    const assets = {
      VistaAssets.marketDotLattice,
      VistaAssets.marketBaseline,
      VistaAssets.marketClipAbove,
      VistaAssets.marketClipBelow,
      VistaAssets.marketLiveHalo,
      VistaAssets.markerLive,
    };
    final figmaLayers = find.descendant(
      of: find.byType(YourMarketScreen),
      matching: find.byWidgetPredicate(
        (w) =>
            w is SvgPicture &&
            w.bytesLoader is SvgAssetLoader &&
            assets.contains((w.bytesLoader as SvgAssetLoader).assetName),
      ),
    );

    for (final seeded in [false, true]) {
      if (seeded) {
        Scenario.reset(withMarket: true);
      } else {
        AccountState.listMarket(PortfolioMock.marketSymbol);
      }
      final cap = Scenario.ownCapCents! / 100;
      final series = ownCapSeries(PortfolioMock.defaultSpan)!;
      void check(List<double>? line) {
        expect(line, isNotNull);
        if (seeded) {
          final move = Scenario.ownCapMoveCents(PortfolioMock.defaultSpan);
          expect(line!.first, closeTo(cap - move / 100, 0.01));
          expect(line.last, closeTo(cap, 0.01));
        } else {
          expect(line, List.filled(48, cap));
        }
        expect(line, series);
      }

      await openWallet(tester);
      check(onlyChart(tester).muted);
      await swipeToCap(tester);
      check(onlyChart(tester).focus);
      await swipeBack(tester);

      await openYourMarket(tester);
      check(onlyChart(tester).focus);
      expect(figmaLayers, findsNothing);
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('with no market Wallet builds no cap page and Your market '
      'shows unavailable', (tester) async {
    await openWallet(tester);
    expect(find.text(r'$MAYA market cap'), findsNothing);
    expect(onlyChart(tester).muted, isNull);
    expect(
      find.bySemanticsLabel(
        RegExp('^Swipe to switch between portfolio and market cap'),
      ),
      findsNothing,
    );

    await pumpApp(tester, home: const YourMarketScreen());
    expect(tester.takeException(), isNull);
    final head = find.ancestor(
      of: find.text('Market cap'),
      matching: find.byType(Column),
    );
    final headUnavailable = find.descendant(
      of: head.first,
      matching: find.text(unavailable),
    );
    final price = find.descendant(
      of: find.widgetWithText(VistaMetric, 'Price'),
      matching: find.text(unavailable),
    );
    expect(headUnavailable, findsNWidgets(3));
    expect(price, findsOneWidget);
    // The window label stays with no cap.
    expect(find.text('Last 24 hours'), findsOneWidget);
    for (final f in [headUnavailable, price]) {
      for (final t in tester.widgetList<Text>(f)) {
        expect(t.style?.color, VistaColors.textMuted);
      }
    }
    expect(find.byType(SeriesChart), findsNothing);
  });

  testWidgets('a bare pager with no market cannot reach a cap page', (
    tester,
  ) async {
    await pumpApp(tester, home: const Scaffold(body: PortfolioPager()));
    expect(find.text(r'$MAYA market cap'), findsNothing);
    expect(
      find.bySemanticsLabel(
        RegExp('^Swipe to switch between portfolio and market cap'),
      ),
      findsNothing,
    );
    await swipeToCap(tester);
    final portfolio = tester.widget<Opacity>(
      find
          .ancestor(
            of: find.text('My portfolio'),
            matching: find.byType(Opacity),
          )
          .first,
    );
    expect(portfolio.opacity, 1);
    expect(find.text(r'$MAYA market cap'), findsNothing);
  });

  testWidgets("Your market's span selector drives its cap chart and change", (
    tester,
  ) async {
    Scenario.reset(withMarket: true);
    await pumpApp(tester, home: const YourMarketScreen());
    final day = onlyChart(tester).focus;
    await tester.tap(find.text('1h'));
    await tester.pumpAndSettle();
    expect(colorOf(tester, '−\$210,000 (0.48%)'), VistaColors.short);
    expect(find.text('Past hour'), findsOneWidget);
    expect(onlyChart(tester).focus, isNot(day));
    expect(onlyChart(tester).focus, ownCapSeries(0));

    Scenario.reset(withMarket: false);
    AccountState.listMarket(PortfolioMock.marketSymbol);
    await pumpApp(tester, home: const YourMarketScreen());
    for (var i = 0; i < PortfolioMock.spans.length; i++) {
      await tester.tap(find.text(PortfolioMock.spans[i]));
      await tester.pumpAndSettle();
      expect(find.text(r'+$0 (0.00%)'), findsOneWidget);
      expect(find.text(spanWindows[i]), findsOneWidget);
      expect(onlyChart(tester).focus, ownCapSeries(i));
    }
  });

  // Ruled 2026-10-09: maya.eth's trader market is the user's listed market.
  group("maya.eth's trader market reads the user's cap (#29)", () {
    MarketItem maya() =>
        MarketsMock.traders.firstWhere((m) => m.id == 'maya.eth');
    VistaBattleSide mayaSide() => [
      for (final b in ArenaMock.battles) ...[b.bull, b.bear],
    ].firstWhere((s) => s.caller == 'maya.eth');

    test('before a listing and in seeded mode it is the seed market', () {
      for (final withMarket in [false, true]) {
        Scenario.reset(withMarket: withMarket);
        expect(MarketPrices.base('maya.eth'), 0.44);
        expect(maya().third, r'$44.0M');
        expect(maya().changePct, 4.3);
        expect(mayaSide().price, r'$0.4400');
        expect(mayaSide().change, '+4.3%');
      }
    });

    test('a fresh listing prices Explore, Arena and the feed from its cap', () {
      AccountState.listMarket(PortfolioMock.marketSymbol);
      expect(MarketPrices.base('maya.eth'), 0.0001);
      expect(maya().third, r'$10,000');
      expect(maya().footLeft, r'Cap $10,000');
      expect(maya().changePct, 0);
      expect(maya().sortValues['Market cap'], 0.01);
      expect(mayaSide().price, r'$0.0001');
      expect(mayaSide().change, '+0.0%');
    });

    test("Home hides calls on the user's market while it is fresh", () {
      bool ownCall() =>
          homeFeed.any((i) => i is TradeIdea && i.ticker == 'maya.eth');
      expect(ownCall(), isTrue); // before a listing: the seed market
      AccountState.listMarket(PortfolioMock.marketSymbol);
      expect(ownCall(), isFalse); // deltaone's 2d-old call can't exist
      Scenario.reset(withMarket: true);
      expect(ownCall(), isTrue);
    });

    testWidgets('Trader market shows the listed cap and a flat line', (
      tester,
    ) async {
      AccountState.listMarket(PortfolioMock.marketSymbol);
      await pumpApp(tester, home: const TraderMarketScreen(handle: 'maya.eth'));
      expect(find.text(r'$10,000'), findsWidgets);
      expect(find.text(r'+$0'), findsOneWidget);
      expect(find.text('+0.00%'), findsOneWidget);
      expect(find.textContaining('44.0M'), findsNothing);
      expect(find.byType(TraderMarketChart), findsNothing);
      expect(find.byType(SeriesChart), findsOneWidget);
    });

    testWidgets('seeded Trader market keeps the fixture figures and chart', (
      tester,
    ) async {
      Scenario.reset(withMarket: true);
      await pumpApp(tester, home: const TraderMarketScreen(handle: 'maya.eth'));
      expect(find.text(r'$44.0M'), findsOneWidget);
      expect(find.text(r'+$1.8M'), findsOneWidget);
      expect(find.text('+4.27%'), findsOneWidget);
      expect(find.byType(SeriesChart), findsNothing);
    });

    testWidgets("maya.eth's Profile reads the listed cap; others keep theirs", (
      tester,
    ) async {
      AccountState.listMarket(PortfolioMock.marketSymbol);
      await pumpApp(tester, home: const ProfileScreen(handle: 'maya.eth'));
      expect(find.text(r'$10,000'), findsOneWidget);
      expect(find.text(r'$0.0001'), findsOneWidget);
      expect(find.text(r'$10,000 cap'), findsOneWidget);
      expect(find.text('+0.00%'), findsOneWidget);
      expect(find.textContaining('44.0M'), findsNothing);
      expect(find.byType(ProfileIndexChart), findsNothing);
      expect(find.byType(SeriesChart), findsOneWidget);

      await pumpApp(tester, home: const ProfileScreen(handle: '0xreal'));
      expect(find.text(r'$44.0M'), findsOneWidget);
    });
  });
}
