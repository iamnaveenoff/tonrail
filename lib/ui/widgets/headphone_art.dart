import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Front view of a pair of over-ear headphones, drawn as matte anthracite
/// hardware. [connected] lights the status LED and brings the object forward;
/// offline it rests dimmed. A generic drawing, not any real product's design.
class HeadphoneArt extends StatelessWidget {
  const HeadphoneArt({super.key, required this.connected, this.charging = false, this.width = 160});
  final bool connected;
  final bool charging;
  final double width;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final reduce = MediaQuery.of(context).disableAnimations;
    return Semantics(
      image: true,
      label: connected ? 'Headphones connected' : 'Headphones not connected',
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: connected ? 1 : 0),
        duration: reduce ? Duration.zero : const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
        builder: (context, v, _) => CustomPaint(
          size: Size(width, width * 0.92),
          painter: _HeadphonePainter(
            lit: v,
            charging: charging,
            dark: s.brightness == Brightness.dark,
            led: s.tertiary,
            accent: s.primary,
          ),
        ),
      ),
    );
  }
}

class _HeadphonePainter extends CustomPainter {
  _HeadphonePainter({
    required this.lit,
    required this.charging,
    required this.dark,
    required this.led,
    required this.accent,
  });

  final double lit;
  final bool charging;
  final bool dark;
  final Color led;
  final Color accent;

  static const shell = Color(0xFF2B2B29);
  static const shellHi = Color(0xFF3B3A37);
  static const shellLo = Color(0xFF1A1A19);
  static const cushion = Color(0xFF121211);
  static const metal = Color(0xFF8E8A82);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    // Offline the object recedes: lower contrast, slightly smaller.
    final k = 0.94 + 0.06 * lit;
    canvas.save();
    canvas.translate(w / 2, h / 2);
    canvas.scale(k);
    canvas.translate(-w / 2, -h / 2);
    final fade = 0.5 + 0.5 * lit;

    Color c(Color x) => Color.lerp(dark ? const Color(0xFF242423) : const Color(0xFFBDB9B1), x, fade)!;

    // Ground shadow.
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w / 2, h * 0.97), width: w * 0.78, height: h * 0.07),
      Paint()
        ..color = Colors.black.withValues(alpha: (dark ? 0.55 : 0.18) * fade)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    final cupW = w * 0.26;
    final cupH = h * 0.52;
    final cupTop = h * 0.40;
    final leftCx = w * 0.20;
    final rightCx = w * 0.80;

    // Headband: a thick arc with a padded underside.
    final bandRect = Rect.fromLTRB(w * 0.13, h * 0.02, w * 0.87, h * 0.92);
    final band = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = w * 0.075
      ..color = c(shell);
    canvas.drawArc(bandRect, math.pi * 1.06, math.pi * 0.88, false, band);
    canvas.drawArc(
      bandRect.deflate(w * 0.03),
      math.pi * 1.12,
      math.pi * 0.76,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = w * 0.035
        ..color = c(cushion),
    );
    // Highlight along the top of the band.
    canvas.drawArc(
      bandRect.inflate(w * 0.02),
      math.pi * 1.25,
      math.pi * 0.5,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 1.4
        ..color = c(shellHi).withValues(alpha: 0.9),
    );

    // Metal sliders from band to yokes.
    final slider = Paint()
      ..strokeWidth = w * 0.022
      ..strokeCap = StrokeCap.round
      ..color = c(metal);
    canvas.drawLine(Offset(leftCx + cupW * 0.05, h * 0.30), Offset(leftCx + cupW * 0.05, cupTop + cupH * 0.08), slider);
    canvas.drawLine(
      Offset(rightCx - cupW * 0.05, h * 0.30),
      Offset(rightCx - cupW * 0.05, cupTop + cupH * 0.08),
      slider,
    );

    void cup(double cx, {required bool right}) {
      final outer = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cupTop + cupH / 2), width: cupW, height: cupH),
        Radius.circular(cupW * 0.48),
      );
      // Cushion peeking out on the inner side.
      final cush = outer.shift(Offset(right ? -cupW * 0.14 : cupW * 0.14, 0)).deflate(cupW * 0.04);
      canvas.drawRRect(cush, Paint()..color = c(cushion));
      canvas.drawRRect(outer, Paint()..color = c(shell));
      canvas.drawRRect(
        outer.deflate(0.6),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = c(shellHi),
      );
      // Inner plate with perforated grille.
      final plate = outer.deflate(cupW * 0.16);
      canvas.drawRRect(plate, Paint()..color = c(shellLo));
      canvas.save();
      canvas.clipRRect(plate.deflate(cupW * 0.06));
      final dot = Paint()..color = c(const Color(0xFF4A4945));
      final pitch = cupW * 0.105;
      for (var y = plate.top; y < plate.bottom; y += pitch) {
        for (var x = plate.left; x < plate.right; x += pitch) {
          canvas.drawCircle(Offset(x + pitch / 2, y + pitch / 2), pitch * 0.2, dot);
        }
      }
      canvas.restore();

      if (right) {
        // Multifunction button on the right cup, lit in the accent when connected.
        final btn = Offset(cx + cupW * 0.5 - 1, cupTop + cupH * 0.5);
        canvas.drawCircle(btn, cupW * 0.07, Paint()..color = Color.lerp(c(metal), accent, lit)!);
        for (final dy in [-1, 1]) {
          canvas.drawCircle(btn + Offset(0, dy * cupH * 0.17), cupW * 0.05, Paint()..color = c(metal));
        }
      } else {
        // Status LED: green when the control link runs.
        final ledAt = Offset(cx, cupTop + cupH * 0.86);
        if (lit > 0.01) {
          canvas.drawCircle(
            ledAt,
            cupW * 0.14 * lit,
            Paint()
              ..color = led.withValues(alpha: 0.35 * lit)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
          );
        }
        canvas.drawCircle(ledAt, cupW * 0.045, Paint()..color = Color.lerp(c(const Color(0xFF55534E)), led, lit)!);
      }
    }

    cup(leftCx, right: false);
    cup(rightCx, right: true);

    if (charging) {
      final tp = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(Icons.bolt_rounded.codePoint),
          style: TextStyle(fontFamily: Icons.bolt_rounded.fontFamily, fontSize: w * 0.12, color: led),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(w / 2 - tp.width / 2, h * 0.52));
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_HeadphonePainter o) =>
      o.lit != lit || o.charging != charging || o.dark != dark || o.led != led || o.accent != accent;
}
