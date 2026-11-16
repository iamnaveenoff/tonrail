import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../protocol/commands.dart';

/// A perforated speaker grille that shows the noise mode: light rolls inward
/// and dots draw toward the core while cancelling, rolls outward while sound
/// is let in, and the grille rests when processing is off.
class NoiseField extends StatefulWidget {
  const NoiseField({super.key, required this.family, required this.active, required this.child});

  final NoiseFamily? family;
  final bool active;
  final Widget child;

  @override
  State<NoiseField> createState() => _NoiseFieldState();
}

class _NoiseFieldState extends State<NoiseField> with TickerProviderStateMixin {
  late final _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 3600));
  // Fades the lit layer when the mode changes so switches never snap.
  late final _shift = AnimationController(vsync: this, duration: const Duration(milliseconds: 520), value: 1);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(covariant NoiseField old) {
    super.didUpdateWidget(old);
    if (old.family != widget.family || old.active != widget.active) _shift.forward(from: 0);
    _sync();
  }

  void _sync() {
    final still =
        MediaQuery.of(context).disableAnimations ||
        !widget.active ||
        widget.family == NoiseFamily.off ||
        widget.family == null;
    if (still) {
      _ctrl.stop();
    } else if (!_ctrl.isAnimating) {
      _ctrl.repeat();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _shift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final still = MediaQuery.of(context).disableAnimations;
    return AspectRatio(
      aspectRatio: 1.25,
      child: LayoutBuilder(
        builder: (context, box) {
          final core = (math.min(box.maxWidth, box.maxHeight) * 0.5 - 2) * _GrillePainter.coreRatio;
          return RepaintBoundary(
            child: AnimatedBuilder(
              animation: Listenable.merge([_ctrl, _shift]),
              builder: (context, child) => CustomPaint(
                painter: _GrillePainter(
                  t: _ctrl.value,
                  fade: Curves.easeOutCubic.transform(_shift.value),
                  family: widget.active ? widget.family : null,
                  still: still,
                  base: s.outlineVariant,
                  rest: s.outline,
                  lit: s.primary,
                ),
                child: child,
              ),
              child: Center(
                child: SizedBox(width: core * 1.7, child: widget.child),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GrillePainter extends CustomPainter {
  _GrillePainter({
    required this.t,
    required this.fade,
    required this.family,
    required this.still,
    required this.base,
    required this.rest,
    required this.lit,
  });

  final double t;
  final double fade;
  final NoiseFamily? family;
  final bool still;
  final Color base;
  final Color rest;
  final Color lit;

  static const pitch = 13.0;
  static const coreRatio = 0.56;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final maxR = math.min(size.width, size.height) * 0.5 - 2;
    final core = maxR * coreRatio;
    final paint = Paint()..isAntiAlias = true;

    final cols = (size.width / pitch).floor();
    final rows = (size.height / pitch).floor();
    final ox = c.dx - (cols - 1) * pitch / 2;
    final oy = c.dy - (rows - 1) * pitch / 2;

    for (var y = 0; y < rows; y++) {
      for (var x = 0; x < cols; x++) {
        final p = Offset(ox + x * pitch, oy + y * pitch);
        final v = p - c;
        final d = v.distance;
        if (d > maxR || d < core) continue;
        final u = (d - core) / (maxR - core); // 0 at the core edge, 1 at the rim

        // Edge falloff so the grille reads as a round perforation.
        final edge = math.min(1.0, (1 - u) * 6);
        var glow = 0.0;
        var pull = 0.0;
        switch (family) {
          case NoiseFamily.cancel:
            final w = _wave(u + t);
            glow = still ? 0.55 * (1 - u) : w * (0.35 + 0.65 * (1 - u));
            pull = still ? 0 : w * 2.4;
          case NoiseFamily.aware:
            final w = _wave(u - t);
            glow = still ? 0.45 * u + 0.15 : w * (0.35 + 0.65 * u);
            pull = still ? 0 : -w * 2.0;
          case NoiseFamily.off:
            glow = 0;
          case null:
            glow = 0;
        }
        glow *= fade;
        final at = d == 0 ? p : p - v / d * pull;
        final r = 1.5 + 1.1 * glow;
        final baseColor = family == NoiseFamily.off ? rest : base;
        paint.color = Color.lerp(baseColor, lit, glow.clamp(0, 1))!.withValues(alpha: edge.clamp(0.0, 1.0));
        canvas.drawCircle(at, r, paint);
      }
    }

    // Hairline rim of the core where the readout sits.
    canvas.drawCircle(
      c,
      core - pitch * 0.4,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = (family == NoiseFamily.cancel || family == NoiseFamily.aware ? lit : rest).withValues(
          alpha: family == null ? 0.25 : 0.55 * fade + 0.15,
        ),
    );
  }

  /// A soft travelling band with period 1.
  static double _wave(double x) {
    final f = x - x.floorToDouble();
    final k = math.sin(f * math.pi);
    return math.pow(k, 6).toDouble();
  }

  @override
  bool shouldRepaint(_GrillePainter o) =>
      o.t != t || o.fade != fade || o.family != family || o.base != base || o.lit != lit || o.still != still;
}
