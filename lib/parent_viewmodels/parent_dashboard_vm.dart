import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/models/tutor_model.dart';
import '../data/models/user_model.dart';
import '../data/services/tutor_services.dart';
import '../data/services/user_services.dart';
import '../core/utils/distance_calculator.dart';
import '../core/services/preferences_service.dart';
import '../core/utils/debug_logger.dart';

/// Model for nearby tutor display
class NearbyTutor {
  final String tutorId;
  final String name;
  final String subject;
  final String distance;
  final String imageUrl;

  NearbyTutor({
    required this.tutorId,
    required this.name,
    required this.subject,
    required this.distance,
    this.imageUrl = '',
  });
}

/// Model for recommended tutor display
class RecommendedTutor {
  final String tutorId;
  final String name;
  final double rating;
  final int reviewCount;
  final String specialization;
  final String imageUrl;
  final bool isSaved;

  RecommendedTutor({
    required this.tutorId,
    required this.name,
    required this.rating,
    required this.reviewCount,
    required this.specialization,
    this.imageUrl = '',
    this.isSaved = false,
  });
}

class ParentDashboardViewModel extends ChangeNotifier {
  final TutorService _tutorService;
  final UserService _userService;
  final FirebaseAuth _auth;
  PreferencesService? _prefsService;

