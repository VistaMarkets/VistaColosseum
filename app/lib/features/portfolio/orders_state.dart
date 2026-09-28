import 'package:flutter/foundation.dart';

import 'portfolio_mock.dart';

/// The user's resting orders, shared by the order ticket (which adds to
/// them) and Portfolio's Open orders tab (which lists and cancels them).
/// Held in memory; simulated, nothing is sent.
abstract final class OrdersState {
  static final open = ValueNotifier<List<OpenOrder>>(
    List.unmodifiable(OpenOrdersMock.orders),
  );

  static void add(OpenOrder order) =>
      open.value = List.unmodifiable([order, ...open.value]);

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

  static void reset() => open.value = List.unmodifiable(OpenOrdersMock.orders);
}
