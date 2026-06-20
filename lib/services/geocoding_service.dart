import 'package:geocoding/geocoding.dart';

import '../models/geocode_result.dart';

/// Reverse geocoding with on-device geocoder. Results are cached in memory by cell.
class GeocodingService {
  final Map<String, GeocodeResult> _cache = {};

  static String cellKey(double lat, double lng) {
    return '${(lat * 100).round()}_${(lng * 100).round()}';
  }

  Future<GeocodeResult> reverseGeocode(double lat, double lng) async {
    final key = cellKey(lat, lng);
    final cached = _cache[key];
    if (cached != null) return cached;

    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) {
        final unknown = GeocodeResult.unknown(lat, lng);
        _cache[key] = unknown;
        return unknown;
      }

      final place = placemarks.first;
      final cityName = _firstNonEmpty([
            place.locality,
            place.subAdministrativeArea,
            place.administrativeArea,
          ]) ??
          '未知地点';
      final district = _firstNonEmpty([
        place.subLocality,
        place.subAdministrativeArea,
      ]);
      final cityKey = [
        place.isoCountryCode ?? 'XX',
        place.administrativeArea ?? '',
        cityName,
      ].join('|');

      final result = GeocodeResult(
        cityKey: cityKey,
        cityName: cityName,
        district: district,
      );
      _cache[key] = result;
      return result;
    } catch (_) {
      final unknown = GeocodeResult.unknown(lat, lng);
      _cache[key] = unknown;
      return unknown;
    }
  }

  String? _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      if (value != null && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }
}
