import 'package:album_organizer/models/theme_preference.dart';
import 'package:album_organizer/models/footprint_map_style.dart';
import 'package:album_organizer/models/pending_delete_item.dart';
import 'package:album_organizer/models/active_session.dart';
import 'package:album_organizer/services/database/app_database.dart';
import 'package:album_organizer/services/organize_repository.dart';
import 'package:album_organizer/services/session_service.dart';
import 'package:album_organizer/services/settings_repository.dart';

/// In-memory stubs so widget tests never touch the on-disk SQLite singleton.
class StubSettingsRepository extends SettingsRepository {
  StubSettingsRepository() : super(AppDatabase.instance);

  ThemePreference _themePreference = ThemePreference.system;

  @override
  Future<bool> hasSeenOnboarding() async => true;

  @override
  Future<String?> getLastTargetAlbumId() async => null;

  @override
  Future<ThemePreference> getThemePreference() async => _themePreference;

  @override
  Future<void> setThemePreference(ThemePreference preference) async {
    _themePreference = preference;
  }

  @override
  Future<bool> isBiometricLockEnabled() async => false;

  @override
  Future<FootprintMapStyle> getFootprintMapStyle() async => FootprintMapStyle.system;
}

class StubOrganizeRepository extends OrganizeRepository {
  StubOrganizeRepository() : super(AppDatabase.instance);

  @override
  Future<Set<String>> getProcessedIds(String sourceAlbumId) async => {};

  @override
  Future<int> pendingDeleteCount() async => 0;

  @override
  Future<List<PendingDeleteItem>> getPendingDelete() async => [];

  @override
  Future<void> removePendingDelete(List<String> assetIds) async {}
}

class StubSessionService extends SessionService {
  StubSessionService() : super(AppDatabase.instance);

  @override
  Future<ActiveSession?> getActiveSession() async => null;
}
