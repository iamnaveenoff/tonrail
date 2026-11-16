import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tonrail/data/store.dart';
import 'package:tonrail/device/headset_controller.dart';
import 'package:tonrail/main.dart';
import 'package:tonrail/protocol/commands.dart';
import 'package:tonrail/protocol/framing.dart';
import 'package:tonrail/ui/appearance.dart';
import 'package:tonrail/ui/scope.dart';
import 'package:tonrail/ui/screens/splash_screen.dart';
import 'package:tonrail/ui/theme.dart';

Future<void> _loadFonts() async {
  final loader = FontLoader('Archivo');
  for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    final bytes = File('assets/fonts/Archivo-$w.ttf').readAsBytesSync();
    loader.addFont(Future.value(ByteData.view(bytes.buffer)));
  }
  await loader.load();
}

/// Stands in for the headphones: every command is acknowledged and logged.
class _AckingController extends HeadsetController {
  _AckingController(super.store);
  final sent = <String>[];

  @override
  Future<Packet?> send(DeviceCommand c, {Duration timeout = const Duration(seconds: 3)}) async {
    sent.add(c.label);
    return Packet(isCommand: false, wantsResponse: false, opcode: c.opcode, sn: 0, status: 0, payload: Uint8List(0));
  }
}

Future<HeadsetController> _controller({bool ready = true}) async {
  SharedPreferences.setMockInitialValues({});
  final store = await Store.open();
  Appearance.instance = Appearance(store);
  final c = ready ? _AckingController(store) : HeadsetController(store);
  if (ready) {
    c.link = Link.ready;
    c.battery = 40;
    c.noise = const NoiseState(NoiseScenes.commuting, 2);
    c.powerKnown = true;
  }
  return c;
}

Future<void> _pumpShell(
  WidgetTester tester,
  HeadsetController c, {
  ThemeData? theme,
  double textScale = 1,
  Size size = const Size(412, 915),
}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    HeadsetScope(
      controller: c,
      child: MaterialApp(
        theme: theme ?? AppTheme.dark(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: const Shell(),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 600));
}

Future<void> _tapVisible(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pump(const Duration(milliseconds: 300));
  await tester.tap(f);
  for (var i = 0; i < 30; i++) {
    await tester.pump(const Duration(milliseconds: 40));
  }
}

Future<void> _tab(WidgetTester tester, String label) async {
  await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text(label)));
  await tester.pump(const Duration(milliseconds: 400));
}

/// Scrolls through the visible tab so every section is laid out and painted.
Future<void> _scrollThrough(WidgetTester tester) async {
  final scrollable = find.byType(Scrollable).hitTestable().first;
  for (var i = 0; i < 6; i++) {
    await tester.drag(scrollable, const Offset(0, -500));
    await tester.pump(const Duration(milliseconds: 200));
  }
}

