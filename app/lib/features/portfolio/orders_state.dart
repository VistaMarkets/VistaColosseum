import 'package:flutter/foundation.dart';

import '../../scenario/scenario.dart';
import 'portfolio_mock.dart';

/// The user's resting orders, listed and cancelled by Portfolio's Open
/// orders tab. The list lives in [Scenario]; tickets add to it only through
/// `Scenario.placeOrder`. Simulated, nothing is sent.
abstract final class OrdersState {
  static ValueNotifier<List<OpenOrder>> get open => Scenario.openOrders;

  /// Removes [order]; returns where it was, for Undo.
  static int remove(OpenOrder order) {
    final index = open.value.indexOf(order);
    if (index >= 0) {
      open.value = List.unmodifiable([...open.value]..removeAt(index));
    }
    return index;
  }

  static void insert(int index, OpenOrder order) {
    if (open.value.contains(order)) return;
    final items = [...open.value];
    items.insert(index.clamp(0, items.length), order);
    open.value = List.unmodifiable(items);
  }
}
