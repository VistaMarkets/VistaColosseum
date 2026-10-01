import 'package:flutter/foundation.dart';

import '../../charting/charting.dart';

/// Device-only display preferences (Settings › Display). The backend has no
/// field for these, so they live on the device; in the demo they reset when
/// the app restarts.
abstract final class DisplayPrefs {
  /// Candles or line, for every chart that can draw both.
  static final chartMode = ValueNotifier<PlotMode>(PlotMode.candles);

  /// Long (or bull) on the right of a two-button pair instead of the left.
  static final longOnRight = ValueNotifier<bool>(false);

  static void reset() {
    chartMode.value = PlotMode.candles;
    longOnRight.value = false;
  }
}

/// Account settings as the backend models them, held locally. Every change
/// is simulated: nothing is sent anywhere.
///
/// - [notify]: `NotificationPrefs` (`GET/PATCH /v1/accounts/me/notification-prefs`),
///   one switch per category.
/// - [notifyFrom]: per-trader switches from the design; the backend has no
///   endpoint for these yet.
/// - [tradesPublic]: `Account.tradeVisibility` (PUBLIC / PRIVATE).
/// - [tradingPermission]: `Account.delegationActive`; revoking maps to
///   `DELETE /v1/accounts/me/delegation`.
abstract final class SettingsState {
  static final notify = ValueNotifier<Map<String, bool>>(_notifyDefaults);
  static final notifyFrom = ValueNotifier<Map<String, bool>>(_fromDefaults);
  static final tradesPublic = ValueNotifier<bool>(true);
  static final tradingPermission = ValueNotifier<bool>(true);

  static const _notifyDefaults = {
    'calls': true,
    'technicals': true,
    'traders': true,
    'flips': true,
  };
  static const _fromDefaults = {
    'kaito.eth': true,
    '0xreal': false,
    'kilo.sol': true,
  };

  static void setNotify(String key, bool on) =>
      notify.value = {...notify.value, key: on};

  static void setNotifyFrom(String handle, bool on) =>
      notifyFrom.value = {...notifyFrom.value, handle: on};

  /// "All on", "All off" or "2 of 4 on", for the Notifications row.
  static String get notifySummary {
    final on = notify.value.values.where((v) => v).length;
    final all = notify.value.length;
    if (on == all) return 'All on';
    if (on == 0) return 'All off';
    return '$on of $all on';
  }

  static void reset() {
    notify.value = _notifyDefaults;
    notifyFrom.value = _fromDefaults;
    tradesPublic.value = true;
    tradingPermission.value = true;
    DisplayPrefs.reset();
  }
}
