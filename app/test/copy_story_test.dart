import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vista_colosseum/design_system/design_system.dart';
import 'package:vista_colosseum/features/account/account_state.dart';
import 'package:vista_colosseum/features/live/live_feed.dart';
import 'package:vista_colosseum/features/market/market_mock.dart';
import 'package:vista_colosseum/features/market/receipt_screens.dart';
import 'package:vista_colosseum/features/portfolio/portfolio_mock.dart';
import 'package:vista_colosseum/features/settings/settings_state.dart';
import 'package:vista_colosseum/features/trade/order_ticket.dart';
import 'package:vista_colosseum/main.dart';
import 'package:vista_colosseum/scenario/scenario.dart';

import 'order_ticket_test.dart' show homeCard, inSheet;
import 'receipts_test.dart' show pumpApp;
import 'scenario_test.dart' show ethLong, state;

/// A long on ETH copied from [author]'s call: a market order at 10x unless
/// told otherwise.
OrderIntent copyOf(
  String actionId, {
  String author = PortfolioMock.handle,
  double units = 0.12345,
  int lev = 10,
  OrderKind kind = OrderKind.market,
}) => OrderIntent(
  actionId: actionId,
  symbol: 'ETH',
  name: 'Ethereum',
  side: TradeSide.long,
  units: units,
  price: 2968.40,
  leverage: lev,
  kind: kind,
  sourceCallId: '$author/ETH',
  sourceAuthorHandle: author,
);

