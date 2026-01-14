# Polylines & Route Drawing Implementation Guide

Yeh guide aapko Polylines aur Route Drawing features add karne mein help karega.

---

## 📋 Overview

**Features to Add:**
1. ✅ Polylines (path drawing between two points)
2. ✅ Route Drawing (showing route from parent to tutor location)

**Current Status:**
- Google Maps: ✅ Implemented
- Markers: ✅ Implemented
- Location: ✅ Implemented
- **Polylines: ❌ Missing**
- **Route Drawing: ❌ Missing**

---

## 🎯 Implementation Steps

### Step 1: Add Required Package

Add `flutter_polyline_points` package to `pubspec.yaml`:

```yaml
dependencies:
  flutter_polyline_points: ^2.0.0
```

**Note:** Yeh package polyline points calculate karta hai. For complete route calculation with Directions API, aapko Google Directions API bhi enable karna padega.

---

### Step 2: Create Directions Service (Optional but Recommended)

Agar aapko proper route calculation chahiye (not just straight line), to Google Directions API use karein.

**File:** `lib/data/services/directions_service.dart`

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DirectionsService {
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/directions/json';

  /// Get route between two points using Google Directions API
  Future<DirectionsResponse?> getDirections({
    required LatLng origin,
    required LatLng destination,
  }) async {
    final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('Google Maps API Key not configured');
    }

    final url = Uri.parse(
      '$_baseUrl?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&key=$apiKey',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          return DirectionsResponse.fromJson(data);
        }
      }
      return null;
    } catch (e) {
      print('Error getting directions: $e');
      return null;
    }
  }
}

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
    final route = json['routes'][0];
    final leg = route['legs'][0];
    
    // Decode polyline
    final overviewPolyline = route['overview_polyline']['points'];
    final points = _decodePolyline(overviewPolyline);
    
    return DirectionsResponse(
      polylinePoints: points,
      distance: leg['distance']['text'],
      duration: leg['duration']['text'],
    );
  }

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
```

---

### Step 3: Update BookingViewDetailViewModel

**File:** `lib/parent_viewmodels/booking_view_detail_vm.dart`

Add these imports and properties:

```dart
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import '../data/services/directions_service.dart';

class BookingViewDetailViewModel extends ChangeNotifier {
  // ... existing code ...
  
  // Add new properties for route
  Set<Polyline> _polylines = {};
  bool _isLoadingRoute = false;
  String? _routeDistance;
  String? _routeDuration;
  DirectionsService? _directionsService;
  
  // Getters
  Set<Polyline> get polylines => _polylines;
  bool get isLoadingRoute => _isLoadingRoute;
  String? get routeDistance => _routeDistance;
  String? get routeDuration => _routeDuration;
  
  // ... existing code ...
  
  /// Load route between parent and tutor
  Future<void> loadRoute() async {
    if (_parent?.latitude == null || 
        _parent?.longitude == null ||
        _tutor?.latitude == null || 
        _tutor?.longitude == null) {
      return;
    }

    _isLoadingRoute = true;
    notifyListeners();

    try {
      _directionsService ??= DirectionsService();
      
      final origin = LatLng(_parent!.latitude!, _parent!.longitude!);
      final destination = LatLng(_tutor!.latitude!, _tutor!.longitude!);
      
      final directions = await _directionsService!.getDirections(
        origin: origin,
        destination: destination,
      );

      if (directions != null && directions.polylinePoints.isNotEmpty) {
        _polylines = {
          Polyline(
            polylineId: const PolylineId('route'),
            points: directions.polylinePoints,
            color: Colors.blue,
            width: 5,
            patterns: [],
          ),
        };
        _routeDistance = directions.distance;
        _routeDuration = directions.duration;
      }
    } catch (e) {
      print('Error loading route: $e');
    } finally {
      _isLoadingRoute = false;
      notifyListeners();
    }
  }
  
  // Update initialize method to load route
  Future<void> initialize(String bookingId) async {
    // ... existing code ...
    
    // After loading tutor and parent, load route
    if (_parent?.latitude != null && 
        _parent?.longitude != null &&
        _tutor?.latitude != null && 
        _tutor?.longitude != null) {
      await loadRoute();
    }
  }
}
```

---

### Step 4: Update Booking View Detail Screen

**File:** `lib/views/parent/booking_view_detail_screen.dart`

Update GoogleMap widget to include polylines:

```dart
GoogleMap(
  // ... existing properties ...
  polylines: vm.polylines, // Add this line
  markers: {
    // Add parent marker
    if (vm.parent?.latitude != null && vm.parent?.longitude != null)
      Marker(
        markerId: const MarkerId('parent_location'),
        position: LatLng(
          vm.parent!.latitude!,
          vm.parent!.longitude!,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueGreen,
        ),
        infoWindow: InfoWindow(
          title: 'Your Location',
          snippet: vm.parent!.name,
        ),
      ),
    // Existing tutor marker
    Marker(
      markerId: const MarkerId('tutor_location'),
      position: LatLng(
        vm.tutorLatitude!,
        vm.tutorLongitude!,
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(
        BitmapDescriptor.hueBlue,
      ),
    ),
  },
),
```

---

## 📝 Notes

### **Option 1: Simple Implementation (Straight Line)**
- Use `flutter_polyline_points` package
- Draw straight line between two points
- No Directions API needed
- Simple but not accurate for actual routes

### **Option 2: Full Implementation (Directions API)**
- Use Google Directions API
- Get actual route with turns
- Show distance and duration
- More accurate but requires API key setup

---

## ⚙️ Configuration

### **Google Maps API Key Setup:**

1. **Enable Directions API:**
   - Google Cloud Console → APIs & Services → Enable "Directions API"
   - Add API key to `.env` file:
     ```
     GOOGLE_MAPS_API_KEY=your_api_key_here
     ```

2. **Add to .env file:**
   ```
   GOOGLE_MAPS_API_KEY=your_api_key_here
   ```

---

## ✅ Testing

1. **Test with valid locations:**
   - Parent location: ✅
   - Tutor location: ✅
   - Route calculation: ✅
   - Polyline display: ✅

2. **Test edge cases:**
   - Missing locations: ✅
   - API errors: ✅
   - Network errors: ✅

---

## 🎯 Current Implementation Status

- ✅ Google Maps: Implemented
- ✅ Markers: Implemented
- ✅ Location: Implemented
- ❌ **Polylines: To be implemented**
- ❌ **Route Drawing: To be implemented**

---

**Next Steps:**
1. Add `flutter_polyline_points` package
2. Create Directions Service (optional)
3. Update ViewModel
4. Update UI
5. Test implementation
