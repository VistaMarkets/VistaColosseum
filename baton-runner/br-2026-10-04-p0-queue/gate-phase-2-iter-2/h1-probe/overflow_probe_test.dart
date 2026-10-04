// Review-only probe (phase 2 review iter 2, finding H-1). Not part of the suite.
import 'package:flutter_test/flutter_test.dart';
import 'package:vista_colosseum/design_system/design_system.dart';
import 'package:vista_colosseum/scenario/scenario.dart';

void main() {
  setUp(Scenario.reset);
  test('BTC 1.37e12 units at 1x', () {
    final cash0 = Scenario.cashCents.value;
    final i = OrderIntent(
      actionId: 'ovf', symbol: 'BTC', name: 'Bitcoin', side: TradeSide.long,
      units: 1.37e12, price: 67412, leverage: 1, icon: VistaAssets.navHome,
    );
    // ignore: avoid_print
    print('notional=${i.notionalCents} margin=${i.marginCents} fee=${i.feeCents} total=${i.totalCents} problem=${Scenario.problem(i)}');
    final r = Scenario.placeOrder(i);
    // ignore: avoid_print
    print('result=${r.runtimeType} cash0=$cash0 cash1=${Scenario.cashCents.value}');
  });
}
