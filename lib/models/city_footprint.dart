class CityFootprint {
  const CityFootprint({
    required this.cityKey,
    required this.cityName,
    required this.photoCount,
    required this.centerLat,
    required this.centerLng,
    required this.assetIds,
    this.district,
  });

  final String cityKey;
  final String cityName;
  final String? district;
  final int photoCount;
  final double centerLat;
  final double centerLng;
  final List<String> assetIds;

  String get displayLabel {
    if (district != null && district!.isNotEmpty && district != cityName) {
      return '$cityName · $district';
    }
    return cityName;
  }
}

class FootprintSummary {
  const FootprintSummary({
    required this.cityCount,
    required this.momentCount,
    required this.withoutGpsCount,
    this.lastScannedAt,
  });

  final int cityCount;
  final int momentCount;
  final int withoutGpsCount;
  final DateTime? lastScannedAt;

  String get headline => '已点亮 $cityCount 个城市 · 留下 $momentCount 个美好瞬间';
}
