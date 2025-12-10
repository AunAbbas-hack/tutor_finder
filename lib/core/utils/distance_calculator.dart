import 'dart:math';

/// Calculate distance between two coordinates using Haversine formula
/// Returns distance in miles
class DistanceCalculator {
  static const double earthRadiusMiles = 3959.0; // Earth radius in miles

  /// Calculate distance between two lat/lng points in miles
  static double calculateDistance(
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
    final distance = earthRadiusMiles * c;

    return distance;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (pi / 180.0);
  }

  /// Format distance as string (e.g., "1.2 miles away")
  static String formatDistance(double distance) {
    if (distance < 0.1) {
      return 'Less than 0.1 miles away';
    } else if (distance < 1) {
      return '${distance.toStringAsFixed(1)} miles away';
    } else {
      return '${distance.toStringAsFixed(1)} miles away';
    }
  }
}

