class GeocodeResult {
  const GeocodeResult({
    required this.cityKey,
    required this.cityName,
    this.district,
  });

  final String cityKey;
  final String cityName;
  final String? district;

  String get displayLabel {
    if (district != null && district!.isNotEmpty && district != cityName) {
      return '$cityName · $district';
    }
    return cityName;
  }

  factory GeocodeResult.unknown(double lat, double lng) {
    final key = 'unknown|${lat.toStringAsFixed(2)}|${lng.toStringAsFixed(2)}';
    return GeocodeResult(
      cityKey: key,
      cityName: '未知地点',
      district: '${lat.toStringAsFixed(2)}, ${lng.toStringAsFixed(2)}',
    );
  }
}
