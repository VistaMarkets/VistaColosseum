// Review-only probe 2 (architect-reviewer): feed amount length vs layout overflow.
// ignore_for_file: avoid_print
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vista_colosseum/design_system/design_system.dart';
import 'package:vista_colosseum/features/account/account_state.dart';
import 'package:vista_colosseum/features/settings/settings_state.dart';
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
  setUp(() {
    Scenario.reset();
    AccountState.listMarket('MAYA');
    SettingsState.reset();
  });
  for (final n in [6, 7, 8, 9, 10, 11, 12, 13]) {
    testWidgets('feed amount of $n nines', (t) async {
      t.view
        ..physicalSize = const Size(402, 874) * 3
        ..devicePixelRatio = 3;
      addTearDown(t.view.reset);
      await t.pumpWidget(const VistaColosseumApp());
      await t.pumpAndSettle();
      await t.tap(find.widgetWithText(VistaPillButton, 'Long').first);
      await t.pumpAndSettle();
      await t.enterText(find.widgetWithText(TextField, '200'), '9' * n);
      await t.pumpAndSettle();
      final ex = t.takeException();
      print('ARCH2 nines=$n exception=${ex == null ? 'none' : 'overflow'}');
    });
  }
}
