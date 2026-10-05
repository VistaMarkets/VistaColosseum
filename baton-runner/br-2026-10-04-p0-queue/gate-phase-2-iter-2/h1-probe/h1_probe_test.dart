// Review-only probe (phase 2 review iter 2): drives every trader-market
// route by hand and asserts the store is untouched. Not part of the suite.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vista_colosseum/app_shell.dart';
import 'package:vista_colosseum/design_system/design_system.dart';
import 'package:vista_colosseum/features/account/account_state.dart';
import 'package:vista_colosseum/features/home/mock_trade_idea.dart';
import 'package:vista_colosseum/features/market/trader_market_screen.dart';
import 'package:vista_colosseum/features/profile/profile_screen.dart';
import 'package:vista_colosseum/features/settings/settings_state.dart';
import 'package:vista_colosseum/features/trade/order_ticket.dart';
import 'package:vista_colosseum/main.dart';
import 'package:vista_colosseum/scenario/scenario.dart';

import '../../../../app/test/scenario_test.dart' show state;

const toast = 'Trader-index ticket — not in the demo yet';

Future<void> app(WidgetTester t) async {
  t.view
    ..physicalSize = const Size(402, 874) * 3
    ..devicePixelRatio = 3;
  addTearDown(t.view.reset);
  await t.pumpWidget(const VistaColosseumApp());
  await t.pumpAndSettle();
}

Finder inSheet(Finder f) =>
    find.descendant(of: find.byType(BottomSheet), matching: f);

/// On a trader market page: Long, then [tab], then Place. Asserts the toast,
/// the ticket closed and nothing changed.
Future<void> placeOnTraderPage(WidgetTester t, String tab, Object before) async {
  expect(find.byType(TraderMarketScreen), findsOneWidget);
  await t.tap(find.text('Long').hitTestable().last);
  await t.pumpAndSettle();
  expect(find.byType(OrderTicket), findsOneWidget, reason: tab);
  if (tab != 'Market') {
    await t.tap(inSheet(find.text(tab)));
    await t.pumpAndSettle();
  }
  final place = find.textContaining('Place ');
  expect(place, findsOneWidget, reason: '$tab: place button');
  await t.tap(place);
  await t.pumpAndSettle();
  expect(find.text(toast), findsOneWidget, reason: tab);
  expect(find.byType(OrderTicket), findsNothing, reason: tab);
  expect(state(), equals(before), reason: tab);
  // let the toast go
  await t.pump(const Duration(seconds: 6));
  await t.pumpAndSettle();
}

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

  for (final handle in mockFeed.where((i) => i.traderMarket).map((i) => i.ticker)) {
    testWidgets('Home card $handle: feed ticket call side x Market/Limit refused', (t) async {
      await app(t);
      final before = state();
      final feed = t.widget<PageView>(find.byType(PageView).first);
      feed.controller!.jumpToPage(mockFeed.indexWhere((i) => i.ticker == handle));
      await t.pumpAndSettle();
      final side = mockFeed.firstWhere((i) => i.ticker == handle).side.label;
      for (final tab in ['Market', 'Limit']) {
        await t.tap(find.widgetWithText(VistaPillButton, side).hitTestable().first);
        await t.pumpAndSettle();
        await t.tap(inSheet(find.text(tab)));
        await t.pumpAndSettle();
        final btn = inSheet(find.textContaining('$side \$'));
        expect(btn, findsOneWidget, reason: '$handle $side $tab button');
        await t.tap(btn);
        await t.pumpAndSettle();
        expect(find.text(toast), findsOneWidget, reason: '$handle $side $tab');
        expect(find.byType(FeedOrderTicket), findsNothing, reason: '$handle $side $tab');
        expect(state(), equals(before), reason: '$handle $side $tab');
        await t.pump(const Duration(seconds: 6));
        await t.pumpAndSettle();
      }
    });
  }

  testWidgets('Home card maya.eth -> Details (trader page) Market/Limit/Stop refused', (t) async {
    await app(t);
    final before = state();
    final feed = t.widget<PageView>(find.byType(PageView).first);
    feed.controller!.jumpToPage(mockFeed.indexWhere((i) => i.ticker == 'maya.eth'));
    await t.pumpAndSettle();
    await t.tap(find.text('Details').hitTestable());
    await t.pumpAndSettle();
    for (final tab in ['Market', 'Limit', 'Stop']) {
      await placeOnTraderPage(t, tab, before);
    }
  });

  testWidgets('Arena -> caller maya.eth -> Profile -> Market page refused', (t) async {
    await app(t);
    final before = state();
    AppShell.tab.value = 2; // the Arena tab (nav labels are icons in tests)
    await t.pumpAndSettle();
    await t.tap(find.text('maya.eth').hitTestable().first);
    await t.pumpAndSettle();
    expect(find.byType(ProfileScreen), findsOneWidget);
    await t.tap(find.text('Market').hitTestable().first);
    await t.pumpAndSettle();
    for (final tab in ['Market', 'Limit']) {
      await placeOnTraderPage(t, tab, before);
    }
  });

  test('store refuses every trader handle on every kind', () {
    final before = state();
    for (final h in mockFeed.where((i) => i.traderMarket).map((i) => i.ticker)) {
      for (final k in OrderKind.values) {
        final r = Scenario.placeOrder(OrderIntent(
          actionId: 'probe-$h-$k', symbol: h, name: h, side: TradeSide.long,
          units: 10, price: 1, leverage: 2, kind: k, icon: VistaAssets.navHome,
        ));
        expect(r, isA<OrderFailed>(), reason: '$h $k');
      }
    }
    expect(state(), equals(before));
  });
}
