import 'package:sqflite/sqflite.dart';

import '../models/theme_preference.dart';
import '../shared/constants/organize_mode.dart';
import 'database/app_database.dart';

class SettingsRepository {
  SettingsRepository(this._db);

  final AppDatabase _db;

  static const _onboardingKey = 'has_seen_onboarding';
  static const _lastTargetKey = 'last_target_album_id';
  static const _themePreferenceKey = 'theme_preference';

  Future<String?> getLastTargetAlbumId() async {
    final db = await _db.database;
    final rows = await db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: [_lastTargetKey],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  Future<void> setLastTargetAlbumId(String? albumId) async {
    final db = await _db.database;
    await db.insert(
      'app_settings',
      {'key': _lastTargetKey, 'value': albumId ?? OrganizeMode.deleteOnlyTargetId},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<bool> hasSeenOnboarding() async {
    final db = await _db.database;
    final rows = await db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: [_onboardingKey],
      limit: 1,
    );
    if (rows.isEmpty) return false;
    return rows.first['value'] == '1';
  }

  Future<void> setHasSeenOnboarding(bool value) async {
    final db = await _db.database;
    await db.insert(
      'app_settings',
      {'key': _onboardingKey, 'value': value ? '1' : '0'},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<ThemePreference> getThemePreference() async {
    final db = await _db.database;
    final rows = await db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: [_themePreferenceKey],
      limit: 1,
    );
    if (rows.isEmpty) return ThemePreference.system;
    return ThemePreference.fromStorage(rows.first['value'] as String?);
  }

  Future<void> setThemePreference(ThemePreference preference) async {
    final db = await _db.database;
    await db.insert(
      'app_settings',
      {'key': _themePreferenceKey, 'value': preference.storageValue},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
