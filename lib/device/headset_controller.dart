import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../data/store.dart';
import '../protocol/commands.dart';
import '../protocol/framing.dart';

enum Link { idle, permissions, bluetoothOff, searching, connecting, ready, notFound }

class LogLine {
  LogLine(this.dir, this.text) : time = DateTime.now();
  final DateTime time;
  final String dir;
  final String text;
}

/// Owns the BLE link to the headphones and mirrors their settings.
class HeadsetController extends ChangeNotifier {
  HeadsetController(this.store)
    : userPresets = store.userPresets,
      moments = store.moments,
      activePresetId = store.activePresetId,
      draft = store.draftBands ?? Eq.flatBands() {
    final active = presetById(activePresetId);
    eqBands = active?.bands ?? draft;
    eqMaster = active?.masterGain ?? 0;
  }

  static final _service = Guid('A002');
  static final _writeUuid = Guid('0001');
  static final _notifyUuid = Guid('0002');
  static const _manufacturerId = 0x522C;

  // Bluetooth names the supported headphones advertise (README ? Compatibility).
  static const _controlNameHint = 'P10-APP';
  static const _audioNameHint = 'SA-HP';

  final Store store;

  // Link -----------------------------------------------------------------
  Link link = Link.idle;
  bool syncing = false;
  BluetoothDevice? _device;
  BluetoothCharacteristic? _tx;
  StreamSubscription<List<int>>? _rxSub;
  StreamSubscription<BluetoothConnectionState>? _connSub;
  StreamSubscription<BluetoothAdapterState>? _adapterSub;
  final _decoder = FrameDecoder();
  final _pending = <int, (int, Completer<Packet>)>{};
  int _sn = 0;
  Future<void> _writeChain = Future.value();
  bool _userDisconnected = false;
  Timer? _poll;
  Timer? _reconnect;
  Timer? _eqDebounce;
  int _attempt = 0;

  final _messages = StreamController<String>.broadcast();
  Stream<String> get messages => _messages.stream;
  final logs = <LogLine>[];

  // Mirrored device state -------------------------------------------------
  String deviceName = 'Headphones';
  int? battery;
  bool charging = false;
  NoiseState? noise;
  bool gaming = false;
  int balance = 50;
  Map<int, int> keys = {};
  bool powerKnown = false;
  int? powerMinutes;
  bool eqV2 = true;
  late List<EqBand> eqBands;
  late double eqMaster;
  List<EqBand> draft;
  String? activePresetId;
  List<EqPreset> userPresets;
  List<Moment> moments;
  String? activeMomentId;

  bool get isReady => link == Link.ready;

  List<EqPreset> get allPresets => [...Eq.factoryPresets, ...userPresets];

  EqPreset? presetById(String? id) {
    if (id == null) return null;
    for (final p in allPresets) {
      if (p.id == id) return p;
    }
    return null;
  }

  // -----------------------------------------------------------------------
  // Connection
  // -----------------------------------------------------------------------

  Future<void> start() async {
    _adapterSub ??= FlutterBluePlus.adapterState.listen((s) {
      if (s == BluetoothAdapterState.off) {
        _teardown();
        _setLink(Link.bluetoothOff);
      } else if (s == BluetoothAdapterState.on && link == Link.bluetoothOff) {
        connect();
      }
    });
    await connect();
  }

  Future<void> connect() async {
    if (link == Link.searching || link == Link.connecting || link == Link.ready) return;
    _reconnect?.cancel();
    _userDisconnected = false;
    if (!await _ensurePermissions()) return;
    if (FlutterBluePlus.adapterStateNow != BluetoothAdapterState.on) {
      final on = await FlutterBluePlus.adapterState
          .where((s) => s == BluetoothAdapterState.on)
          .first
          .timeout(const Duration(seconds: 3), onTimeout: () => BluetoothAdapterState.off);
      if (on != BluetoothAdapterState.on) {
        _setLink(Link.bluetoothOff);
        return;
      }
    }
    _setLink(Link.searching);
    final device = await _findDevice();
    if (device == null) {
      _setLink(Link.notFound);
      _scheduleReconnect();
      return;
    }
    await _open(device);
  }

