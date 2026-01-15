// lib/data/services/nominatim_service.dart
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// Service for reverse geocoding using Nominatim API (OpenStreetMap)
/// Note: Nominatim requires max 1 request per second and proper User-Agent
class NominatimService {
  static const String _baseUrl = 'https://nominatim.openstreetmap.org/reverse';
  static DateTime? _lastRequestTime;
  static const Duration _minRequestInterval = Duration(seconds: 1);
  
  /// Get address from coordinates using Nominatim API
  /// Returns formatted address string
  /// Respects rate limiting (max 1 request per second)
  static Future<String> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      // Respect rate limiting - wait if last request was less than 1 second ago
      if (_lastRequestTime != null) {
        final timeSinceLastRequest = DateTime.now().difference(_lastRequestTime!);
        if (timeSinceLastRequest < _minRequestInterval) {
          await Future.delayed(_minRequestInterval - timeSinceLastRequest);
        }
      }
      
      final url = Uri.parse(
        '$_baseUrl?format=json&lat=$latitude&lon=$longitude&zoom=18&addressdetails=1',
      );

      _lastRequestTime = DateTime.now();
      
      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'TutorFinderApp/1.0 (contact: support@tutorfinder.com)', // Required by Nominatim
          'Accept': 'application/json',
          'Accept-Language': 'en', // Prefer English addresses
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['address'] != null) {
          return _formatAddress(data['address']);
        } else if (data['display_name'] != null) {
          // Fallback to display_name if address structure is different
          return data['display_name'] as String;
        } else {
          throw Exception('No address data in response');
        }
      } else if (response.statusCode == 429) {
        // Rate limited - wait and retry once
        if (kDebugMode) {
          print('⚠️ Nominatim rate limited, waiting...');
        }
        await Future.delayed(const Duration(seconds: 2));
        return getAddressFromCoordinates(latitude, longitude);
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Nominatim API error: $e');
      }
      rethrow;
    }
  }

  /// Format address from Nominatim address object
  static String _formatAddress(Map<String, dynamic> address) {
    List<String> parts = [];

    // Building/House number
    if (address['house_number'] != null && address['house_number'].toString().isNotEmpty) {
      parts.add(address['house_number'].toString());
    }

    // Road/Street
    if (address['road'] != null && address['road'].toString().isNotEmpty) {
      parts.add(address['road'].toString());
    } else if (address['street'] != null && address['street'].toString().isNotEmpty) {
      parts.add(address['street'].toString());
    }

    // Suburb/Neighborhood
    if (address['suburb'] != null && address['suburb'].toString().isNotEmpty) {
      parts.add(address['suburb'].toString());
    } else if (address['neighbourhood'] != null && address['neighbourhood'].toString().isNotEmpty) {
      parts.add(address['neighbourhood'].toString());
    } else if (address['quarter'] != null && address['quarter'].toString().isNotEmpty) {
      parts.add(address['quarter'].toString());
    }

    // City/Town
    if (address['city'] != null && address['city'].toString().isNotEmpty) {
      parts.add(address['city'].toString());
    } else if (address['town'] != null && address['town'].toString().isNotEmpty) {
      parts.add(address['town'].toString());
    } else if (address['municipality'] != null && address['municipality'].toString().isNotEmpty) {
      parts.add(address['municipality'].toString());
    }

    // State/Province
    if (address['state'] != null && address['state'].toString().isNotEmpty) {
      parts.add(address['state'].toString());
    } else if (address['province'] != null && address['province'].toString().isNotEmpty) {
      parts.add(address['province'].toString());
    } else if (address['region'] != null && address['region'].toString().isNotEmpty) {
      parts.add(address['region'].toString());
    }

    // Country
    if (address['country'] != null && address['country'].toString().isNotEmpty) {
      parts.add(address['country'].toString());
    }

    // If we have parts, join them
    if (parts.isNotEmpty) {
      return parts.join(', ');
    }

    // Fallback: try to get any available address component
    final fallbackKeys = [
      'village',
      'county',
      'postcode',
      'district',
    ];

    for (final key in fallbackKeys) {
      if (address[key] != null && address[key].toString().isNotEmpty) {
        return address[key].toString();
      }
    }

    return 'Unknown location';
  }
}
