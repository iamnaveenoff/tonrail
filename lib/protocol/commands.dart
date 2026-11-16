import 'dart:convert';
import 'dart:math' as math;

import 'framing.dart';

/// A command ready to send: opcode + payload.
class DeviceCommand {
  const DeviceCommand(this.opcode, this.payload, {this.label = ''});
  final int opcode;
  final List<int> payload;
  final String label;
}

// ---------------------------------------------------------------------------
// Noise control
// ---------------------------------------------------------------------------

enum NoiseFamily { off, cancel, aware }

/// One noise-control target, sent as custom command `17 03 mode scene level`.
class NoiseScene {
  const NoiseScene({
    required this.id,
    required this.family,
    required this.label,
    required this.hint,
    required this.mode,
    required this.scene,
    this.levels = 1,
    this.defaultLevel = 0,
  });

  final String id;
  final NoiseFamily family;
  final String label;
  final String hint;
  final int mode;
  final int scene;
  final int levels;
  final int defaultLevel;

  bool get hasStrength => levels > 1;
}

class NoiseScenes {
  static const adaptive = NoiseScene(
    id: 'adaptive',
    family: NoiseFamily.cancel,
    label: 'Adaptive',
    hint: 'Adjusts to your surroundings',
    mode: 1,
    scene: 5,
  );
  static const noisy = NoiseScene(
    id: 'noisy',
    family: NoiseFamily.cancel,
    label: 'Loud places',
    hint: 'Flights, trains, busy streets',
    mode: 1,
    scene: 1,
    levels: 3,
    defaultLevel: 2,
  );
  static const commuting = NoiseScene(
    id: 'commuting',
    family: NoiseFamily.cancel,
    label: 'Commute',
    hint: 'Buses, cafés, open offices',
    mode: 1,
    scene: 2,
    levels: 3,
    defaultLevel: 2,
  );
  static const indoor = NoiseScene(
    id: 'indoor',
    family: NoiseFamily.cancel,
    label: 'Indoor',
    hint: 'Quiet rooms, light hum',
    mode: 1,
    scene: 3,
    levels: 3,
    defaultLevel: 2,
  );
  static const wind = NoiseScene(
    id: 'wind',
    family: NoiseFamily.cancel,
    label: 'Wind',
    hint: 'Outdoors, cycling, gusts',
    mode: 1,
    scene: 4,
  );
  static const transparency = NoiseScene(
    id: 'aware',
    family: NoiseFamily.aware,
    label: 'Aware',
    hint: 'Hear voices and traffic',
    mode: 3,
    scene: 1,
    defaultLevel: 4,
  );
  static const off = NoiseScene(
    id: 'off',
    family: NoiseFamily.off,
    label: 'Off',
    hint: 'No processing, longest battery',
    mode: 2,
    scene: 0,
  );

  static const cancelScenes = [adaptive, noisy, commuting, indoor, wind];
  static const all = [...cancelScenes, transparency, off];

  static NoiseScene byId(String id) => all.firstWhere((s) => s.id == id, orElse: () => adaptive);

  static NoiseScene? fromDevice(int mode, int scene) {
    if (mode == 2) return off;
    if (mode == 3) return transparency;
    for (final s in cancelScenes) {
      if (s.mode == mode && s.scene == scene) return s;
    }
    return mode == 1 ? adaptive : null;
  }
}

class NoiseState {
  const NoiseState(this.scene, this.level);
  final NoiseScene scene;
  final int level;
}

// ---------------------------------------------------------------------------
// Buttons
// ---------------------------------------------------------------------------

class ButtonGesture {
  const ButtonGesture(this.keyNum, this.action, this.button, this.gesture, this.defaultFunction);
  final int keyNum;
  final int action;
  final String button;
  final String gesture;
  final int defaultFunction;

  int get id => (keyNum << 8) | action;
}

class ButtonMap {
  static const gestures = [
    ButtonGesture(7, 1, 'Multifunction', 'Press once', 1),
    ButtonGesture(7, 2, 'Multifunction', 'Press twice', 7),
    ButtonGesture(7, 3, 'Multifunction', 'Press three times', 4),
    ButtonGesture(7, 4, 'Multifunction', 'Press four times', 0),
    ButtonGesture(5, 1, 'Volume +', 'Press once', 5),
    ButtonGesture(3, 1, 'Volume −', 'Press once', 6),
  ];

