import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:contact_navigator/core/utils/map_utils.dart';

void main() {
  group('MapUtils.parseLocationLink', () {
    test('parses OpenStreetMap mlat/mlon format', () {
      final result = MapUtils.parseLocationLink(
        'https://www.openstreetmap.org/?mlat=30.0444&mlon=31.2357',
      );
      expect(result, isA<LatLng>());
      expect(result!.latitude, closeTo(30.0444, 0.0001));
      expect(result.longitude, closeTo(31.2357, 0.0001));
    });

    test('parses OpenStreetMap map=zoom/lat/lon format', () {
      final result = MapUtils.parseLocationLink(
        'https://www.openstreetmap.org/?map=16/30.0444/31.2357',
      );
      expect(result, isA<LatLng>());
      expect(result!.latitude, closeTo(30.0444, 0.0001));
      expect(result.longitude, closeTo(31.2357, 0.0001));
    });

    test('parses Google Maps q=lat,lon format', () {
      final result = MapUtils.parseLocationLink(
        'https://maps.google.com/?q=30.0444,31.2357',
      );
      expect(result, isA<LatLng>());
      expect(result!.latitude, closeTo(30.0444, 0.0001));
      expect(result.longitude, closeTo(31.2357, 0.0001));
    });

    test('parses Google Maps @lat,lon,zoom format', () {
      final result = MapUtils.parseLocationLink(
        'https://www.google.com/maps/@30.0444,31.2357,15z',
      );
      expect(result, isA<LatLng>());
      expect(result!.latitude, closeTo(30.0444, 0.0001));
      expect(result.longitude, closeTo(31.2357, 0.0001));
    });

    test('parses Google Maps !3d!4d data format', () {
      final result = MapUtils.parseLocationLink(
        'https://www.google.com/maps/place/30.0444,31.2357/!3d30.0444!4d31.2357',
      );
      expect(result, isA<LatLng>());
      expect(result!.latitude, closeTo(30.0444, 0.0001));
      expect(result.longitude, closeTo(31.2357, 0.0001));
    });

    test('parses raw coordinates format', () {
      final result = MapUtils.parseLocationLink('30.0444, 31.2357');
      expect(result, isA<LatLng>());
      expect(result!.latitude, closeTo(30.0444, 0.0001));
      expect(result.longitude, closeTo(31.2357, 0.0001));
    });

    test('returns null for empty string', () {
      expect(MapUtils.parseLocationLink(''), isNull);
    });

    test('returns null for garbage input', () {
      expect(MapUtils.parseLocationLink('not a location'), isNull);
      expect(MapUtils.parseLocationLink('abc def'), isNull);
    });
  });

  group('MapUtils.generateOsmLink', () {
    test('generates correct URL', () {
      final loc = LatLng(30.0444, 31.2357);
      final link = MapUtils.generateOsmLink(loc);
      expect(link, contains('mlat=30.0444'));
      expect(link, contains('mlon=31.2357'));
    });
  });
}
