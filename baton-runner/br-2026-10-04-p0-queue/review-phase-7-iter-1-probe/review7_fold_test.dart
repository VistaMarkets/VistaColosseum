// Phase 7 review probe: where the record panel lands on small phones.
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vista_colosseum/features/profile/profile_screen.dart';
import 'package:vista_colosseum/features/settings/settings_state.dart';
import 'package:vista_colosseum/scenario/scenario.dart';
import 'home_screen_test.dart' show phones;
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
  setUp(() { Scenario.reset(); SettingsState.reset(); });
  testWidgets('P8 panel position on landing', (t) async {
    for (final scale in [1.0, 1.3]) {
      t.platformDispatcher.textScaleFactorTestValue = scale;
      for (final name in phones.keys) {
        final (size, padding) = phones[name]!;
        await pumpApp(t, home: const ProfileScreen(handle: 'kilo.sol'), size: size, padding: padding);
        final cap = find.textContaining('Illustrative index');
        final top = cap.evaluate().isEmpty ? null : t.getRect(cap).top;
        debugPrint('PROBE x$scale $name screenH=${size.height} caption.top=$top onScreen=${top != null && top < size.height - 30}');
      }
    }
    t.platformDispatcher.clearTextScaleFactorTestValue();
  });
}
