import 'package:flutter/material.dart';

import '../../device/headset_controller.dart';
import '../scope.dart';
import 'panel.dart';

/// Explains why controls are unavailable and offers the one fixing action.
class LinkBanner extends StatelessWidget {
  const LinkBanner({super.key, this.padding = const EdgeInsets.fromLTRB(16, 0, 16, 12)});
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final c = HeadsetScope.of(context);
    final s = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    final (IconData icon, String title, String body, String? action, VoidCallback? onTap) = switch (c.link) {
      Link.ready => (Icons.check, '', '', null, null),
      Link.searching => (
        Icons.bluetooth_searching_rounded,
        'Looking for your headphones',
        'Keep them switched on and close to your phone.',
        null,
        null,
      ),
      Link.connecting => (Icons.bluetooth_connected_rounded, 'Connecting', 'Opening the control link…', null, null),
      Link.bluetoothOff => (
        Icons.bluetooth_disabled_rounded,
        'Bluetooth is off',
        'Turn it on to control your headphones.',
        'Turn on',
        c.turnOnBluetooth,
      ),
      Link.permissions => (
        Icons.lock_outline_rounded,
        'Nearby devices permission needed',
        'Allow it so the app can talk to your headphones. Nothing else is accessed.',
        'Allow',
        c.openPermissionSettings,
      ),
      Link.notFound => (
        Icons.headset_off_outlined,
        'Headphones not reachable',
        'Turn them on and close the headphones\' official app; only one app can hold the control link. Retrying automatically.',
        'Try now',
        c.connect,
      ),
      Link.idle => (
        Icons.headset_outlined,
        'Not connected',
        'Your settings are stored on the headphones and load when connected.',
        'Connect',
        c.connect,
      ),
    };

    final busy = c.link == Link.searching || c.link == Link.connecting;

    return AnimatedSize(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: c.isReady
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: padding,
              child: Semantics(
                liveRegion: true,
                child: Panel(
                  color: s.surfaceContainer,
                  padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox.square(
                        dimension: 24,
                        child: busy
                            ? Padding(
                                padding: const EdgeInsets.all(3),
                                child: CircularProgressIndicator(strokeWidth: 2, color: s.primary),
                              )
                            : Icon(icon, color: s.primary, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, style: t.titleSmall),
                            const SizedBox(height: 2),
                            Text(body, style: t.bodySmall?.copyWith(color: s.onSurfaceVariant)),
                          ],
                        ),
                      ),
                      if (action != null) ...[
                        const SizedBox(width: 8),
                        FilledButton(onPressed: onTap, child: Text(action)),
                      ],
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
