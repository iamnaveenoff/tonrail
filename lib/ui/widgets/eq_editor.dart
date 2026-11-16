import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../protocol/commands.dart';
import '../theme.dart';

/// Frequency-response view with draggable band handles.
class EqEditor extends StatefulWidget {
  const EqEditor({
    super.key,
    required this.curve,
    required this.handles,
    required this.handlesLive,
    required this.selected,
    required this.onSelect,
    required this.onChanged,
    this.onReset,
    this.enabled = true,
    this.height = 220,
  });

  /// What is playing now (may be a 7-band factory tuning).
  final List<EqBand> curve;

  /// Editable 10-band custom curve.
  final List<EqBand> handles;

  /// False when a factory preset is playing; handles show as a starting point.
  final bool handlesLive;
  final int selected;
  final ValueChanged<int> onSelect;
  final void Function(int index, double gain) onChanged;

  /// Double-tap: return the touched band to 0 dB.
  final ValueChanged<int>? onReset;
  final bool enabled;
  final double height;

  @override
  State<EqEditor> createState() => _EqEditorState();
}

class _EqEditorState extends State<EqEditor> {
  static const _pad = EdgeInsets.fromLTRB(34, 14, 14, 28);
  int? _dragging;
  double? _lastStep;
  Offset? _tapAt;

  static double _xFor(double f, double w) {
    const lo = 20.0, hi = 20000.0;
    return (math.log(f / lo) / math.log(hi / lo)) * w;
  }

  static double _yFor(double db, double h) => h / 2 - db / 10 * (h / 2);
  static double _dbFor(double y, double h) => (h / 2 - y) / (h / 2) * 10;

  int _nearest(double x, double w) {
    var best = 0;
    var dist = double.infinity;
    for (var i = 0; i < widget.handles.length; i++) {
      final d = (_xFor(widget.handles[i].freq.toDouble(), w) - x).abs();
      if (d < dist) {
        dist = d;
        best = i;
      }
    }
    return best;
  }

  void _update(Offset local, Size size, {bool start = false}) {
    final w = size.width - _pad.horizontal;
    final h = size.height - _pad.vertical;
    final p = local - Offset(_pad.left, _pad.top);
    if (start) {
      _dragging = _nearest(p.dx, w);
      _lastStep = null;
      widget.onSelect(_dragging!);
      setState(() {});
    }
    final i = _dragging;
    if (i == null) return;
    final g = _dbFor(p.dy, h).clamp(Eq.minGain, Eq.maxGain);
    final step = (g * 2).round() / 2;
    if (step != _lastStep) {
      if (_lastStep != null && (step == 0 || step == Eq.minGain || step == Eq.maxGain)) {
        HapticFeedback.selectionClick();
      }
      _lastStep = step;
      widget.onChanged(i, g);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final band = widget.handles[widget.selected];
    return Semantics(
      label: 'Equalizer curve. Selected ${formatFreq(band.freq)}, ${formatDb(band.gain)}',
      child: LayoutBuilder(
        builder: (context, c) {
          final size = Size(c.maxWidth, widget.height);
          final w = size.width - _pad.horizontal;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: widget.enabled ? (d) => _update(d.localPosition, size, start: true) : null,
            onPanUpdate: widget.enabled ? (d) => _update(d.localPosition, size) : null,
            onPanEnd: (_) => setState(() => _dragging = null),
            onPanCancel: () => setState(() => _dragging = null),
            onTapDown: (d) => _tapAt = d.localPosition,
            onTapUp: widget.enabled ? (d) => widget.onSelect(_nearest(d.localPosition.dx - _pad.left, w)) : null,
            onDoubleTap: widget.enabled && widget.onReset != null
                ? () {
                    final at = _tapAt;
                    if (at == null) return;
                    HapticFeedback.lightImpact();
                    widget.onReset!(_nearest(at.dx - _pad.left, w));
                  }
                : null,
            child: CustomPaint(
              size: size,
              painter: _EqPainter(
                curve: widget.curve,
                handles: widget.handles,
                handlesLive: widget.handlesLive,
                selected: widget.selected,
                dragging: _dragging != null,
                scheme: s,
                label: Theme.of(context).textTheme.labelSmall!.copyWith(letterSpacing: 0.4),
                pad: _pad,
              ),
            ),
          );
        },
      ),
    );
  }
}

String formatFreq(int f) => f >= 1000 ? '${(f / 1000).toStringAsFixed(f % 1000 == 0 ? 0 : 1)} kHz' : '$f Hz';
String formatFreqShort(int f) => f >= 1000 ? '${(f / 1000).toStringAsFixed(f % 1000 == 0 ? 0 : 1)}k' : '$f';
String formatDb(double g) =>
    '${g > 0
        ? '+'
        : g < 0
        ? '−'
        : ''}${g.abs().toStringAsFixed(g % 1 == 0 ? 0 : 1)} dB';

class _EqPainter extends CustomPainter {
  _EqPainter({
    required this.curve,
    required this.handles,
    required this.handlesLive,
    required this.selected,
    required this.dragging,
    required this.scheme,
    required this.label,
    required this.pad,
  });

  final List<EqBand> curve;
  final List<EqBand> handles;
  final bool handlesLive;
  final int selected;
  final bool dragging;
  final ColorScheme scheme;
  final TextStyle label;
  final EdgeInsets pad;

