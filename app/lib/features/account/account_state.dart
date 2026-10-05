import 'package:flutter/foundation.dart';

import '../../scenario/scenario.dart';

/// Whether the signed-in user has listed a market yet, and its ticker. The
/// values live in [Scenario]; this keeps the listing helper next to them.
///
/// Starts without a market, as for a new user; `--dart-define=HAS_MARKET=true`
/// starts with one (handy for demoing the market screens). Completing the
/// make-a-market flow sets it.
abstract final class AccountState {
  static ValueNotifier<bool> get hasMarket => Scenario.hasMarket;
  static ValueNotifier<String> get ticker => Scenario.ticker;

  /// Records a newly created market.
  static void listMarket(String symbol) {
    Scenario.ticker.value = symbol;
    Scenario.marketId.value = symbol;
    Scenario.hasMarket.value = true;
  }
}
