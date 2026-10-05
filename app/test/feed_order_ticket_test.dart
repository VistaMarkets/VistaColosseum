import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vista_colosseum/design_system/design_system.dart';
import 'package:vista_colosseum/features/account/account_state.dart';
import 'package:vista_colosseum/features/live/live_feed.dart';
import 'package:vista_colosseum/features/portfolio/portfolio_mock.dart';
import 'package:vista_colosseum/features/settings/settings_state.dart';
import 'package:vista_colosseum/scenario/scenario.dart';

import 'order_ticket_test.dart' show homeCard, inSheet, paperFunds;

/// The app's font, so text measures as on a device.
Future<void> _loadFonts() async {
  final loader = FontLoader('OpenRunde');
  for (final w in ['Regular', 'Medium', 'Semibold', 'Bold']) {
    final bytes = File('assets/fonts/OpenRunde-$w.otf').readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
}

void main() {
  setUpAll(_loadFonts);
  setUp(() {
    Scenario.reset();
    AccountState.listMarket('MAYA');
    SettingsState.reset();
  });

  testWidgets(r'copy review shows the $5.00 copy fee in the total', (
    tester,
  ) async {
    Scenario.switchPersona(); // the copier opens kaito.eth's ETH call
    await homeCard(tester, 'ETH');
    await tester.tap(
      find.widgetWithText(VistaPillButton, 'Long').hitTestable().first,
    );
    await tester.pumpAndSettle();
    await tester.tap(inSheet(find.text(r'Long $200 · 2x')));
    await tester.pumpAndSettle();

    const line = r'Copying @kaito.eth · $5.00 copy fee';
    expect(inSheet(find.text('Review order')), findsOneWidget);
    expect(inSheet(find.text(line)), findsOneWidget);
    final reviewed = paperFunds(tester);

    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    final receipt = Scenario.receipts.value.single;
    expect(receipt.copyFeeCents, 500);
    expect(receipt.sourceCallId, 'kaito.eth/ETH');
    expect(
      receipt.totalCents,
      receipt.marginCents + receipt.feeCents + receipt.copyFeeCents,
    );
    // Review, receipt and store agree to the cent.
    expect(reviewed, formatCents(receipt.totalCents));
    expect(
      Scenario.cashCents.value,
      PortfolioMock.copierCashCents - receipt.totalCents,
    );
    expect(inSheet(find.text('Order filled')), findsOneWidget);
    expect(inSheet(find.text(line)), findsOneWidget);
    expect(paperFunds(tester), formatCents(receipt.totalCents));
  });
}