  void _text(Canvas canvas, String t, Offset at, Color color, {bool center = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: t,
        style: label.copyWith(color: color, fontFeatures: tabular),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, at - Offset(center ? tp.width / 2 : tp.width, tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width - pad.horizontal;
    final h = size.height - pad.vertical;
    canvas.save();
    canvas.translate(pad.left, pad.top);

    final dot = Paint()..color = scheme.outlineVariant;
    // Perforated reference rows at ±4 and ±8 dB, solid hairline at 0.
    for (final db in [-8, -4, 0, 4, 8]) {
      final y = _EqEditorState._yFor(db.toDouble(), h);
      if (db == 0) {
        canvas.drawLine(Offset(0, y), Offset(w, y), Paint()..color = scheme.outline.withValues(alpha: 0.7));
      } else {
        for (var x = 0.0; x <= w; x += 6) {
          canvas.drawCircle(Offset(x, y), 0.9, dot);
        }
      }
      _text(
        canvas,
        db > 0
            ? '+$db'
            : db < 0
            ? '−${-db}'
            : '0',
        Offset(-10, y),
        scheme.onSurfaceVariant,
      );
    }

    // Selected band column.
    final sel = handles[selected];
    final sx = _EqEditorState._xFor(sel.freq.toDouble(), w);
    canvas.drawRect(
      Rect.fromLTWH(sx - 12, 0, 24, h),
      Paint()..color = scheme.onSurface.withValues(alpha: dragging ? 0.07 : 0.04),
    );

    for (final f in [100, 1000, 10000]) {
      final x = _EqEditorState._xFor(f.toDouble(), w);
      canvas.drawLine(Offset(x, 0), Offset(x, h), Paint()..color = scheme.outlineVariant.withValues(alpha: 0.6));
      _text(canvas, f >= 1000 ? '${f ~/ 1000}k' : '$f', Offset(x, h + 16), scheme.onSurfaceVariant, center: true);
    }

    final path = Path();
    for (var px = 0.0; px <= w; px += 2) {
      final f = 20 * math.pow(1000, px / w).toDouble();
      final y = _EqEditorState._yFor(EqMath.responseDb(curve, f).clamp(-10, 10), h);
      px == 0 ? path.moveTo(px, y) : path.lineTo(px, y);
    }
    final fill = Path.from(path)
      ..lineTo(w, h / 2)
      ..lineTo(0, h / 2)
      ..close();
    canvas.drawPath(fill, Paint()..color = scheme.primary.withValues(alpha: 0.12));
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..color = scheme.primary,
    );

    for (var i = 0; i < handles.length; i++) {
      final b = handles[i];
      final o = Offset(_EqEditorState._xFor(b.freq.toDouble(), w), _EqEditorState._yFor(b.gain, h));
      final isSel = i == selected;
      if (!handlesLive) {
        canvas.drawCircle(
          o,
          isSel ? 6 : 4,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..color = scheme.outline,
        );
        continue;
      }
      if (isSel) {
        // Index line from 0 dB to the handle, like a knob's pointer.
        canvas.drawLine(
          Offset(o.dx, h / 2),
          o,
          Paint()
            ..strokeWidth = 2
            ..color = scheme.primary.withValues(alpha: 0.5),
        );
        final r = dragging ? 11.0 : 9.0;
        canvas.drawCircle(
          o + const Offset(0, 1),
          r,
          Paint()
            ..color = scheme.shadow.withValues(alpha: 0.35)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
        );
        canvas.drawCircle(o, r, Paint()..color = scheme.onSurface);
        canvas.drawCircle(o, r * 0.42, Paint()..color = scheme.primary);
      } else {
        // Stem from 0 dB: the point is the band's own level; the line is the sum you hear.
        if (b.gain != 0) {
          canvas.drawLine(
            Offset(o.dx, h / 2),
            o,
            Paint()
              ..strokeWidth = 1.5
              ..color = scheme.onSurfaceVariant.withValues(alpha: 0.45),
          );
        }
        canvas.drawCircle(o, 5.5, Paint()..color = scheme.surfaceContainerLow);
        canvas.drawCircle(
          o,
          5.5,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..color = scheme.onSurfaceVariant,
        );
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_EqPainter old) => true;
}

/// Tiny response curve for preset keys.
class CurveThumb extends StatelessWidget {
  const CurveThumb({super.key, required this.bands, required this.color, this.width = 56, this.height = 22});
  final List<EqBand> bands;
  final Color color;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size(width, height),
    painter: _ThumbPainter(bands, color, Theme.of(context).colorScheme.outlineVariant),
  );
}

class _ThumbPainter extends CustomPainter {
  _ThumbPainter(this.bands, this.color, this.axis);
  final List<EqBand> bands;
  final Color color;
  final Color axis;

  @override
  void paint(Canvas canvas, Size size) {
    final mid = size.height / 2;
    canvas.drawLine(Offset(0, mid), Offset(size.width, mid), Paint()..color = axis);
    final path = Path();
    for (var px = 0.0; px <= size.width; px += 1.5) {
      final f = 20 * math.pow(1000, px / size.width).toDouble();
      final db = EqMath.responseDb(bands, f).clamp(-12, 12);
      final y = mid - db / 12 * mid;
      px == 0 ? path.moveTo(px, y) : path.lineTo(px, y);
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_ThumbPainter o) => o.bands != bands || o.color != color;
}
