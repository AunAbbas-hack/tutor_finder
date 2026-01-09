// lib/parent_viewmodels/request_booking_vm.dart
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/models/booking_model.dart';
import '../data/models/tutor_model.dart';
import '../data/models/student_model.dart';
import '../data/models/user_model.dart';
import '../data/services/booking_services.dart';
import '../data/services/user_services.dart';
import '../data/services/student_services.dart';
import '../data/services/tutor_services.dart';
import '../data/services/notification_service.dart';

class RequestBookingViewModel extends ChangeNotifier {
  final BookingService _bookingService;
  final UserService _userService;
  final StudentService _studentService;
  final FirebaseAuth _auth;

  final String tutorId;
  final String tutorName;
  final String? tutorImageUrl;
  final List<String> tutorSubjects;

  RequestBookingViewModel({
    required this.tutorId,
    required this.tutorName,
    this.tutorImageUrl,
    required this.tutorSubjects,
    BookingService? bookingService,
    UserService? userService,
    StudentService? studentService,
    FirebaseAuth? auth,
  })  : _bookingService = bookingService ?? BookingService(),
        _userService = userService ?? UserService(),
        _studentService = studentService ?? StudentService(),
        _auth = auth ?? FirebaseAuth.instance;

  // State
  bool _isLoading = false;
  String? _errorMessage;
  List<String> _selectedSubjects = [];
  List<String> _selectedChildrenIds = [];
  BookingType _bookingType = BookingType.monthlyBooking;
  DateTime? _startDate;
  List<int> _recurringDays = [];
  String? _selectedTimeSlot;
  double _monthlyBudget = 5000.0; // Default 5000 rupees
  String _notes = '';
  
  // Single session fields
  DateTime? _preferredDate; // For single session
  String? _timePreference; // 'Morning', 'Afternoon', 'Evening'
  double _hourlyBudget = 2000.0; // Default ₹2000/hr (converted from $75/hr)
  
  // Available data
  List<StudentModel> _children = [];
  List<String> _availableTimeSlots = [
    '4:00 PM',
    '5:00 PM',
    '6:00 PM',
    '7:00 PM',
    '8:00 PM',
  ];
  
  List<String> get timePreferences => ['Morning', 'Afternoon', 'Evening'];

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<String> get selectedSubjects => _selectedSubjects;
  List<String> get selectedChildrenIds => _selectedChildrenIds;
  BookingType get bookingType => _bookingType;
  DateTime? get startDate => _startDate;
  List<int> get recurringDays => _recurringDays;
  String? get selectedTimeSlot => _selectedTimeSlot;
  double get monthlyBudget => _monthlyBudget;
  String get notes => _notes;
  List<StudentModel> get children => _children;
  List<String> get availableTimeSlots => _availableTimeSlots;
  
  // Single session getters
  DateTime? get preferredDate => _preferredDate;
  String? get timePreference => _timePreference;
  double get hourlyBudget => _hourlyBudget;

  // Initialize
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

      // Load parent's children
      await _loadChildren(currentUser.uid);
      
