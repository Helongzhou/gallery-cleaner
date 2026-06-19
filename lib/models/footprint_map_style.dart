import 'package:flutter/material.dart';

enum FootprintMapStyle {
  system('system'),
  light('light'),
  dark('dark');

  const FootprintMapStyle(this.storageValue);

  final String storageValue;

  static FootprintMapStyle fromStorage(String? value) {
    return FootprintMapStyle.values.firstWhere(
      (e) => e.storageValue == value,
      orElse: () => FootprintMapStyle.system,
    );
  }

  String get label => switch (this) {
        FootprintMapStyle.system => '跟随系统',
        FootprintMapStyle.light => '浅色极简',
        FootprintMapStyle.dark => '暗色极简',
      };

  FootprintMapStyle resolve(Brightness brightness) {
    return switch (this) {
      FootprintMapStyle.system =>
        brightness == Brightness.dark ? FootprintMapStyle.dark : FootprintMapStyle.light,
      _ => this,
    };
  }

  String tileUrlFor(Brightness brightness) => resolve(brightness)._tileUrl;

  String get _tileUrl => switch (this) {
        FootprintMapStyle.system => FootprintMapStyle.dark._tileUrl,
        FootprintMapStyle.dark => 'https://basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
        FootprintMapStyle.light => 'https://basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
      };
}