  static const functions = <int, String>{
    0: 'Do nothing',
    1: 'Play / pause',
    2: 'Previous track',
    3: 'Next track',
    4: 'Voice assistant',
    5: 'Volume up',
    6: 'Volume down',
    7: 'Gaming mode',
  };
}

// ---------------------------------------------------------------------------
// Equalizer
// ---------------------------------------------------------------------------

class EqBand {
  const EqBand(this.freq, this.gain, this.q, [this.type = 2]);
  final int freq;
  final double gain;
  final double q;
  final int type;

  EqBand copyWith({double? gain}) => EqBand(freq, gain ?? this.gain, q, type);

  Map<String, dynamic> toJson() => {'f': freq, 'g': gain, 'q': q, 't': type};
  factory EqBand.fromJson(Map<String, dynamic> j) => EqBand(
    (j['f'] as num).toInt(),
    (j['g'] as num).toDouble(),
    (j['q'] as num).toDouble(),
    (j['t'] as num?)?.toInt() ?? 2,
  );
}

class EqPreset {
  const EqPreset({
    required this.id,
    required this.name,
    required this.bands,
    this.masterGain = 0,
    this.factory = false,
  });

  final String id;
  final String name;
  final List<EqBand> bands;
  final double masterGain;
  final bool factory;

  EqPreset copyWith({String? id, String? name, List<EqBand>? bands, double? masterGain}) => EqPreset(
    id: id ?? this.id,
    name: name ?? this.name,
    bands: bands ?? this.bands,
    masterGain: masterGain ?? this.masterGain,
    factory: false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'mg': masterGain,
    'bands': bands.map((b) => b.toJson()).toList(),
  };

  factory EqPreset.fromJson(Map<String, dynamic> j) => EqPreset(
    id: j['id'] as String,
    name: j['name'] as String,
    masterGain: (j['mg'] as num?)?.toDouble() ?? 0,
    bands: (j['bands'] as List).map((b) => EqBand.fromJson(Map<String, dynamic>.from(b as Map))).toList(),
  );
}

class Eq {
  static const minGain = -8.0;
  static const maxGain = 8.0;
  static const userFreqs = [60, 220, 500, 1000, 2000, 2500, 5000, 7500, 12000, 16000];
  static const userQs = [0.4, 1.2, 1.5, 1.5, 1.2, 0.8, 1.2, 1.2, 1.2, 1.2];

  static List<EqBand> flatBands() => [for (var i = 0; i < 10; i++) EqBand(userFreqs[i], 0, userQs[i])];

  static EqPreset _factory(String id, String name, List<double> gains, List<double> qs, double mg) {
    const f = [60, 220, 500, 1000, 2000, 2500, 7500];
    return EqPreset(
      id: id,
      name: name,
      factory: true,
      masterGain: mg,
      bands: [for (var i = 0; i < 7; i++) EqBand(f[i], gains[i], qs[i])],
    );
  }

  /// The headphones' built-in tunings, expressed as band parameters.
  static final factoryPresets = [
    _factory('signature', 'Signature', [4, -10, 1, -1, 2, 3.5, 3], [0.4, 1.2, 1.5, 1.5, 1.2, 0.8, 1.2], -5.5),
    _factory('pop', 'Pop', [-2, -10, 1, -1, 2, 3.5, 3], [0.4, 1.2, 1.5, 1.5, 1.2, 0.8, 1.2], -5.5),
    _factory('bass', 'Bass', [6, -3.5, 1, -1, -3.5, 0, -4], [0.4, 1.2, 1.5, 1.5, 0.9, 0.7, 0.5], -5),
    _factory('rock', 'Rock', [5.5, -10, 0, -1, 1.5, 3.5, 3], [0.4, 0.7, 0.7, 1.5, 0.7, 0.8, 0.7], -5.5),
    _factory('soft', 'Soft', [0, -10, 1, -1, 2, 2, 2], [0.7, 1.2, 1.5, 1.5, 1.2, 0.8, 1.2], -5.5),
    _factory('classic', 'Classical', [5, -5, 1, 0, 2, 2, 3], [0.4, 1.5, 1.5, 0.7, 1.2, 0.8, 1.2], -5.5),
  ];

  /// Gain needed so the summed curve never exceeds +[ceiling] dB, avoiding clipping.
  static double headroomFor(List<EqBand> bands, {double ceiling = 0}) {
    final peak = EqMath.peakDb(bands);
    return peak > ceiling ? -(peak - ceiling) : 0;
  }
}

/// RBJ peaking-filter response, used to draw curves and compute headroom.
class EqMath {
  static const fs = 44100.0;

