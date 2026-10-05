// ignore_for_file: avoid_print
import 'package:flutter_test/flutter_test.dart';
import 'package:vista_colosseum/design_system/design_system.dart';
import 'package:vista_colosseum/features/live/live_feed.dart';
import 'package:vista_colosseum/scenario/scenario.dart';

void main() {
  test('Q1 clamped figures a ticket would show for a 13-digit BTC size at 10x', () {
    final i = OrderIntent(actionId: 'q', symbol: 'BTC', name: 'Bitcoin',
        side: TradeSide.long, units: 1.37e12, price: 67412, leverage: 10);
    final trueNotional = 1.37e12 * 67412;
    print('Q1 shown margin=${formatCents(i.marginCents)} fee=${formatCents(i.feeCents)} '
        'true notional=\$${trueNotional.toStringAsExponential(3)} true margin=\$${(trueNotional / 10).toStringAsExponential(3)} '
        'problem=${Scenario.problem(i)}');
  });
  test('Q2 _parseCents wrap range (same expression as the feed ticket)', () {
    int parseCents(String text) {
      final [whole, ...rest] = '${text.replaceAll(',', '')}.'.split('.');
      final frac = '${rest.first}00'.substring(0, 2);
      return (int.tryParse(whole) ?? 0) * 100 + (int.tryParse(frac) ?? 0);
    }
    for (final s in ['92233720368547758', '92233720368547759', '184467440737095517',
        '184467440737095716.16', '9223372036854775807', '99999999999999999999']) {
      print('Q2 "$s" -> ${parseCents(s)}');
    }
  });
}
