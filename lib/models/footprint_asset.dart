class FootprintAsset {
  const FootprintAsset({
    required this.id,
    required this.lat,
    required this.lng,
    required this.cityKey,
    required this.cityName,
    this.district,
    this.takenAt,
  });

  final String id;
  final double lat;
  final double lng;
  final String cityKey;
  final String cityName;
  final String? district;
  final DateTime? takenAt;

  String get displayLabel {
    if (district != null && district!.isNotEmpty && district != cityName) {
      return '$cityName · $district';
    }
    return cityName;
  }

  Map<String, Object?> toRow(int scannedAtMs) => {
        'asset_id': id,
        'lat': lat,
        'lng': lng,
        'city_key': cityKey,
        'city_name': cityName,
        'district': district,
        'taken_at': takenAt?.millisecondsSinceEpoch,
        'scanned_at': scannedAtMs,
      };

  factory FootprintAsset.fromRow(Map<String, Object?> row) {
    final takenMs = row['taken_at'] as int?;
    return FootprintAsset(
      id: row['asset_id'] as String,
      lat: (row['lat'] as num).toDouble(),
      lng: (row['lng'] as num).toDouble(),
      cityKey: row['city_key'] as String,
      cityName: row['city_name'] as String,
      district: row['district'] as String?,
      takenAt: takenMs == null ? null : DateTime.fromMillisecondsSinceEpoch(takenMs),
    );
  }
}

class RawGeoAsset {
  const RawGeoAsset({
    required this.id,
    required this.lat,
    required this.lng,
    this.takenAt,
  });

  final String id;
  final double lat;
  final double lng;
  final DateTime? takenAt;
}
