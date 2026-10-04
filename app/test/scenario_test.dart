import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vista_colosseum/features/account/account_state.dart';
import 'package:vista_colosseum/features/home/likes_state.dart';
import 'package:vista_colosseum/features/home/mock_trade_idea.dart';
import 'package:vista_colosseum/features/portfolio/orders_state.dart';
import 'package:vista_colosseum/features/portfolio/portfolio_mock.dart';
import 'package:vista_colosseum/features/settings/settings_screen.dart';
import 'package:vista_colosseum/features/watchlist/watchlist_state.dart';
import 'package:vista_colosseum/main.dart';
import 'package:vista_colosseum/scenario/scenario.dart';

/// Every value the store holds, in a fixed order, for deep comparison.
/// A field added to [Scenario] must be added here and to [mutateEverything].
List<Object?> state() => [
  Scenario.cashCents.value,
  Scenario.positions.value,
  Scenario.openOrders.value,
  Scenario.hasMarket.value,
  Scenario.ticker.value,
  Scenario.marketId.value,
  Scenario.liked.value,
  Scenario.favoriteAssets.value,
  Scenario.favoriteTraders.value,
  Scenario.followers.value,
  Scenario.following.value,
  Scenario.followed.value,
  Scenario.clock.value,
];

/// Changes every field, through the app's own helpers where they exist.
void mutateEverything() {
  Scenario.cashCents.value -= 1000;
  Scenario.positions.value = Scenario.positions.value.sublist(1);
  OrdersState.remove(OrdersState.open.value.first);
  AccountState.listMarket('ZED');
  LikesState.toggle(mockFeed.first);
  WatchlistState.toggleAsset('ZED');
  WatchlistState.toggleTrader('zed');
  Scenario.followers.value = const [];
  Scenario.following.value = const [];
  Scenario.followed.value = {...Scenario.followed.value, 'zed'};
  Scenario.clock.value = Scenario.clock.value.add(const Duration(hours: 1));
}

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

  // Read before any test touches the store: the values the app starts with.
  final seed = state();

  setUp(Scenario.reset);

  test('seed → mutate everything → reset equals the fresh seed', () {
    mutateEverything();
    final mutated = state();
    for (var i = 0; i < seed.length; i++) {
      expect(mutated[i], isNot(equals(seed[i])), reason: 'field $i unchanged');
    }
    Scenario.reset();
    expect(state(), equals(seed));
  });

  test('reset twice yields equal state', () {
    mutateEverything();
    Scenario.reset();
    final once = state();
    Scenario.reset();
    expect(state(), equals(once));
    expect(once, equals(seed));
  });

  testWidgets('Reset demo in Settings restores the fixture and says so', (
    tester,
  ) async {
    mutateEverything();
    await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Reset demo'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Reset demo'));
    await tester.pump();
    expect(find.text('Demo reset to fixture-v1'), findsOneWidget);
    expect(state(), equals(seed));
  });

  testWidgets('Wallet lists the positions held in Scenario', (tester) async {
    tester.view
      ..physicalSize = const Size(402, 874) * 3
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    Scenario.positions.value = [PortfolioMock.positions.last];
    await tester.pumpWidget(const VistaColosseumApp());
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Wallet'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Positions · '), findsOneWidget);
    expect(find.text('Positions · 1'), findsOneWidget);
    expect(find.text('Ethereum'), findsNothing);
  });
}
