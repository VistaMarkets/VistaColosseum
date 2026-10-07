import 'package:flutter_test/flutter_test.dart';
import 'package:vista_colosseum/features/account/account_state.dart';
import 'package:vista_colosseum/features/make_market/make_market_mock.dart';
import 'package:vista_colosseum/features/market/market_mock.dart';
import 'package:vista_colosseum/features/portfolio/portfolio_mock.dart';
import 'package:vista_colosseum/features/trade/trade_mock.dart';
import 'package:vista_colosseum/scenario/scenario.dart';

/// Spans 0..5 of [PortfolioMock.spans].
final spans = [for (var i = 0; i < PortfolioMock.spans.length; i++) i];

void main() {
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
}
