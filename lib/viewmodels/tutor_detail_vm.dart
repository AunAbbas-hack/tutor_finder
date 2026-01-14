// lib/viewmodels/tutor_detail_vm.dart
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geocoding/geocoding.dart';
import '../data/models/user_model.dart';
import '../data/models/tutor_model.dart';
import '../data/models/review_model.dart';
import '../data/services/user_services.dart';
import '../data/services/tutor_services.dart';
import '../data/services/review_service.dart';
import '../data/services/availability_service.dart';
import '../data/models/availability_model.dart';
import '../core/utils/debug_logger.dart';

class TutorDetailViewModel extends ChangeNotifier {
  final UserService _userService;
  final TutorService _tutorService;
  final ReviewService _reviewService;
  final AvailabilityService _availabilityService;
  final FirebaseAuth _auth;

  final String tutorId;

  TutorDetailViewModel({
    required this.tutorId,
    UserService? userService,
    TutorService? tutorService,
    ReviewService? reviewService,
    AvailabilityService? availabilityService,
    FirebaseAuth? auth,
  })  : _userService = userService ?? UserService(),
        _tutorService = tutorService ?? TutorService(),
        _reviewService = reviewService ?? ReviewService(),
        _availabilityService = availabilityService ?? AvailabilityService(),
        _auth = auth ?? FirebaseAuth.instance;

  // Loading state
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Error message
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Tutor and User data
  UserModel? _tutorUser;
  TutorModel? _tutor;
  UserModel? get tutorUser => _tutorUser;
  TutorModel? get tutor => _tutor;

  // Selected tab (0: About, 1: Schedule, 2: Reviews)
  int _selectedTab = 0;
  int get selectedTab => _selectedTab;

  // Selected date for availability
  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

  // Selected time slot
  String? _selectedTimeSlot;
  String? get selectedTimeSlot => _selectedTimeSlot;

  // Availability data
  AvailabilityModel? _availability;
  AvailabilityModel? get availability => _availability;

  // Reviews data
  List<ReviewModel> _reviews = [];
  double _averageRating = 0.0;
  int _reviewCount = 0;

  // Location address
  String? _locationAddress;

  List<ReviewModel> get reviews => _reviews;
  double get rating => _averageRating;
  int get reviewCount => _reviewCount;
  double get hourlyFee => _tutor?.hourlyFee ?? 0.0; // Get fee from TutorModel, default to 0 if not set
  double? get monthlyFee => _tutor?.monthlyFee; // Get monthly fee from TutorModel
  List<String> get languages => _tutor?.languages ?? []; // Get languages from TutorModel
  String get fullAddress {
    if (_locationAddress != null && _locationAddress!.isNotEmpty) {
      return _locationAddress!;
    }
    // Never show coordinates - show appropriate message instead
    if (_isLoading) {
      return 'Loading address...';
    }
    // If address fetch failed or coordinates not available
    return 'Address not available';
  }

  // Load availability
  Future<void> _loadAvailability() async {
    try {
      _availability = await _availabilityService.getAvailabilityByTutorId(tutorId);
      if (kDebugMode) {
        print('✅ Availability loaded for tutor: $tutorId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading availability: $e');
      }
      _availability = null;
    }
  }

