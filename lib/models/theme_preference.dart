enum ThemePreference {
  system('system'),
  light('light'),
  dark('dark');

  const ThemePreference(this.storageValue);

  final String storageValue;

  static ThemePreference fromStorage(String? value) {
    return ThemePreference.values.firstWhere(
      (e) => e.storageValue == value,
      orElse: () => ThemePreference.system,
    );
  }

  String get label => switch (this) {
        ThemePreference.system => '跟随系统',
        ThemePreference.light => '浅色',
        ThemePreference.dark => '深色',
      };
}
