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

/// Per-child booking details
class ChildBookingDetails {
  DateTime? bookingDate;
  String? timeSlot; // For monthly: "4:00 PM", For single: "Morning"
  double budget; // Monthly or hourly budget
  String notes;
  List<String> selectedSubjects; // Subjects selected for this child

  ChildBookingDetails({
    this.bookingDate,
    this.timeSlot,
    this.budget = 5000.0,
    this.notes = '',
    this.selectedSubjects = const [],
  });

  ChildBookingDetails copyWith({
    DateTime? bookingDate,
    String? timeSlot,
    double? budget,
    String? notes,
    List<String>? selectedSubjects,
  }) {
    return ChildBookingDetails(
      bookingDate: bookingDate ?? this.bookingDate,
      timeSlot: timeSlot ?? this.timeSlot,
      budget: budget ?? this.budget,
      notes: notes ?? this.notes,
      selectedSubjects: selectedSubjects ?? this.selectedSubjects,
    );
  }
}

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
  List<String> _selectedChildrenIds = [];
  BookingType _bookingType = BookingType.singleSession; // Changed default to single session
  
  // Per-child booking details
  final Map<String, ChildBookingDetails> _childBookingDetails = {};
  
  // For monthly booking: recurring days (shared across all children)
  List<int> _recurringDays = [];
  
  // Available data
  List<StudentModel> _children = [];
  List<String> _availableTimeSlots = [
    '4:00 PM',
    '5:00 PM',
    '6:00 PM',
    '7:00 PM',
    '8:00 PM',
  ];

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<String> get selectedChildrenIds => _selectedChildrenIds;
  BookingType get bookingType => _bookingType;
  List<int> get recurringDays => _recurringDays;
  List<StudentModel> get children => _children;
  List<String> get availableTimeSlots => _availableTimeSlots;

  // Get booking details for a specific child
  ChildBookingDetails? getChildBookingDetails(String childId) {
    return _childBookingDetails[childId];
  }

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

  // Refresh children list (called after adding new child)
  Future<void> refreshChildren() async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      await _loadChildren(currentUser.uid);
    }
  }

  // Per-child subject selection
  void toggleChildSubject(String childId, String subject) {
    if (_childBookingDetails.containsKey(childId)) {
      final details = _childBookingDetails[childId]!;
      final subjects = List<String>.from(details.selectedSubjects);
      if (subjects.contains(subject)) {
        subjects.remove(subject);
      } else {
        subjects.add(subject);
      }
      _childBookingDetails[childId] = details.copyWith(selectedSubjects: subjects);
      notifyListeners();
    }
  }

  bool isChildSubjectSelected(String childId, String subject) {
    final details = _childBookingDetails[childId];
    if (details == null) return false;
    return details.selectedSubjects.contains(subject);
  }

  // Children selection
  void toggleChild(String childId) {
    if (_selectedChildrenIds.contains(childId)) {
      _selectedChildrenIds.remove(childId);
      _childBookingDetails.remove(childId); // Remove booking details
    } else {
      _selectedChildrenIds.add(childId);
      // Initialize booking details for new child
      _childBookingDetails[childId] = ChildBookingDetails(
        bookingDate: DateTime.now(),
        timeSlot: '4:00 PM', // Same time slots for both types
        budget: _bookingType == BookingType.singleSession ? 500.0 : 5000.0,
        selectedSubjects: [],
      );
    }
    notifyListeners();
  }

  bool isChildSelected(String childId) {
    return _selectedChildrenIds.contains(childId);
  }

  // Booking type
  void setBookingType(BookingType type) {
    _bookingType = type;
    
    // Update all child booking details with new defaults
    for (var childId in _selectedChildrenIds) {
      if (_childBookingDetails.containsKey(childId)) {
        _childBookingDetails[childId] = _childBookingDetails[childId]!.copyWith(
          timeSlot: '4:00 PM', // Same time slots for both types
          budget: type == BookingType.singleSession ? 500.0 : 5000.0,
        );
      }
    }
    
    notifyListeners();
  }

  // Per-child methods
  void setChildBookingDate(String childId, DateTime date) {
    if (_childBookingDetails.containsKey(childId)) {
      _childBookingDetails[childId] = _childBookingDetails[childId]!.copyWith(
        bookingDate: date,
      );
      notifyListeners();
    }
  }

  void setChildTimeSlot(String childId, String timeSlot) {
    if (_childBookingDetails.containsKey(childId)) {
      _childBookingDetails[childId] = _childBookingDetails[childId]!.copyWith(
        timeSlot: timeSlot,
      );
      notifyListeners();
    }
  }

  // Check if a time slot is custom (not in predefined list)
  bool isCustomTimeSlot(String? timeSlot) {
    if (timeSlot == null) return false;
    return !_availableTimeSlots.contains(timeSlot);
  }

  void setChildBudget(String childId, double budget) {
    if (_childBookingDetails.containsKey(childId)) {
      _childBookingDetails[childId] = _childBookingDetails[childId]!.copyWith(
        budget: budget,
      );
      notifyListeners();
    }
  }

  void setChildNotes(String childId, String notes) {
    if (_childBookingDetails.containsKey(childId)) {
      _childBookingDetails[childId] = _childBookingDetails[childId]!.copyWith(
        notes: notes,
      );
      notifyListeners();
    }
  }

  // Recurring days (for monthly booking - shared across children)
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

  // Validation
  bool get canSubmit {
    if (_selectedChildrenIds.isEmpty) return false;
    
    // Check each child has complete booking details
    for (var childId in _selectedChildrenIds) {
      final details = _childBookingDetails[childId];
      if (details == null) return false;
      if (details.selectedSubjects.isEmpty) return false; // Each child must have at least one subject
      if (details.bookingDate == null) return false;
      if (details.timeSlot == null) return false;
      
      // For monthly bookings, check recurring days
      if (_bookingType == BookingType.monthlyBooking && _recurringDays.isEmpty) {
        return false;
      }
    }
    
    return true;
  }

  // Calculate sessions per month (for monthly booking)
  int get sessionsPerMonth {
    return _recurringDays.length * 4; // Approximate 4 weeks per month
  }

  // Calculate price per session for a child
  double getChildPricePerSession(String childId) {
    if (sessionsPerMonth == 0) return 0;
    final details = _childBookingDetails[childId];
    if (details == null) return 0;
    return details.budget / sessionsPerMonth;
  }

  // Calculate total estimated cost
  double get totalEstimatedCost {
    double total = 0;
    for (var childId in _selectedChildrenIds) {
      final details = _childBookingDetails[childId];
      if (details != null) {
        total += details.budget;
      }
    }
    return total;
  }

  // Submit bookings (one for each child)
  Future<bool> submitBooking() async {
    if (!canSubmit) {
      _errorMessage = 'Please complete booking details for all children';
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

      final notificationService = NotificationService();
      final tutorService = TutorService();
      final parent = await _userService.getUserById(currentUser.uid);

      // Store first booking ID for payment redirect
      String? firstBookingId;
      final totalAmount = totalEstimatedCost;

      // Create separate booking for each child
      for (var childId in _selectedChildrenIds) {
        final details = _childBookingDetails[childId];
        if (details == null || 
            details.selectedSubjects.isEmpty ||
            details.bookingDate == null || 
            details.timeSlot == null) {
          continue; // Skip if incomplete
        }

        final bookingId = '${DateTime.now().millisecondsSinceEpoch}_$childId';
        if (firstBookingId == null) {
          firstBookingId = bookingId; // Store first booking ID for payment
        }
        
        final booking = BookingModel(
          bookingId: bookingId,
          parentId: currentUser.uid,
          tutorId: tutorId,
          subject: details.selectedSubjects.first, // For backward compatibility
          subjects: details.selectedSubjects,
          bookingDate: details.bookingDate!,
          bookingTime: details.timeSlot!,
          status: BookingStatus.pending,
          notes: details.notes.isNotEmpty ? details.notes : null,
          createdAt: DateTime.now(),
          bookingType: _bookingType,
          startDate: details.bookingDate,
          recurringDays: _bookingType == BookingType.monthlyBooking ? _recurringDays : null,
          monthlyBudget: details.budget,
          childrenIds: [childId], // Single child per booking
        );

        await _bookingService.createBooking(booking);

        // Send notification to tutor for each booking
        try {
          if (parent != null) {
            final child = _children.firstWhere((c) => c.studentId == childId);
            final childUser = await _userService.getUserById(childId);
            final childName = childUser?.name ?? 'Student';
            
            final subjectsText = details.selectedSubjects.join(', ');
            await notificationService.sendBookingNotificationToTutor(
              tutorId: tutorId,
              parentName: '${parent.name} (for $childName)',
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
      }

      // Payment redirect removed - parent will pay after booking is approved
      // Payment will be handled in BookingViewDetailScreen when status is approved

      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to submit bookings: ${e.toString()}';
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Format budget in rupees
  String formatBudget(double amount) {
    return '₹${amount.toStringAsFixed(0)}${_bookingType == BookingType.monthlyBooking ? '/mo' : '/hr'}';
  }

  // Format price per session
  String formatPricePerSession(double pricePerSession) {
    return '₹${pricePerSession.toStringAsFixed(0)}/session';
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
