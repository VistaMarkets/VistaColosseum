import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vista_colosseum/app_shell.dart';
import 'package:vista_colosseum/design_system/design_system.dart';
import 'package:vista_colosseum/features/account/account_state.dart';
import 'package:vista_colosseum/features/market/receipt_screens.dart';
import 'package:vista_colosseum/features/settings/settings_state.dart';
import 'package:vista_colosseum/features/share/copy_card.dart';
import 'package:vista_colosseum/features/trade/order_ticket.dart';
import 'package:vista_colosseum/scenario/scenario.dart';

import 'order_ticket_test.dart' show homeCard, inSheet, openTicket, review;
import 'receipts_test.dart' show pumpApp;
import 'scenario_test.dart' show state;

/// A copier's fill of kilo.sol's SOL call, through the store.
void copySol() {
  Scenario.switchPersona();
  final result = Scenario.placeOrder(
    OrderIntent(
      actionId: 'card-1',
      symbol: 'SOL',
      name: 'Solana',
      side: TradeSide.long,
      units: 100 / 214.90,
      price: 214.90,
      leverage: 5,
      sourceCallId: 'kilo.sol/SOL',
      sourceAuthorHandle: 'kilo.sol',
    ),
  );
  expect(result, isA<OrderFilled>());
}

const row = 'Share copy card · @sam.sol · SOL';
const cardLines = [
  'Copied @kilo.sol · SOL',
  r'$5.00 copy fee → @maya.eth',
  'by @sam.sol · Simulated',
];
const targets = ['Messages', 'Telegram', 'X', 'Copy text'];

void expectSheet() {
  expect(find.byType(CopyCardSheet), findsOneWidget);
  expect(find.text('Share copy'), findsOneWidget);
  for (final line in cardLines) {
    expect(find.text(line), findsOneWidget, reason: line);
  }
  for (final t in targets) {
    expect(find.bySemanticsLabel(t), findsOneWidget, reason: t);
  }
}

List<String> mockClipboard(WidgetTester tester) {
  final copied = <String>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'Clipboard.setData') {
        copied.add((call.arguments as Map)['text'] as String);
      }
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );
  return copied;
}

/// The app's font, so text measures as on a device.
Future<void> _loadFonts() async {
  // The text face and its fixed-width-digit twin for numbers.
  for (final family in ['OpenRunde', 'OpenRundeTabular']) {
    final loader = FontLoader(family);
    for (final w in ['Regular', 'Medium', 'Semibold', 'Bold']) {
      final bytes = File('assets/fonts/$family-$w.otf').readAsBytesSync();
      loader.addFont(Future.value(ByteData.sublistView(bytes)));
    }
    await loader.load();
  }
}

void main() {
  setUpAll(_loadFonts);
  setUp(() {
    Scenario.reset();
    AccountState.listMarket('MAYA');
    SettingsState.reset();
    AppShell.tab.value = 0;
  });

  testWidgets('the ledger row opens the copy card', (tester) async {
    copySol();
    await pumpApp(tester, home: const LedgerScreen());
    expect(find.text('Copy fee · @sam.sol · SOL'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel(row));
    await tester.pumpAndSettle();
    expectSheet();
    expect(tester.takeException(), isNull);
  });

  testWidgets('order filled offers the copy card for a copy', (tester) async {
    Scenario.switchPersona();
    await homeCard(tester, 'SOL');
    await tester.tap(
      find.widgetWithText(VistaPillButton, 'Long').hitTestable().first,
    );
    await tester.pumpAndSettle();
    await tester.tap(inSheet(find.text(r'Long $200   2x')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(inSheet(find.text('Order filled')), findsOneWidget);
    expect(Scenario.receipts.value.single.copyFeeCents, 500);

    await tester.tap(find.text('Share copy card'));
    await tester.pumpAndSettle();
    expectSheet();

    // The copy sheet's Done closes it; the ticket's buttons still work.
    await tester.tap(
      find.descendant(
        of: find.byType(CopyCardSheet),
        matching: find.text('Done'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(CopyCardSheet), findsNothing);
    expect(inSheet(find.text('Done')), findsOneWidget);
    await tester.tap(inSheet(find.text('View in Wallet')));
    await tester.pumpAndSettle();
    expect(find.byType(FeedOrderTicket), findsNothing);
    expect(AppShell.tab.value, AppShell.wallet);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an ordinary fill offers no card', (tester) async {
    await openTicket(tester, 'BTC');
    await review(tester);
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(inSheet(find.text('Order filled')), findsOneWidget);
    expect(Scenario.receipts.value.single.copyFeeCents, 0);
    expect(find.text('Share copy card'), findsNothing);
  });

  testWidgets('targets copy the card text or toast, and never write', (
    tester,
  ) async {
    copySol();
    final copied = mockClipboard(tester);
    final before = state();
    await pumpApp(tester, home: const LedgerScreen());

    await tester.tap(find.bySemanticsLabel(row));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Copy text'));
    await tester.pumpAndSettle();
    expect(
      copied.single,
      r'Copied @kilo.sol · SOL · $5.00 copy fee → @maya.eth · by @sam.sol',
    );
    expect(find.byType(CopyCardSheet), findsNothing);
    expect(find.text('Card text copied'), findsOneWidget);
    expect(state(), equals(before));

    await tester.tap(find.bySemanticsLabel(row));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('X'));
    await tester.pumpAndSettle();
    expect(find.byType(CopyCardSheet), findsNothing);
    expect(find.text('Shared to X (simulated)'), findsOneWidget);
    expect(copied, hasLength(1));
    expect(state(), equals(before));
    expect(tester.takeException(), isNull);
  });
}
