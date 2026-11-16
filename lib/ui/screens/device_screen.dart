import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../device/headset_controller.dart';
import '../appearance.dart';
import '../scope.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/panel.dart';
import 'sound_screen.dart' show promptText;
import 'splash_screen.dart' show BrandMark;

class DeviceScreen extends StatelessWidget {
  const DeviceScreen({super.key});

  static const _custom = -1;
  static const _never = 0;
  static const _powerChoices = <int>[_never, 15, 30, 60, 90];

  String _powerLabel(HeadsetController c) {
    if (!c.powerKnown) return 'Unknown';
    final m = c.powerMinutes;
    if (m == null) return 'Never';
    return m < 60 || m % 60 != 0 ? '$m min' : '${m ~/ 60} h';
  }

  @override
  Widget build(BuildContext context) {
    final c = HeadsetScope.of(context);
    final s = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          PanelHeader(
            'Device',
            caption: Row(
              children: [
                StatusLamp(on: c.isReady),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    c.isReady ? '${c.deviceName} · connected' : '${c.deviceName} · offline',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.bodyMedium?.copyWith(color: s.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
          const LinkBanner(),
          PanelSection(
            legend: 'Headphones',
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: PanelGroup(
              children: [
                PanelRow(
                  icon: Icons.badge_outlined,
                  title: 'Name',
                  value: c.deviceName,
                  enabled: c.isReady,
                  onTap: () async {
                    final name = await promptText(
                      context,
                      title: 'Rename headphones',
                      label: 'Name',
                      initial: c.deviceName,
                      maxLength: 20,
                    );
                    if (name != null && name.isNotEmpty && name != c.deviceName) await c.rename(name);
                  },
                ),
                PanelRow(
                  icon: Icons.timer_outlined,
                  title: 'Auto power-off',
                  subtitle: 'Turns the headphones off after they sit idle',
                  value: _powerLabel(c),
                  enabled: c.isReady,
                  onTap: () => _pickPower(context, c),
                ),
              ],
            ),
          ),
          PanelSection(
            legend: 'Behaviour',
            child: PanelGroup(
              children: [
                ValueListenableBuilder<ThemeMode>(
                  valueListenable: Appearance.instance,
                  builder: (context, mode, _) => PanelRow(
                    icon: Icons.contrast_rounded,
                    title: 'Appearance',
                    value: switch (mode) {
                      ThemeMode.dark => 'Dark',
                      ThemeMode.light => 'Light',
                      ThemeMode.system => 'System',
                    },
                    onTap: () async {
                      final picked = await showChoiceSheet<ThemeMode>(
                        context,
                        title: 'Appearance',
                        current: mode,
                        choices: const [
                          (ThemeMode.dark, 'Dark', Icons.dark_mode_outlined),
                          (ThemeMode.light, 'Light', Icons.light_mode_outlined),
                          (ThemeMode.system, 'Match the system', Icons.brightness_auto_outlined),
                        ],
                      );
                      if (picked != null) Appearance.instance.set(picked);
                    },
                  ),
                ),
                PanelRow(
                  icon: Icons.restore_rounded,
                  title: 'Restore noise control',
                  subtitle: 'Re-apply your last mode whenever the headphones reconnect',
                  onTap: () => c.setKeepNoise(!c.store.keepNoise),
                  trailing: Switch(value: c.store.keepNoise, onChanged: c.setKeepNoise),
                ),
                PanelRow(
                  icon: Icons.vertical_align_center_rounded,
                  title: 'Headroom protection',
                  subtitle: 'Lower output when a custom curve boosts, so peaks never distort',
                  onTap: () => c.setHeadroom(!c.store.headroom),
                  trailing: Switch(value: c.store.headroom, onChanged: c.setHeadroom),
                ),
              ],
            ),
          ),
          PanelSection(
            legend: 'Connection',
            child: PanelGroup(
              children: [
                PanelRow(
                  icon: c.isReady ? Icons.link_off_rounded : Icons.link_rounded,
                  title: c.isReady ? 'Disconnect' : 'Connect',
                  subtitle: c.isReady
                      ? 'Release the control link so another app can use it'
                      : 'Close the headphones\' official app first',
                  onTap: c.isReady ? c.disconnect : c.connect,
                ),
                PanelRow(
                  icon: Icons.receipt_long_outlined,
                  title: 'Diagnostics',
                  subtitle: 'Protocol log · EQ format ${c.eqV2 ? 'v2' : 'v1'}',
                  onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const _LogScreen())),
                ),
              ],
            ),
          ),
          PanelSection(
            legend: 'Reset',
            child: PanelGroup(
              children: [
                PanelRow(
                  icon: Icons.settings_backup_restore_rounded,
                  title: 'Restore headphone defaults',
                  subtitle: 'Sound, buttons and modes go back to factory settings',
                  enabled: c.isReady,
                  onTap: () => _confirm(
                    context,
                    title: 'Restore headphone defaults?',
                    body:
                        'Sound, button assignments and modes on the headphones reset. Presets saved in this app stay.',
                    action: 'Restore',
                    run: c.resetSettings,
                  ),
                ),
                PanelRow(
                  icon: Icons.phonelink_erase_rounded,
                  title: 'Forget all paired phones',
                  subtitle: 'You will need to pair this phone again',
                  destructive: true,
                  enabled: c.isReady,
                  onTap: () => _confirm(
                    context,
                    title: 'Forget all paired phones?',
                    body:
                        'The headphones drop every pairing, including this phone. Pair again from Android Bluetooth settings afterwards.',
                    action: 'Forget all',
                    destructive: true,
                    run: c.clearPairings,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 40, 20, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const BrandMark(size: 36),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tonrail', style: t.titleSmall),
                      const SizedBox(height: 4),
                      Text(
                        'An independent open-source app, not affiliated with or endorsed by any headphone maker. '
                        'Firmware updates are not offered here.',
                        style: t.bodySmall?.copyWith(color: s.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickPower(BuildContext context, HeadsetController c) async {
    final current = !c.powerKnown ? null : (c.powerMinutes ?? _never);
    final known = current == null || _powerChoices.contains(current) ? current : _custom;
    final picked = await showChoiceSheet<int>(
      context,
      title: 'Auto power-off',
      caption: 'Turn off after the headphones sit idle for…',
      current: known,
      choices: [
        for (final m in _powerChoices)
          (
            m,
            m == _never
                ? 'Never'
                : m < 60
                ? '$m minutes'
                : m == 60
                ? '1 hour'
                : '${m / 60} hours',
            null,
          ),
        (_custom, known == _custom ? 'Custom · ${c.powerMinutes} minutes' : 'Custom…', null),
      ],
    );
    if (picked == null || !context.mounted) return;
    if (picked == _custom) {
      final v = await promptText(
        context,
        title: 'Minutes before power-off',
        label: 'Minutes (1–600)',
        initial: '',
        maxLength: 3,
      );
      final n = int.tryParse(v ?? '');
      if (n != null && n >= 1 && n <= 600) {
        await c.setPowerOff(n);
      } else if (v != null && v.isNotEmpty && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a number from 1 to 600')));
      }
      return;
    }
    await c.setPowerOff(picked == _never ? null : picked);
  }

  Future<void> _confirm(
    BuildContext context, {
    required String title,
    required String body,
    required String action,
    bool destructive = false,
    required Future<bool> Function() run,
  }) async {
    final s = Theme.of(context).colorScheme;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: destructive ? FilledButton.styleFrom(backgroundColor: s.error, foregroundColor: s.onError) : null,
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(action),
          ),
        ],
      ),
    );
    if (ok == true) await run();
  }
}

class _LogScreen extends StatelessWidget {
  const _LogScreen();

  @override
  Widget build(BuildContext context) {
    final c = HeadsetScope.of(context);
    final s = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final lines = c.logs.reversed.toList();
    String two(int v) => v.toString().padLeft(2, '0');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnostics'),
        actions: [
          IconButton(
            tooltip: 'Copy log',
            icon: const Icon(Icons.copy_all_outlined),
            onPressed: lines.isEmpty
                ? null
                : () {
                    Clipboard.setData(
                      ClipboardData(
                        text: c.logs.map((l) => '${l.time.toIso8601String()} ${l.dir} ${l.text}').join('\n'),
                      ),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Log copied')));
                  },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: lines.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.receipt_long_outlined, size: 32, color: s.onSurfaceVariant),
                  const SizedBox(height: 12),
                  Text('Nothing sent yet', style: t.titleSmall),
                  const SizedBox(height: 4),
                  Text(
                    'Commands appear here once the headphones connect.',
                    style: t.bodySmall?.copyWith(color: s.onSurfaceVariant),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              itemCount: lines.length,
              separatorBuilder: (_, _) => Divider(color: s.outlineVariant.withValues(alpha: 0.5)),
              itemBuilder: (_, i) {
                final l = lines[i];
                final color = switch (l.dir) {
                  '→' => s.primary,
                  '←' => s.tertiary,
                  '!' => s.error,
                  _ => s.onSurfaceVariant,
                };
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '${two(l.time.hour)}:${two(l.time.minute)}:${two(l.time.second)}  ',
                          style: TextStyle(color: s.outline),
                        ),
                        TextSpan(
                          text: '${l.dir} ',
                          style: TextStyle(color: color, fontWeight: FontWeight.w700),
                        ),
                        TextSpan(text: l.text),
                      ],
                    ),
                    style: t.bodySmall?.copyWith(fontFamily: 'monospace', fontFeatures: tabular, height: 1.45),
                  ),
                );
              },
            ),
    );
  }
}
