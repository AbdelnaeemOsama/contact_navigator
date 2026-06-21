import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class MapUtils {
  /// Internal synchronous parser
  static LatLng? parseLocationLink(String link) {
    if (link.isEmpty) return null;

    try {
      final uri = Uri.parse(link);

      // Handle OpenStreetMap links: https://www.openstreetmap.org/?mlat=30.044&mlon=31.235
      if (uri.host.contains('openstreetmap.org')) {
        final latStr = uri.queryParameters['mlat'];
        final lonStr = uri.queryParameters['mlon'];
        if (latStr != null && lonStr != null) {
          return LatLng(double.parse(latStr), double.parse(lonStr));
        }

        // Also check map=zoom/lat/lon
        final mapStr = uri.queryParameters['map'];
        if (mapStr != null) {
          final parts = mapStr.split('/');
          if (parts.length == 3) {
            return LatLng(double.parse(parts[1]), double.parse(parts[2]));
          }
        }
      }

      // Handle Google Maps links: https://www.google.com/maps/place/30.0444,31.2357
      // or https://maps.google.com/?q=30.0444,31.2357
      if (uri.host.contains('google.com') || uri.host.contains('maps.app.goo.gl')) {
        final q = uri.queryParameters['q'];
        if (q != null) {
          final parts = q.split(',');
          if (parts.length == 2) {
            return LatLng(double.parse(parts[0]), double.parse(parts[1]));
          }
        }

        // Try extracting from path: /maps/place/30.0444,31.2357 or /maps/@30.0444,31.2357,15z
        final path = uri.path;
        final latLngMatch = RegExp(r'@?(-?\d+\.\d+),(-?\d+\.\d+)').firstMatch(path);
        if (latLngMatch != null) {
          return LatLng(
            double.parse(latLngMatch.group(1)!),
            double.parse(latLngMatch.group(2)!),
          );
        }

        // Try extracting from Google Maps data parameters: !3d30.0444!4d31.2357
        final dataMatch = RegExp(r'!3d(-?\d+\.\d+)!4d(-?\d+\.\d+)').firstMatch(link);
        if (dataMatch != null) {
          return LatLng(
            double.parse(dataMatch.group(1)!),
            double.parse(dataMatch.group(2)!),
          );
        }
      }

      // Try raw coordinates string "30.0444, 31.2357"
      final rawMatch = RegExp(r'^(-?\d+\.\d+),\s*(-?\d+\.\d+)$').firstMatch(link);
      if (rawMatch != null) {
        return LatLng(
          double.parse(rawMatch.group(1)!),
          double.parse(rawMatch.group(2)!),
        );
      }
    } catch (e) {
      // Ignore parse errors and return null
    }

    return null;
  }

  /// Generates an OpenStreetMap URL for the given coordinates
  static String generateOsmLink(LatLng location) {
    return 'https://www.openstreetmap.org/?mlat=${location.latitude}&mlon=${location.longitude}#map=16/${location.latitude}/${location.longitude}';
  }

  /// Fetches a route from OSRM between two points
  static Future<List<LatLng>> getRoute(LatLng start, LatLng end) async {
    final url = 'https://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final coordinates = data['routes'][0]['geometry']['coordinates'] as List;
          return coordinates.map((c) => LatLng(c[1].toDouble(), c[0].toDouble())).toList();
        }
      }
    } catch (e) {
      // Ignore errors
    }
    return [];
  }
}
