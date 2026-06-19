import '../models/city_footprint.dart';
import '../models/footprint_asset.dart';

abstract final class FootprintCityGrouper {
  static List<CityFootprint> group(List<FootprintAsset> assets) {
    final grouped = <String, List<FootprintAsset>>{};
    for (final asset in assets) {
      grouped.putIfAbsent(asset.cityKey, () => []).add(asset);
    }

    final cities = grouped.entries.map((entry) {
      final list = entry.value;
      final lat = list.fold<double>(0, (sum, a) => sum + a.lat) / list.length;
      final lng = list.fold<double>(0, (sum, a) => sum + a.lng) / list.length;
      final sample = list.first;
      return CityFootprint(
        cityKey: entry.key,
        cityName: sample.cityName,
        district: sample.district,
        photoCount: list.length,
        centerLat: lat,
        centerLng: lng,
        assetIds: list.map((a) => a.id).toList(),
      );
    }).toList();

    cities.sort((a, b) => b.photoCount.compareTo(a.photoCount));
    return cities;
  }
}
