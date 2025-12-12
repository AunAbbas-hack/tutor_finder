// lib/viewmodels/tutor_detail_vm.dart
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/models/user_model.dart';
import '../data/models/tutor_model.dart';
import '../data/services/user_services.dart';
import '../data/services/tutor_services.dart';

class TutorDetailViewModel extends ChangeNotifier {
  final UserService _userService;
  final TutorService _tutorService;
  final FirebaseAuth _auth;

  final String tutorId;

  TutorDetailViewModel({
    required this.tutorId,
    UserService? userService,
    TutorService? tutorService,
    FirebaseAuth? auth,
  })  : _userService = userService ?? UserService(),
        _tutorService = tutorService ?? TutorService(),
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

  // Mock data (will be replaced with actual data from Firestore)
  double get rating => 4.9; // TODO: Fetch from reviews collection
  int get reviewCount => 82; // TODO: Fetch from reviews collection
  double get hourlyFee => 75.0; // TODO: Add fee field to TutorModel
  List<String> get languages => ['English', 'German']; // TODO: Add languages field to TutorModel
  String get fullAddress {
    // TODO: Get full address from UserModel or ParentModel
    // For now, using latitude/longitude to construct address
    if (_tutorUser?.latitude != null && _tutorUser?.longitude != null) {
      return '${_tutorUser!.latitude}, ${_tutorUser!.longitude}';
    }
    return 'Address not available';
  }

  // Available time slots (mock data - will be fetched from availability/schedule)
  List<String> getAvailableTimeSlots(DateTime date) {
    // TODO: Fetch actual time slots from tutor's schedule
    // Mock data for now
    return ['10:00 AM', '1:00 PM', '3:00 PM', '5:00 PM'];
  }

  // Get next 5 days starting from today
  List<DateTime> getNextFiveDays() {
    final today = DateTime.now();
    return List.generate(5, (index) => today.add(Duration(days: index)));
  }

  // Initialize and load data
  Future<void> initialize() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      // Load tutor user data
      _tutorUser = await _userService.getUserById(tutorId);
      if (_tutorUser == null) {
        _errorMessage = 'Tutor not found';
        _setLoading(false);
        notifyListeners();
        return;
      }

      // Load tutor profile data
      _tutor = await _tutorService.getTutorById(tutorId);
      if (_tutor == null) {
        _errorMessage = 'Tutor profile not found';
        _setLoading(false);
        notifyListeners();
        return;
      }

      _setLoading(false);
      notifyListeners();
    } catch (e) {
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
  }

  // Select time slot
  void selectTimeSlot(String timeSlot) {
    _selectedTimeSlot = timeSlot;
    notifyListeners();
  }

  // Request booking
  Future<bool> requestBooking({
    required String subject,
    required DateTime bookingDate,
    required String bookingTime,
    String? notes,
  }) async {
    try {
      // TODO: Implement booking request creation
      // This will call BookingService to create a booking request
      return true;
    } catch (e) {
      _errorMessage = 'Failed to request booking: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}

