import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../widgets/panel.dart';

/// The app mark: a perforated grille tile with one orange power dot.
/// [progress] draws the grille in from the centre (used by the splash).
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 48, this.progress = 1});
  final double size;
  final double progress;

  static const tile = Color(0xFF1C1C1B);
  static const edge = Color(0xFF3A3936);
  static const dot = Color(0xFF8E8A82);
  static const power = Color(0xFFEE6A24);

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Tonrail',
    image: true,
    child: CustomPaint(size: Size.square(size), painter: _MarkPainter(progress)),
  );
}

class _MarkPainter extends CustomPainter {
  _MarkPainter(this.p);
  final double p;

  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(size.width * 0.24));
    canvas.drawRRect(r, Paint()..color = BrandMark.tile);
    canvas.drawRRect(
      r.deflate(0.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = BrandMark.edge,
    );

    final c = size.center(Offset.zero);
    final pitch = size.width * 0.15;
    final dr = size.width * 0.034;
    for (var y = -2; y <= 2; y++) {
      for (var x = -2; x <= 2; x++) {
        final d2 = x * x + y * y;
        if (d2 > 5) continue;
        final o = c + Offset(x * pitch, y * pitch);
        if (d2 == 0) {
          final k = Curves.easeOutBack.transform(((p - 0.55) / 0.45).clamp(0.0, 1.0));
          if (k > 0) canvas.drawCircle(o, dr * 1.9 * k, Paint()..color = BrandMark.power);
          continue;
        }
        // Each ring of dots lands slightly after the one inside it.
        final start = math.sqrt(d2) / math.sqrt(5) * 0.45;
        final k = Curves.easeOutCubic.transform(((p - start) / 0.3).clamp(0.0, 1.0));
        if (k <= 0) continue;
        canvas.drawCircle(o, dr * k, Paint()..color = BrandMark.dot.withValues(alpha: k));
      }
    }
  }

  @override
  bool shouldRepaint(_MarkPainter o) => o.p != p;
}

/// Launch screen: the grille draws in, the power dot lights, the name settles.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onDone});
  final VoidCallback onDone;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _c.addStatusListener((st) {
      if (st == AnimationStatus.completed) widget.onDone();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.of(context).disableAnimations) {
      _c.value = 0.999;
      Future<void>.delayed(const Duration(milliseconds: 450), () {
        if (mounted) widget.onDone();
      });
    } else {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return ColoredBox(
      color: s.surface,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final v = _c.value;
          final mark = (v / 0.62).clamp(0.0, 1.0);
          final word = Curves.easeOutQuart.transform(((v - 0.42) / 0.38).clamp(0.0, 1.0));
          return Stack(
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    BrandMark(size: 112, progress: mark),
                    const SizedBox(height: 28),
                    Opacity(
                      opacity: word,
                      child: Transform.translate(
                        offset: Offset(0, 10 * (1 - word)),
                        child: Column(
                          children: [
                            Text('Tonrail', style: t.headlineSmall),
                            const SizedBox(height: 8),
                            const Legend('Headphone control'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 32 + MediaQuery.of(context).padding.bottom,
                child: Opacity(
                  opacity: word,
                  child: const Legend('Independent app', textAlign: TextAlign.center),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