  Future<void> disconnect() async {
    _userDisconnected = true;
    _reconnect?.cancel();
    await _device?.disconnect();
    _teardown();
    _setLink(Link.idle);
  }

  Future<void> turnOnBluetooth() async {
    try {
      await FlutterBluePlus.turnOn();
    } catch (_) {
      _messages.add('Turn on Bluetooth from quick settings');
    }
  }

  Future<void> openPermissionSettings() => openAppSettings();

  Future<bool> _ensurePermissions() async {
    if (!Platform.isAndroid) return true;
    final r = await [Permission.bluetoothScan, Permission.bluetoothConnect].request();
    final ok = r.values.every((s) => s.isGranted || s.isLimited);
    if (!ok) _setLink(Link.permissions);
    return ok;
  }

  /// The headphones expose two identities: an audio link (classic Bluetooth)
  /// and a control link (Bluetooth LE, name ends in "-APP"). Only the latter carries service A002.
  static bool _isControlName(String name) => name.toUpperCase().contains(_controlNameHint);

  /// Classic audio MAC carried in the control link's manufacturer data.
  static String? audioMacFromAdv(List<int>? d) {
    if (d == null || d.length < 17) return null;
    String h(int i) => d[i].toRadixString(16).padLeft(2, '0');
    return [h(12), h(11), h(13), h(16), h(15), h(14)].join(':').toUpperCase();
  }

