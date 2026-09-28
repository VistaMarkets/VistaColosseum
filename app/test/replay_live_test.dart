import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vista_colosseum/charting/charting.dart';
import 'package:vista_colosseum/design_system/design_system.dart';
import 'package:vista_colosseum/features/home/signal_replay_chart.dart';
import 'package:vista_colosseum/features/settings/settings_state.dart';

void main() {
  tearDown(DisplayPrefs.reset);

  Future<ValueNotifier<double>> pumpChart(WidgetTester tester) async {
    final price = ValueNotifier<double>(2968.40);
    addTearDown(price.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: VistaTheme.dark(),
        home: Scaffold(
          body: SizedBox(
            width: 360,
            height: 403,
            child: SignalReplayChart(livePrice: price),
          ),
        ),
      ),
    );
    return price;
  }

  List<Offset> points(WidgetTester tester, String painter) {
    final paint = tester.widget<CustomPaint>(
      find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter.runtimeType.toString() == painter,
      ),
    );
    return (paint.painter as dynamic).points as List<Offset>;
  }

  for (final (mode, painter) in [
    (PlotMode.line, 'ReplayLinePainter'),
    (PlotMode.candles, '_ReplayCandles'),
  ]) {
    testWidgets('after the replay the $mode chart follows the live price', (
      tester,
    ) async {
      DisplayPrefs.chartMode.value = mode;
      final price = await pumpChart(tester);

      // Mid-replay, live ticks are ignored.
      await tester.pump(const Duration(milliseconds: 500));
      price.value = 3000;
      await tester.pumpAndSettle();
      // Ignored as a tick, but as the replay ends the newest point eases to
      // the live price (3,000, above the designed top), keeping chart and
      // header on one number.
      expect(points(tester, painter).length, 48);
      final at3000 = points(tester, painter).last.dy;
      expect(at3000, lessThan(24));
      expect(at3000, greaterThanOrEqualTo(17)); // squeezed to stay in view

      // Then each tick eases the newest point to the new price: 2,990 sits
      // below 3,000.
      price.value = 2990;
      await tester.pumpAndSettle();
      var p = points(tester, painter);
      expect(p.length, 48);
      expect(p.last.dy, greaterThan(at3000));

      // Every fourth tick opens a new point and the chart scrolls left, so
      // "now" stays at the right edge.
      for (final v in [2985.0, 2992.0, 2988.0]) {
        price.value = v;
        await tester.pumpAndSettle();
      }
      p = points(tester, painter);
      expect(p.length, 49);
      expect(p.last.dx, closeTo(352, 0.01));
      expect(p.first.dx, closeTo(4 - 7.4, 0.01));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('replay opens close on the first candle and pulls back to '
      'the designed frame', (tester) async {
    DisplayPrefs.chartMode.value = PlotMode.candles;
    await pumpChart(tester);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    final early = points(tester, '_ReplayCandles');
    final earlySlot = early[1].dx - early[0].dx;

    await tester.pumpAndSettle();
    final end = points(tester, '_ReplayCandles');
    expect(end.first, const Offset(4, 232));
    expect(end.last, const Offset(352, 24));
    // At the start each candle's slot is several times its final width.
    expect(earlySlot, greaterThan((end[1].dx - end[0].dx) * 3));
  });
}
