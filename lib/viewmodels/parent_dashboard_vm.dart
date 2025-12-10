import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/models/tutor_model.dart';
import '../data/models/user_model.dart';
import '../data/services/tutor_services.dart';
import '../data/services/user_services.dart';
import '../core/utils/distance_calculator.dart';
import '../core/services/preferences_service.dart';

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
    _setLoading(true);
    try {
      // Initialize SharedPreferences if not provided
      if (_prefsService == null) {
        _prefsService = await createPreferencesService();
      }

      // Load saved tutor IDs from SharedPreferences
      _savedTutorIds = await _prefsService!.getSavedTutorIds();

      final user = _auth.currentUser;
      if (user != null) {
        final userModel = await _userService.getUserById(user.uid);
        if (userModel != null) {
          _userName = userModel.name;
          _userImageUrl = userModel.imageUrl ?? '';
        }
      }

      await loadTutors();
      await loadNotifications();
    } catch (e) {
      _errorMessage = 'Failed to load dashboard: ${e.toString()}';
    } finally {
      _setLoading(false);
    }
  }

  // ---------- Load Tutors ----------
  Future<void> loadTutors() async {
    try {
      // Get current user location
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final currentUserModel = await _userService.getUserById(currentUser.uid);
      if (currentUserModel == null) return;

      final parentLat = currentUserModel.latitude;
      final parentLng = currentUserModel.longitude;

      // Get all tutors from Firestore
      final tutors = await _tutorService.getAllTutors();
      if (tutors.isEmpty) {
        _nearbyTutors = [];
        _recommendedTutors = [];
        notifyListeners();
        return;
      }

      // Get user data for each tutor
      final tutorsWithUserData = <Map<String, dynamic>>[];
      for (final tutor in tutors) {
        final tutorUser = await _userService.getUserById(tutor.tutorId);
        if (tutorUser != null && tutorUser.status == UserStatus.active) {
          tutorsWithUserData.add({
            'tutor': tutor,
            'user': tutorUser,
          });
        }
      }

      // Calculate distances and create nearby tutors list
      final nearbyTutorsList = <NearbyTutor>[];
      for (final data in tutorsWithUserData) {
        final tutor = data['tutor'] as TutorModel;
        final user = data['user'] as UserModel;

        // Calculate distance if both have coordinates
        String distanceText = 'Distance unknown';
        if (parentLat != null &&
            parentLng != null &&
            user.latitude != null &&
            user.longitude != null) {
          final distance = DistanceCalculator.calculateDistance(
            parentLat,
            parentLng,
            user.latitude!,
            user.longitude!,
          );
          distanceText = DistanceCalculator.formatDistance(distance);
        }

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

      // Sort by distance (if available)
      nearbyTutorsList.sort((a, b) {
        final aDist = _extractDistance(a.distance);
        final bDist = _extractDistance(b.distance);
        return aDist.compareTo(bDist);
      });

      // Take top 10 for nearby
      _nearbyTutors = nearbyTutorsList.take(10).toList();

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

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading tutors: $e');
      }
      _errorMessage = 'Failed to load tutors: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Extract numeric distance from string (e.g., "1.2 miles away" -> 1.2)
  double _extractDistance(String distanceStr) {
    try {
      final match = RegExp(r'(\d+\.?\d*)').firstMatch(distanceStr);
      if (match != null) {
        return double.parse(match.group(1)!);
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
      _notificationCount = 3; // Mock data
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading notifications: $e');
      }
    }
  }

  // ---------- Search ----------
  void searchTutors(String query) {
    // TODO: Implement search functionality
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

      notifyListeners();
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
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

