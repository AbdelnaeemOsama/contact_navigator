import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

// فئة مساعدة للتعامل مع الخرائط وإحداثيات الموقع وتوجيهات السير
class MapUtils {
  /// Parses a Google Maps or OSM link to extract the coordinates
  // تحليل روابط خرائط Google أو OSM لاستخراج الإحداثيات
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
      if (uri.host.contains('google.com') ||
          uri.host.contains('maps.app.goo.gl')) {
        final q = uri.queryParameters['q'];
        if (q != null) {
          final parts = q.split(',');
          if (parts.length == 2) {
            return LatLng(double.parse(parts[0]), double.parse(parts[1]));
          }
        }

        // Try extracting from path: /maps/place/30.0444,31.2357 or /maps/@30.0444,31.2357,15z
        final path = uri.path;
        final latLngMatch =
            RegExp(r'@?(-?\d+\.\d+),(-?\d+\.\d+)').firstMatch(path);
        if (latLngMatch != null) {
          return LatLng(
            double.parse(latLngMatch.group(1)!),
            double.parse(latLngMatch.group(2)!),
          );
        }

        // Try extracting from Google Maps data parameters: !3d30.0444!4d31.2357
        final dataMatch =
            RegExp(r'!3d(-?\d+\.\d+)!4d(-?\d+\.\d+)').firstMatch(link);
        if (dataMatch != null) {
          return LatLng(
            double.parse(dataMatch.group(1)!),
            double.parse(dataMatch.group(2)!),
          );
        }
      }

      // Try raw coordinates string "30.0444, 31.2357"
      final rawMatch =
          RegExp(r'^(-?\d+\.\d+),\s*(-?\d+\.\d+)$').firstMatch(link);
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