  // Get available time slots for a date (with booked slots excluded)
  Future<List<String>> getAvailableTimeSlots(DateTime date) async {
    try {
      final slots = await _availabilityService.getAvailableTimeSlotsForDate(
        tutorId: tutorId,
        date: date,
        excludeBooked: true,
      );
      
      // Convert TimeSlot objects to display strings
      return slots.map((slot) => slot.displayStartTime).toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting available time slots: $e');
      }
      // Fallback: return from availability model if available
      if (_availability != null) {
        final slots = _availability!.getAvailableTimeSlotsForDate(date);
        return slots.map((slot) => slot.displayStartTime).toList();
      }
      return [];
    }
  }

  // Get next 5 days starting from today
  List<DateTime> getNextFiveDays() {
    final today = DateTime.now();
    return List.generate(5, (index) => today.add(Duration(days: index)));
  }

  // Initialize and load data
  Future<void> initialize() async {
    // #region agent log
    await DebugLogger.log(location: 'tutor_detail_vm.dart:79', message: 'Initializing tutor detail view', data: {'tutorId': tutorId}, hypothesisId: 'TUTOR-DETAIL-1');
    // #endregion
    _setLoading(true);
    _errorMessage = null;

    try {
      // Load tutor user data
      _tutorUser = await _userService.getUserById(tutorId);
      // #region agent log
      await DebugLogger.log(location: 'tutor_detail_vm.dart:86', message: 'Tutor user loaded', data: {'tutorId': tutorId, 'found': _tutorUser != null, 'status': _tutorUser?.status.toString()}, hypothesisId: 'TUTOR-DETAIL-1');
      // #endregion
      if (_tutorUser == null) {
        _errorMessage = 'Tutor not found';
        // #region agent log
        await DebugLogger.log(location: 'tutor_detail_vm.dart:89', message: 'Tutor user not found', data: {'tutorId': tutorId}, hypothesisId: 'TUTOR-DETAIL-1');
        // #endregion
        _setLoading(false);
        notifyListeners();
        return;
      }

      // Load tutor profile data
      _tutor = await _tutorService.getTutorById(tutorId);
      // #region agent log
      await DebugLogger.log(location: 'tutor_detail_vm.dart:95', message: 'Tutor profile loaded', data: {'tutorId': tutorId, 'found': _tutor != null, 'subjects': _tutor?.subjects.length ?? 0}, hypothesisId: 'TUTOR-DETAIL-1');
      // #endregion
      if (_tutor == null) {
        _errorMessage = 'Tutor profile not found';
        // #region agent log
        await DebugLogger.log(location: 'tutor_detail_vm.dart:98', message: 'Tutor profile not found', data: {'tutorId': tutorId}, hypothesisId: 'TUTOR-DETAIL-1');
        // #endregion
        _setLoading(false);
        notifyListeners();
        return;
      }

      // Load reviews and ratings
      await _loadReviews();

      // Load availability
      await _loadAvailability();

      // Fetch address from coordinates if location is available
      if (_tutorUser?.latitude != null && _tutorUser?.longitude != null) {
        await _fetchAddressFromCoordinates(
          _tutorUser!.latitude!,
          _tutorUser!.longitude!,
        );
      }

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      // #region agent log
      await DebugLogger.log(location: 'tutor_detail_vm.dart:107', message: 'Error loading tutor details', data: {'tutorId': tutorId, 'error': e.toString()}, hypothesisId: 'TUTOR-DETAIL-1');
      // #endregion
      _errorMessage = 'Failed to load tutor details: ${e.toString()}';
      _setLoading(false);
      notifyListeners();
    }
  }

  // Change selected tab
  void selectTab(int index) {
    _selectedTab = index;
    notifyListeners();
  }

  // Select date
  void selectDate(DateTime date) {
    _selectedDate = date;
    _selectedTimeSlot = null; // Reset time slot when date changes
    notifyListeners();
    // Time slots will reload automatically via FutureBuilder in UI
  }

  // Select time slot
  void selectTimeSlot(String timeSlot) {
    _selectedTimeSlot = timeSlot;
    notifyListeners();
  }

  // ---------- Load Reviews ----------
  Future<void> _loadReviews() async {
    try {
      _reviews = await _reviewService.getReviewsByTutorId(tutorId);
      _reviewCount = _reviews.length;
      
      if (_reviews.isNotEmpty) {
        _averageRating = await _reviewService.getAverageRating(tutorId);
      } else {
        _averageRating = 0.0;
      }

      if (kDebugMode) {
        print('✅ Reviews loaded: $_reviewCount reviews, average rating: $_averageRating');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading reviews: $e');
      }
      // Don't fail initialization if reviews fail to load
      _reviews = [];
      _reviewCount = 0;
      _averageRating = 0.0;
    }
  }

  // Refresh reviews (call after submitting a new review)
  Future<void> refreshReviews() async {
    await _loadReviews();
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Fetch address from coordinates using geocoding
  Future<void> _fetchAddressFromCoordinates(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        _locationAddress = _formatAddress(place);
        notifyListeners();
      }
    } catch (e) {
      // Silently fail - address is optional
      if (kDebugMode) {
        print('Error fetching address: $e');
      }
      _locationAddress = null;
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
}

