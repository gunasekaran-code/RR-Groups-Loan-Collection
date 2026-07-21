import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class LocationResult {
  final double latitude;
  final double longitude;
  LocationResult(this.latitude, this.longitude);
}

class LocationServiceException implements Exception {
  final String message;
  LocationServiceException(this.message);
  @override
  String toString() => message;
}

class LocationService {
  /// Geocodes a free-text address using OpenStreetMap Nominatim (no API key).
  /// Respect Nominatim's usage policy: don't call this in a tight loop.
  Future<LocationResult> geocodeAddress(String address) async {
    if (address.trim().isEmpty) {
      throw LocationServiceException('Enter an address first');
    }
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': address,
      'format': 'json',
      'limit': '1',
    });
    final res = await http.get(uri, headers: {
      // Nominatim asks for an identifying header; adjust to your app name.
      'User-Agent': 'FinCollect-App/1.0',
    });
    if (res.statusCode != 200) {
      throw LocationServiceException('Lookup failed (${res.statusCode})');
    }
    final results = jsonDecode(res.body) as List<dynamic>;
    if (results.isEmpty) {
      throw LocationServiceException('No location found for that address');
    }
    final first = results.first as Map<String, dynamic>;
    return LocationResult(
      double.parse(first['lat'] as String),
      double.parse(first['lon'] as String),
    );
  }

  /// Captures the device/browser's current GPS position.
  Future<LocationResult> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationServiceException('Location services are disabled');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw LocationServiceException('Location permission denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw LocationServiceException(
          'Location permission permanently denied. Enable it in browser/device settings.');
    }

    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    return LocationResult(pos.latitude, pos.longitude);
  }
}