  Future<BluetoothDevice?> _findDevice() async {
    final saved = store.lastDeviceId;
    final audioMacs = <String>{};
    try {
      for (final d in await FlutterBluePlus.bondedDevices) {
        if (d.remoteId.str == saved || _isControlName(d.platformName)) return d;
        if (d.platformName.toUpperCase().contains(_audioNameHint)) audioMacs.add(d.remoteId.str.toUpperCase());
      }
    } catch (_) {}

    // Location is only needed for scanning on Android 11 and older.
    try {
      await Permission.locationWhenInUse.request();
    } catch (_) {}
    final found = Completer<BluetoothDevice?>();
    BluetoothDevice? fallback;
    final sub = FlutterBluePlus.onScanResults.listen((results) {
      for (final r in results) {
        final ad = r.advertisementData;
        final msd = ad.manufacturerData[_manufacturerId];
        final isP10 = msd != null || _isControlName(ad.advName) || r.device.remoteId.str == saved;
        if (!isP10) continue;
        _log('i', 'found ${ad.advName} ${r.device.remoteId.str} audio=${audioMacFromAdv(msd)}');
        // Prefer the control link belonging to the headphones paired with this phone.
        final mine = audioMacs.isEmpty || audioMacs.contains(audioMacFromAdv(msd));
        if (mine) {
          if (!found.isCompleted) found.complete(r.device);
        } else {
          fallback ??= r.device;
        }
      }
    });
    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 12));
      return await Future.any([found.future, FlutterBluePlus.isScanning.where((s) => !s).first.then((_) => fallback)]);
    } catch (e) {
      _log('!', 'scan failed: $e');
      return null;
    } finally {
      await sub.cancel();
      if (FlutterBluePlus.isScanningNow) await FlutterBluePlus.stopScan();
    }
  }

  Future<void> _open(BluetoothDevice device) async {
    _setLink(Link.connecting);
    try {
      await device.connect(license: License.nonprofit, timeout: const Duration(seconds: 15), mtu: 247);
      final services = await device.discoverServices();
      final svc = services.firstWhere(
        (s) => s.uuid == _service,
        orElse: () => throw StateError('Control service A002 not found'),
      );
      _tx = svc.characteristics.firstWhere((c) => c.uuid == _writeUuid);
      final rx = svc.characteristics.firstWhere((c) => c.uuid == _notifyUuid);
      _decoder.reset();
      _rxSub = rx.onValueReceived.listen(_onBytes);
      device.cancelWhenDisconnected(_rxSub!);
      await rx.setNotifyValue(true);
      _device = device;
      store.lastDeviceId = device.remoteId.str;
      if (device.platformName.isNotEmpty) {
        deviceName = device.platformName.replaceAll('-APP', '');
      }
      _connSub = device.connectionState.listen((s) {
        if (s == BluetoothConnectionState.disconnected) _onDisconnected();
      });
      _attempt = 0;
      _setLink(Link.ready);
      await _sync(initial: true);
      _poll = Timer.periodic(const Duration(seconds: 30), (_) => _refreshStatus());
    } catch (e) {
      _log('!', 'connect failed: $e');
      try {
        await device.disconnect();
      } catch (_) {}
      _teardown();
      _setLink(Link.notFound);
      _scheduleReconnect();
    }
  }

  void _onDisconnected() {
    if (link != Link.ready) return;
    _log('!', 'link lost');
    _teardown();
    _setLink(Link.idle);
    if (!_userDisconnected) _scheduleReconnect(soon: true);
  }

  void _teardown() {
    _poll?.cancel();
    _rxSub?.cancel();
    _connSub?.cancel();
    _rxSub = null;
    _connSub = null;
    _tx = null;
    syncing = false;
    for (final p in _pending.values) {
      if (!p.$2.isCompleted) p.$2.completeError(StateError('disconnected'));
    }
    _pending.clear();
  }

  void _scheduleReconnect({bool soon = false}) {
    if (_userDisconnected) return;
    _reconnect?.cancel();
    const steps = [2, 4, 8, 15, 30];
    final s = soon ? 1 : steps[math.min(_attempt, steps.length - 1)];
    _attempt++;
    _reconnect = Timer(Duration(seconds: s), connect);
  }

  void _setLink(Link l) {
    link = l;
    notifyListeners();
  }

  // -----------------------------------------------------------------------
  // Transport
  // -----------------------------------------------------------------------

  void _log(String dir, String text) {
    logs.add(LogLine(dir, text));
    if (logs.length > 400) logs.removeRange(0, logs.length - 400);
    if (kDebugMode) debugPrint('[tonrail] $dir $text');
  }

  Future<void> _write(Uint8List data) {
    final next = _writeChain.then((_) async {
      final tx = _tx;
      if (tx == null) throw StateError('disconnected');
      final chunk = math.max(20, (_device?.mtuNow ?? 23) - 3);
      final noResponse = !tx.properties.write && tx.properties.writeWithoutResponse;
      for (var i = 0; i < data.length; i += chunk) {
        await tx.write(data.sublist(i, math.min(i + chunk, data.length)), withoutResponse: noResponse);
      }
    });
    _writeChain = next.catchError((_) {});
    return next;
  }

  /// Sends a command and waits for the matching reply. Null means it failed.
  Future<Packet?> send(DeviceCommand c, {Duration timeout = const Duration(seconds: 3)}) async {
    if (_tx == null) return null;
    _sn = (_sn + 1) & 0xFF;
    final sn = _sn;
    final frame = Frame.encodeCommand(c.opcode, sn, c.payload);
    final done = Completer<Packet>();
    _pending[sn] = (c.opcode, done);
    _log('→', '${c.label}  ${hex(frame)}');
    try {
      await _write(frame);
      final r = await done.future.timeout(timeout);
      if (r.status != 0) _log('!', '${c.label} status ${r.status}');
      return r;
    } catch (e) {
      _log('!', '${c.label}: $e');
      return null;
    } finally {
      _pending.remove(sn);
    }
  }

  Future<bool> _apply(DeviceCommand c) async {
    final r = await send(c);
    return r != null && r.status == 0;
  }

  void _onBytes(List<int> value) {
    _log('←', hex(value));
    for (final p in _decoder.add(value)) {
      if (!p.isCommand) {
        final waiting = _pending[p.sn];
        if (waiting != null && waiting.$1 == p.opcode && !waiting.$2.isCompleted) {
          waiting.$2.complete(p);
        }
        if (p.status != 0) continue;
        if (p.opcode == Frame.opGetAdv) _applyAdv(HeadsetProtocol.parseAdv(p.payload));
        if (p.opcode == Frame.opCustom) _onCustom(p.payload, fromDevice: false);
        continue;
      }
      switch (p.opcode) {
        case Frame.opNotifyAdv:
          final info = HeadsetProtocol.parseNotifyAdv(p.payload);
          if (info != null) _applyAdv(info);
        case Frame.opRequestAdvOp:
          if (p.payload.isNotEmpty && p.payload[0] == 0) send(HeadsetProtocol.advInfo());
        case Frame.opCustom:
          _onCustom(p.payload, fromDevice: true);
      }
    }
  }

  void _applyAdv(AdvInfo a) {
    if (a.battery != null) {
      battery = a.battery;
      charging = a.charging;
    }
    if (a.name != null && a.name!.isNotEmpty) deviceName = a.name!;
    if (a.keys != null) keys = {...keys, ...a.keys!};
    if (a.gaming != null) gaming = a.gaming!;
    if (a.balance != null) balance = a.balance!;
    notifyListeners();
  }

  void _onCustom(List<int> payload, {required bool fromDevice}) {
    final split = HeadsetProtocol.splitCustom(payload);
    if (split == null) return;
    final (attr, data) = split;
    switch (attr) {
      case HeadsetProtocol.attrAnc:
        final n = HeadsetProtocol.parseNoise(data);
        if (n != null) {
          noise = n;
          // A change made with the headphone's own button is the user's latest choice.
          if (fromDevice) store.saveNoise(n.scene.id, n.level);
          notifyListeners();
        }
      case HeadsetProtocol.attrPower:
        final m = HeadsetProtocol.parsePowerMinutes(data);
        if (m != null) {
          powerKnown = true;
          powerMinutes = m == 0xFFFF || m == 0 ? null : m;
          notifyListeners();
        }
    }
  }

  Future<void> _sync({bool initial = false}) async {
    syncing = true;
    notifyListeners();
    await send(HeadsetProtocol.targetInfo());
    await send(HeadsetProtocol.syncTime(DateTime.now()));
    await send(HeadsetProtocol.advInfo());
    await send(HeadsetProtocol.query(HeadsetProtocol.attrAnc));
    await send(HeadsetProtocol.query(HeadsetProtocol.attrPower));
    await _detectEq();
    syncing = false;
    notifyListeners();

    if (initial && store.keepNoise && store.lastNoiseId != null) {
      final want = NoiseScenes.byId(store.lastNoiseId!);
      final level = store.lastNoiseLevel;
      if (noise == null || noise!.scene.id != want.id || (want.hasStrength && noise!.level != level)) {
        _log('i', 'restoring ${want.id}');
        await setNoise(want, level, remember: false);
      }
    }
  }

  Future<void> _detectEq() async {
    for (final v2 in [true, false]) {
      final r = await send(HeadsetProtocol.query(v2 ? HeadsetProtocol.attrEqV2 : HeadsetProtocol.attrEqV1));
      if (r == null || r.status != 0) continue;
      final split = HeadsetProtocol.splitCustom(r.payload);
      if (split == null) continue;
      eqV2 = v2;
      final parsed = HeadsetProtocol.parseEq(split.$2, v2: v2);
      if (parsed != null && activePresetId == null) {
        eqBands = parsed.$1;
        eqMaster = parsed.$2;
        if (parsed.$1.length == 10) draft = parsed.$1;
      }
      _log('i', 'EQ protocol ${v2 ? 'v2' : 'v1'}');
      return;
    }
  }

  Future<void> _refreshStatus() async {
    if (!isReady) return;
    await send(HeadsetProtocol.advStatus());
    await send(HeadsetProtocol.query(HeadsetProtocol.attrAnc));
  }

  Future<void> refresh() => isReady ? _sync() : connect();

  // -----------------------------------------------------------------------
  // Settings (optimistic, reverted on failure)
  // -----------------------------------------------------------------------

  void _fail(String what) => _messages.add("Couldn't $what. Check the headphones are on and nearby.");

  Future<bool> setNoise(NoiseScene scene, int level, {bool remember = true}) async {
    final prev = noise;
    noise = NoiseState(scene, scene.hasStrength ? level : scene.defaultLevel);
    activeMomentId = null;
    notifyListeners();
    final ok = await _apply(HeadsetProtocol.noise(scene, level));
    if (ok) {
      if (remember) store.saveNoise(scene.id, level);
    } else {
      noise = prev;
      notifyListeners();
      _fail('change noise control');
    }
    return ok;
  }

  Future<bool> setGaming(bool on) async {
    gaming = on;
    activeMomentId = null;
    notifyListeners();
    final ok = await _apply(HeadsetProtocol.gaming(on));
    if (!ok) {
      gaming = !on;
      notifyListeners();
      _fail('switch gaming mode');
    }
    return ok;
  }

  void previewBalance(int v) {
    balance = v;
    notifyListeners();
  }

  Future<void> setBalance(int v) async {
    balance = v;
    notifyListeners();
    if (!await _apply(HeadsetProtocol.balance(v))) _fail('set channel balance');
  }

  int functionFor(ButtonGesture g) => keys[g.id] ?? g.defaultFunction;

  Future<void> setButton(ButtonGesture g, int function) async {
    final prev = keys[g.id];
    keys = {...keys, g.id: function};
    notifyListeners();
    if (!await _apply(HeadsetProtocol.button(g, function))) {
      keys = {...keys}..remove(g.id);
      if (prev != null) keys[g.id] = prev;
      notifyListeners();
      _fail('remap the button');
    }
  }

  Future<void> resetButtons() async {
    for (final g in ButtonMap.gestures) {
      await setButton(g, g.defaultFunction);
    }
  }

  Future<bool> rename(String name) async {
    final ok = await _apply(HeadsetProtocol.rename(name));
    if (ok) {
      deviceName = name;
      notifyListeners();
      _messages.add('Renamed. Other phones see the new name after re-pairing.');
    } else {
      _fail('rename the headphones');
    }
    return ok;
  }

  Future<void> setPowerOff(int? minutes) async {
    final prev = powerMinutes;
    powerMinutes = minutes;
    powerKnown = true;
    notifyListeners();
    if (!await _apply(HeadsetProtocol.powerOff(minutes))) {
      powerMinutes = prev;
      notifyListeners();
      _fail('set the power-off timer');
    }
  }

  Future<bool> resetSettings() async {
    final ok = await _apply(HeadsetProtocol.resetSettings());
    if (ok) {
      _messages.add('Headphone settings restored to factory defaults');
      await Future<void>.delayed(const Duration(milliseconds: 600));
      await _sync();
    } else {
      _fail('reset settings');
    }
    return ok;
  }

  Future<bool> clearPairings() async {
    final ok = await _apply(HeadsetProtocol.clearPairings());
    _messages.add(
      ok ? 'Pairing records cleared. Pair again from Bluetooth settings.' : "Couldn't clear pairing records.",
    );
    return ok;
  }

  void setKeepNoise(bool v) {
    store.keepNoise = v;
    notifyListeners();
  }

  void setHeadroom(bool v) {
    store.headroom = v;
    notifyListeners();
    if (activePresetId == null || !(presetById(activePresetId)?.factory ?? false)) {
      _queueEq(eqBands);
    }
  }

  // -----------------------------------------------------------------------
  // Equalizer
  // -----------------------------------------------------------------------

  double _masterFor(List<EqBand> bands) {
    if (store.headroom) return Eq.headroomFor(bands);
    // Without headroom protection, only pull down when the curve exceeds +8 dB.
    final peak = EqMath.peakDb(bands);
    return peak > 8 ? 8 - peak : 0;
  }

  Future<void> applyPreset(EqPreset p) async {
    _eqDebounce?.cancel();
    final prev = (eqBands, eqMaster, activePresetId);
    activePresetId = p.id;
    activeMomentId = null;
    store.activePresetId = p.id;
    eqBands = p.bands;
    eqMaster = p.factory ? p.masterGain : _masterFor(p.bands);
    if (!p.factory) draft = p.bands;
    notifyListeners();
    if (!await _apply(HeadsetProtocol.eq(eqBands, eqMaster, v2: eqV2))) {
      eqBands = prev.$1;
      eqMaster = prev.$2;
      activePresetId = prev.$3;
      store.activePresetId = activePresetId;
      notifyListeners();
      _fail('apply the sound preset');
    }
  }

  /// Live editing of the 10-band custom curve; sends are debounced.
  void editBand(int index, double gain) {
    final base = (eqBands.length == 10) ? eqBands : draft;
    final g = (gain * 2).round() / 2;
    draft = [
      for (var i = 0; i < base.length; i++)
        i == index ? base[i].copyWith(gain: g.clamp(Eq.minGain, Eq.maxGain)) : base[i],
    ];
    // Any edit becomes an unsaved curve until the user saves it.
    activePresetId = null;
    store.activePresetId = null;
    eqBands = draft;
    store.draftBands = draft;
    _queueEq(draft);
    notifyListeners();
  }

  /// Replaces the whole 10-band custom curve at once (tone macros, undo).
  void setBands(List<EqBand> bands) {
    draft = [for (final b in bands) b.copyWith(gain: ((b.gain * 2).round() / 2).clamp(Eq.minGain, Eq.maxGain))];
    activePresetId = null;
    store.activePresetId = null;
    eqBands = draft;
    store.draftBands = draft;
    _queueEq(draft);
    notifyListeners();
  }

  void resetDraft() {
    draft = Eq.flatBands();
    eqBands = draft;
    activePresetId = null;
    store.activePresetId = null;
    store.draftBands = draft;
    _queueEq(draft);
    notifyListeners();
  }

  void _queueEq(List<EqBand> bands) {
    _eqDebounce?.cancel();
    _eqDebounce = Timer(const Duration(milliseconds: 180), () async {
      eqMaster = _masterFor(bands);
      notifyListeners();
      await send(HeadsetProtocol.eq(bands, eqMaster, v2: eqV2));
    });
  }

  /// Hold-to-compare: temporarily play flat, then restore the current curve.
  Future<void> compare(bool flat) async {
    _eqDebounce?.cancel();
    if (flat) {
      await send(HeadsetProtocol.eq(Eq.flatBands(), 0, v2: eqV2));
    } else {
      await send(HeadsetProtocol.eq(eqBands, eqMaster, v2: eqV2));
    }
  }

  EqPreset savePreset(String name) {
    final p = EqPreset(id: 'u${DateTime.now().millisecondsSinceEpoch}', name: name, bands: List.of(draft));
    userPresets = [...userPresets, p];
    store.userPresets = userPresets;
    activePresetId = p.id;
    store.activePresetId = p.id;
    notifyListeners();
    return p;
  }

  void renamePreset(String id, String name) {
    userPresets = [for (final p in userPresets) p.id == id ? p.copyWith(name: name) : p];
    store.userPresets = userPresets;
    notifyListeners();
  }

  void deletePreset(String id) {
    userPresets = userPresets.where((p) => p.id != id).toList();
    store.userPresets = userPresets;
    if (activePresetId == id) {
      activePresetId = null;
      store.activePresetId = null;
    }
    moments = [
      for (final m in moments)
        m.presetId == id
            ? Moment(
                id: m.id,
                name: m.name,
                icon: m.icon,
                noiseId: m.noiseId,
                level: m.level,
                presetId: 'signature',
                gaming: m.gaming,
              )
            : m,
    ];
    store.moments = moments;
    notifyListeners();
  }

  // -----------------------------------------------------------------------
  // Moments
  // -----------------------------------------------------------------------

  Future<void> applyMoment(Moment m) async {
    final preset = presetById(m.presetId) ?? Eq.factoryPresets.first;
    await setNoise(NoiseScenes.byId(m.noiseId), m.level);
    await applyPreset(preset);
    if (gaming != m.gaming) await setGaming(m.gaming);
    activeMomentId = m.id;
    notifyListeners();
  }

  void saveMoment(String name, String icon) {
    final n = noise ?? const NoiseState(NoiseScenes.adaptive, 0);
    final presetId = activePresetId ?? savePreset('$name sound').id;
    final m = Moment(
      id: 'm${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      icon: icon,
      noiseId: n.scene.id,
      level: n.level,
      presetId: presetId,
      gaming: gaming,
    );
    moments = [...moments, m];
    store.moments = moments;
    activeMomentId = m.id;
    notifyListeners();
  }

  void deleteMoment(String id) {
    moments = moments.where((m) => m.id != id).toList();
    store.moments = moments;
    if (activeMomentId == id) activeMomentId = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _reconnect?.cancel();
    _eqDebounce?.cancel();
    _adapterSub?.cancel();
    _teardown();
    _messages.close();
    super.dispose();
  }
}
