import 'package:flutter/material.dart';

import '../data/store.dart';

/// App-wide light/dark preference, persisted in [Store.appearance].
class Appearance extends ValueNotifier<ThemeMode> {
  Appearance(this._store) : super(_parse(_store.appearance));
  final Store _store;

  static ThemeMode _parse(String v) => switch (v) {
    'light' => ThemeMode.light,
    'system' => ThemeMode.system,
    _ => ThemeMode.dark,
  };

  void set(ThemeMode mode) {
    value = mode;
    _store.appearance = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.system => 'system',
      ThemeMode.dark => 'dark',
    };
  }

  static late Appearance instance;
}