      // Set default dates to today
      _startDate = DateTime.now();
      _preferredDate = DateTime.now();
      
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to initialize: ${e.toString()}';
      _setLoading(false);
      notifyListeners();
    }
  }

  Future<void> _loadChildren(String parentId) async {
    try {
      _children = await _studentService.getStudentsByParentId(parentId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading children: $e');
    }
  }

  // Subject selection
  void toggleSubject(String subject) {
    if (_selectedSubjects.contains(subject)) {
      _selectedSubjects.remove(subject);
    } else {
      _selectedSubjects.add(subject);
    }
    notifyListeners();
  }

  bool isSubjectSelected(String subject) {
    return _selectedSubjects.contains(subject);
  }

  // Children selection
  void toggleChild(String childId) {
    if (_selectedChildrenIds.contains(childId)) {
      _selectedChildrenIds.remove(childId);
    } else {
      _selectedChildrenIds.add(childId);
    }
    notifyListeners();
  }

  bool isChildSelected(String childId) {
    return _selectedChildrenIds.contains(childId);
  }

  // Booking type
  void setBookingType(BookingType type) {
    _bookingType = type;
    // Set default time preference for single session
    if (type == BookingType.singleSession && _timePreference == null) {
      _timePreference = 'Afternoon';
    }
    notifyListeners();
  }

  // Start date
  void setStartDate(DateTime date) {
    _startDate = date;
    notifyListeners();
  }

  // Recurring days (1=Monday, 2=Tuesday, etc.)
  void toggleRecurringDay(int day) {
    if (_recurringDays.contains(day)) {
      _recurringDays.remove(day);
    } else {
      _recurringDays.add(day);
      _recurringDays.sort();
    }
    notifyListeners();
  }

  bool isRecurringDaySelected(int day) {
    return _recurringDays.contains(day);
  }

  // Time slot
  void setTimeSlot(String timeSlot) {
    _selectedTimeSlot = timeSlot;
    notifyListeners();
  }

  // Monthly budget
  void setMonthlyBudget(double budget) {
    _monthlyBudget = budget;
    notifyListeners();
  }

  // Notes
  void updateNotes(String notes) {
    _notes = notes;
    notifyListeners();
  }

  // Single session - Preferred date
  void setPreferredDate(DateTime date) {
    _preferredDate = date;
    notifyListeners();
  }

  // Single session - Time preference
  void setTimePreference(String preference) {
    _timePreference = preference;
    notifyListeners();
  }

  bool isTimePreferenceSelected(String preference) {
    return _timePreference == preference;
  }

  // Single session - Hourly budget
  void setHourlyBudget(double budget) {
    _hourlyBudget = budget;
    notifyListeners();
  }

  // Validation
  bool get canSubmit {
    if (_selectedSubjects.isEmpty) return false;
    if (_selectedChildrenIds.isEmpty) return false;
    if (_bookingType == BookingType.monthlyBooking) {
      if (_startDate == null) return false;
      if (_recurringDays.isEmpty) return false;
      if (_selectedTimeSlot == null) return false;
    } else {
      // Single session validation
      if (_preferredDate == null) return false;
      if (_timePreference == null) return false;
    }
    return true;
  }

  // Calculate sessions per month
  int get sessionsPerMonth {
    return _recurringDays.length * 4; // Approximate 4 weeks per month
  }

  // Calculate price per session
  double get pricePerSession {
    if (sessionsPerMonth == 0) return 0;
    return _monthlyBudget / sessionsPerMonth;
  }

  // Submit booking
  Future<bool> submitBooking() async {
    if (!canSubmit) {
      _errorMessage = 'Please fill all required fields';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    _errorMessage = null;
    notifyListeners();

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        _errorMessage = 'User not authenticated';
        _setLoading(false);
        notifyListeners();
        return false;
      }

      final bookingId = DateTime.now().millisecondsSinceEpoch.toString();
      
      // Determine booking date and time based on type
      final bookingDate = _bookingType == BookingType.monthlyBooking
          ? (_startDate ?? DateTime.now())
          : (_preferredDate ?? DateTime.now());
      
      final bookingTime = _bookingType == BookingType.monthlyBooking
          ? (_selectedTimeSlot ?? '4:00 PM')
          : (_timePreference ?? 'Afternoon');

      final booking = BookingModel(
        bookingId: bookingId,
        parentId: currentUser.uid,
        tutorId: tutorId,
        subject: _selectedSubjects.first, // For backward compatibility
        subjects: _selectedSubjects,
        bookingDate: bookingDate,
        bookingTime: bookingTime,
        status: BookingStatus.pending,
        notes: _notes.isNotEmpty ? _notes : null,
        createdAt: DateTime.now(),
        bookingType: _bookingType,
        startDate: _bookingType == BookingType.monthlyBooking ? _startDate : _preferredDate,
        recurringDays: _recurringDays.isNotEmpty ? _recurringDays : null,
        monthlyBudget: _bookingType == BookingType.monthlyBooking ? _monthlyBudget : _hourlyBudget,
        childrenIds: _selectedChildrenIds.isNotEmpty ? _selectedChildrenIds : null,
      );

      await _bookingService.createBooking(booking);

      // Send notification to tutor
      try {
        final notificationService = NotificationService();
        final tutorService = TutorService();
        final tutor = await tutorService.getTutorById(tutorId);
        final parent = await _userService.getUserById(currentUser.uid);
        
        if (tutor != null && parent != null) {
          final subjectsText = _selectedSubjects.join(', ');
          await notificationService.sendBookingNotificationToTutor(
            tutorId: tutorId,
            parentName: parent.name,
            subject: subjectsText,
            bookingId: bookingId,
          );
        }
      } catch (e) {
        // Don't fail booking if notification fails
        if (kDebugMode) {
          print('⚠️ Failed to send booking notification: $e');
        }
      }

      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to submit booking: ${e.toString()}';
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Format budget in rupees
  String formatBudget(double amount) {
    return '₹${amount.toStringAsFixed(0)}/mo';
  }

  // Format hourly budget in rupees
  String formatHourlyBudget(double amount) {
    return '₹${amount.toStringAsFixed(0)}/hr';
  }

  // Format price per session
  String formatPricePerSession() {
    return '₹${pricePerSession.toStringAsFixed(0)}/session';
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}

