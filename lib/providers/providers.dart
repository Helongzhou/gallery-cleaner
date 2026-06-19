import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/database/app_database.dart';
import '../services/organize_repository.dart';
import '../services/photo_library_service.dart';
import '../services/session_service.dart';
import '../services/settings_repository.dart';

final databaseProvider = Provider<AppDatabase>((ref) => AppDatabase.instance);

final photoLibraryServiceProvider = Provider<PhotoLibraryService>(
  (ref) => PhotoLibraryService(),
);

final organizeRepositoryProvider = Provider<OrganizeRepository>(
  (ref) => OrganizeRepository(ref.watch(databaseProvider)),
);

final sessionServiceProvider = Provider<SessionService>(
  (ref) => SessionService(ref.watch(databaseProvider)),
);

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(databaseProvider)),
);