  ParentDashboardViewModel({
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
  String _userName = '';
  String _userImageUrl = '';
  int _notificationCount = 0;

  List<NearbyTutor> _nearbyTutors = [];
  List<RecommendedTutor> _recommendedTutors = [];
  List<String> _savedTutorIds = [];

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get userName => _userName;
  String get userImageUrl => _userImageUrl;
  int get notificationCount => _notificationCount;
  List<NearbyTutor> get nearbyTutors => _nearbyTutors;
  List<RecommendedTutor> get recommendedTutors => _recommendedTutors;

  // ---------- Initialize ----------
  Future<void> initialize() async {
    if (_isDisposed) return;
    
    _setLoading(true);
    try {
      // Initialize SharedPreferences if not provided
      if (_prefsService == null) {
        _prefsService = await createPreferencesService();
      }

      if (_isDisposed) return;

      // Load saved tutor IDs from SharedPreferences
      _savedTutorIds = await _prefsService!.getSavedTutorIds();

      if (_isDisposed) return;

      final user = _auth.currentUser;
      if (user != null) {
        final userModel = await _userService.getUserById(user.uid);
        if (userModel != null && !_isDisposed) {
          _userName = userModel.name;
          _userImageUrl = userModel.imageUrl ?? '';
        }
      }

      if (_isDisposed) return;

      await loadTutors();
      
      if (_isDisposed) return;
      
      await loadNotifications();
    } catch (e) {
      if (!_isDisposed) {
        _errorMessage = 'Failed to load dashboard: ${e.toString()}';
      }
    } finally {
      if (!_isDisposed) {
        _setLoading(false);
      }
    }
  }

  // ---------- Load Tutors ----------
  Future<void> loadTutors() async {
    // #region agent log
    await DebugLogger.log(location: 'parent_dashboard_vm.dart:131', message: 'Loading tutors for parent', data: {'userId': _auth.currentUser?.uid}, hypothesisId: 'SEARCH-1');
    // #endregion
    try {
      // Get current user location
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final currentUserModel = await _userService.getUserById(currentUser.uid);
      // #region agent log
      await DebugLogger.log(location: 'parent_dashboard_vm.dart:141', message: 'Current user model loaded', data: {'userId': currentUser.uid, 'found': currentUserModel != null, 'hasLocation': currentUserModel?.latitude != null && currentUserModel?.longitude != null}, hypothesisId: 'SEARCH-1');
      // #endregion
      if (currentUserModel == null) {
        // #region agent log
        await DebugLogger.log(location: 'parent_dashboard_vm.dart:142', message: 'Current user model not found - returning early', data: {'userId': currentUser.uid}, hypothesisId: 'SEARCH-1');
        // #endregion
        return;
      }

      final parentLat = currentUserModel.latitude;
      final parentLng = currentUserModel.longitude;
      // #region agent log
      await DebugLogger.log(location: 'parent_dashboard_vm.dart:145', message: 'Parent location extracted', data: {'lat': parentLat, 'lng': parentLng, 'hasLocation': parentLat != null && parentLng != null}, hypothesisId: 'SEARCH-1');
      // #endregion

      // Get all tutors from Firestore
      final tutors = await _tutorService.getAllTutors();
      // #region agent log
      await DebugLogger.log(location: 'parent_dashboard_vm.dart:144', message: 'Tutors loaded from Firestore', data: {'tutorCount': tutors.length, 'parentLat': parentLat, 'parentLng': parentLng}, hypothesisId: 'SEARCH-1');
      // #endregion
      if (_isDisposed) return;
      
      if (tutors.isEmpty) {
        _nearbyTutors = [];
        _recommendedTutors = [];
        _safeNotifyListeners();
        return;
      }

      // Get user data for each tutor
      final tutorsWithUserData = <Map<String, dynamic>>[];
      int activeCount = 0;
      int inactiveCount = 0;
      for (final tutor in tutors) {
        if (_isDisposed) return;
        
        final tutorUser = await _userService.getUserById(tutor.tutorId);
        if (tutorUser != null && tutorUser.status == UserStatus.active) {
          tutorsWithUserData.add({
            'tutor': tutor,
            'user': tutorUser,
          });
          activeCount++;
        } else {
          inactiveCount++;
        }
      }
      // #region agent log
      await DebugLogger.log(location: 'parent_dashboard_vm.dart:173', message: 'Tutor user data loaded', data: {'totalTutors': tutors.length, 'activeTutors': activeCount, 'inactiveTutors': inactiveCount, 'tutorsWithUserData': tutorsWithUserData.length}, hypothesisId: 'SEARCH-1');
      // #endregion
      
      if (_isDisposed) return;

      // Calculate distances and create nearby tutors list
      // Filter tutors within 5km radius
      //agr distance ko 10km ka circle krna to idr 10 likh do
      const double radiusInKm = 5.0; // 5km radius
      final nearbyTutorsList = <NearbyTutor>[];
      
      for (final data in tutorsWithUserData) {
        final tutor = data['tutor'] as TutorModel;
        final user = data['user'] as UserModel;

        // Skip if parent or tutor doesn't have location
        if (parentLat == null ||
            parentLng == null ||
            user.latitude == null ||
            user.longitude == null) {
          continue; // Skip tutors without location data
        }

        // Check if tutor is within 5km radius
        final isWithinRadius = DistanceCalculator.isWithinRadius(
          parentLat,
          parentLng,
          user.latitude!,
          user.longitude!,
          radiusInKm,
        );

        // Only add tutors within 5km radius
        if (!isWithinRadius) {
          continue;
        }

        // Calculate distance for display
        final distanceInKm = DistanceCalculator.calculateDistanceInKm(
          parentLat,
          parentLng,
          user.latitude!,
          user.longitude!,
        );
        final distanceText = DistanceCalculator.formatDistanceInKm(distanceInKm);

        // Get first subject or default
        final subject = tutor.subjects.isNotEmpty
            ? tutor.subjects.first
            : 'General';

        nearbyTutorsList.add(
          NearbyTutor(
            tutorId: tutor.tutorId,
            name: user.name,
            subject: subject,
            distance: distanceText,
            imageUrl: user.imageUrl ?? '',
          ),
        );
      }

      // Sort by distance (if available) - now in kilometers
      nearbyTutorsList.sort((a, b) {
        final aDist = _extractDistanceInKm(a.distance);
        final bDist = _extractDistanceInKm(b.distance);
        return aDist.compareTo(bDist);
      });

      // Take top 10 for nearby
      _nearbyTutors = nearbyTutorsList.take(10).toList();
      // #region agent log
      await DebugLogger.log(location: 'parent_dashboard_vm.dart:215', message: 'Nearby tutors calculated', data: {'nearbyCount': _nearbyTutors.length, 'totalTutors': tutorsWithUserData.length}, hypothesisId: 'SEARCH-1');
      // #endregion

      // Create recommended tutors (all tutors for now, can add recommendation logic later)
      _recommendedTutors = tutorsWithUserData.map((data) {
        final tutor = data['tutor'] as TutorModel;
        final user = data['user'] as UserModel;

        // Combine subjects for specialization
        final specialization = tutor.subjects.isNotEmpty
            ? tutor.subjects.join(' & ')
            : tutor.bio ?? 'General Tutoring';

        return RecommendedTutor(
          tutorId: tutor.tutorId,
          name: user.name,
          rating: 4.5, // TODO: Get from reviews/ratings collection
          reviewCount: 0, // TODO: Get from reviews collection
          specialization: specialization,
          imageUrl: user.imageUrl ?? '',
          isSaved: _savedTutorIds.contains(tutor.tutorId),
        );
      }).toList();

      if (!_isDisposed) {
        _safeNotifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading tutors: $e');
      }
      if (!_isDisposed) {
        _errorMessage = 'Failed to load tutors: ${e.toString()}';
        _safeNotifyListeners();
      }
    }
  }

  /// Extract numeric distance from string (e.g., "1.2 km away" -> 1.2)
  /// Supports both km and miles format
  double _extractDistanceInKm(String distanceStr) {
    try {
      final match = RegExp(r'(\d+\.?\d*)').firstMatch(distanceStr);
      if (match != null) {
        final value = double.parse(match.group(1)!);
        // If string contains "miles", convert to km
        if (distanceStr.toLowerCase().contains('miles')) {
          return value * 1.60934; // Convert miles to km
        }
        return value; // Already in km
      }
    } catch (e) {
      // Ignore
    }
    return double.infinity; // Unknown distance goes to end
  }

  // ---------- Notifications ----------
  Future<void> loadNotifications() async {
    try {
      // TODO: Implement notification count from Firestore
      if (!_isDisposed) {
        _notificationCount = 3; // Mock data
        _safeNotifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading notifications: $e');
      }
    }
  }

  // ---------- Search ----------
  void searchTutors(String query) {
    // #region agent log
    DebugLogger.log(location: 'parent_dashboard_vm.dart:281', message: 'Search tutors called', data: {'query': query, 'queryLength': query.length}, hypothesisId: 'SEARCH-2').catchError((_) {});
    // #endregion
    // TODO: Implement search functionality
    // #region agent log
    DebugLogger.log(location: 'parent_dashboard_vm.dart:283', message: 'Search functionality not implemented - only prints to console', data: {'query': query}, hypothesisId: 'SEARCH-2').catchError((_) {});
    // #endregion
    if (kDebugMode) {
      print('Searching for: $query');
    }
  }

  // ---------- Save/Unsave Tutor ----------
  Future<void> toggleSaveTutor(String tutorId) async {
    try {
      if (_prefsService == null) {
        _prefsService = await createPreferencesService();
      }

      if (_savedTutorIds.contains(tutorId)) {
        _savedTutorIds.remove(tutorId);
        await _prefsService!.removeTutorId(tutorId);
      } else {
        _savedTutorIds.add(tutorId);
        await _prefsService!.saveTutorId(tutorId);
      }

      // Update recommended tutors list
      _recommendedTutors = _recommendedTutors.map((tutor) {
        if (tutor.tutorId == tutorId) {
          return RecommendedTutor(
            tutorId: tutor.tutorId,
            name: tutor.name,
            rating: tutor.rating,
            reviewCount: tutor.reviewCount,
            specialization: tutor.specialization,
            imageUrl: tutor.imageUrl,
            isSaved: _savedTutorIds.contains(tutorId),
          );
        }
        return tutor;
      }).toList();

      if (!_isDisposed) {
        _safeNotifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to save tutor: ${e.toString()}';
      notifyListeners();
    }
  }

  // ---------- Get Greeting ----------
  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning';
    } else if (hour < 17) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }

  // ---------- Helpers ----------
  void _setLoading(bool value) {
    if (_isDisposed) return;
    _isLoading = value;
    _safeNotifyListeners();
  }

  void clearError() {
    if (_isDisposed) return;
    _errorMessage = null;
    _safeNotifyListeners();
  }

  // Safe notify listeners - checks if disposed before notifying
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