List<FeeEntry> get copyRows => Scenario.copyFees;

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

  test('confirming a copied order debits the copy fee once and credits the '
      'creator once', () {
    Scenario.switchPersona();
    expect(Scenario.activePersona.value, Persona.copier);
    final intent = copyOf('c1');
    final result = Scenario.placeOrder(intent);

    expect(result, isA<OrderFilled>());
    final receipt = (result as OrderFilled).receipt;
    expect(receipt.copyFeeCents, kCopyFeeCents);
    expect(kCopyFeeCents, 500);
    expect(
      Scenario.cashCents.value,
      PortfolioMock.copierCashCents -
          intent.marginCents -
          intent.feeCents -
          500,
    );
    expect(receipt.totalCents, intent.marginCents + intent.feeCents + 500);
    expect(Scenario.positions.value, hasLength(1));
    expect(Scenario.receipts.value.single.sourceCallId, 'maya.eth/ETH');

    final row = copyRows.single;
    expect(row.amountCents, 500);
    expect(row.sourceCallId, 'maya.eth/ETH');
    expect(row.counterparty, Persona.copier.handle);
    expect(row.asset, 'ETH');
    expect(
      Scenario.feeEntries.value,
      hasLength(YourMarketMock.fees.length + 1),
    );
    // A copy fee is not a market credit: the fresh MAYA listing still has
    // none, even though the row carries its ticker and the clock.
    expect(Scenario.marketFeesCents, 0);
    // The creator's own books are untouched by the copier's order.
    final creator = Scenario.booksOf(Persona.creator);
    expect(creator.cashCents, PortfolioMock.cashCents);
    expect(creator.receipts, isEmpty);
  });

  testWidgets('the ledger lists a copy fee in its copy section and counts it '
      'once in the total', (tester) async {
    Scenario.switchPersona();
    Scenario.placeOrder(copyOf('c7'));
    await pumpApp(tester, home: const LedgerScreen());
    expect(find.text('Copy fee · @sam.sol · ETH'), findsOneWidget);
    // The fresh MAYA listing has no market credit, so the Total is the copy
    // fee alone: the row and the Total both read $5.00.
    expect(Scenario.marketFeesCents, 0);
    expect(find.text(formatCents(500)), findsNWidgets(2));
  });

  testWidgets('cancelling a copied order writes nothing', (tester) async {
    Scenario.switchPersona();
    final before = state();
    await homeCard(tester, 'ETH');
    await tester.tap(
      find.widgetWithText(VistaPillButton, 'Long').hitTestable().first,
    );
    await tester.pumpAndSettle();
    await tester.tap(inSheet(find.text(r'Long $200 · 2x')));
    await tester.pumpAndSettle();
    expect(inSheet(find.text('Review order')), findsOneWidget);
    expect(
      inSheet(find.text(r'Copying @kaito.eth · $5.00 copy fee')),
      findsOneWidget,
    );
    expect(state(), equals(before)); // opening and review change nothing
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.byType(FeedOrderTicket), findsNothing);
    expect(state(), equals(before));
  });

  test('copy fails whole when cash cannot cover margin, fee and copy fee', () {
    Scenario.switchPersona();
    // Margin + fee fit the copier's cash; the copy fee on top does not.
    final intent = copyOf('c2', units: 999 / 2968.40, lev: 1);
    expect(intent.totalCents, lessThanOrEqualTo(PortfolioMock.copierCashCents));
    expect(
      intent.totalCents + kCopyFeeCents,
      greaterThan(PortfolioMock.copierCashCents),
    );
    final before = state();

    expect(Scenario.problem(intent), notEnoughFunds);
    final result = Scenario.placeOrder(intent);
    expect(result, isA<OrderFailed>());
    expect((result as OrderFailed).reason, notEnoughFunds);
    expect(Scenario.cashCents.value, PortfolioMock.copierCashCents);
    expect(Scenario.positions.value, isEmpty);
    expect(Scenario.receipts.value, isEmpty);
    expect(copyRows, isEmpty);
    expect(state(), equals(before));
  });

  test('repeated actionId on a copy does not double-pay', () {
    Scenario.switchPersona();
    final first = Scenario.placeOrder(copyOf('c3'));
    final cash = Scenario.cashCents.value;
    final again = Scenario.placeOrder(copyOf('c3'));

    expect(again, isA<OrderFilled>());
    expect(
      (again as OrderFilled).receipt,
      same((first as OrderFilled).receipt),
    );
    expect(Scenario.cashCents.value, cash);
    expect(Scenario.positions.value, hasLength(1));
    expect(Scenario.receipts.value, hasLength(1));
    expect(copyRows, hasLength(1));
  });

  test('own call places an ordinary order', () {
    expect(Scenario.activePersona.value, Persona.creator);
    final intent = copyOf('c4');
    final result = Scenario.placeOrder(intent);

    expect(result, isA<OrderFilled>());
    final receipt = (result as OrderFilled).receipt;
    expect(receipt.copyFeeCents, 0);
    expect(receipt.totalCents, intent.marginCents + intent.feeCents);
    expect(
      Scenario.cashCents.value,
      PortfolioMock.cashCents - intent.marginCents - intent.feeCents,
    );
    expect(copyRows, isEmpty);
    expect(Scenario.feeEntries.value, same(YourMarketMock.fees));
  });

  test('a resting copy writes no fee and no ledger row', () {
    Scenario.switchPersona();
    final result = Scenario.placeOrder(copyOf('c5', kind: OrderKind.limit));

    expect(result, isA<OrderResting>());
    expect(Scenario.openOrders.value, hasLength(1));
    expect(Scenario.cashCents.value, PortfolioMock.copierCashCents);
    expect(Scenario.receipts.value, isEmpty);
    expect(copyRows, isEmpty);
    expect(Scenario.feeEntries.value, same(YourMarketMock.fees));
  });

  test('a stale-price copy fails and writes nothing', () {
    Scenario.switchPersona();
    Scenario.stalePrices.value = const {'ETH'};
    final before = state();
    final result = Scenario.placeOrder(copyOf('c6'));

    expect(result, isA<OrderFailed>());
    expect((result as OrderFailed).reason, priceExpired);
    expect(copyRows, isEmpty);
    expect(state(), equals(before));
  });

  test('switch then reset restores creator and both seeds', () {
    // The creator trades, then hands over: her books stay as she left them.
    Scenario.placeOrder(copyOf('own', author: PortfolioMock.handle));
    final creatorCash = Scenario.cashCents.value;
    final creatorPositions = Scenario.positions.value;
    final creatorReceipts = Scenario.receipts.value;

    final beforeSwitch = state();
    Scenario.switchPersona();
    Scenario.switchPersona();
    // A round trip through the copier changes nothing at all.
    expect(state(), equals(beforeSwitch));

    Scenario.switchPersona();
    expect(Scenario.activePersona.value, Persona.copier);
    expect(Scenario.cashCents.value, PortfolioMock.copierCashCents);
    expect(Scenario.positions.value, isEmpty);
    expect(Scenario.openOrders.value, isEmpty);
    expect(Scenario.receipts.value, isEmpty);
    expect(Scenario.booksOf(Persona.creator).cashCents, creatorCash);

    Scenario.placeOrder(copyOf('copy'));
    final copierCash = Scenario.cashCents.value;
    Scenario.switchPersona();
    expect(Scenario.activePersona.value, Persona.creator);
    expect(Scenario.cashCents.value, creatorCash);
    expect(Scenario.positions.value, same(creatorPositions));
    expect(Scenario.receipts.value, same(creatorReceipts));
    expect(Scenario.booksOf(Persona.copier).cashCents, copierCash);
    expect(Scenario.booksOf(Persona.copier).positions, hasLength(1));

    Scenario.switchPersona();
    Scenario.reset();
    expect(Scenario.activePersona.value, Persona.creator);
    final creator = Scenario.booksOf(Persona.creator);
    expect(creator.cashCents, PortfolioMock.cashCents);
    expect(creator.positions, same(PortfolioMock.positions));
    expect(creator.openOrders, same(OpenOrdersMock.orders));
    expect(creator.receipts, isEmpty);
    final copier = Scenario.booksOf(Persona.copier);
    expect(copier.cashCents, PortfolioMock.copierCashCents);
    expect(copier.positions, isEmpty);
    expect(copier.openOrders, isEmpty);
    expect(copier.receipts, isEmpty);
    expect(Scenario.feeEntries.value, same(YourMarketMock.fees));
  });

  testWidgets('the Settings Demo persona row switches hands and says who is '
      'acting', (tester) async {
    tester.view
      ..physicalSize = const Size(402, 874) * 3
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const VistaColosseumApp());
    await tester.pumpAndSettle();
    // Settings is pushed over the shell from the Wallet gear, as in the app.
    await tester.tap(find.bySemanticsLabel('Wallet'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Settings'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Demo persona'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Creator'), findsOneWidget);
    final before = state();

    await tester.tap(find.text('Demo persona'));
    await tester.pumpAndSettle();
    // The toast names the persona the store now acts as, not the old one.
    expect(find.text('Now acting as sam.sol').hitTestable(), findsOneWidget);
    expect(Scenario.activePersona.value, Persona.copier);
    expect(find.text('Copier'), findsOneWidget);
    expect(Scenario.cashCents.value, PortfolioMock.copierCashCents);

    await tester.tap(find.text('Demo persona'));
    await tester.pumpAndSettle();
    expect(find.text('Now acting as maya.eth').hitTestable(), findsOneWidget);
    expect(Scenario.activePersona.value, Persona.creator);
    expect(find.text('Creator'), findsOneWidget);
    // A round trip through Settings changes nothing financial.
    expect(state(), equals(before));
  });

  test('participation follows the persona, as its receipts do', () {
    // The creator joins Bull on eth-4k; the copier never did.
    Scenario.placeOrder(ethLong('join', clashId: 'eth-4k'));
    expect(Scenario.participation.value, {'eth-4k': TradeSide.long});
    expect(Scenario.joins('eth-4k', TradeSide.long), 1);

    Scenario.switchPersona();
    expect(Scenario.participation.value, isEmpty);
    expect(Scenario.joins('eth-4k', TradeSide.long), 0);

    // The copier joins Bear on sol-200; back as the creator, her side stands.
    Scenario.placeOrder(
      OrderIntent(
        actionId: 'copier-join',
        symbol: 'SOL',
        name: 'Solana',
        side: TradeSide.short,
        units: 1,
        price: 150,
        leverage: 2,
        clashId: 'sol-200',
      ),
    );
    expect(Scenario.participation.value, {'sol-200': TradeSide.short});
    Scenario.switchPersona();
    expect(Scenario.participation.value, {'eth-4k': TradeSide.long});
    expect(Scenario.joins('eth-4k', TradeSide.long), 1);
    expect(Scenario.joins('sol-200', TradeSide.short), 0);
  });

  testWidgets('the receipts list shows the copy line on the copier\'s own '
      'paper receipt and no paper section under the creator', (tester) async {
    Scenario.switchPersona();
    expect(Scenario.placeOrder(copyOf('r1')), isA<OrderFilled>());
    final line = copyLine(PortfolioMock.handle, kCopyFeeCents);

    // The copier's own list: the paper section, with the copy line.
    await pumpApp(
      tester,
      home: const ReceiptsScreen(author: PortfolioMock.copierHandle),
    );
    expect(find.text('PAPER ORDER RECEIPTS'), findsOneWidget);
    expect(find.text(line), findsOneWidget);

    // The creator's list while the copier is active: her calls only, so
    // the copier's paper receipt never shows under maya.eth.
    await pumpApp(
      tester,
      home: const ReceiptsScreen(author: PortfolioMock.handle),
    );
    expect(find.text('PAPER ORDER RECEIPTS'), findsNothing);
    expect(find.text(line), findsNothing);
  });
}