void main() {
  setUpAll(_loadFonts);

  group('every screen lays out without overflow', () {
    for (final dark in [true, false]) {
      for (final scale in [1.0, 1.3]) {
        for (final ready in [true, false]) {
          testWidgets('${dark ? 'dark' : 'light'} · text ${scale}x · ${ready ? 'connected' : 'offline'}', (
            tester,
          ) async {
            final c = await _controller(ready: ready);
            await _pumpShell(tester, c, theme: dark ? AppTheme.dark() : AppTheme.light(), textScale: scale);
            for (final tab in ['Listen', 'Sound', 'Buttons', 'Device']) {
              await _tab(tester, tab);
              await _scrollThrough(tester);
            }
            expect(tester.takeException(), isNull);
          });
        }
      }
    }
  });

  testWidgets('splash plays and hands over', (tester) async {
    var done = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: SplashScreen(onDone: () => done = true),
      ),
    );
    expect(find.text('Tonrail'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1600));
    expect(done, isTrue);
  });

  testWidgets('Listen: noise switch, environments, strength, gaming', (tester) async {
    final c = await _controller();
    await _pumpShell(tester, c);
    expect(find.text('Connected'), findsOneWidget);
    expect(find.text('40'), findsOneWidget);

    // Each control sends its command and the UI follows the acknowledged state.
    final sent = (c as _AckingController).sent;
    await tester.tap(find.text('Aware'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(c.noise!.scene.id, 'aware');
    expect(sent.last, 'noise aware');

    await tester.tap(find.text('Cancel'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(c.noise!.scene.id, 'commuting');

    await tester.tap(find.text('Loud places').first);
    await tester.pump(const Duration(milliseconds: 600));
    expect(c.noise!.scene.id, 'noisy');
    expect(sent.last, 'noise noisy');

    await tester.tap(find.text('Low'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(c.noise!.scene.id, 'noisy');
    expect(c.noise!.level, 0);

    await tester.tap(find.text('Off'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(sent.last, 'noise off');

    await tester.drag(find.byType(Scrollable).first, const Offset(0, -900));
    await tester.pump(const Duration(milliseconds: 300));
    await _tapVisible(tester, find.text('Gaming mode'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(c.gaming, isTrue);
    expect(sent.last, 'gaming true');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Listen: save and remove a moment', (tester) async {
    final c = await _controller();
    await _pumpShell(tester, c);
    final before = c.moments.length;
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -500));
    await tester.pump(const Duration(milliseconds: 300));
    await _tapVisible(tester, find.text('Save current'));
    await tester.enterText(find.byType(TextField), 'Flight');
    await tester.pump();
    await _tapVisible(tester, find.byIcon(Icons.flight_outlined));
    await _tapVisible(tester, find.text('Save moment'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(c.moments.length, before + 1);
    expect(c.moments.last.name, 'Flight');
    expect(c.moments.last.icon, 'flight');

    c.deleteMoment(c.moments.last.id);
    expect(c.moments.length, before);
  });

  testWidgets('Sound: presets, band strip, steppers, tone, flat with undo, save', (tester) async {
    final c = await _controller();
    await _pumpShell(tester, c);
    await _tab(tester, 'Sound');

    await tester.drag(find.byType(Scrollable).hitTestable().first, const Offset(0, -700));
    await tester.pump(const Duration(milliseconds: 300));
    await _tapVisible(tester, find.text('Rock'));
    expect(c.activePresetId, 'rock');

    await tester.drag(find.byType(Scrollable).hitTestable().first, const Offset(0, 700));
    await tester.pump(const Duration(milliseconds: 300));

    // Select 60 Hz in the band strip and raise it twice.
    await _tapVisible(tester, find.bySemanticsLabel(RegExp(r'^60 Hz')));
    await _tapVisible(tester, find.byTooltip('Raise 0.5 dB'));
    await _tapVisible(tester, find.byTooltip('Raise 0.5 dB'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(c.draft[0].gain, 1.0);
    expect(c.activePresetId, isNull);
    await tester.drag(find.byType(Scrollable).hitTestable().first, const Offset(0, 1500));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Custom curve · not saved'), findsOneWidget);

    // Start flat, then undo.
    await _tapVisible(tester, find.text('Start flat'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(c.draft.every((b) => b.gain == 0), isTrue);
    await _tapVisible(tester, find.text('Undo'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(c.draft[0].gain, 1.0);

    // Quick tone: drag Bass up; both low bands rise together.
    await tester.ensureVisible(find.text('Weight and punch'));
    await tester.pump(const Duration(milliseconds: 300));
    final bass = find.byType(Slider).hitTestable().first;
    await tester.drag(bass, const Offset(60, 0));
    await tester.pump(const Duration(milliseconds: 300));
    expect(c.draft[1].gain, greaterThan(0));

    // Save as a preset.
    await tester.drag(find.byType(Scrollable).hitTestable().first, const Offset(0, 1200));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.widgetWithText(OutlinedButton, 'Save'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.enterText(find.byType(TextField), 'Mine');
    await tester.tap(find.widgetWithText(FilledButton, 'Save').last);
    await tester.pump(const Duration(milliseconds: 600));
    expect(c.userPresets.single.name, 'Mine');
    expect(c.activePresetId, c.userPresets.single.id);

    // Hold to compare returns to the curve on release.
    final gesture = await tester.startGesture(tester.getCenter(find.text('Hold to compare')));
    await tester.pump();
    expect(find.text('Playing flat'), findsOneWidget);
    await gesture.up();
    await tester.pump();
    expect(find.text('Hold to compare'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Buttons: pick a new action for a press', (tester) async {
    final c = await _controller();
    await _pumpShell(tester, c);
    await _tab(tester, 'Buttons');
    await tester.tap(find.bySemanticsLabel(RegExp('Multifunction, Press four times')));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Default: Do nothing'), findsOneWidget);
    await _tapVisible(tester, find.text('Next track'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(c.functionFor(ButtonMap.gestures[3]), 3);
    expect(find.text('CHANGED'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Device: appearance, power-off sheet, toggles, diagnostics', (tester) async {
    final c = await _controller();
    await _pumpShell(tester, c);
    await _tab(tester, 'Device');

    await _tapVisible(tester, find.text('Auto power-off'));
    expect(find.text('30 minutes'), findsOneWidget);
    await _tapVisible(tester, find.text('30 minutes'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(c.powerMinutes, 30);

    await _tapVisible(tester, find.text('Appearance'));
    await tester.tap(find.text('Light'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(Appearance.instance.value, ThemeMode.light);

    final keep = c.store.keepNoise;
    await _tapVisible(tester, find.text('Restore noise control'));
    expect(c.store.keepNoise, !keep);

    await tester.drag(find.byType(Scrollable).hitTestable().first, const Offset(0, -500));
    await tester.pump(const Duration(milliseconds: 300));
    await _tapVisible(tester, find.text('Diagnostics'));
    expect(find.text('Nothing sent yet'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
