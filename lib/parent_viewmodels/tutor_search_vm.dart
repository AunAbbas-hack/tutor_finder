import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/models/tutor_model.dart';
import '../data/models/user_model.dart';
import '../data/services/tutor_services.dart';
import '../data/services/user_services.dart';
import '../core/utils/distance_calculator.dart';
import '../core/services/preferences_service.dart';

/// Model for tutor search result
class TutorSearchResult {
  final String tutorId;
  final String name;
  final String profession; // e.g., "Mathematics Professor", "Calculus & Stats Expert"
  final double rating;
  final String distance; // e.g., "1.2 km"
  final double hourlyRate;
  final String imageUrl;
  final bool isOnline;
  final bool isFavorite;
  final List<String> subjects;

  TutorSearchResult({
    required this.tutorId,
    required this.name,
    required this.profession,
    required this.rating,
    required this.distance,
    required this.hourlyRate,
    this.imageUrl = '',
    this.isOnline = false,
    this.isFavorite = false,
    this.subjects = const [],
  });
}

enum SortOption {
  distance,
  rating,
  priceLow,
  priceHigh,
}

class TutorSearchViewModel extends ChangeNotifier {
  final TutorService _tutorService;
  final UserService _userService;
  final FirebaseAuth _auth;
  PreferencesService? _prefsService;

  TutorSearchViewModel({
    TutorService? tutorService,
    UserService? userService,
    FirebaseAuth? auth,
    PreferencesService? prefsService,
  })  : _tutorService = tutorService ?? TutorService(),
        _userService = userService ?? UserService(),
        _auth = auth ?? FirebaseAuth.instance,
        _prefsService = prefsService;

  // ---------- State ----------
  bool _isDisposed = false;
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';

  // Filters
  List<String> _selectedSubjects = [];
  double _minPrice = 15.0;
  double _maxPrice = 80.0;
  double _locationRadius = 10.0; // Default 10km (max allowed)
  SortOption _sortOption = SortOption.distance;

  // Available subjects (common subjects)
  final List<String> _availableSubjects = [
    'Math',
    'Science',
    'History',
    'English',
    'Physics',
    'Chemistry',
    'Biology',
    'Geography',
    'Computer Science',
    'Economics',
  ];

  // Data
  List<TutorSearchResult> _allTutors = [];
  List<TutorSearchResult> _filteredTutors = [];
  List<String> _savedTutorIds = [];

  // Parent location
  double? _parentLat;
  double? _parentLng;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  List<String> get selectedSubjects => _selectedSubjects;
  double get minPrice => _minPrice;
  double get maxPrice => _maxPrice;
  double get locationRadius => _locationRadius;
  SortOption get sortOption => _sortOption;
  List<String> get availableSubjects => _availableSubjects;
  List<TutorSearchResult> get filteredTutors => _filteredTutors;
  int get tutorCount => _filteredTutors.length;

