// Review-only probe: the Wallet headline is fixed; does its change line drift?
// ignore_for_file: avoid_print
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vista_colosseum/features/live/live_feed.dart';
import 'package:vista_colosseum/features/portfolio/portfolio_pager.dart';
import 'package:vista_colosseum/main.dart';
import 'package:vista_colosseum/scenario/scenario.dart';

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
  setUp(Scenario.reset);
  testWidgets('headline vs change line under a feed tick', (t) async {
    t.view
      ..physicalSize = const Size(402, 874) * 3
      ..devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(const VistaColosseumApp());
    await t.pumpAndSettle();
    await t.tap(find.bySemanticsLabel('Wallet'));
    await t.pumpAndSettle();
    List<String> pager() => t
        .widgetList<Text>(find.descendant(of: find.byType(PortfolioPager), matching: find.byType(Text)))
        .map((w) => w.data)
        .whereType<String>()
        .where((s) => s.contains(r'$'))
        .toList();
    print('CHG before=${pager()}');
    final feed = LiveFeed.watch('portfolio', Scenario.cashCents.value / 100, 9) as ValueNotifier<double>;
    for (var k = 0; k < 3; k++) {
      feed.value += 9;
      await t.pump();
      print('CHG tick${k + 1}=${pager()}');
    }
  });
}
