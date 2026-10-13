import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vista_colosseum/app_shell.dart';
import 'package:vista_colosseum/features/account/account_state.dart';
import 'package:vista_colosseum/features/home/home_screen.dart';
import 'package:vista_colosseum/features/live/live_feed.dart';
import 'package:vista_colosseum/features/settings/settings_state.dart';
import 'package:vista_colosseum/main.dart';
import 'package:vista_colosseum/scenario/scenario.dart';

final pill = RegExp(r'^Simulated · fixture-v1');

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

Future<void> launch(WidgetTester tester, Size size, {required bool web}) async {
  tester.view
    ..physicalSize = size * 2
    ..devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(VistaColosseumApp(web: web));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(_loadFonts);
  setUp(() {
    Scenario.reset();
    AccountState.listMarket('MAYA');
    SettingsState.reset();
    AppShell.tab.value = 0;
  });

  testWidgets('the web frame is phone-wide and hints once', (tester) async {
    await launch(tester, const Size(1280, 800), web: true);
    expect(tester.getSize(find.byType(HomeScreen)).width, 390);
    final badge = tester.getRect(find.bySemanticsLabel(pill));
    expect(badge.left, greaterThanOrEqualTo(445));
    expect(badge.right, lessThanOrEqualTo(835));

    final toast = find.text(kLaunchHint);
    expect(toast.hitTestable(), findsOneWidget);
    expect(tester.getRect(find.byType(SnackBar)).overlaps(badge), isFalse);
    expect(tester.takeException(), isNull);

    await tester.pump(const Duration(seconds: 9));
    await tester.pumpAndSettle();
    expect(toast, findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('off the web there is no frame and no hint', (tester) async {
    await launch(tester, const Size(390, 844), web: false);
    expect(tester.getSize(find.byType(HomeScreen)).width, 390);
    expect(find.text(kLaunchHint), findsNothing);
    expect(find.byType(SnackBar), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test('the live feed stays off under test', () {
    expect(LiveFeed.enabled, isFalse);
  });
}
