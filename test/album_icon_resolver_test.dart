import 'package:album_organizer/shared/utils/album_icon_resolver.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AlbumIconResolver', () {
    test('matches screenshot albums', () {
      expect(AlbumIconResolver.resolve('Screenshots'), LucideIcons.monitor_smartphone);
      expect(AlbumIconResolver.resolve('屏幕截图'), LucideIcons.monitor_smartphone);
    });

    test('matches travel keywords', () {
      expect(AlbumIconResolver.resolve('2024 旅行'), LucideIcons.plane);
    });

    test('falls back to default icon', () {
      expect(AlbumIconResolver.resolve('Random Album'), LucideIcons.image);
    });
  });
}
