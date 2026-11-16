import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/store.dart';
import '../../device/headset_controller.dart';
import '../../protocol/commands.dart';
import '../scope.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/headphone_art.dart';
import '../widgets/noise_field.dart';
import '../widgets/panel.dart';

const momentIcons = <String, IconData>{
  'train': Icons.train_outlined,
  'focus': Icons.center_focus_strong_outlined,
  'walk': Icons.directions_walk_rounded,
  'game': Icons.sports_esports_outlined,
  'flight': Icons.flight_outlined,
  'work': Icons.work_outline_rounded,
  'night': Icons.bedtime_outlined,
  'run': Icons.directions_run_rounded,
  'tune': Icons.tune_rounded,
};

const _strengthLabels = ['Low', 'Medium', 'High'];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  NoiseScene _lastCancel = NoiseScenes.adaptive;

  @override
  Widget build(BuildContext context) {
    final c = HeadsetScope.of(context);
    final s = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final noise = c.noise;
    if (noise != null && noise.scene.family == NoiseFamily.cancel) _lastCancel = noise.scene;
    final family = noise?.scene.family;

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _Header(c: c)),
          const SliverToBoxAdapter(child: LinkBanner()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Panel(
                padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const SizedBox(width: 4),
                        const Expanded(child: Legend('Noise control')),
                        if (noise != null && noise.scene.family != NoiseFamily.off)
                          Legend(
                            noise.scene.family == NoiseFamily.cancel ? 'Cancelling' : 'Letting sound in',
                            color: s.primary,
                          ),
                        const SizedBox(width: 4),
                      ],
                    ),
                    NoiseField(
                      family: family,
                      active: c.isReady,
                      child: _ModeReadout(noise: noise, ready: c.isReady),
                    ),
                    SlideSwitch<NoiseFamily>(
                      semanticLabel: 'Noise control',
                      height: 60,
                      values: const [NoiseFamily.off, NoiseFamily.cancel, NoiseFamily.aware],
                      labels: const ['Off', 'Cancel', 'Aware'],
                      selected: family,
                      enabled: c.isReady,
                      onChanged: (f) {
                        final scene = switch (f) {
                          NoiseFamily.off => NoiseScenes.off,
                          NoiseFamily.aware => NoiseScenes.transparency,
                          NoiseFamily.cancel => _lastCancel,
                        };
                        c.setNoise(scene, scene.defaultLevel);
                      },
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutQuart,
                      alignment: Alignment.topCenter,
                      child: family == NoiseFamily.cancel
                          ? _CancelDetails(c: c, noise: noise!)
                          : const SizedBox(width: double.infinity),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: PanelSection(
              legend: 'Moments',
              trailing: TextButton.icon(
                onPressed: c.isReady ? () => _saveMoment(context, c) : null,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Save current'),
              ),
              padding: const EdgeInsets.fromLTRB(16, 24, 8, 0),
              child: const SizedBox.shrink(),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: MediaQuery.textScalerOf(context).scale(148).clamp(148, 220),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: c.moments.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, i) => _MomentKey(moment: c.moments[i]),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Text(
                'Tap a moment to apply it. Press and hold for options.',
                style: t.bodySmall?.copyWith(color: s.onSurfaceVariant),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: PanelSection(
              legend: 'Latency',
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              child: PanelGroup(
                children: [
                  PanelRow(
                    icon: Icons.speed_rounded,
                    title: 'Gaming mode',
                    subtitle: 'Lower audio delay for games and video',
                    enabled: c.isReady,
                    onTap: () => c.setGaming(!c.gaming),
                    trailing: Switch(value: c.gaming, onChanged: c.isReady ? c.setGaming : null),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveMoment(BuildContext context, HeadsetController c) async {
    final result = await showModalBottomSheet<(String, String)>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _SaveMomentSheet(),
    );
    if (result != null) c.saveMoment(result.$1, result.$2);
  }
}

/// Mode name in a fixed cell; changes roll through like a flap, never reflow.
class _ModeReadout extends StatelessWidget {
  const _ModeReadout({required this.noise, required this.ready});
  final NoiseState? noise;
  final bool ready;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final reduce = MediaQuery.of(context).disableAnimations;
    final scene = noise?.scene;
    final name = scene?.label ?? (ready ? 'Reading' : 'Offline');
    final sub = scene == null
        ? (ready ? 'Asking the headphones…' : 'Not connected')
        : scene.hasStrength
        ? '${scene.hint} · ${_strengthLabels[noise!.level.clamp(0, 2)]}'
        : scene.hint;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRect(
          child: SizedBox(
            height: 40,
            child: AnimatedSwitcher(
              duration: reduce ? Duration.zero : const Duration(milliseconds: 360),
              switchInCurve: Curves.easeOutQuart,
              switchOutCurve: Curves.easeInQuart,
              transitionBuilder: (child, anim) => SlideTransition(
                position: Tween(begin: const Offset(0, 0.6), end: Offset.zero).animate(anim),
                child: FadeTransition(opacity: anim, child: child),
              ),
              child: FittedBox(
                key: ValueKey(name),
                fit: BoxFit.scaleDown,
                child: Text(
                  name,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: t.headlineMedium?.copyWith(color: scene == null ? s.onSurfaceVariant : s.onSurface),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          sub,
          maxLines: 3,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: t.bodySmall?.copyWith(color: s.onSurfaceVariant, height: 1.3),
        ),
      ],
    );
  }
}

class _CancelDetails extends StatelessWidget {
  const _CancelDetails({required this.c, required this.noise});
  final HeadsetController c;
  final NoiseState noise;

  @override
  Widget build(BuildContext context) {
    final scene = noise.scene;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 18),
        const Padding(padding: EdgeInsets.only(left: 4), child: Legend('Environment')),
        const SizedBox(height: 10),
        // All five scenes stay visible, so the active one is never scrolled away.
        LayoutBuilder(
          builder: (context, box) {
            const gap = 8.0;
            final w = (box.maxWidth - gap * 2) / 3;
            final h = MediaQuery.textScalerOf(context).scale(84).clamp(84.0, 140.0);
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final sc in NoiseScenes.cancelScenes)
                  SizedBox(
                    width: w,
                    height: h,
                    child: _SceneKey(
                      scene: sc,
                      selected: sc.id == scene.id,
                      enabled: c.isReady,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        c.setNoise(sc, sc.id == scene.id ? noise.level : sc.defaultLevel);
                      },
                    ),
                  ),
              ],
            );
          },
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutQuart,
          alignment: Alignment.topCenter,
          child: scene.hasStrength
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 18),
                    const Padding(padding: EdgeInsets.only(left: 4), child: Legend('Strength')),
                    const SizedBox(height: 10),
                    SlideSwitch<int>(
                      semanticLabel: 'Cancelling strength',
                      height: 52,
                      values: [for (var i = 0; i < scene.levels; i++) i],
                      labels: [for (var i = 0; i < scene.levels; i++) _strengthLabels[i.clamp(0, 2)]],
                      selected: noise.level,
                      enabled: c.isReady,
                      onChanged: (v) => c.setNoise(scene, v),
                    ),
                  ],
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

class _SceneKey extends StatelessWidget {
  const _SceneKey({required this.scene, required this.selected, required this.enabled, required this.onTap});
  final NoiseScene scene;
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
      child: Material(
        color: selected ? s.surfaceContainerHighest : s.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radius + 2),
          side: BorderSide(color: selected ? s.primary : s.outlineVariant, width: selected ? 1.5 : 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? onTap : null,
          child: SizedBox.expand(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          scene.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.labelLarge?.copyWith(color: enabled ? s.onSurface : s.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    scene.hint,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: t.bodySmall?.copyWith(color: s.onSurfaceVariant, height: 1.25),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.c});
  final HeadsetController c;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final busy = c.link == Link.searching || c.link == Link.connecting;
    final status = c.isReady ? (c.syncing ? 'Syncing' : 'Connected') : (busy ? 'Connecting…' : 'Not connected');
    final battery = c.isReady ? c.battery : null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Panel(
        padding: const EdgeInsets.fromLTRB(12, 14, 6, 14),
        child: Row(
          children: [
            HeadphoneArt(connected: c.isReady, charging: c.isReady && c.charging, width: 132),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.deviceName, style: t.titleLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      StatusLamp(on: c.isReady, pulse: busy || c.syncing),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          status,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.bodyMedium?.copyWith(color: c.isReady ? s.tertiary : s.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: battery == null
                        ? Text(
                            key: const ValueKey('nobattery'),
                            c.isReady ? 'Reading battery…' : 'Battery shows when connected',
                            style: t.bodySmall?.copyWith(color: s.onSurfaceVariant),
                          )
                        : Row(
                            key: const ValueKey('battery'),
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('$battery', style: t.headlineMedium?.copyWith(fontFeatures: tabular, height: 1)),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 2, left: 2, right: 10),
                                child: Text('%', style: t.titleSmall?.copyWith(color: s.onSurfaceVariant)),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: BatteryCells(level: battery, charging: c.charging),
                              ),
                            ],
                          ),
                  ),
                  if (c.isReady && c.gaming) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.speed_rounded, size: 14, color: s.primary),
                        const SizedBox(width: 6),
                        Text('Low latency on', style: t.labelMedium?.copyWith(color: s.primary)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: IconButton(
                tooltip: c.isReady ? 'Reload from headphones' : 'Connect',
                onPressed: c.refresh,
                icon: Icon(Icons.refresh_rounded, color: s.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MomentKey extends StatelessWidget {
  const _MomentKey({required this.moment});
  final Moment moment;

  @override
  Widget build(BuildContext context) {
    final c = HeadsetScope.of(context);
    final s = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final active = c.activeMomentId == moment.id;
    final preset = c.presetById(moment.presetId);
    final noise = NoiseScenes.byId(moment.noiseId);
    final enabled = c.isReady;

    Widget line(IconData icon, String text) => Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        children: [
          Icon(icon, size: 12, color: s.onSurfaceVariant),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: t.bodySmall?.copyWith(color: s.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );

    return Semantics(
      button: true,
      selected: active,
      label: '${moment.name}: ${noise.label}, ${preset?.name ?? 'Signature'}${moment.gaming ? ', low latency' : ''}',
      excludeSemantics: true,
      child: Material(
        color: active ? s.surfaceContainerHigh : s.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          side: BorderSide(color: active ? s.primary : s.outlineVariant, width: active ? 1.5 : 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled
              ? () {
                  HapticFeedback.lightImpact();
                  c.applyMoment(moment);
                }
              : null,
          onLongPress: () => _actions(context, c),
          child: SizedBox(
            width: 156,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconTile(
                        momentIcons[moment.icon] ?? Icons.tune_rounded,
                        selected: active,
                        enabled: enabled,
                        size: 38,
                      ),
                      const Spacer(),
                      Detent(on: active, enabled: enabled, size: 8),
                    ],
                  ),
                  const Spacer(),
                  Text(moment.name, style: t.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  line(Icons.hearing_rounded, noise.label),
                  line(
                    Icons.graphic_eq_rounded,
                    '${preset?.name ?? 'Signature'}${moment.gaming ? ' · Low latency' : ''}',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _actions(BuildContext context, HeadsetController c) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(moment.name, style: Theme.of(ctx).textTheme.titleLarge),
            ),
            PanelRow(
              icon: Icons.play_arrow_rounded,
              title: 'Apply',
              enabled: c.isReady,
              onTap: () {
                Navigator.pop(ctx);
                c.applyMoment(moment);
              },
              trailing: const SizedBox.shrink(),
            ),
            PanelRow(
              icon: Icons.delete_outline_rounded,
              title: 'Remove moment',
              destructive: true,
              onTap: () {
                Navigator.pop(ctx);
                c.deleteMoment(moment.id);
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(content: Text('Removed “${moment.name}”')));
              },
              trailing: const SizedBox.shrink(),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _SaveMomentSheet extends StatefulWidget {
  const _SaveMomentSheet();

  @override
  State<_SaveMomentSheet> createState() => _SaveMomentSheetState();
}

class _SaveMomentSheetState extends State<_SaveMomentSheet> {
  final _name = TextEditingController();
  String _icon = 'tune';

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 0, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Save as a moment', style: t.titleLarge),
          const SizedBox(height: 6),
          Text(
            'Captures the current noise control, sound and gaming mode.',
            style: t.bodyMedium?.copyWith(color: s.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _name,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            maxLength: 24,
            decoration: const InputDecoration(labelText: 'Name', hintText: 'e.g. Flight'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          const Legend('Symbol'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final e in momentIcons.entries)
                Semantics(
                  button: true,
                  selected: _icon == e.key,
                  label: e.key,
                  child: Material(
                    color: _icon == e.key ? s.surfaceContainerHighest : s.surfaceContainerLowest,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radius + 2),
                      side: BorderSide(color: _icon == e.key ? s.primary : s.outlineVariant),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppTheme.radius + 2),
                      onTap: () => setState(() => _icon = e.key),
                      child: SizedBox.square(
                        dimension: 52,
                        child: Icon(e.value, color: _icon == e.key ? s.primary : s.onSurfaceVariant),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _name.text.trim().isEmpty ? null : () => Navigator.pop(context, (_name.text.trim(), _icon)),
              child: const Text('Save moment'),
            ),
          ),
        ],
      ),
    );
  }
}
