/// Typography helpers for mixed Chinese / Latin copy.
abstract final class AppText {
  static final _colloquialParticles = RegExp(r'[哦呢]');

  /// Inserts half-width spaces between Chinese and English/number runs.
  /// Optionally strips colloquial particles (哦, 呢).
  static String formatMixed(String text, {bool stripColloquial = true}) {
    var result = stripColloquial ? text.replaceAll(_colloquialParticles, '') : text;
    result = result.replaceAllMapped(
      RegExp(r'([\u4e00-\u9fff])([A-Za-z0-9])'),
      (m) => '${m[1]} ${m[2]}',
    );
    result = result.replaceAllMapped(
      RegExp(r'([A-Za-z0-9])([\u4e00-\u9fff])'),
      (m) => '${m[1]} ${m[2]}',
    );
    return result.trim();
  }
}
