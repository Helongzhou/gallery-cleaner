import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

void runAlbumOrganizerApp({List<Override> overrides = const []}) {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(ProviderScope(overrides: overrides, child: const AlbumOrganizerApp()));
}
