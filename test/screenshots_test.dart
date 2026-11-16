// Renders the README screenshots into docs/screenshots/.
//
//   flutter test test/screenshots_test.dart --dart-define=SCREENSHOTS=true
//
// Skipped in normal test runs. Uses demo state only, so no personal data
// ever reaches the repository.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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

const _enabled = bool.fromEnvironment('SCREENSHOTS');
const _size = Size(412, 892);
const _ratio = 2.0;
final _boundary = GlobalKey();

class _DemoController extends HeadsetController {
  _DemoController(super.store);

  @override
  Future<Packet?> send(DeviceCommand c, {Duration timeout = const Duration(seconds: 3)}) async =>
      Packet(isCommand: false, wantsResponse: false, opcode: c.opcode, sn: 0, status: 0, payload: Uint8List(0));
}

Future<void> _loadFonts() async {
  Future<void> load(String family, List<String> files) async {
    final loader = FontLoader(family);
    for (final f in files) {
      loader.addFont(Future.value(ByteData.view(File(f).readAsBytesSync().buffer)));
    }
    await loader.load();
  }

  await load('Archivo', [
    for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold']) 'assets/fonts/Archivo-$w.ttf',
  ]);
  final sdk = Platform.environment['FLUTTER_ROOT']!;
  await load('MaterialIcons', ['$sdk/bin/cache/artifacts/material_fonts/materialicons-regular.otf']);
}

Future<HeadsetController> _demo({bool connected = true}) async {
  SharedPreferences.setMockInitialValues({});
  final store = await Store.open();
  Appearance.instance = Appearance(store);
  final c = _DemoController(store);
  if (!connected) return c;
  c
    ..link = Link.ready
    ..battery = 82
    ..noise = const NoiseState(NoiseScenes.commuting, 2)
    ..powerKnown = true
    ..powerMinutes = 30
    ..activeMomentId = 'commute'
    ..keys = {(7 << 8) | 4: 3};
  c.setBands([
    for (final (i, g) in [-1.0, -0.5, 0.0, 1.0, 1.5, 2.0, 1.0, -1.0, -2.0, -2.5].indexed)
      EqBand(Eq.userFreqs[i], g, Eq.userQs[i]),
  ]);
  c.savePreset('Late night');
  c.setBands([
    for (final (i, g) in [4.0, 2.5, 0.5, -1.0, 0.0, 1.5, 2.0, 3.0, 1.5, 0.5].indexed)
      EqBand(Eq.userFreqs[i], g, Eq.userQs[i]),
  ]);
  return c;
}

Future<void> _pump(WidgetTester tester, Widget home, HeadsetController c, {ThemeData? theme}) async {
  tester.view.physicalSize = _size * _ratio;
  tester.view.devicePixelRatio = _ratio;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    RepaintBoundary(
      key: _boundary,
      child: HeadsetScope(
        controller: c,
        child: MaterialApp(debugShowCheckedModeBanner: false, theme: theme ?? AppTheme.dark(), home: home),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 900));
}

Future<void> _tab(WidgetTester tester, String label) async {
  await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text(label)));
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _scroll(WidgetTester tester, double dy) async {
  await tester.drag(find.byType(Scrollable).hitTestable().first, Offset(0, -dy));
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _shot(WidgetTester tester, String name) async {
  await tester.pump(const Duration(milliseconds: 1300));
  await tester.runAsync(() async {
    final boundary = _boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: _ratio);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('docs/screenshots/$name.png')..createSync(recursive: true);
    file.writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

void main() {
  setUpAll(() async {
    if (_enabled) await _loadFonts();
  });

  testWidgets('screenshots', skip: !_enabled, (tester) async {
    await _pump(tester, SplashScreen(onDone: () {}), await _demo());
    await tester.pump(const Duration(milliseconds: 1600));
    await _shot(tester, 'splash');

    final c = await _demo();
    await _pump(tester, const Shell(), c);
    await _shot(tester, 'listen');

    await _scroll(tester, 560);
    await _shot(tester, 'moments');

    await _tab(tester, 'Sound');
    await _shot(tester, 'sound');
    await _scroll(tester, 640);
    await _shot(tester, 'presets');

    await _tab(tester, 'Buttons');
    await _shot(tester, 'buttons');

    await _tab(tester, 'Device');
    await _shot(tester, 'device');

    await _pump(tester, Shell(key: UniqueKey()), await _demo(), theme: AppTheme.light());
    await _shot(tester, 'listen-light');

    await _pump(tester, Shell(key: UniqueKey()), await _demo(connected: false));
    await _shot(tester, 'offline');
  });
}
