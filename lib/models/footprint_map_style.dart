enum FootprintMapStyle {
  dark('dark', '暗色极简'),
  light('light', '浅色极简');

  const FootprintMapStyle(this.storageValue, this.label);

  final String storageValue;
  final String label;

  static FootprintMapStyle fromStorage(String? value) {
    return FootprintMapStyle.values.firstWhere(
      (e) => e.storageValue == value,
      orElse: () => FootprintMapStyle.dark,
    );
  }

  String get tileUrl => switch (this) {
        FootprintMapStyle.dark => 'https://basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
        FootprintMapStyle.light => 'https://basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
      };
}
