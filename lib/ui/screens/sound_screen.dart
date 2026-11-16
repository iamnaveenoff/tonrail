import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../device/headset_controller.dart';
import '../../protocol/commands.dart';
import '../scope.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/eq_editor.dart';
import '../widgets/panel.dart';

/// Bands moved together by the quick tone controls.
const _toneGroups = <(String, String, List<int>)>[
  ('Bass', 'Weight and punch', [0, 1]),
  ('Voice', 'Vocals and instruments', [2, 3, 4, 5]),
  ('Treble', 'Detail and air', [6, 7, 8, 9]),
];

class SoundScreen extends StatefulWidget {
  const SoundScreen({super.key});

  @override
  State<SoundScreen> createState() => _SoundScreenState();
}

class _SoundScreenState extends State<SoundScreen> {
  int _band = 3;
  bool _comparing = false;

  List<EqBand> _handles(HeadsetController c) {
    final active = c.presetById(c.activePresetId);
    final factoryPlaying = active?.factory ?? false;
    return (!factoryPlaying && c.eqBands.length == 10) ? c.eqBands : c.draft;
  }

  void _startFlat(BuildContext context, HeadsetController c) {
    final prevPreset = c.presetById(c.activePresetId);
    final prevBands = _handles(c);
    c.resetDraft();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Curve set flat'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => prevPreset != null ? c.applyPreset(prevPreset) : c.setBands(prevBands),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final c = HeadsetScope.of(context);
    final s = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final active = c.presetById(c.activePresetId);
    final factoryPlaying = active?.factory ?? false;
    final handles = _handles(c);
    final band = handles[_band.clamp(0, handles.length - 1)];
    final unsaved = active == null;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          PanelHeader(
            'Sound',
            caption: Row(
              children: [
                Detent(on: unsaved, size: 7),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    unsaved ? 'Custom curve · not saved' : active.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.bodyMedium?.copyWith(color: s.onSurfaceVariant),
                  ),
                ),
              ],
            ),
            trailing: [
              if (unsaved)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: OutlinedButton.icon(
                    onPressed: () => _savePreset(context, c),
                    icon: const Icon(Icons.bookmark_add_outlined, size: 18),
                    label: const Text('Save'),
                  ),
                ),
            ],
          ),
          const LinkBanner(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Panel(
              padding: const EdgeInsets.fromLTRB(8, 14, 8, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        const Expanded(child: Legend('Equalizer')),
                        if (c.eqMaster < 0)
                          Tooltip(
                            message: 'Output is lowered so boosted bands don’t distort.',
                            child: Legend('Output ${formatDb(c.eqMaster)}'),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  EqEditor(
                    curve: _comparing ? Eq.flatBands() : c.eqBands,
                    handles: handles,
                    handlesLive: !factoryPlaying,
                    selected: _band,
                    enabled: c.isReady,
                    onSelect: (i) => setState(() => _band = i),
                    onChanged: c.editBand,
                    onReset: (i) {
                      setState(() => _band = i);
                      c.editBand(i, 0);
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
                    child: Text(
                      factoryPlaying
                          ? 'Drag a point to start your own curve from flat.'
                          : 'Points are band levels; the line is what you hear. Drag a point to shape it, double-tap to reset.',
                      style: t.bodySmall?.copyWith(color: s.onSurfaceVariant),
                    ),
                  ),
                  _BandStrip(
                    bands: handles,
                    selected: _band,
                    live: !factoryPlaying,
                    onSelect: (i) {
                      HapticFeedback.selectionClick();
                      setState(() => _band = i);
                    },
                  ),
                  const SizedBox(height: 10),
                  _FineTune(band: band, enabled: c.isReady, onStep: (d) => c.editBand(_band, band.gain + d)),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: _HoldToCompare(
                    enabled: c.isReady,
                    comparing: _comparing,
                    onChanged: (v) {
                      setState(() => _comparing = v);
                      c.compare(v);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: c.isReady ? () => _startFlat(context, c) : null,
                    icon: const Icon(Icons.horizontal_rule_rounded, size: 20),
                    label: const Text('Start flat'),
                  ),
                ),
              ],
            ),
          ),
          PanelSection(
            legend: 'Quick tone',
            child: Panel(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              child: Column(
                children: [
                  for (final (i, g) in _toneGroups.indexed) ...[
                    if (i > 0) const Divider(),
                    _ToneControl(
                      label: g.$1,
                      hint: g.$2,
                      indices: g.$3,
                      bands: handles,
                      enabled: c.isReady,
                      onChanged: c.setBands,
                    ),
                  ],
                ],
              ),
            ),
          ),
          PanelSection(
            legend: 'Tuned by the maker',
            child: _PresetGrid(
              presets: Eq.factoryPresets,
              activeId: c.activePresetId,
              enabled: c.isReady,
              onTap: c.applyPreset,
            ),
          ),
          PanelSection(
            legend: 'Your presets',
            trailing: c.userPresets.isEmpty
                ? null
                : Padding(padding: const EdgeInsets.only(right: 4), child: Legend('${c.userPresets.length} saved')),
            child: c.userPresets.isEmpty
                ? Panel(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.bookmark_border_rounded, color: s.onSurfaceVariant),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            'Shape the curve above, then tap Save. Presets live on this phone and can be renamed or deleted any time.',
                            style: t.bodyMedium?.copyWith(color: s.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ),
                  )
                : PanelGroup(children: [for (final p in c.userPresets) _UserPresetRow(preset: p)]),
          ),
          PanelSection(
            legend: 'Balance',
            trailing: TextButton(
              onPressed: c.isReady && c.balance != 50 ? () => c.setBalance(50) : null,
              child: const Text('Center'),
            ),
            child: Panel(
              padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
              child: _BalanceSlider(c: c),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _savePreset(BuildContext context, HeadsetController c) async {
    final name = await promptText(context, title: 'Save preset', label: 'Name', initial: '');
    if (name != null && name.isNotEmpty) {
      c.savePreset(name);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Saved “$name”')));
    }
  }
}

/// Ten band cells: a glance at every gain and a large target for selecting.
class _BandStrip extends StatelessWidget {
  const _BandStrip({required this.bands, required this.selected, required this.live, required this.onSelect});
  final List<EqBand> bands;
  final int selected;
  final bool live;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return SizedBox(
      height: 72,
      child: Row(
        children: [
          for (var i = 0; i < bands.length; i++)
            Expanded(
              child: Semantics(
                button: true,
                selected: i == selected,
                label: '${formatFreq(bands[i].freq)}, ${formatDb(bands[i].gain)}',
                excludeSemantics: true,
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppTheme.radius),
                  onTap: () => onSelect(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.symmetric(horizontal: 1.5),
                    decoration: BoxDecoration(
                      color: i == selected ? s.surfaceContainerHighest : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppTheme.radius),
                      border: Border.all(color: i == selected ? s.outline : Colors.transparent),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: CustomPaint(
                              size: const Size(6, double.infinity),
                              painter: _MeterPainter(
                                gain: bands[i].gain,
                                on: live ? (i == selected ? s.primary : s.onSurface) : s.outline,
                                track: s.outlineVariant,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        FittedBox(
                          child: Text(
                            formatFreqShort(bands[i].freq),
                            style: t.labelSmall?.copyWith(
                              letterSpacing: 0,
                              fontFeatures: tabular,
                              color: i == selected ? s.onSurface : s.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MeterPainter extends CustomPainter {
  _MeterPainter({required this.gain, required this.on, required this.track});
  final double gain;
  final Color on;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final x = size.width / 2;
    final mid = size.height / 2;
    canvas.drawLine(
      Offset(x, 0),
      Offset(x, size.height),
      Paint()
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..color = track,
    );
    canvas.drawLine(
      Offset(x - 4, mid),
      Offset(x + 4, mid),
      Paint()
        ..color = track
        ..strokeWidth = 1,
    );
    if (gain == 0) return;
    final y = mid - gain / Eq.maxGain * mid;
    canvas.drawLine(
      Offset(x, mid),
      Offset(x, y),
      Paint()
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..color = on,
    );
  }

  @override
  bool shouldRepaint(_MeterPainter o) => o.gain != gain || o.on != on || o.track != track;
}

class _FineTune extends StatelessWidget {
  const _FineTune({required this.band, required this.enabled, required this.onStep});
  final EqBand band;
  final bool enabled;
  final ValueChanged<double> onStep;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Row(
      children: [
        const SizedBox(width: 4),
        _StepButton(
          icon: Icons.remove_rounded,
          tooltip: 'Lower 0.5 dB',
          onStep: enabled && band.gain > Eq.minGain ? () => onStep(-0.5) : null,
        ),
        Expanded(
          child: Column(
            children: [
              Legend(formatFreq(band.freq)),
              const SizedBox(height: 2),
              Text(formatDb(band.gain), style: t.titleLarge?.copyWith(fontFeatures: tabular)),
            ],
          ),
        ),
        _StepButton(
          icon: Icons.add_rounded,
          tooltip: 'Raise 0.5 dB',
          onStep: enabled && band.gain < Eq.maxGain ? () => onStep(0.5) : null,
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}

/// Step key that repeats while held.
class _StepButton extends StatefulWidget {
  const _StepButton({required this.icon, required this.tooltip, required this.onStep});
  final IconData icon;
  final String tooltip;
  final VoidCallback? onStep;

  @override
  State<_StepButton> createState() => _StepButtonState();
}

class _StepButtonState extends State<_StepButton> {
  bool _held = false;

  Future<void> _repeat() async {
    _held = true;
    await Future<void>.delayed(const Duration(milliseconds: 380));
    while (_held && mounted && widget.onStep != null) {
      widget.onStep!();
      await Future<void>.delayed(const Duration(milliseconds: 90));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return GestureDetector(
      onLongPressStart: widget.onStep == null ? null : (_) => _repeat(),
      onLongPressEnd: (_) => _held = false,
      onLongPressCancel: () => _held = false,
      child: IconButton.outlined(
        tooltip: widget.tooltip,
        style: IconButton.styleFrom(
          minimumSize: const Size(56, 56),
          side: BorderSide(color: s.outlineVariant),
          backgroundColor: s.surfaceContainerLowest,
        ),
        onPressed: widget.onStep == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                widget.onStep!();
              },
        icon: Icon(widget.icon),
      ),
    );
  }
}

/// Moves a group of bands together, keeping their shape relative to each other.
class _ToneControl extends StatefulWidget {
  const _ToneControl({
    required this.label,
    required this.hint,
    required this.indices,
    required this.bands,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final String hint;
  final List<int> indices;
  final List<EqBand> bands;
  final bool enabled;
  final ValueChanged<List<EqBand>> onChanged;

  @override
  State<_ToneControl> createState() => _ToneControlState();
}

class _ToneControlState extends State<_ToneControl> {
  List<EqBand>? _base;
  double? _drag;

  double _mean(List<EqBand> bands) =>
      widget.indices.map((i) => bands[i].gain).reduce((a, b) => a + b) / widget.indices.length;

  void _apply(double v) {
    final base = _base ?? widget.bands;
    final delta = v - _mean(base);
    widget.onChanged([
      for (var i = 0; i < base.length; i++)
        widget.indices.contains(i)
            ? base[i].copyWith(gain: (base[i].gain + delta).clamp(Eq.minGain, Eq.maxGain))
            : base[i],
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final value = (_drag ?? _mean(widget.bands)).clamp(-6.0, 6.0);
    return Row(
      children: [
        SizedBox(
          width: 92,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.label, style: t.titleSmall),
              Text(
                widget.hint,
                maxLines: 2,
                style: t.bodySmall?.copyWith(color: s.onSurfaceVariant, fontSize: 11, height: 1.2),
              ),
            ],
          ),
        ),
        Expanded(
          child: Semantics(
            label: '${widget.label} level',
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(trackShape: const CenterTrackShape()),
              child: Slider(
                value: value,
                min: -6,
                max: 6,
                divisions: 24,
                label: formatDb(value),
                onChangeStart: widget.enabled
                    ? (v) => setState(() {
                        _base = List.of(widget.bands);
                        _drag = v;
                      })
                    : null,
                onChanged: widget.enabled
                    ? (v) {
                        if (v == 0 && _drag != 0) HapticFeedback.selectionClick();
                        setState(() => _drag = v);
                        _apply(v);
                      }
                    : null,
                onChangeEnd: (_) => setState(() {
                  _base = null;
                  _drag = null;
                }),
              ),
            ),
          ),
        ),
        SizedBox(
          width: 58,
          child: Text(
            formatDb(value),
            textAlign: TextAlign.end,
            style: t.labelLarge?.copyWith(fontFeatures: tabular),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

class _HoldToCompare extends StatelessWidget {
  const _HoldToCompare({required this.enabled, required this.comparing, required this.onChanged});
  final bool enabled;
  final bool comparing;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      label: 'Hold to hear the sound without equalizer',
      child: Listener(
        onPointerDown: enabled
            ? (_) {
                HapticFeedback.lightImpact();
                onChanged(true);
              }
            : null,
        onPointerUp: (_) {
          if (comparing) onChanged(false);
        },
        onPointerCancel: (_) {
          if (comparing) onChanged(false);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 48,
          decoration: BoxDecoration(
            color: comparing ? s.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radius),
            border: Border.all(color: comparing ? s.primary : s.outlineVariant),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                comparing ? Icons.hearing_rounded : Icons.compare_arrows_rounded,
                size: 20,
                color: !enabled
                    ? s.onSurface.withValues(alpha: 0.38)
                    : comparing
                    ? s.onPrimary
                    : s.onSurface,
              ),
              const SizedBox(width: 8),
              Text(
                comparing ? 'Playing flat' : 'Hold to compare',
                style: t.labelLarge?.copyWith(
                  color: !enabled
                      ? s.onSurface.withValues(alpha: 0.38)
                      : comparing
                      ? s.onPrimary
                      : s.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PresetGrid extends StatelessWidget {
  const _PresetGrid({required this.presets, required this.activeId, required this.enabled, required this.onTap});
  final List<EqPreset> presets;
  final String? activeId;
  final bool enabled;
  final ValueChanged<EqPreset> onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        const gap = 8.0;
        final cols = box.maxWidth > 520 ? 4 : 3;
        final w = (box.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final p in presets)
              SizedBox(
                width: w,
                child: _PresetKey(
                  preset: p,
                  selected: p.id == activeId,
                  enabled: enabled,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onTap(p);
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

class _PresetKey extends StatelessWidget {
  const _PresetKey({required this.preset, required this.selected, required this.enabled, required this.onTap});
  final EqPreset preset;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      selected: selected,
      label: preset.name,
      excludeSemantics: true,
      child: Material(
        color: selected ? s.surfaceContainerHigh : s.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radius + 2),
          side: BorderSide(color: selected ? s.primary : s.outlineVariant, width: selected ? 1.5 : 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        preset.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.labelLarge?.copyWith(color: enabled ? s.onSurface : s.onSurfaceVariant),
                      ),
                    ),
                    Detent(on: selected, enabled: enabled, size: 7),
                  ],
                ),
                const SizedBox(height: 10),
                CurveThumb(
                  bands: preset.bands,
                  color: selected ? s.primary : s.onSurfaceVariant,
                  width: double.infinity,
                  height: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UserPresetRow extends StatelessWidget {
  const _UserPresetRow({required this.preset});
  final EqPreset preset;

  @override
  Widget build(BuildContext context) {
    final c = HeadsetScope.of(context);
    final s = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final selected = c.activePresetId == preset.id;
    return InkWell(
      onTap: c.isReady
          ? () {
              HapticFeedback.selectionClick();
              c.applyPreset(preset);
            }
          : null,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
          child: Row(
            children: [
              Detent(on: selected, enabled: c.isReady, size: 8),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  preset.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.bodyLarge?.copyWith(fontWeight: selected ? FontWeight.w600 : FontWeight.w500),
                ),
              ),
              CurveThumb(bands: preset.bands, color: selected ? s.primary : s.onSurfaceVariant, width: 64),
              PopupMenuButton<String>(
                tooltip: 'Preset options',
                icon: Icon(Icons.more_vert_rounded, color: s.onSurfaceVariant),
                onSelected: (v) async {
                  if (v == 'rename') {
                    final name = await promptText(context, title: 'Rename preset', label: 'Name', initial: preset.name);
                    if (name != null && name.isNotEmpty) c.renamePreset(preset.id, name);
                  } else if (v == 'delete') {
                    c.deletePreset(preset.id);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(SnackBar(content: Text('Deleted “${preset.name}”')));
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'rename', child: Text('Rename')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BalanceSlider extends StatelessWidget {
  const _BalanceSlider({required this.c});
  final HeadsetController c;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final s = Theme.of(context).colorScheme;
    final v = c.balance;
    final left = v <= 50 ? 100 : ((100 - v) * 2);
    final right = v >= 50 ? 100 : v * 2;

    Widget side(String label, int value) => SizedBox(
      width: 52,
      child: Column(
        children: [
          Legend(label),
          const SizedBox(height: 2),
          Text(
            '$value',
            style: t.titleMedium?.copyWith(fontFeatures: tabular, color: s.onSurface),
          ),
        ],
      ),
    );

    return Row(
      children: [
        side('Left', left),
        Expanded(
          child: Semantics(
            label: 'Balance. Left $left, right $right',
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(trackShape: const CenterTrackShape()),
              child: Slider(
                value: v.toDouble(),
                min: 0,
                max: 100,
                divisions: 100,
                onChanged: c.isReady
                    ? (x) {
                        // Snap to centre so it's easy to return to even.
                        var r = x.round();
                        if ((r - 50).abs() <= 2) r = 50;
                        if (r == 50 && v != 50) HapticFeedback.selectionClick();
                        c.previewBalance(r);
                      }
                    : null,
                onChangeEnd: (x) {
                  var r = x.round();
                  if ((r - 50).abs() <= 2) r = 50;
                  c.setBalance(r);
                },
              ),
            ),
          ),
        ),
        side('Right', right),
      ],
    );
  }
}

Future<String?> promptText(
  BuildContext context, {
  required String title,
  required String label,
  required String initial,
  int maxLength = 24,
}) {
  final ctrl = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        maxLength: maxLength,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(labelText: label),
        onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('Save')),
      ],
    ),
  );
}
