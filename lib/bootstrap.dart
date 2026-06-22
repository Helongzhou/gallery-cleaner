import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'shared/utils/immersive_system_ui.dart';

void runAlbumOrganizerApp({List<Override> overrides = const []}) {
  WidgetsFlutterBinding.ensureInitialized();
  ImmersiveSystemUi.enable();
  runApp(ProviderScope(overrides: overrides, child: const AlbumOrganizerApp()));
}
