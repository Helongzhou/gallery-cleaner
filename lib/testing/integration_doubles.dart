import '../services/database/app_database.dart';
import '../services/organize_repository.dart';
import '../services/session_service.dart';
import '../services/settings_repository.dart';
import '../models/active_session.dart';
import '../models/pending_delete_item.dart';

/// Test doubles used when `INTEGRATION_TEST=true` (simulator integration tests).
class IntegrationSettingsRepository extends SettingsRepository {
  IntegrationSettingsRepository() : super(AppDatabase.instance);

  @override
  Future<bool> hasSeenOnboarding() async => true;

  @override
  Future<String?> getLastTargetAlbumId() async => null;
}

class IntegrationOrganizeRepository extends OrganizeRepository {
  IntegrationOrganizeRepository() : super(AppDatabase.instance);

  @override
  Future<Set<String>> getProcessedIds(String sourceAlbumId) async => {};

  @override
  Future<int> pendingDeleteCount() async => 0;
}

class IntegrationSessionService extends SessionService {
  IntegrationSessionService() : super(AppDatabase.instance);

  @override
  Future<ActiveSession?> getActiveSession() async => null;
}
