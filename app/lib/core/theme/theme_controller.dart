import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/storage_providers.dart';

/// Persisted app theme-mode controller.
///
/// Reads the saved preference from the settings store on build and writes back
/// on every change, so the user's light/dark/system choice survives restarts.
/// Exposed to `MaterialApp.themeMode` via [themeModeControllerProvider].
class ThemeModeController extends Notifier<ThemeMode> {
  static const String _storageKey = 'settings.theme_mode';

  @override
  ThemeMode build() {
    final store = ref.watch(settingsStoreProvider);
    return _decode(store.get<String>(_storageKey));
  }

  /// Persists and applies a new [mode].
  Future<void> setThemeMode(ThemeMode mode) async {
    final store = ref.read(settingsStoreProvider);
    await store.set(_storageKey, mode.name);
    state = mode;
  }

  /// Toggles between light and dark (treating `system` as light -> dark).
  Future<void> toggle() =>
      setThemeMode(state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);

  ThemeMode _decode(String? raw) => switch (raw) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
}

/// Current [ThemeMode]; drives `MaterialApp.themeMode`.
final themeModeControllerProvider =
    NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);
