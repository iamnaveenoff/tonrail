import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'data/store.dart';
import 'device/headset_controller.dart';
import 'ui/appearance.dart';
import 'ui/scope.dart';
import 'ui/screens/buttons_screen.dart';
import 'ui/screens/device_screen.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/sound_screen.dart';
import 'ui/screens/splash_screen.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
  final store = await Store.open();
  Appearance.instance = Appearance(store);
  final controller = HeadsetController(store);
  runApp(TonrailApp(controller: controller));
  WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(controller.start()));
}

class TonrailApp extends StatelessWidget {
  const TonrailApp({super.key, required this.controller});
  final HeadsetController controller;

  static final _light = AppTheme.light();
  static final _dark = AppTheme.dark();

  @override
  Widget build(BuildContext context) {
    return HeadsetScope(
      controller: controller,
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: Appearance.instance,
        builder: (context, mode, _) => MaterialApp(
          title: 'Tonrail',
          debugShowCheckedModeBanner: false,
          theme: _light,
          darkTheme: _dark,
          themeMode: mode,
          builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
            value: AppTheme.overlay(Theme.of(context).colorScheme),
            child: child!,
          ),
          home: const _Root(),
        ),
      ),
    );
  }
}

/// Splash first, then the app, crossfaded.
class _Root extends StatefulWidget {
  const _Root();

  @override
  State<_Root> createState() => _RootState();
}

class _RootState extends State<_Root> {
  bool _ready = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 420),
      switchInCurve: Curves.easeOutCubic,
      child: _ready
          ? const Shell()
          : SplashScreen(key: const ValueKey('splash'), onDone: () => setState(() => _ready = true)),
    );
  }
}

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> with SingleTickerProviderStateMixin {
  int _tab = 0;
  StreamSubscription<String>? _sub;
  late final _fade = AnimationController(vsync: this, duration: const Duration(milliseconds: 220), value: 1);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sub ??= HeadsetScope.read(context).messages.listen((m) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(m)));
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _fade.dispose();
    super.dispose();
  }

  void _select(int i) {
    if (i == _tab) return;
    HapticFeedback.selectionClick();
    setState(() => _tab = i);
    if (!MediaQuery.of(context).disableAnimations) _fade.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _fade,
        builder: (context, child) {
          final v = Curves.easeOutCubic.transform(_fade.value);
          return Opacity(
            opacity: 0.2 + 0.8 * v,
            child: Transform.translate(offset: Offset(0, 8 * (1 - v)), child: child),
          );
        },
        child: IndexedStack(
          index: _tab,
          children: [
            // Hidden tabs keep their state but stop animating.
            for (final (i, screen) in const [HomeScreen(), SoundScreen(), ButtonsScreen(), DeviceScreen()].indexed)
              TickerMode(enabled: i == _tab, child: screen),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: _select,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.headphones_outlined),
            selectedIcon: Icon(Icons.headphones_rounded),
            label: 'Listen',
          ),
          NavigationDestination(
            icon: Icon(Icons.graphic_eq_rounded),
            selectedIcon: Icon(Icons.graphic_eq_rounded),
            label: 'Sound',
          ),
          NavigationDestination(
            icon: Icon(Icons.radio_button_unchecked_rounded),
            selectedIcon: Icon(Icons.radio_button_checked_rounded),
            label: 'Buttons',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_rounded),
            selectedIcon: Icon(Icons.tune_rounded),
            label: 'Device',
          ),
        ],
      ),
    );
  }
}
