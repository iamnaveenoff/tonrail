import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../protocol/commands.dart';

/// A one-tap combination of noise control, sound and latency.
class Moment {
  const Moment({
    required this.id,
    required this.name,
    required this.icon,
    required this.noiseId,
    required this.level,
    required this.presetId,
    required this.gaming,
  });

  final String id;
  final String name;
  final String icon;
  final String noiseId;
  final int level;
  final String presetId;
  final bool gaming;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'icon': icon,
    'noise': noiseId,
    'level': level,
    'preset': presetId,
    'gaming': gaming,
  };

  factory Moment.fromJson(Map<String, dynamic> j) => Moment(
    id: j['id'] as String,
    name: j['name'] as String,
    icon: j['icon'] as String? ?? 'tune',
    noiseId: j['noise'] as String,
    level: (j['level'] as num?)?.toInt() ?? 0,
    presetId: j['preset'] as String,
    gaming: j['gaming'] as bool? ?? false,
  );

  static const defaults = [
    Moment(
      id: 'commute',
      name: 'Commute',
      icon: 'train',
      noiseId: 'commuting',
      level: 2,
      presetId: 'bass',
      gaming: false,
    ),
    Moment(
      id: 'focus',
      name: 'Deep focus',
      icon: 'focus',
      noiseId: 'adaptive',
      level: 0,
      presetId: 'signature',
      gaming: false,
    ),
    Moment(
      id: 'outside',
      name: 'Out & about',
      icon: 'walk',
      noiseId: 'aware',
      level: 4,
      presetId: 'pop',
      gaming: false,
    ),
    Moment(id: 'play', name: 'Play', icon: 'game', noiseId: 'off', level: 0, presetId: 'signature', gaming: true),
  ];
}

class Store {
  Store._(this._p);
  final SharedPreferences _p;

  static Future<Store> open() async => Store._(await SharedPreferences.getInstance());

  String? get lastDeviceId => _p.getString('device');
  set lastDeviceId(String? v) => v == null ? _p.remove('device') : _p.setString('device', v);

  bool get keepNoise => _p.getBool('keepNoise') ?? true;
  set keepNoise(bool v) => _p.setBool('keepNoise', v);

  bool get headroom => _p.getBool('headroom') ?? true;
  set headroom(bool v) => _p.setBool('headroom', v);

  /// 'dark' (default), 'light' or 'system'.
  String get appearance => _p.getString('appearance') ?? 'dark';
  set appearance(String v) => _p.setString('appearance', v);

  String? get lastNoiseId => _p.getString('noiseId');
  int get lastNoiseLevel => _p.getInt('noiseLevel') ?? 0;
  void saveNoise(String id, int level) {
    _p.setString('noiseId', id);
    _p.setInt('noiseLevel', level);
  }

  String? get activePresetId => _p.getString('preset');
  set activePresetId(String? v) => v == null ? _p.remove('preset') : _p.setString('preset', v);

  List<EqPreset> get userPresets {
    final raw = _p.getString('presets');
    if (raw == null) return [];
    return (jsonDecode(raw) as List).map((e) => EqPreset.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  set userPresets(List<EqPreset> v) => _p.setString('presets', jsonEncode(v.map((e) => e.toJson()).toList()));

  /// The unsaved working curve, so edits survive app restarts.
  List<EqBand>? get draftBands {
    final raw = _p.getString('draft');
    if (raw == null) return null;
    return (jsonDecode(raw) as List).map((e) => EqBand.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  set draftBands(List<EqBand>? v) =>
      v == null ? _p.remove('draft') : _p.setString('draft', jsonEncode(v.map((e) => e.toJson()).toList()));

  List<Moment> get moments {
    final raw = _p.getString('moments');
    if (raw == null) return Moment.defaults;
    return (jsonDecode(raw) as List).map((e) => Moment.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  set moments(List<Moment> v) => _p.setString('moments', jsonEncode(v.map((e) => e.toJson()).toList()));
}
