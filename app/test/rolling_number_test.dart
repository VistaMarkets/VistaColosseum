import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vista_colosseum/design_system/design_system.dart';

/// Figma 108:125 ("Live number · B — rolling digits"): $12,480 → $12,486.
void main() {
  Widget host(String text, {bool reduceMotion = false}) => MediaQuery(
    data: MediaQueryData(disableAnimations: reduceMotion),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: Center(child: VistaRollingNumber(text, style: VistaType.display)),
    ),
  );

  Color? colorOf(WidgetTester tester, String char) =>
      tester.widget<Text>(find.text(char).last).style?.color;

  testWidgets('a rise rolls only the changed digit up, in green', (
    tester,
  ) async {
    await tester.pumpWidget(host(r'$12,480'));
    expect(find.text(r'$12,480'), findsOneWidget);

    await tester.pumpWidget(host(r'$12,486'));
    await tester.pump(const Duration(milliseconds: 120));
    // Mid-roll: the old 0 and the new 6 share the last digit's window;
    // unchanged characters are single cells.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('6'), findsWidgets);
    expect(colorOf(tester, '6'), VistaColors.long);
    expect(find.text('1'), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text(r'$12,486'), findsOneWidget);
    expect(
      tester.widget<Text>(find.text(r'$12,486')).style?.color,
      VistaColors.textPrimary,
    );
  });

  testWidgets('a fall rolls in pink', (tester) async {
    await tester.pumpWidget(host(r'$12,486'));
    await tester.pumpWidget(host(r'$12,481'));
    await tester.pump(const Duration(milliseconds: 120));
    expect(colorOf(tester, '1'), VistaColors.short);
    await tester.pumpAndSettle();
    expect(find.text(r'$12,481'), findsOneWidget);
  });

  testWidgets('reduced motion swaps the value without rolling', (tester) async {
    await tester.pumpWidget(host(r'$12,480', reduceMotion: true));
    await tester.pumpWidget(host(r'$12,486', reduceMotion: true));
    await tester.pump();
    expect(find.text(r'$12,486'), findsOneWidget);
    expect(find.text('0'), findsNothing);
  });
}
