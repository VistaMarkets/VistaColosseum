// Review-only probe: replicates feed_order_ticket.dart:97-101 verbatim.
int parseCents(String text) {
  final [whole, ...rest] = '${text.replaceAll(',', '')}.'.split('.');
  final frac = '${rest.first}00'.substring(0, 2);
  return (int.tryParse(whole) ?? 0) * 100 + (int.tryParse(frac) ?? 0);
}

void main() {
  for (final t in [
    '200',
    '92233720368547758', // largest whole that fits after *100
    '92233720368547759', // first that wraps
    '184467440737095517',
    '4611686018427388104',
    '9223372036854775807',
    '9223372036854775808', // past int64: tryParse null
    '1.2.3',
  ]) {
    final c = parseCents(t);
    final pct = (c * 100 / 1248000).round();
    print('$t -> cents=$c  max(0,c)=${c < 0 ? 0 : c}  pctLabel=$pct%');
  }
  // OrderIntent._cents with an infinite product of finite inputs.
  final usd = 1e305 * 67412;
  print('1e305*67412 isFinite=${usd.isFinite}');
  // clamp then round on a huge finite product.
  final big = (1.37e12 * 67412 * 100).clamp(0, 900719925474 + 1).round();
  print('clamped=$big');
}
