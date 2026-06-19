import 'package:album_organizer/models/footprint_asset.dart';
import 'package:album_organizer/services/footprint_city_grouper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('groups assets by city key', () {
    final assets = [
      const FootprintAsset(
        id: 'a1',
        lat: 39.9,
        lng: 116.4,
        cityKey: 'CN|北京|北京市',
        cityName: '北京市',
        district: '朝阳区',
      ),
      const FootprintAsset(
        id: 'a2',
        lat: 39.91,
        lng: 116.41,
        cityKey: 'CN|北京|北京市',
        cityName: '北京市',
        district: '海淀区',
      ),
      const FootprintAsset(
        id: 'b1',
        lat: 31.2,
        lng: 121.5,
        cityKey: 'CN|上海|上海市',
        cityName: '上海市',
      ),
    ];

    final cities = FootprintCityGrouper.group(assets);
    expect(cities.length, 2);
    expect(cities.first.cityName, '北京市');
    expect(cities.first.photoCount, 2);
    expect(cities.last.photoCount, 1);
  });
}
