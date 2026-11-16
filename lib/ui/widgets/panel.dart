import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';

/// Tracked-caps legend, like the printing beside a control on a hi-fi panel.
class Legend extends StatelessWidget {
  const Legend(this.text, {super.key, this.color, this.textAlign});
  final String text;
  final Color? color;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return Text(
      text.toUpperCase(),
      textAlign: textAlign,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color ?? s.onSurfaceVariant),
    );
  }
}

/// Screen title row used at the top of every tab.
class PanelHeader extends StatelessWidget {
  const PanelHeader(this.title, {super.key, this.caption, this.trailing});
  final String title;
  final Widget? caption;
  final List<Widget>? trailing;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 8, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: t.headlineSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                if (caption != null) ...[const SizedBox(height: 6), caption!],
              ],
            ),
          ),
          ...?trailing,
        ],
      ),
    );
  }
}

/// A flat panel face with a hairline edge. Never nest one inside another.
class Panel extends StatelessWidget {
  const Panel({super.key, required this.child, this.padding = EdgeInsets.zero, this.color});
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return Material(
      color: color ?? s.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        side: BorderSide(color: s.outlineVariant),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

/// A legend line followed by its controls; the page's section rhythm.
class PanelSection extends StatelessWidget {
  const PanelSection({
    super.key,
    required this.legend,
    required this.child,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(16, 28, 16, 0),
  });

  final String legend;
  final Widget child;
  final Widget? trailing;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 40,
            child: Row(
              children: [
                const SizedBox(width: 4),
                Expanded(child: Legend(legend)),
                ?trailing,
              ],
            ),
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}

/// Rows inside one panel, separated by hairlines.
class PanelGroup extends StatelessWidget {
  const PanelGroup({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Panel(
      child: Column(
        children: [
          for (final (i, c) in children.indexed) ...[if (i > 0) const Divider(indent: 16, endIndent: 16), c],
        ],
      ),
    );
  }
}

/// State as a physical mark: filled when on, hairline ring when off,
/// struck through when the control can't be used.
class Detent extends StatelessWidget {
  const Detent({super.key, required this.on, this.enabled = true, this.size = 8, this.color});
  final bool on;
  final bool enabled;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _DetentPainter(on: on && enabled, enabled: enabled, fill: color ?? s.primary, ring: s.outline),
      ),
    );
  }
}

class _DetentPainter extends CustomPainter {
  _DetentPainter({required this.on, required this.enabled, required this.fill, required this.ring});
  final bool on;
  final bool enabled;
  final Color fill;
  final Color ring;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    if (on) {
      canvas.drawCircle(c, r, Paint()..color = fill);
      return;
    }
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = ring;
    canvas.drawCircle(c, r - 0.5, p);
    if (!enabled) canvas.drawLine(Offset(0, size.height), Offset(size.width, 0), p);
  }

  @override
  bool shouldRepaint(_DetentPainter o) => o.on != on || o.enabled != enabled || o.fill != fill || o.ring != ring;
}

/// A multi-position slide switch with detents, the panel's primary selector.
/// Tap a position or drag the slider across.
class SlideSwitch<T> extends StatefulWidget {
  const SlideSwitch({
    super.key,
    required this.values,
    required this.labels,
    required this.selected,
    required this.onChanged,
    this.enabled = true,
    this.height = 56,
    this.semanticLabel,
  });

  final List<T> values;
  final List<String> labels;
  final T? selected;
  final ValueChanged<T> onChanged;
  final bool enabled;
  final double height;
  final String? semanticLabel;

  @override
  State<SlideSwitch<T>> createState() => _SlideSwitchState<T>();
}

class _SlideSwitchState<T> extends State<SlideSwitch<T>> {
  int? _drag;

  int? get _index {
    if (_drag != null) return _drag;
    final sel = widget.selected;
    if (sel == null) return null;
    final i = widget.values.indexOf(sel);
    return i < 0 ? null : i;
  }

  int _cellAt(double x, double width) =>
      (x / (width / widget.values.length)).floor().clamp(0, widget.values.length - 1);