  static double bandDb(EqBand b, double f) {
    if (b.freq <= 0 || b.gain == 0) return 0;
    final a = math.pow(10, b.gain / 40).toDouble();
    final w0 = 2 * math.pi * b.freq / fs;
    final alpha = math.sin(w0) / (2 * b.q);
    final b0 = 1 + alpha * a, b1 = -2 * math.cos(w0), b2 = 1 - alpha * a;
    final a0 = 1 + alpha / a, a1 = -2 * math.cos(w0), a2 = 1 - alpha / a;
    final w = 2 * math.pi * f / fs;
    final c1 = math.cos(w), s1 = math.sin(w), c2 = math.cos(2 * w), s2 = math.sin(2 * w);
    final nr = b0 + b1 * c1 + b2 * c2, ni = -(b1 * s1 + b2 * s2);
    final dr = a0 + a1 * c1 + a2 * c2, di = -(a1 * s1 + a2 * s2);
    final mag = math.sqrt((nr * nr + ni * ni) / (dr * dr + di * di));
    return 20 * math.log(mag) / math.ln10;
  }

  static double responseDb(List<EqBand> bands, double f) => bands.fold(0.0, (sum, b) => sum + bandDb(b, f));

  static double peakDb(List<EqBand> bands) {
    var peak = -100.0;
    for (var f = 20.0; f <= 20000; f *= 1.03) {
      peak = math.max(peak, responseDb(bands, f));
    }
    return peak;
  }
}

// ---------------------------------------------------------------------------
// Device state parsed from ADV info
// ---------------------------------------------------------------------------

class AdvInfo {
  int? battery;
  bool charging = false;
  String? name;
  Map<int, int>? keys;
  bool? gaming;
  int? balance;
  int? rawNoiseMode;

  @override
  String toString() =>
      'AdvInfo(battery=$battery charging=$charging name=$name gaming=$gaming balance=$balance keys=$keys)';
}

class HeadsetProtocol {
  static const attrPower = 20;
  static const attrAnc = 23;
  static const attrEqV1 = 32;
  static const attrEqV2 = 34;

  // Requests ------------------------------------------------------------

  static DeviceCommand targetInfo() =>
      const DeviceCommand(Frame.opGetTargetInfo, [0xFF, 0xFF, 0xFF, 0xFF, 0x00], label: 'target info');

  static DeviceCommand advInfo([int mask = 0xFFFFFFFF]) => DeviceCommand(Frame.opGetAdv, [
    (mask >> 24) & 0xFF,
    (mask >> 16) & 0xFF,
    (mask >> 8) & 0xFF,
    mask & 0xFF,
  ], label: 'read settings');

  /// Battery, work mode, noise mode and similar fast-changing values.
  static DeviceCommand advStatus() => advInfo(0x0D21);

  static DeviceCommand query(int attr) => DeviceCommand(Frame.opCustom, [0xFE, 0x01, attr], label: 'query $attr');

  // Settings ------------------------------------------------------------

  static DeviceCommand _setAdv(int type, List<int> data, String label) =>
      DeviceCommand(Frame.opSetAdv, [data.length + 1, type, ...data], label: label);

  static DeviceCommand noise(NoiseScene s, int level) => DeviceCommand(Frame.opCustom, [
    attrAnc,
    3,
    s.mode,
    s.scene,
    s.hasStrength ? level : s.defaultLevel,
  ], label: 'noise ${s.id}');

  static DeviceCommand gaming(bool on) => _setAdv(5, [on ? 2 : 1], 'gaming $on');

  static DeviceCommand balance(int value) => _setAdv(12, [value.clamp(0, 100)], 'balance $value');

  static DeviceCommand button(ButtonGesture g, int function) =>
      _setAdv(2, [g.keyNum, g.action, function == 0 ? 127 : function], 'button ${g.id}');

  static DeviceCommand rename(String name) => _setAdv(1, utf8.encode(name), 'rename');

  static DeviceCommand syncTime(DateTime now) {
    final s = now.millisecondsSinceEpoch ~/ 1000;
    return _setAdv(7, [(s >> 24) & 0xFF, (s >> 16) & 0xFF, (s >> 8) & 0xFF, s & 0xFF], 'sync time');
  }

  /// [minutes] of idle before power-off; null disables the timer.
  static DeviceCommand powerOff(int? minutes) {
    final v = minutes ?? 0xFFFF;
    return DeviceCommand(Frame.opCustom, [attrPower, 4, v & 0xFF, (v >> 8) & 0xFF, 0, 0], label: 'power off $minutes');
  }

