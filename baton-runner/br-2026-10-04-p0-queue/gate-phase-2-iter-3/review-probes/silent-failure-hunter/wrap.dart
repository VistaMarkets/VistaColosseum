int parseCents(String text) {
  final [whole, ...rest] = '${text.replaceAll(',', '')}.'.split('.');
  final frac = '${rest.first}00'.substring(0, 2);
  return (int.tryParse(whole) ?? 0) * 100 + (int.tryParse(frac) ?? 0);
}
void main() {
  for (final t in ['184467440737095517', '184467440737095717', '92233720368547759', '99999999999999999999', '1000000000000000', '1.2.3', '1,5']) {
    final c = parseCents(t);
    print('$t -> cents=$c');
  }
  const cash = 1248000;
  final m = 100000000000000000; // $1e15 typed => 1e17 cents
  print('slider semantics pct for 1e17 cents: ${(m * 100 / cash).round()}%');
  // smallest typed whole-dollar amount whose *100 wraps
  print('wrap threshold whole > ${9223372036854775807 ~/ 100}');
}
