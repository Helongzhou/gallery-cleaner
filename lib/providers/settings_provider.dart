import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/footprint_map_style.dart';
import '../services/settings_repository.dart';
import 'providers.dart';

final footprintMapStyleProvider =
    StateNotifierProvider<FootprintMapStyleController, FootprintMapStyle>((ref) {
  return FootprintMapStyleController(ref.watch(settingsRepositoryProvider));
});

class FootprintMapStyleController extends StateNotifier<FootprintMapStyle> {
  FootprintMapStyleController(this._settings) : super(FootprintMapStyle.system) {
    _load();
  }

  final SettingsRepository _settings;

  Future<void> _load() async {
    state = await _settings.getFootprintMapStyle();
  }

  Future<void> setStyle(FootprintMapStyle style) async {
    await _settings.setFootprintMapStyle(style);
    state = style;
  }
}

final biometricLockProvider =
    StateNotifierProvider<BiometricLockController, bool>((ref) {
  return BiometricLockController(ref.watch(settingsRepositoryProvider));
});

class BiometricLockController extends StateNotifier<bool> {
  BiometricLockController(this._settings) : super(false) {
    _load();
  }

  final SettingsRepository _settings;

  Future<void> _load() async {
    state = await _settings.isBiometricLockEnabled();
  }

  Future<void> setEnabled(bool value) async {
    await _settings.setBiometricLockEnabled(value);
    state = value;
  }
}
