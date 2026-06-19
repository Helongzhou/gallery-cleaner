import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/theme_preference.dart';
import '../services/settings_repository.dart';
import 'providers.dart';

final themePreferenceProvider =
    StateNotifierProvider<ThemePreferenceController, ThemePreference>((ref) {
  return ThemePreferenceController(ref.watch(settingsRepositoryProvider));
});

final themeModeProvider = Provider<ThemeMode>((ref) {
  return switch (ref.watch(themePreferenceProvider)) {
    ThemePreference.system => ThemeMode.system,
    ThemePreference.light => ThemeMode.light,
    ThemePreference.dark => ThemeMode.dark,
  };
});

class ThemePreferenceController extends StateNotifier<ThemePreference> {
  ThemePreferenceController(this._settings) : super(ThemePreference.system) {
    _load();
  }

  final SettingsRepository _settings;

  Future<void> _load() async {
    state = await _settings.getThemePreference();
  }

  Future<void> setPreference(ThemePreference preference) async {
    await _settings.setThemePreference(preference);
    state = preference;
  }
}
