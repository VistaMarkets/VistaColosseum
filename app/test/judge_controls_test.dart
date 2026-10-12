import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vista_colosseum/app_shell.dart';
import 'package:vista_colosseum/features/account/account_state.dart';
import 'package:vista_colosseum/features/market/receipt_screens.dart';
import 'package:vista_colosseum/features/settings/settings_state.dart';
import 'package:vista_colosseum/features/trade/order_ticket.dart';
import 'package:vista_colosseum/main.dart';
import 'package:vista_colosseum/scenario/scenario.dart';

/// The pill, whichever persona it names.
final pill = RegExp(r'^Simulated · fixture-v1');

const credited =
    r'sam.sol copied @kilo.sol · $5.00 copy fee credited to maya.eth '
    '(simulated)';
const alreadyPlayed =
    r'Already played · the $5.00 copy fee is on the Fee ledger (simulated)';

Future<void> _loadFonts() async {
  final loader = FontLoader('OpenRunde');
  for (final w in ['Regular', 'Medium', 'Semibold', 'Bold']) {
    final bytes = File('assets/fonts/OpenRunde-$w.otf').readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
}

Future<void> launch(
  WidgetTester tester, [
  Size size = const Size(375, 667),
  EdgeInsets pad = const EdgeInsets.only(top: 20),
]) async {
  tester.view
    ..physicalSize = size * 3
    ..devicePixelRatio = 3
    ..padding = FakeViewPadding(top: pad.top * 3, bottom: pad.bottom * 3);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const VistaColosseumApp());
  await tester.pumpAndSettle();
}

Future<void> tapPillThen(WidgetTester tester, String button) async {
  await tester.tap(find.bySemanticsLabel(pill));
  await tester.pumpAndSettle();
  await tester.tap(find.text(button));
  await tester.pumpAndSettle();
}

bool canPop(WidgetTester tester) =>
    tester.state<NavigatorState>(find.byType(Navigator)).canPop();

void main() {
  setUpAll(_loadFonts);
  setUp(() {
    Scenario.reset();
    AccountState.listMarket('MAYA');
    SettingsState.reset();
    AppShell.tab.value = 0;
  });

  testWidgets('the note offers act-as, play and reset', (tester) async {
    await launch(tester);
    expect(
      find.bySemanticsLabel('Simulated · fixture-v1 · maya.eth'),
      findsOneWidget,
    );
    await tester.tap(find.bySemanticsLabel(pill));
    await tester.pumpAndSettle();
    final actAs = tester.getTopLeft(find.text('Act as @sam.sol')).dy;
    final play = tester.getTopLeft(find.text('Play the copy story')).dy;
    final reset = tester.getTopLeft(find.text('Reset demo')).dy;
    expect(actAs, lessThan(play));
    expect(play, lessThan(reset));
    expect(tester.takeException(), isNull);
  });

  testWidgets('act as switches persona and closes sheets', (tester) async {
    await launch(tester);
    // A pushed route with a ticket sheet over it.
    await tester.tap(find.text('Details').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Long').last);
    await tester.pumpAndSettle();
    expect(find.byType(OrderTicket), findsOneWidget);

    await tapPillThen(tester, 'Act as @sam.sol');

    expect(find.byType(OrderTicket), findsNothing);
    expect(canPop(tester), isFalse);
    expect(Scenario.activePersona.value, Persona.copier);
    expect(Scenario.cashCents.value, 100000);
    expect(
      find.bySemanticsLabel('Simulated · fixture-v1 · sam.sol'),
      findsOneWidget,
    );
    expect(find.text('Now acting as sam.sol').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('play the copy story lands on the ledger row', (tester) async {
    await launch(tester);
    await tapPillThen(tester, 'Play the copy story');

    expect(Scenario.activePersona.value, Persona.creator);
    final copier = Scenario.booksOf(Persona.copier);
    expect(copier.cashCents, 97495);
    expect(copier.receipts, hasLength(1));
    final receipt = copier.receipts.single;
    expect(receipt.id, 'preset-copy');
    expect(receipt.sourceAuthorHandle, 'kilo.sol');
    expect(receipt.copyFeeCents, 500);
    final fee = Scenario.copyFees.single;
    expect(fee.amountCents, 500);
    expect(fee.counterparty, 'sam.sol');
    expect(fee.asset, 'SOL');
    expect(AppShell.tab.value, AppShell.wallet);
    expect(find.byType(LedgerScreen), findsOneWidget);
    expect(find.text('COPY FEES'), findsOneWidget);
    expect(find.text('Copy fee · @sam.sol · SOL'), findsOneWidget);
    expect(find.text(r'$5.00'), findsWidgets);
    expect(find.text(credited).hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a repeat play writes nothing; reset lets it play again', (
    tester,
  ) async {
    await launch(tester);
    await tapPillThen(tester, 'Play the copy story');
    await tapPillThen(tester, 'Play the copy story');

    expect(Scenario.copyFees, hasLength(1));
    expect(Scenario.booksOf(Persona.copier).cashCents, 97495);
    expect(find.byType(LedgerScreen), findsOneWidget);
    expect(find.text(alreadyPlayed).hitTestable(), findsOneWidget);
    expect(find.text(credited), findsNothing);

    await tapPillThen(tester, 'Reset demo');
    expect(Scenario.copyFees, isEmpty);
    await tapPillThen(tester, 'Play the copy story');
    expect(Scenario.copyFees, hasLength(1));
    expect(find.text(credited).hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('play fails whole when the copier cannot pay', (tester) async {
    Scenario.switchPersona();
    Scenario.cashCents.value = 1000;
    Scenario.switchPersona();
    await launch(tester);
    await tapPillThen(tester, 'Play the copy story');

    expect(Scenario.activePersona.value, Persona.copier);
    expect(Scenario.receipts.value, isEmpty);
    expect(Scenario.copyFees, isEmpty);
    expect(Scenario.cashCents.value, 1000);
    expect(find.byType(LedgerScreen), findsNothing);
    expect(find.text('Not enough funds').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