  static DeviceCommand resetSettings() => const DeviceCommand(Frame.opAdvSystemOp, [1], label: 'reset settings');

  static DeviceCommand clearPairings() => const DeviceCommand(Frame.opAdvSystemOp, [2], label: 'clear pairings');

  static DeviceCommand eq(List<EqBand> bands, double masterGain, {required bool v2}) {
    final per = v2 ? 7 : 6;
    final n = math.min(bands.length, 10);
    final mg = (masterGain * 100).truncate();
    final out = <int>[v2 ? attrEqV2 : attrEqV1, n * per + 3, 0xFF, mg & 0xFF, (mg >> 8) & 0xFF];
    for (var i = 0; i < n; i++) {
      final b = bands[i];
      final g = (b.gain * 100).round();
      final q = (b.q * 100).round();
      out.addAll([b.freq & 0xFF, (b.freq >> 8) & 0xFF, g & 0xFF, (g >> 8) & 0xFF, q & 0xFF, (q >> 8) & 0xFF]);
      if (v2) out.add(b.type & 0xFF);
    }
    return DeviceCommand(Frame.opCustom, out, label: 'eq');
  }

  // Parsing -------------------------------------------------------------

  static AdvInfo parseAdv(List<int> p) {
    final info = AdvInfo();
    var i = 0;
    while (i + 2 <= p.length) {
      final len = p[i];
      if (len <= 0 || i + 1 + len > p.length) break;
      final type = p[i + 1];
      final data = p.sublist(i + 2, i + 1 + len);
      i += len + 1;
      if (data.isEmpty) continue;
      switch (type) {
        case 0:
          final levels = [for (final b in data.take(2)) b & 0x7F].where((v) => v > 0 && v <= 100);
          if (levels.isNotEmpty) info.battery = levels.first;
          info.charging = data.take(2).any((b) => (b & 0x80) != 0);
        case 1:
          info.name = utf8.decode(data, allowMalformed: true).replaceAll('\u0000', '').trim();
        case 2:
          final keys = <int, int>{};
          for (var k = 0; k + 3 <= data.length; k += 3) {
            final f = data[k + 2];
            keys[(data[k] << 8) | data[k + 1]] = f == 127 ? 0 : f;
          }
          info.keys = keys;
        case 5:
          info.gaming = data[0] == 2;
        case 11:
          info.rawNoiseMode = data[0];
        case 12:
          info.balance = data[0];
      }
    }
    return info;
  }

  /// Device-initiated status broadcast (opcode 0xC2).
  static AdvInfo? parseNotifyAdv(List<int> p) {
    if (p.length < 18) return null;
    final info = AdvInfo();
    final levels = [p[14] & 0x7F, p[15] & 0x7F].where((v) => v > 0 && v <= 100);
    if (levels.isNotEmpty) info.battery = levels.first;
    info.charging = (p[14] & 0x80) != 0 || (p[15] & 0x80) != 0;
    return info;
  }

  /// Validates and splits a custom payload `attr len data...`.
  static (int, List<int>)? splitCustom(List<int> p) {
    if (p.length < 2 || p.length != p[1] + 2) return null;
    return (p[0], p.sublist(2));
  }

  static NoiseState? parseNoise(List<int> data) {
    if (data.length < 3) return null;
    final s = NoiseScenes.fromDevice(data[0], data[1]);
    return s == null ? null : NoiseState(s, data[2]);
  }

  static int? parsePowerMinutes(List<int> data) {
    if (data.length < 2) return null;
    return data[0] | (data[1] << 8);
  }

  static (List<EqBand>, double)? parseEq(List<int> data, {required bool v2}) {
    final per = v2 ? 7 : 6;
    if (data.length < 3 + per) return null;
    int s16(int lo, int hi) => ((hi << 8) | lo).toSigned(16);
    final mg = s16(data[1], data[2]) / 100;
    final bands = <EqBand>[];
    for (var i = 3; i + per <= data.length; i += per) {
      final f = data[i] | (data[i + 1] << 8);
      if (f == 0) continue;
      bands.add(
        EqBand(f, s16(data[i + 2], data[i + 3]) / 100, (data[i + 4] | (data[i + 5] << 8)) / 100, v2 ? data[i + 6] : 2),
      );
    }
    return bands.isEmpty ? null : (bands, mg);
  }
}