  void _commit(int i) {
    if (widget.values[i] != widget.selected) {
      HapticFeedback.selectionClick();
      widget.onChanged(widget.values[i]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final n = widget.values.length;
    final idx = _index;
    final reduce = MediaQuery.of(context).disableAnimations;

    return Semantics(
      label: widget.semanticLabel,
      container: true,
      child: LayoutBuilder(
        builder: (context, box) {
          final w = box.maxWidth;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragStart: widget.enabled
                ? (d) => setState(() => _drag = _cellAt(d.localPosition.dx, w))
                : null,
            onHorizontalDragUpdate: widget.enabled
                ? (d) {
                    final i = _cellAt(d.localPosition.dx, w);
                    if (i != _drag) {
                      HapticFeedback.selectionClick();
                      setState(() => _drag = i);
                    }
                  }
                : null,
            onHorizontalDragEnd: widget.enabled
                ? (_) {
                    final i = _drag;
                    setState(() => _drag = null);
                    if (i != null && widget.values[i] != widget.selected) widget.onChanged(widget.values[i]);
                  }
                : null,
            child: Container(
              height: widget.height,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: s.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(AppTheme.radius + 4),
                border: Border.all(color: s.outlineVariant),
              ),
              child: Stack(
                children: [
                  if (idx != null)
                    AnimatedAlign(
                      duration: reduce ? Duration.zero : const Duration(milliseconds: 320),
                      curve: Curves.easeOutQuart,
                      alignment: Alignment(n == 1 ? 0 : -1 + 2 * idx / (n - 1), 0),
                      child: FractionallySizedBox(
                        widthFactor: 1 / n,
                        heightFactor: 1,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: widget.enabled ? s.surfaceContainerHighest : s.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(AppTheme.radius),
                            border: Border.all(color: s.outlineVariant),
                            boxShadow: [
                              BoxShadow(
                                color: s.shadow.withValues(alpha: 0.25),
                                offset: const Offset(0, 1),
                                blurRadius: 3,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  Positioned.fill(
                    child: Row(
                      children: [
                        for (var i = 0; i < n; i++)
                          Expanded(
                            child: Semantics(
                              button: true,
                              selected: i == idx,
                              enabled: widget.enabled,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(AppTheme.radius),
                                onTap: widget.enabled ? () => _commit(i) : null,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Detent(on: i == idx, enabled: widget.enabled, size: 7),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: AnimatedDefaultTextStyle(
                                        duration: const Duration(milliseconds: 200),
                                        style: t.labelLarge!.copyWith(
                                          color: !widget.enabled
                                              ? s.onSurfaceVariant.withValues(alpha: 0.6)
                                              : i == idx
                                              ? s.onSurface
                                              : s.onSurfaceVariant,
                                        ),
                                        child: Text(widget.labels[i], maxLines: 1, overflow: TextOverflow.ellipsis),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Battery as five lit cells, like a level meter.
class BatteryCells extends StatelessWidget {
  const BatteryCells({super.key, required this.level, required this.charging});
  final int level;
  final bool charging;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final lit = (level / 20).ceil().clamp(0, 5);
    final low = level <= 15;
    return Semantics(
      label: 'Battery $level percent${charging ? ', charging' : ''}',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 5; i++)
            Container(
              width: 5,
              height: 12,
              margin: const EdgeInsets.only(right: 2),
              decoration: BoxDecoration(
                color: i < lit ? (low ? s.error : s.onSurface) : Colors.transparent,
                border: Border.all(color: i < lit ? Colors.transparent : s.outline, width: 1),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          if (charging) Icon(Icons.bolt_rounded, size: 14, color: s.tertiary),
        ],
      ),
    );
  }
}

/// Slider track that fills outward from the centre, for ± controls.
class CenterTrackShape extends SliderTrackShape with BaseSliderTrackShape {
  const CenterTrackShape();

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isDiscrete = false,
    bool isEnabled = false,
    double additionalActiveTrackHeight = 2,
  }) {
    final rect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );
    final canvas = context.canvas;
    final h = rect.height;
    final inactive = Paint()..color = sliderTheme.inactiveTrackColor!;
    final active = Paint()
      ..color =
          (isEnabled ? sliderTheme.activeTrackColor : sliderTheme.disabledActiveTrackColor) ??
          sliderTheme.activeTrackColor!;
    canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(h / 2)), inactive);
    final cx = rect.center.dx;
    // Centre detent.
    canvas.drawRect(Rect.fromCenter(center: Offset(cx, rect.center.dy), width: 2, height: h + 8), inactive);
    final left = thumbCenter.dx < cx ? thumbCenter.dx : cx;
    final right = thumbCenter.dx < cx ? cx : thumbCenter.dx;
    if (right - left > 0.5) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTRB(left, rect.top - 1, right, rect.bottom + 1), Radius.circular(h)),
        active,
      );
    }
  }
}

/// Small status lamp. Green when the link runs, hollow when it doesn't.
class StatusLamp extends StatelessWidget {
  const StatusLamp({super.key, required this.on, this.pulse = false});
  final bool on;
  final bool pulse;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final lamp = Detent(on: on, size: 8, color: s.tertiary);
    if (!pulse || MediaQuery.of(context).disableAnimations) return lamp;
    return _Pulse(child: Detent(on: true, size: 8, color: s.outline));
  }
}

class _Pulse extends StatefulWidget {
  const _Pulse({required this.child});
  final Widget child;
  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      FadeTransition(opacity: Tween(begin: 0.25, end: 1.0).animate(_c), child: widget.child);
}

/// Rounded tile behind a row icon, so icons read as one consistent family.
class IconTile extends StatelessWidget {
  const IconTile(this.icon, {super.key, this.enabled = true, this.selected = false, this.tone, this.size = 40});
  final IconData icon;
  final bool enabled;
  final bool selected;
  final Color? tone;
  final double size;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final fg = !enabled ? s.onSurfaceVariant.withValues(alpha: 0.5) : tone ?? (selected ? s.primary : s.onSurface);
    final bg = !enabled
        ? s.surfaceContainer
        : tone != null
        ? tone!.withValues(alpha: 0.14)
        : selected
        ? s.primary.withValues(alpha: 0.16)
        : s.surfaceContainerHighest;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(size * 0.3)),
      child: Icon(icon, size: size * 0.52, color: fg),
    );
  }
}

/// A settings row with icon, title, value and optional trailing control.
class PanelRow extends StatelessWidget {
  const PanelRow({
    super.key,
    required this.title,
    this.icon,
    this.value,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.enabled = true,
    this.destructive = false,
  });

  final IconData? icon;
  final String title;
  final String? value;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool enabled;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final fg = !enabled
        ? s.onSurface.withValues(alpha: 0.38)
        : destructive
        ? s.error
        : s.onSurface;
    return InkWell(
      onTap: enabled ? onTap : null,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
          child: Row(
            children: [
              if (icon != null) ...[
                IconTile(icon!, enabled: enabled, tone: destructive ? s.error : null),
                const SizedBox(width: 14),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: t.bodyLarge?.copyWith(fontWeight: FontWeight.w500, color: fg),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: t.bodySmall?.copyWith(
                          color: enabled ? s.onSurfaceVariant : s.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (value != null) ...[
                const SizedBox(width: 12),
                Text(
                  value!,
                  style: t.bodyMedium?.copyWith(
                    color: enabled ? s.onSurfaceVariant : s.onSurfaceVariant.withValues(alpha: 0.6),
                    fontFeatures: tabular,
                  ),
                ),
              ],
              if (trailing != null) ...[const SizedBox(width: 8), trailing!],
              if (trailing == null && onTap != null)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: enabled ? s.onSurfaceVariant : s.onSurfaceVariant.withValues(alpha: 0.4),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom-sheet list of choices with a detent on the current one.
Future<T?> showChoiceSheet<T>(
  BuildContext context, {
  required String title,
  String? caption,
  required List<(T, String, IconData?)> choices,
  required T? current,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      final s = Theme.of(ctx).colorScheme;
      final t = Theme.of(ctx).textTheme;
      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.8),
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 4),
                  child: Text(title, style: t.titleLarge),
                ),
                if (caption != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                    child: Text(caption, style: t.bodyMedium?.copyWith(color: s.onSurfaceVariant)),
                  ),
                const SizedBox(height: 4),
                for (final (value, label, icon) in choices)
                  InkWell(
                    onTap: () => Navigator.pop(ctx, value),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 56),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        child: Row(
                          children: [
                            if (icon != null) ...[
                              IconTile(icon, selected: value == current),
                              const SizedBox(width: 14),
                            ],
                            Expanded(
                              child: Text(
                                label,
                                style: t.bodyLarge?.copyWith(
                                  fontWeight: value == current ? FontWeight.w600 : FontWeight.w400,
                                ),
                              ),
                            ),
                            Detent(on: value == current, size: 10),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
