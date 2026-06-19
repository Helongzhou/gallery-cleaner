import 'package:album_organizer/models/footprint_map_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FootprintMapStyle', () {
    test('system resolves from brightness', () {
      expect(
        FootprintMapStyle.system.resolve(Brightness.dark),
        FootprintMapStyle.dark,
      );
      expect(
        FootprintMapStyle.system.resolve(Brightness.light),
        FootprintMapStyle.light,
      );
    });

    test('explicit styles stay unchanged', () {
      expect(
        FootprintMapStyle.dark.resolve(Brightness.light),
        FootprintMapStyle.dark,
      );
      expect(
        FootprintMapStyle.light.resolve(Brightness.dark),
        FootprintMapStyle.light,
      );
    });

    test('fromStorage defaults to system', () {
      expect(FootprintMapStyle.fromStorage(null), FootprintMapStyle.system);
      expect(FootprintMapStyle.fromStorage('system'), FootprintMapStyle.system);
    });
  });
}
