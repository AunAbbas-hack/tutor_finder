import 'dart:math';

/// Calculate distance between two coordinates using Haversine formula
/// Supports both miles and kilometers
class DistanceCalculator {
  static const double earthRadiusMiles = 3959.0; // Earth radius in miles
  static const double earthRadiusKm = 6371.0; // Earth radius in kilometers

  /// Calculate distance between two lat/lng points in miles
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return calculateDistanceInKm(lat1, lon1, lat2, lon2) * 0.621371; // Convert km to miles
  }

  /// Calculate distance between two lat/lng points in kilometers
  static double calculateDistanceInKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    if (lat1 == lat2 && lon1 == lon2) return 0.0;

    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    final distance = earthRadiusKm * c;

    return distance;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (pi / 180.0);
  }

  /// Format distance as string (e.g., "1.2 miles away")
  static String formatDistance(double distanceInMiles) {
    if (distanceInMiles < 0.1) {
      return 'Less than 0.1 miles away';
    } else if (distanceInMiles < 1) {
      return '${distanceInMiles.toStringAsFixed(1)} miles away';
    } else {
      return '${distanceInMiles.toStringAsFixed(1)} miles away';
    }
  }

  /// Format distance in kilometers as string (e.g., "1.2 km away")
  static String formatDistanceInKm(double distanceInKm) {
    if (distanceInKm < 0.1) {
      return 'Less than 0.1 km away';
    } else if (distanceInKm < 1) {
      return '${distanceInKm.toStringAsFixed(1)} km away';
    } else {
      return '${distanceInKm.toStringAsFixed(1)} km away';
    }
  }

  /// Check if a location is within a specified radius (in kilometers)
  /// Returns true if the distance is less than or equal to the radius
  static bool isWithinRadius(
    double centerLat,
    double centerLon,
    double targetLat,
    double targetLon,
    double radiusInKm,
  ) {
    final distance = calculateDistanceInKm(
      centerLat,
      centerLon,
      targetLat,
      targetLon,
    );
    return distance <= radiusInKm;
  }
}

