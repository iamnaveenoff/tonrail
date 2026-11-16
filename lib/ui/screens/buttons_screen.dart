import 'package:flutter/material.dart';

import '../../protocol/commands.dart';
import '../scope.dart';
import '../widgets/common.dart';
import '../widgets/panel.dart';

const functionIcons = <int, IconData>{
  0: Icons.block_rounded,
  1: Icons.play_arrow_rounded,
  2: Icons.skip_previous_rounded,
  3: Icons.skip_next_rounded,
  4: Icons.mic_none_rounded,
  5: Icons.volume_up_rounded,
  6: Icons.volume_down_rounded,
  7: Icons.sports_esports_outlined,
};

class ButtonsScreen extends StatelessWidget {
  const ButtonsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = HeadsetScope.of(context);
    final s = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final groups = <String, List<ButtonGesture>>{};
    for (final g in ButtonMap.gestures) {
      groups.putIfAbsent(g.button, () => []).add(g);
    }
    final changed = ButtonMap.gestures.where((g) => c.functionFor(g) != g.defaultFunction).length;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          PanelHeader(
            'Buttons',
            caption: Text(
              changed == 0
                  ? 'All presses use their original actions'
                  : '$changed ${changed == 1 ? 'press' : 'presses'} changed from default',
              style: t.bodyMedium?.copyWith(color: s.onSurfaceVariant),
            ),
            trailing: [
              TextButton(
                onPressed: c.isReady && changed > 0 ? () => _confirmReset(context) : null,
                child: const Text('Defaults'),
              ),
              const SizedBox(width: 4),
            ],
          ),
          const LinkBanner(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Panel(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: _ButtonDiagram()),
                  const SizedBox(height: 12),
                  Text(
                    'Choose what each press does. Assignments are saved on the headphones, so they work with any phone.',
                    style: t.bodySmall?.copyWith(color: s.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
          for (final entry in groups.entries)
            PanelSection(
              legend: entry.key,
              child: PanelGroup(children: [for (final g in entry.value) _GestureRow(gesture: g)]),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    final c = HeadsetScope.read(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore default buttons?'),
        content: const Text('Every press goes back to its original action.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Restore')),
        ],
      ),
    );
    if (ok == true) await c.resetButtons();
  }
}

class _GestureRow extends StatelessWidget {
  const _GestureRow({required this.gesture});
  final ButtonGesture gesture;

  @override
  Widget build(BuildContext context) {
    final c = HeadsetScope.of(context);
    final s = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final fn = c.functionFor(gesture);
    final custom = fn != gesture.defaultFunction;
    final enabled = c.isReady;
    final presses = switch (gesture.gesture) {
      'Press twice' => 2,
      'Press three times' => 3,
      'Press four times' => 4,
      _ => 1,
    };

    return Semantics(
      button: true,
      label: '${gesture.button}, ${gesture.gesture}: ${ButtonMap.functions[fn] ?? 'Unknown'}',
      excludeSemantics: true,
      child: InkWell(
        onTap: enabled ? () => _pick(context) : null,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 68),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
            child: Row(
              children: [
                SizedBox(
                  width: 36,
                  child: Row(
                    children: [
                      for (var i = 0; i < presses; i++)
                        Padding(
                          padding: const EdgeInsets.only(right: 3),
                          child: Detent(on: true, enabled: enabled, size: 6, color: s.onSurfaceVariant),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(gesture.gesture, style: t.bodySmall?.copyWith(color: s.onSurfaceVariant)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            functionIcons[fn] ?? Icons.help_outline_rounded,
                            size: 18,
                            color: enabled ? s.onSurface : s.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              ButtonMap.functions[fn] ?? 'Unknown',
                              style: t.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: enabled ? s.onSurface : s.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (custom) ...[Legend('Changed', color: s.onSurface), const SizedBox(width: 6)],
                Icon(Icons.chevron_right_rounded, color: s.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pick(BuildContext context) async {
    final c = HeadsetScope.read(context);
    final current = c.functionFor(gesture);
    final picked = await showChoiceSheet<int>(
      context,
      title: '${gesture.button} · ${gesture.gesture}',
      caption: 'Default: ${ButtonMap.functions[gesture.defaultFunction]}',
      current: current,
      choices: [for (final e in ButtonMap.functions.entries) (e.key, e.value, functionIcons[e.key])],
    );
    if (picked != null && picked != current) await c.setButton(gesture, picked);
  }
}

/// A side view of the right ear cup with its three buttons.
class _ButtonDiagram extends StatelessWidget {
  const _ButtonDiagram();

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: SizedBox(
        width: 280,
        height: 156,
        child: CustomPaint(
          painter: _CupPainter(s),
          child: Stack(
            children: [
              for (final (i, label) in ['Volume +', 'Multifunction', 'Volume −'].indexed)
                Positioned(
                  left: 162,
                  top: 30.0 + i * 40 - 8,
                  child: Legend(label, color: i == 1 ? s.onSurface : s.onSurfaceVariant),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CupPainter extends CustomPainter {
  _CupPainter(this.s);
  final ColorScheme s;

  @override
  void paint(Canvas canvas, Size size) {
    const cupRect = Rect.fromLTWH(22, 6, 96, 144);
    final cup = RRect.fromRectAndRadius(cupRect, const Radius.circular(48));
    canvas.drawRRect(cup, Paint()..color = s.surfaceContainerHigh);
    canvas.drawRRect(
      cup,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = s.outline,
    );

    // Perforated grille on the cup face.
    canvas.save();
    canvas.clipRRect(cup.deflate(14));
    final dot = Paint()..color = s.outlineVariant;
    for (var y = cupRect.top + 18; y < cupRect.bottom - 10; y += 8) {
      for (var x = cupRect.left + 18; x < cupRect.right - 10; x += 8) {
        canvas.drawCircle(Offset(x, y), 1.4, dot);
      }
    }
    canvas.restore();

    for (var i = 0; i < 3; i++) {
      final y = 30.0 + i * 40;
      final center = Offset(118, y);
      final r = i == 1 ? 7.5 : 6.0;
      canvas.drawCircle(center, r, Paint()..color = i == 1 ? s.primary : s.onSurface);
      canvas.drawLine(
        center + Offset(r + 6, 0),
        Offset(154, y),
        Paint()
          ..color = s.outline
          ..strokeWidth = 1,
      );
    }
  }

  @override
  bool shouldRepaint(_CupPainter old) => old.s != s;
}
