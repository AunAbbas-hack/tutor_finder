import 'dart:async';
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
  bool _isUpdatingCamera = false; // Prevent updates during programmatic camera moves
  bool _isMapReady = false; // Track if map is fully initialized
  
  // Map controller and camera position
  GoogleMapController? _mapController;
  CameraPosition _cameraPosition = const CameraPosition(
    target: LatLng(0.0, 0.0), // Default: World view (no specific location)
    zoom: 2.0, // Zoomed out to show world map
  );
  
  // Debounce timer for camera idle
  Timer? _cameraIdleTimer;

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
    // Wait a bit for map to fully initialize before marking as ready
    Future.delayed(const Duration(milliseconds: 300), () async {
      _isMapReady = true;
      
      // If a location was already selected before map was ready, animate to it now
      if (_hasUserSelectedLocation && 
          _latitude.isNotEmpty && 
          _longitude.isNotEmpty) {
        final lat = double.tryParse(_latitude);
        final lng = double.tryParse(_longitude);
        if (lat != null && lng != null) {
          try {
            _isUpdatingCamera = true;
            await controller.animateCamera(
              CameraUpdate.newCameraPosition(
                CameraPosition(
                  target: LatLng(lat, lng),
                  zoom: 14.0,
                ),
              ),
            );
            await Future.delayed(const Duration(milliseconds: 500));
            _isUpdatingCamera = false;
          } catch (e) {
            if (kDebugMode) {
              print('Error animating to pending location: $e');
            }
            _isUpdatingCamera = false;
          }
        }
      }
      
      notifyListeners();
    });
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
    
    // Wait for map controller to be ready (with timeout)
    int attempts = 0;
    const maxAttempts = 15; // Wait up to 3 seconds (15 * 200ms)
    
    while ((_mapController == null || !_isMapReady) && attempts < maxAttempts) {
      await Future.delayed(const Duration(milliseconds: 200));
      attempts++;
    }
    
    // Move map camera if controller is available
    if (_mapController != null && _isMapReady) {
      try {
        _isUpdatingCamera = true; // Prevent onCameraIdle from triggering during programmatic move
        await _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(_cameraPosition),
        );
        // Wait a bit after animation completes before allowing camera idle updates
        await Future.delayed(const Duration(milliseconds: 500));
        _isUpdatingCamera = false;
      } catch (e) {
        // If animation fails, try to move camera without animation
        if (kDebugMode) {
          print('Error animating camera: $e');
        }
        try {
          await _mapController!.moveCamera(
            CameraUpdate.newCameraPosition(_cameraPosition),
          );
          await Future.delayed(const Duration(milliseconds: 500));
          _isUpdatingCamera = false;
        } catch (e2) {
          if (kDebugMode) {
            print('Error moving camera: $e2');
          }
          _isUpdatingCamera = false;
        }
      }
    } else {
      // If map controller is still not ready, at least update the camera position
      // so when the map loads, it will use the correct position
      notifyListeners();
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
        if (kDebugMode) {
          print('✅ Address fetched: $_selectedAddress');
        }
      } else {
        // If no placemarks, show coordinates as fallback
        _selectedAddress = 'Location: ${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}';
        if (kDebugMode) {
          print('⚠️ No placemarks found, using coordinates');
        }
      }
    } catch (e) {
      // On error, show coordinates instead of error message
      _selectedAddress = 'Location: ${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}';
      if (kDebugMode) {
        print('❌ Reverse geocoding failed: $e');
        print('📍 Using coordinates as fallback: $lat, $lng');
      }
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
  /// Don't call notifyListeners here to prevent excessive rebuilds
  void onCameraMove(CameraPosition position) {
    // Only update internal state, don't notify listeners
    // This prevents continuous rebuilds during map dragging
    _cameraPosition = position;
  }

  /// Handle camera idle (when user stops dragging)
  /// Only update if user has already selected a location (not on initial load)
  /// Uses debouncing to prevent rapid successive calls
  void onCameraIdle() {
    // Cancel any pending timer
    _cameraIdleTimer?.cancel();
    
    // Only update location if user has already selected one and not during programmatic moves
    // This prevents setting coordinates on initial map load
    if (!_hasUserSelectedLocation || _isUpdatingCamera) {
      return;
    }
    
    // Debounce: Wait 300ms after camera stops moving before updating
    // This prevents rapid successive calls that cause frame issues
    _cameraIdleTimer = Timer(const Duration(milliseconds: 300), () async {
      if (!_isUpdatingCamera && _hasUserSelectedLocation) {
        final lat = _cameraPosition.target.latitude;
        final lng = _cameraPosition.target.longitude;
        _latitude = lat.toStringAsFixed(6);
        _longitude = lng.toStringAsFixed(6);
        
        // Get address from coordinates (async, but don't await to prevent blocking)
        _getAddressFromCoordinates(lat, lng).then((_) {
          notifyListeners();
        });
      }
    });
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
    _cameraIdleTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }
}
