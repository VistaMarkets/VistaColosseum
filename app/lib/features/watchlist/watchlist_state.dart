import 'package:flutter/foundation.dart';

import '../markets/markets_mock.dart';

/// Favourite assets and trader markets, shared by every star in the app
/// (Explore rows and Favourites rail, the asset and trader market pages).
///
/// Lists keep the order items were starred, newest last, so the rail reads
/// in follow order as the backend lists it. Held in memory: the demo sends
/// nothing and favourites reset when the app restarts.
///
/// - [assets] is the backend's followed-markets relation: the watchlist is
///   asset follow, toggled one at a time by `PUT` / `DELETE
///   /v1/assets/{assetId}/follow` and listed by `GET /v1/accounts/me/markets`.
/// - [traders] has no backend relation yet (the only trader relation is
///   Follow, a separate button), so it stays on the device.
abstract final class WatchlistState {
  static final assets = ValueNotifier<List<String>>(_assetDefaults);
  static final traders = ValueNotifier<List<String>>(_traderDefaults);

  static final _assetDefaults = List<String>.unmodifiable(
    MarketsMock.assetFavorites,
  );
  static final _traderDefaults = List<String>.unmodifiable(
    MarketsMock.traderFavorites,
  );

  static bool isAsset(String id) => assets.value.contains(id);
  static bool isTrader(String handle) => traders.value.contains(handle);

  /// Stars or unstars [id]; returns whether it is now a favourite.
  static bool toggleAsset(String id) => _toggle(assets, id);
  static bool toggleTrader(String handle) => _toggle(traders, handle);

  static bool _toggle(ValueNotifier<List<String>> list, String id) {
    final on = !list.value.contains(id);
    list.value = on
        ? List.unmodifiable([...list.value, id])
        : List.unmodifiable(list.value.where((e) => e != id));
    return on;
  }

  /// Moves the favourite at [from] to [to] (list indexes after removal, as
  /// [ReorderableListView] reports them once adjusted).
  static void move(ValueNotifier<List<String>> list, int from, int to) {
    final items = [...list.value];
    items.insert(to, items.removeAt(from));
    list.value = List.unmodifiable(items);
  }

  static void reset() {
    assets.value = _assetDefaults;
    traders.value = _traderDefaults;
  }
}
