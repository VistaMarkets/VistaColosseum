import 'package:flutter/foundation.dart';

import '../../scenario/scenario.dart';
import 'portfolio_mock.dart';

/// The viewer's open positions, shared by Portfolio, the position sheet
/// (which lists and closes them) and Arena's position picker: a view of
/// [Scenario.positions], which the order tickets fill into and Reset demo
/// restores.
abstract final class PositionsState {
  static ValueNotifier<List<PortfolioPosition>> get open => Scenario.positions;

  /// Closes [p]; returns where it was, for Undo.
  static int remove(PortfolioPosition p) {
    final index = open.value.indexOf(p);
    if (index >= 0) {
      open.value = List.unmodifiable([...open.value]..removeAt(index));
    }
    return index;
  }

  static void insert(int index, PortfolioPosition p) {
    if (open.value.contains(p)) return;
    final items = [...open.value];
    items.insert(index.clamp(0, items.length), p);
    open.value = List.unmodifiable(items);
  }
}
