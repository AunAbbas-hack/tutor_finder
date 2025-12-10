import 'package:flutter/foundation.dart';

class LocationViewModel extends ChangeNotifier {
  String _searchQuery = '';
  String _latitude = '';
  String _longitude = '';
  bool _isUsingCurrentLocation = false;
  bool _isLoadingLocation = false;

  String get searchQuery => _searchQuery;
  String get latitude => _latitude;
  String get longitude => _longitude;
  bool get isUsingCurrentLocation => _isUsingCurrentLocation;
  bool get isLoadingLocation => _isLoadingLocation;

  void updateSearchQuery(String value) {
    _searchQuery = value;
    notifyListeners();
  }

  void updateLatitude(String value) {
    _latitude = value.trim();
    notifyListeners();
  }

  void updateLongitude(String value) {
    _longitude = value.trim();
    notifyListeners();
  }

  void setCurrentLocation(double lat, double lng) {
    _latitude = lat.toStringAsFixed(6);
    _longitude = lng.toStringAsFixed(6);
    _isUsingCurrentLocation = true;
    _isLoadingLocation = false;
    notifyListeners();
  }

  void startFetchingLocation() {
    _isUsingCurrentLocation = true;
    _isLoadingLocation = true;
    notifyListeners();
  }

  /// last step pe Save button enable/disable
  bool get canSave {
    if (_latitude.isEmpty || _longitude.isEmpty) return false;
    if (double.tryParse(_latitude) == null) return false;
    if (double.tryParse(_longitude) == null) return false;
    return true;
  }
}
