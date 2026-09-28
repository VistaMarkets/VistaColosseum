import 'package:flutter/foundation.dart';

/// Whether the signed-in user has listed a market yet, and its ticker.
///
/// Starts without a market, as for a new user; `--dart-define=HAS_MARKET=true`
/// starts with one (handy for demoing the market screens). Completing the
/// make-a-market flow sets it.
abstract final class AccountState {
  static const _startWithMarket = bool.fromEnvironment('HAS_MARKET');

  static final hasMarket = ValueNotifier<bool>(_startWithMarket);
  static final ticker = ValueNotifier<String>('MAYA');

  /// Records a newly created market.
  static void listMarket(String symbol) {
    ticker.value = symbol;
    hasMarket.value = true;
  }

  /// Back to the launch state (used by tests).
  @visibleForTesting
  static void reset({bool withMarket = _startWithMarket}) {
    hasMarket.value = withMarket;
    ticker.value = 'MAYA';
  }
}
