// Review iter 2 probe (read-only evidence, not part of the suite).
// Make-a-market step 1 at 1.3x on 360x640 / 375x667: report every Flutter
// error with its creation location. Uses no phase-3 API, so it also runs on a
// main (pre-pill) copy for a baseline.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vista_colosseum/features/account/account_state.dart';
import 'package:vista_colosseum/features/settings/settings_state.dart';
import 'package:vista_colosseum/main.dart';
import 'package:vista_colosseum/scenario/scenario.dart';

const phones = <String, (Size, EdgeInsets)>{
  '360x640': (Size(360, 640), EdgeInsets.only(top: 24)),
  '375x667': (Size(375, 667), EdgeInsets.only(top: 20)),
};

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
  for (final scale in [1.0, 1.3]) {
    for (final MapEntry(key: name, value: (size, pad)) in phones.entries) {
      testWidgets('MM probe step 1 @${scale}x $name', (t) async {
        Scenario.reset(withMarket: false);
        t.view
          ..physicalSize = size * 3
          ..devicePixelRatio = 3
          ..padding = FakeViewPadding(top: pad.top * 3, bottom: pad.bottom * 3)
          ..viewPadding =
              FakeViewPadding(top: pad.top * 3, bottom: pad.bottom * 3);
        t.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(t.view.reset);
        addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
        final errors = <FlutterErrorDetails>[];
        final old = FlutterError.onError;
        FlutterError.onError = errors.add;
        await t.pumpWidget(const VistaColosseumApp());
        await t.pumpAndSettle();
        await t.tap(find.bySemanticsLabel('Wallet'));
        await t.pumpAndSettle();
        await t.tap(find.bySemanticsLabel('Make a market'));
        await t.pumpAndSettle();
        FlutterError.onError = old;
        for (final e in errors) {
          final s = e.toString();
          final loc = RegExp(r'file:///\S+:\d+:\d+').allMatches(s)
              .map((m) => m.group(0)!.split('/lib/').last)
              .toSet();
          // ignore: avoid_print
          print('MM @$scale $name ERROR ${e.exceptionAsString()} at $loc');
        }
        // ignore: avoid_print
        print('MM @$scale $name errors=${errors.length}');
      });
    }
  }
}
