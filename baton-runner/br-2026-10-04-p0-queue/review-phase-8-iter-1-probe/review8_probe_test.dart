// Phase 8 review probe (throwaway copy only): every reachable route with an
// emptied scenario on the two small phones at 1.3x; no exception/overflow.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vista_colosseum/app_shell.dart';
import 'package:vista_colosseum/features/arena/arena_mock.dart';
import 'package:vista_colosseum/features/arena/opinions_screen.dart';
import 'package:vista_colosseum/features/market/trader_market_screen.dart';
import 'package:vista_colosseum/features/market/your_market_screen.dart';
import 'package:vista_colosseum/features/profile/private_profile_screen.dart';
import 'package:vista_colosseum/features/profile/profile_screen.dart';
import 'package:vista_colosseum/features/settings/settings_screen.dart';
import 'package:vista_colosseum/features/settings/settings_state.dart';
import 'package:vista_colosseum/features/trade/asset_trade_screen.dart';
import 'package:vista_colosseum/features/watchlist/edit_favorites_screen.dart';
import 'package:vista_colosseum/scenario/scenario.dart';

import 'empty_states_test.dart' show emptyScenario, small;
import 'trader_record_test.dart' show pumpApp;

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
    Scenario.reset(withMarket: true);
    SettingsState.reset();
  });
  final screens = <String, Widget? Function()>{
    'tab0 Home': () => null,
    'tab1 Explore (empty favourites)': () => null,
    'tab2 Arena': () => null,
    'tab3 Wallet': () => null,
    'AssetTrade BTC': () => const AssetTradeScreen(ticker: 'BTC'),
    'TraderMarket kilo.sol': () => const TraderMarketScreen(handle: 'kilo.sol'),
    'YourMarket': () => const YourMarketScreen(),
    'Opinions btc': () => OpinionsScreen(battle: ArenaMock.battles.first),
    'EditFavorites assets': () => const EditFavoritesScreen(traders: false),
    'EditFavorites traders': () => const EditFavoritesScreen(traders: true),
    'Profile maya.eth': () => const ProfileScreen(handle: 'maya.eth'),
    'PrivateProfile nara': () => const PrivateProfileScreen(handle: 'nara'),
    'Settings': () => const SettingsScreen(),
  };
  final tabs = {'tab0 Home': 0, 'tab1 Explore (empty favourites)': 1, 'tab2 Arena': 2, 'tab3 Wallet': 3};
  for (final MapEntry(key: phone, value: (size, padding)) in small.entries) {
    for (final MapEntry(key: name, value: build) in screens.entries) {
      testWidgets('PROBE $phone 1.3x emptied: $name', (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = 1.3;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        emptyScenario();
        await pumpApp(tester, home: build(), size: size, padding: padding);
        if (tabs[name] != null) {
          AppShell.tab.value = tabs[name]!;
          await tester.pumpAndSettle();
        }
        final lists = find.byWidgetPredicate(
          (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
        );
        if (lists.evaluate().isNotEmpty) {
          await tester.drag(lists.first, const Offset(0, -3000));
          await tester.pumpAndSettle();
        }
        expect(tester.takeException(), isNull);
      });
    }
  }
}
