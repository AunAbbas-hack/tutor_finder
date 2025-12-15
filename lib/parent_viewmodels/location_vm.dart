import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationViewModel extends ChangeNotifier {
  String _searchQuery = '';
  String _latitude = '';
  String _longitude = '';
  bool _isUsingCurrentLocation = false;
  bool _isLoadingLocation = false;
  String? _errorMessage;
  String? _selectedAddress;
  bool _hasUserSelectedLocation = false; // Track if user has selected a location
  
  // Map controller and camera position
  GoogleMapController? _mapController;
  CameraPosition _cameraPosition = const CameraPosition(
    target: LatLng(0.0, 0.0), // Default: World view (no specific location)
    zoom: 2.0, // Zoomed out to show world map
  );

  LocationViewModel({double? initialLatitude, double? initialLongitude, String? initialAddress}) {
    if (initialLatitude != null && initialLongitude != null) {
      _latitude = initialLatitude.toStringAsFixed(6);
      _longitude = initialLongitude.toStringAsFixed(6);
      _selectedAddress = initialAddress;
      _hasUserSelectedLocation = true;
      _cameraPosition = CameraPosition(
        target: LatLng(initialLatitude, initialLongitude),
        zoom: 14.0,
      );
      // Fetch address if not provided
      if (initialAddress == null) {
        _getAddressFromCoordinates(initialLatitude, initialLongitude);
      }
    }
  }

  String get searchQuery => _searchQuery;
  String get latitude => _latitude;
  String get longitude => _longitude;
  bool get isUsingCurrentLocation => _isUsingCurrentLocation;
  bool get isLoadingLocation => _isLoadingLocation;
  String? get errorMessage => _errorMessage;
  String? get selectedAddress => _selectedAddress;
  CameraPosition get cameraPosition => _cameraPosition;
  GoogleMapController? get mapController => _mapController;

  void updateSearchQuery(String value) {
    _searchQuery = value;
    _errorMessage = null;
    notifyListeners();
  }

  void updateLatitude(String value) {
    _latitude = value.trim();
    _errorMessage = null;
    notifyListeners();
  }

  void updateLongitude(String value) {
    _longitude = value.trim();
    _errorMessage = null;
    notifyListeners();
  }

  void setMapController(GoogleMapController controller) {
    _mapController = controller;
  }

  /// Set camera position and update coordinates
  Future<void> updateLocation(double lat, double lng) async {
    _latitude = lat.toStringAsFixed(6);
    _longitude = lng.toStringAsFixed(6);
    _hasUserSelectedLocation = true; // Mark that user has selected a location
    
    // Update camera position
    _cameraPosition = CameraPosition(
      target: LatLng(lat, lng),
      zoom: 14.0,
    );
    
    // Move map camera
    if (_mapController != null) {
      await _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(_cameraPosition),
      );
    }
    
    // Get address from coordinates
    await _getAddressFromCoordinates(lat, lng);
    
    notifyListeners();
  }

  /// Get current location using geolocator
  Future<void> getCurrentLocation() async {
    _isLoadingLocation = true;
    _errorMessage = null;
    _isUsingCurrentLocation = true;
    notifyListeners();

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _errorMessage = 'Location services are disabled. Please enable them.';
        _isLoadingLocation = false;
        notifyListeners();
        return;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _errorMessage = 'Location permissions are denied.';
          _isLoadingLocation = false;
          notifyListeners();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _errorMessage = 'Location permissions are permanently denied. Please enable them in settings.';
        _isLoadingLocation = false;
        notifyListeners();
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Update location
      await updateLocation(position.latitude, position.longitude);
      
      _isLoadingLocation = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to get location: ${e.toString()}';
      _isLoadingLocation = false;
      notifyListeners();
    }
  }

  /// Search for address and update location
  Future<void> searchAddress(String query) async {
    if (query.trim().isEmpty) return;

    _isLoadingLocation = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Use geocoding to search for address
      List<Location> locations = await locationFromAddress(query);
      
      if (locations.isNotEmpty) {
        final location = locations.first;
        await updateLocation(location.latitude, location.longitude);
      } else {
        _errorMessage = 'No location found for "$query"';
      }
      
      _isLoadingLocation = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to search address: ${e.toString()}';
      _isLoadingLocation = false;
      notifyListeners();
    }
  }

  /// Get address from coordinates (reverse geocoding)
  Future<void> _getAddressFromCoordinates(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        _selectedAddress = _formatAddress(place);
      } else {
        _selectedAddress = 'Unknown location';
      }
    } catch (e) {
      _selectedAddress = 'Unable to get address';
    }
  }

  /// Format address from Placemark
  String _formatAddress(Placemark place) {
    List<String> parts = [];
    
    if (place.street != null && place.street!.isNotEmpty) {
      parts.add(place.street!);
    }
    if (place.subLocality != null && place.subLocality!.isNotEmpty) {
      parts.add(place.subLocality!);
    }
    if (place.locality != null && place.locality!.isNotEmpty) {
      parts.add(place.locality!);
    }
    if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
      parts.add(place.administrativeArea!);
    }
    if (place.country != null && place.country!.isNotEmpty) {
      parts.add(place.country!);
    }
    
    return parts.isNotEmpty ? parts.join(', ') : 'Unknown location';
  }

  /// Handle map tap to select location
  Future<void> onMapTap(LatLng position) async {
    await updateLocation(position.latitude, position.longitude);
  }

  /// Handle camera move (when user drags map)
  void onCameraMove(CameraPosition position) {
    _cameraPosition = position;
  }

  /// Handle camera idle (when user stops dragging)
  /// Only update if user has already selected a location (not on initial load)
  Future<void> onCameraIdle() async {
    // Only update location if user has already selected one
    // This prevents setting coordinates on initial map load
    if (_hasUserSelectedLocation) {
      final lat = _cameraPosition.target.latitude;
      final lng = _cameraPosition.target.longitude;
      _latitude = lat.toStringAsFixed(6);
      _longitude = lng.toStringAsFixed(6);
      
      // Get address from coordinates
      await _getAddressFromCoordinates(lat, lng);
      
      notifyListeners();
    }
  }

  void setCurrentLocation(double lat, double lng) {
    updateLocation(lat, lng);
  }

  void startFetchingLocation() {
    getCurrentLocation();
  }

  /// last step pe Save button enable/disable
  bool get canSave {
    if (_latitude.isEmpty || _longitude.isEmpty) return false;
    if (double.tryParse(_latitude) == null) return false;
    if (double.tryParse(_longitude) == null) return false;
    return true;
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
