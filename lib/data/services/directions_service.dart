import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Service for getting directions between two points using Google Directions API
class DirectionsService {
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/directions/json';

  /// Get route between two points using Google Directions API
  Future<DirectionsResponse?> getDirections({
    required LatLng origin,
    required LatLng destination,
  }) async {
    try {
      // Get API key from .env file
      final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];
      
      if (apiKey == null || apiKey.isEmpty) {
        if (kDebugMode) {
          print('❌ Directions Service: GOOGLE_MAPS_API_KEY not found in .env file');
        }
        throw Exception('Google Maps API Key not configured. Please add GOOGLE_MAPS_API_KEY to .env file');
      }

      final url = Uri.parse(
        '$_baseUrl?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&key=$apiKey',
      );

      if (kDebugMode) {
        print('📡 Directions Service: Fetching route from (${origin.latitude}, ${origin.longitude}) to (${destination.latitude}, ${destination.longitude})');
      }

      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Directions API request timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        
        if (data['status'] == 'OK' && data['routes'] != null && (data['routes'] as List).isNotEmpty) {
          return DirectionsResponse.fromJson(data);
        } else {
          final status = data['status'] as String?;
          final errorMessage = data['error_message'] as String?;
          if (kDebugMode) {
            print('❌ Directions Service Error: Status=$status, Message=$errorMessage');
          }
          return null;
        }
      } else {
        if (kDebugMode) {
          print('❌ Directions Service: HTTP ${response.statusCode}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Directions Service Exception: $e');
      }
      return null;
    }
  }
}

/// Response model for Directions API
class DirectionsResponse {
  final List<LatLng> polylinePoints;
  final String distance;
  final String duration;

  DirectionsResponse({
    required this.polylinePoints,
    required this.distance,
    required this.duration,
  });

  factory DirectionsResponse.fromJson(Map<String, dynamic> json) {
    final route = (json['routes'] as List).first;
    final leg = (route['legs'] as List).first;
    
    // Decode polyline
    final overviewPolyline = route['overview_polyline']['points'] as String;
    final points = _decodePolyline(overviewPolyline);
    
    return DirectionsResponse(
      polylinePoints: points,
      distance: leg['distance']['text'] as String? ?? 'Unknown',
      duration: leg['duration']['text'] as String? ?? 'Unknown',
    );
  }

  /// Decode polyline string to list of LatLng points
  static List<LatLng> _decodePolyline(String encoded) {
    final List<LatLng> points = [];
    int index = 0;
    int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int shift = 0;
      int result = 0;
      int byte;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20);
      int dlat = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20);
      int dlng = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }

    return points;
  }
}