  // ---------- Initialization ----------
  Future<void> initialize() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        _errorMessage = 'User not authenticated';
        _setLoading(false);
        notifyListeners();
        return;
      }

      // Load saved tutor IDs
      if (_prefsService != null) {
        _savedTutorIds = await _prefsService!.getSavedTutorIds();
      }

      // Get parent location
      final parentUser = await _userService.getUserById(currentUser.uid);
      if (parentUser != null) {
        _parentLat = parentUser.latitude;
        _parentLng = parentUser.longitude;
      }

      // Load tutors
      await _loadTutors();

      // Ensure radius is within valid range (max 10KM)
      if (_locationRadius > 10.0) {
        _locationRadius = 10.0;
      } else if (_locationRadius < 1.0) {
        _locationRadius = 1.0;
      }

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      if (!_isDisposed) {
        _errorMessage = 'Failed to load tutors: ${e.toString()}';
        _setLoading(false);
        notifyListeners();
      }
    }
  }

  // ---------- Load Tutors ----------
  Future<void> _loadTutors() async {
    try {
      // Get all tutors from Firestore
      final tutors = await _tutorService.getAllTutors();

      if (tutors.isEmpty) {
        _allTutors = [];
        _filteredTutors = [];
        return;
      }

      // Get user data for each tutor and build search results
      final tutorsWithUserData = <TutorSearchResult>[];

      for (final tutor in tutors) {
        final tutorUser = await _userService.getUserById(tutor.tutorId);
        if (tutorUser == null || tutorUser.status != UserStatus.active) {
          continue;
        }

        // Calculate distance if both have location
        String distance = 'N/A';
        if (_parentLat != null &&
            _parentLng != null &&
            tutorUser.latitude != null &&
            tutorUser.longitude != null) {
          final distanceInKm = DistanceCalculator.calculateDistanceInKm(
            _parentLat!,
            _parentLng!,
            tutorUser.latitude!,
            tutorUser.longitude!,
          );
          distance = DistanceCalculator.formatDistanceInKm(distanceInKm);
        }

        // Build profession string from subjects
        String profession = 'Tutor';
        if (tutor.subjects.isNotEmpty) {
          if (tutor.subjects.length == 1) {
            profession = '${tutor.subjects.first} Tutor';
          } else if (tutor.subjects.length <= 2) {
            profession = tutor.subjects.join(' & ');
          } else {
            profession = '${tutor.subjects.take(2).join(' & ')} Expert';
          }
        }

        // Default hourly rate (you can add this to TutorModel later)
        // For now, using a placeholder based on subjects count
        double hourlyRate = 40.0 + (tutor.subjects.length * 5.0);
        if (hourlyRate > 100) hourlyRate = 100.0;

        final isFavorite = _savedTutorIds.contains(tutor.tutorId);

        tutorsWithUserData.add(
          TutorSearchResult(
            tutorId: tutor.tutorId,
            name: tutorUser.name,
            profession: profession,
            rating: 4.5, // TODO: Get from reviews/ratings collection
            distance: distance,
            hourlyRate: hourlyRate,
            imageUrl: tutorUser.imageUrl ?? '',
            isOnline: false, // TODO: Check online status
            isFavorite: isFavorite,
            subjects: tutor.subjects,
          ),
        );
      }

      _allTutors = tutorsWithUserData;
      _applyFilters();
    } catch (e) {
      if (!_isDisposed) {
        _errorMessage = 'Failed to load tutors: ${e.toString()}';
      }
    }
  }

  // ---------- Search & Filter Methods ----------
  void updateSearchQuery(String query) {
    _searchQuery = query.trim();
    _applyFilters();
    notifyListeners();
  }

  void toggleSubject(String subject) {
    if (_selectedSubjects.contains(subject)) {
      _selectedSubjects.remove(subject);
    } else {
      _selectedSubjects.add(subject);
    }
    _applyFilters();
    notifyListeners();
  }

  void setPriceRange(double min, double max) {
    _minPrice = min;
    _maxPrice = max;
    _applyFilters();
    notifyListeners();
  }

  void setLocationRadius(double radius) {
    // Clamp radius between 1KM and 10KM
    _locationRadius = radius.clamp(1.0, 10.0);
    _applyFilters();
    notifyListeners();
  }

  void setSortOption(SortOption option) {
    _sortOption = option;
    _applyFilters();
    notifyListeners();
  }

  // ---------- Apply Filters ----------
  void _applyFilters() {
    List<TutorSearchResult> filtered = List.from(_allTutors);

    // Filter by search query (name or subject)
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((tutor) {
        // Search by name
        if (tutor.name.toLowerCase().contains(query)) {
          return true;
        }
        // Search by subject
        for (final subject in tutor.subjects) {
          if (subject.toLowerCase().contains(query)) {
            return true;
          }
        }
        // Search by profession
        if (tutor.profession.toLowerCase().contains(query)) {
          return true;
        }
        return false;
      }).toList();
    }

    // Filter by selected subjects (multi-select)
    if (_selectedSubjects.isNotEmpty) {
      filtered = filtered.where((tutor) {
        // Check if tutor has at least one of the selected subjects
        return _selectedSubjects.any((subject) => tutor.subjects.contains(subject));
      }).toList();
    }

    // Filter by price range
    filtered = filtered.where((tutor) {
      return tutor.hourlyRate >= _minPrice && tutor.hourlyRate <= _maxPrice;
    }).toList();

    // Filter by location radius (only if parent has location)
    if (_parentLat != null && _parentLng != null) {
      filtered = filtered.where((tutor) {
        // Extract distance from string or calculate
        if (tutor.distance == 'N/A') return true; // Include if no distance available
        
        // Try to extract numeric distance from string like "1.2 km away"
        final distanceMatch = RegExp(r'([\d.]+)\s*km').firstMatch(tutor.distance);
        if (distanceMatch != null) {
          final distanceInKm = double.tryParse(distanceMatch.group(1) ?? '0') ?? 0.0;
          return distanceInKm <= _locationRadius;
        }
        return true;
      }).toList();
    }

    // Sort
    filtered.sort((a, b) {
      switch (_sortOption) {
        case SortOption.distance:
          // Extract numeric distance for sorting
          final aDist = _extractDistanceInKm(a.distance);
          final bDist = _extractDistanceInKm(b.distance);
          return aDist.compareTo(bDist);
        case SortOption.rating:
          return b.rating.compareTo(a.rating);
        case SortOption.priceLow:
          return a.hourlyRate.compareTo(b.hourlyRate);
        case SortOption.priceHigh:
          return b.hourlyRate.compareTo(a.hourlyRate);
      }
    });

    _filteredTutors = filtered;
  }

  // Extract numeric distance from string (e.g., "1.2 km away" -> 1.2)
  double _extractDistanceInKm(String distance) {
    if (distance == 'N/A') return double.infinity;
    final match = RegExp(r'([\d.]+)\s*km').firstMatch(distance);
    if (match != null) {
      return double.tryParse(match.group(1) ?? '0') ?? double.infinity;
    }
    return double.infinity;
  }

  // ---------- Favorite Methods ----------
  Future<void> toggleFavorite(String tutorId) async {
    if (_savedTutorIds.contains(tutorId)) {
      _savedTutorIds.remove(tutorId);
      if (_prefsService != null) {
        await _prefsService!.removeTutorId(tutorId);
      }
    } else {
      _savedTutorIds.add(tutorId);
      if (_prefsService != null) {
        await _prefsService!.saveTutorId(tutorId);
      }
    }

    // Update in all tutors and filtered tutors
    for (final tutor in _allTutors) {
      if (tutor.tutorId == tutorId) {
        final index = _allTutors.indexOf(tutor);
        _allTutors[index] = TutorSearchResult(
          tutorId: tutor.tutorId,
          name: tutor.name,
          profession: tutor.profession,
          rating: tutor.rating,
          distance: tutor.distance,
          hourlyRate: tutor.hourlyRate,
          imageUrl: tutor.imageUrl,
          isOnline: tutor.isOnline,
          isFavorite: _savedTutorIds.contains(tutorId),
          subjects: tutor.subjects,
        );
        break;
      }
    }

    _applyFilters();
    notifyListeners();
  }

  // ---------- Helper Methods ----------
  void _setLoading(bool value) {
    if (!_isDisposed) {
      _isLoading = value;
    }
  }

  void _safeNotifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