  /// Resolves short location links by following HTTP redirects (up to 5 hops)
  static Future<String> resolveLocationLink(String link) async {
    if (link.isEmpty) return link;

    final lowerLink = link.toLowerCase();
    final isShortLink = lowerLink.contains('goo.gl') ||
        lowerLink.contains('g.co') ||
        lowerLink.contains('pp.goo.gl') ||
        lowerLink.contains('maps.app.goo.gl');

    if (!isShortLink) return link;

    final client = http.Client();
    try {
      String currentUrl = link;
      int hops = 0;
      while (hops < 5) {
        final uri = Uri.parse(currentUrl);
        final request = http.Request('GET', uri)..followRedirects = false;
        request.headers['User-Agent'] =
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64)';
        
        final streamedResponse = await client.send(request);
        
        final status = streamedResponse.statusCode;
        if (status < 300 || status >= 400) {
          break;
        }

        String? location = streamedResponse.headers['location'];
        if (location == null) {
          for (final key in streamedResponse.headers.keys) {
            if (key.toLowerCase() == 'location') {
              location = streamedResponse.headers[key];
              break;
            }
          }
        }

        if (location == null || location.isEmpty) {
          break;
        }

        final redirectUri = Uri.parse(location);
        if (redirectUri.isAbsolute) {
          currentUrl = location;
        } else {
          currentUrl = uri.resolveUri(redirectUri).toString();
        }

        hops++;
      }
      return currentUrl;
    } catch (e) {
      debugPrint('Error resolving location link: $e');
      return link;
    } finally {
      client.close();
    }
  }

  /// Generates an OpenStreetMap URL for the given coordinates
  // توليد رابط OpenStreetMap بالاعتماد على إحداثيات معينة
  static String generateOsmLink(LatLng location) {
    return 'https://www.openstreetmap.org/?mlat=${location.latitude}&mlon=${location.longitude}#map=16/${location.latitude}/${location.longitude}';
  }

  static const double _walkingSpeedMps = 5.0 / 3.6;

  // توحيد مسمى وسيلة الانتقال إلى مشي أو قيادة
  static String _normalizeProfile(String profile) {
    return profile == 'foot' || profile == 'walking' ? 'walking' : 'driving';
  }

  // استدعاء خادم OSRM للحصول على مسار القيادة أو المشي بين نقطتين
  static Future<RouteInfo?> _fetchOsrmRoute(
    LatLng start,
    LatLng end,
    String osrmProfile,
    String normalizedProfile,
  ) async {
    final url =
        'https://router.project-osrm.org/route/v1/$osrmProfile/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) return null;

      final data = json.decode(response.body);
      if (data['routes'] == null || (data['routes'] as List).isEmpty) {
        return null;
      }

      final route = data['routes'][0];
      final coordinates = route['geometry']['coordinates'] as List;
      final points = coordinates
          .map((c) => LatLng(c[1].toDouble(), c[0].toDouble()))
          .toList();
      final durationSec = (route['duration'] as num).toDouble();
      final distanceM = (route['distance'] as num).toDouble();

      return RouteInfo(
        points: points,
        durationSeconds: durationSec,
        distanceMeters: distanceM,
        profile: normalizedProfile,
      );
    } catch (e) {
      return null;
    }
  }

  // تعديل مدة المسار بناءً على سرعة المشي القياسية
  static RouteInfo _withWalkingDuration(RouteInfo info) {
    return RouteInfo(
      points: info.points,
      durationSeconds: info.distanceMeters / _walkingSpeedMps,
      distanceMeters: info.distanceMeters,
      profile: 'walking',
    );
  }

  /// Fetches a route from OSRM between two points.
  /// [profile] can be 'driving' or 'walking' ('foot' is also accepted).
  // جلب معلومات المسار الكاملة (إحداثيات ومسافة وزمن) بين نقطتين
  static Future<RouteInfo?> getRouteWithInfo(
    LatLng start,
    LatLng end, {
    String profile = 'driving',
  }) async {
    final normalized = _normalizeProfile(profile);

    if (normalized == 'driving') {
      return _fetchOsrmRoute(start, end, 'driving', 'driving');
    }

    var info = await _fetchOsrmRoute(start, end, 'walking', 'walking');
    info ??= await _fetchOsrmRoute(start, end, 'foot', 'walking');

    if (info == null) {
      final driving = await _fetchOsrmRoute(start, end, 'driving', 'driving');
      if (driving == null) return null;
      return _withWalkingDuration(driving);
    }

    final speedKmh = info.durationSeconds > 0
        ? (info.distanceMeters / info.durationSeconds) * 3.6
        : 0;
    if (speedKmh > 8) {
      return _withWalkingDuration(info);
    }

    return info;
  }

  /// Legacy method for backward compatibility
  // جلب قائمة النقاط المكونة للمسار فقط (متوافق مع الإصدارات السابقة)
  static Future<List<LatLng>> getRoute(LatLng start, LatLng end) async {
    final info = await getRouteWithInfo(start, end);
    return info?.points ?? [];
  }
}

// كلاس يمثل معلومات المسار بين نقطتين بما فيها النقاط المكونة، المدة والمسافة
class RouteInfo {
  final List<LatLng> points;
  final double durationSeconds;
  final double distanceMeters;
  final String profile;

  const RouteInfo({
    required this.points,
    required this.durationSeconds,
    required this.distanceMeters,
    required this.profile,
  });

  // الحصول على المدة الزمنية منسقة للعرض (بالدقائق أو الساعات والدقائق)
  String get formattedDuration {
    final totalMinutes = (durationSeconds / 60).round();
    if (totalMinutes < 60) {
      return '$totalMinutes min';
    }
    final hours = totalMinutes ~/ 60;
    final mins = totalMinutes % 60;
    if (mins == 0) return '$hours hr';
    return '$hours hr $mins min';
  }

  // الحصول على المسافة منسقة للعرض (بالمتر أو الكيلومتر)
  String get formattedDistance {
    if (distanceMeters < 1000) {
      return '${distanceMeters.round()} m';
    }
    final km = distanceMeters / 1000;
    return '${km.toStringAsFixed(1)} km';
  }

  bool get isWalking => profile == 'foot' || profile == 'walking';

  String get profileLabel => isWalking ? 'Walking' : 'Driving';
  IconData get profileIcon =>
      isWalking ? Icons.directions_walk : Icons.directions_car;
}
