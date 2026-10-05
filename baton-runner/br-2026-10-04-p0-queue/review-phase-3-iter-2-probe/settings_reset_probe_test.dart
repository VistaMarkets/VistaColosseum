// Review iter 2 probe (read-only evidence, not part of the suite).
// In-app Settings reset after fix iter 1: Settings pushed over the shell,
// Reset demo pops to the root, resets the store, and the toast is visible.
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vista_colosseum/features/account/account_state.dart';
import 'package:vista_colosseum/features/settings/settings_screen.dart';
import 'package:vista_colosseum/features/settings/settings_state.dart';
import 'package:vista_colosseum/main.dart';
import 'package:vista_colosseum/scenario/scenario.dart';

void main() {
  testWidgets('Settings reset in the app pops to root and toasts', (t) async {
    Scenario.reset();
    AccountState.listMarket('MAYA');
    SettingsState.reset();
    t.view
      ..physicalSize = const Size(375, 667) * 3
      ..devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(const VistaColosseumApp());
    await t.pumpAndSettle();
    Scenario.cashCents.value = 1;
    SettingsState.tradingPermission.value = false;
    final nav = t.state<NavigatorState>(find.byType(Navigator));
    nav.push(CupertinoPageRoute<void>(builder: (_) => const SettingsScreen()));
    await t.pumpAndSettle();
    await t.scrollUntilVisible(find.text('Reset demo'), 200,
        scrollable: find.byType(Scrollable).last);
    await t.pumpAndSettle();
    await t.tap(find.text('Reset demo'));
    await t.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsNothing);
    expect(nav.canPop(), isFalse);
    expect(find.text('Demo reset to fixture-v1').hitTestable(), findsOneWidget);
    expect(Scenario.cashCents.value, 1248000);
    expect(SettingsState.tradingPermission.value, isTrue);
    expect(t.takeException(), isNull);
  });
}
