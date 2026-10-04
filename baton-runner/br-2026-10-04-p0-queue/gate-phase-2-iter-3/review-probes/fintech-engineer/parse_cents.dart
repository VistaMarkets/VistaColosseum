// Verbatim copy of FeedOrderTicket._parseCents (feed_order_ticket.dart:97-101).
int parseCents(String text) {
  final [whole, ...rest] = '${text.replaceAll(',', '')}.'.split('.');
  final frac = '${rest.first}00'.substring(0, 2);
  return (int.tryParse(whole) ?? 0) * 100 + (int.tryParse(frac) ?? 0);
}

void main() {
  for (final t in [
    '200', '12,467.53', '1.999', '1.2.3', '.5',
    '92233720368547758',        // 17 digits: largest whole that fits *100
    '92233720368547759',        // 17 digits: first that wraps
    '99999999999999999',        // 17 digits: wraps negative
    '184467440737095517',       // 18 digits: wraps to 84
    '184467440737095516.50',    // 18 digits: wraps to 0 + 50
    '9223372036854775807',      // 19 digits, int64 max: *100 wraps
    '9223372036854775808',      // 19 digits, past int64: tryParse null -> 0
    '10000000000000000000.84',  // 20 digits: whole dropped, $0.84 remains
  ]) {
    final c = parseCents(t);
    print('${t.padRight(26)} -> $c  (margin after max(0, .) = ${c < 0 ? 0 : c})');
  }
  // The spec-formula rounding at the store bound.
  const maxN = 900719925474;
  print('maxN*5 ~/ 10000 = ${maxN * 5 ~/ 10000}; (maxN+1)*10000 < 2^53: ${(maxN + 1) * 10000 < (1 << 53)}');
  // Finite units x finite price overflowing to +inf.
  final usd = 1e305 * 67412;
  print('1e305*67412 = $usd isFinite=${usd.isFinite}');
}
