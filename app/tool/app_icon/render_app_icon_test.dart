// Renders the app icon master (1024×1024, full bleed) from the Figma layers
// of "Frame 1597880576" (201:1939, a 226×226 frame). Run from app/:
//
//   flutter test tool/app_icon/render_app_icon_test.dart
//   python3 tool/app_icon/make_icons.py
//
// The frame's 50px corner radius is dropped: iOS and Android apply their own
// icon masks and need a square, opaque source.
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

const _frame = 226.0;
const _out = 1024.0;
const _dir = 'tool/app_icon';

/// CSS `linear-gradient(138.74deg, #6CB4EA 0.79%, #5AA6DE 99.21%)` on a
/// square: the gradient line runs along the angle's direction and spans
/// |sin θ| + |cos θ| half-widths either side of the centre.
LinearGradient _background() {
  const deg = 138.74539430043427;
  final t = deg * math.pi / 180;
  final dx = math.sin(t), dy = -math.cos(t);
  final reach = dx.abs() + dy.abs();
  return LinearGradient(
    begin: Alignment(-dx * reach, -dy * reach),
    end: Alignment(dx * reach, dy * reach),
    colors: const [Color(0xFF6CB4EA), Color(0xFF5AA6DE)],
    stops: const [0.0078557, 0.99214],
  );
}

/// Figma "Ellipse 16" (light, top left) and "Ellipse 17" (dark, bottom
/// right), each with a layer blur. The export uses an SVG filter flutter_svg
/// cannot draw, so they are painted here. Figma blur radius = 2σ.
class _Glow extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / _frame;
    for (final (centre, radius, colour, sigma) in const [
      (Offset(30, 30), 83.0, Color(0xFFABD6F6), 25.75),
      (Offset(213, 214), 100.0, Color(0xFF326F9D), 57.55),
    ]) {
      // An image filter, not a mask filter: MaskFilter.blur stops growing
      // past σ ≈ 200px, which both glows exceed at 1024px.
      canvas
        ..saveLayer(
          null,
          Paint()
            ..imageFilter = ui.ImageFilter.blur(
              sigmaX: sigma * s,
              sigmaY: sigma * s,
              tileMode: TileMode.decal,
            ),
        )
        ..drawCircle(centre * s, radius * s, Paint()..color = colour)
        ..restore();
    }
  }

  @override
  bool shouldRepaint(_Glow old) => false;
}

void main() {
  testWidgets('render app icon', (tester) async {
    tester.view
      ..physicalSize = const Size(_out, _out)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    const s = _out / _frame;
    final fill = File('$_dir/mark_fill.svg').readAsStringSync();
    final key = GlobalKey();

    await tester.runAsync(() async {
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Container(
              width: _out,
              height: _out,
              decoration: BoxDecoration(gradient: _background()),
              child: Stack(
                children: [
                  Positioned.fill(child: CustomPaint(painter: _Glow())),
                  // Mark shadow: #3C7DAC, offset (−6, 6), blur 8.9 (σ 4.45).
                  Positioned(
                    left: (39 - 6) * s,
                    top: (48 + 6) * s,
                    width: 148.999 * s,
                    height: 130.375 * s,
                    child: ImageFiltered(
                      imageFilter: ui.ImageFilter.blur(
                        sigmaX: 4.45 * s,
                        sigmaY: 4.45 * s,
                        tileMode: TileMode.decal,
                      ),
                      child: SvgPicture.string(
                        fill,
                        fit: BoxFit.fill,
                        colorFilter: const ColorFilter.mode(
                          Color(0xFF3C7DAC),
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                  // Mark: 149×130.4 at (39, 48), solid white.
                  Positioned(
                    left: 39 * s,
                    top: 48 * s,
                    width: 148.999 * s,
                    height: 130.375 * s,
                    child: SvgPicture.string(fill, fit: BoxFit.fill),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      for (var i = 0; i < 5; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await tester.pump();
      }
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage();
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$_dir/app_icon_1024.png')
          .writeAsBytesSync(png!.buffer.asUint8List());
    });
  });
}
