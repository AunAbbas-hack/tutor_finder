// lib/student_viewmodels/student_dashboard_vm.dart
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/models/user_model.dart';
import '../data/models/student_model.dart';
import '../data/models/booking_model.dart';
import '../data/services/user_services.dart';
import '../data/services/student_services.dart';
import '../data/services/booking_services.dart';

class StudentDashboardViewModel extends ChangeNotifier {
  final UserService _userService;
  final StudentService _studentService;
  final BookingService _bookingService;
  final FirebaseAuth _auth;

  StudentDashboardViewModel({
    UserService? userService,
    StudentService? studentService,
    BookingService? bookingService,
    FirebaseAuth? auth,
  })  : _userService = userService ?? UserService(),
        _studentService = studentService ?? StudentService(),
        _bookingService = bookingService ?? BookingService(),
        _auth = auth ?? FirebaseAuth.instance;

  // ---------- State ----------
  bool _isDisposed = false;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? _studentUser;
  StudentModel? _student;
  UserModel? _parent;

  List<BookingModel> _allBookings = [];
  List<UserModel> _tutors = [];
  Map<String, UserModel> _tutorCache = {}; // tutorId -> UserModel

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  UserModel? get studentUser => _studentUser;
  StudentModel? get student => _student;
  UserModel? get parent => _parent;

  // Bookings
  List<BookingModel> get allBookings => _allBookings;
  List<BookingModel> get upcomingBookings => _allBookings
      .where((booking) =>
          booking.status == BookingStatus.approved &&
          booking.bookingDate.isAfter(DateTime.now()))
      .toList()
    ..sort((a, b) => a.bookingDate.compareTo(b.bookingDate));

  List<BookingModel> get completedBookings => _allBookings
      .where((booking) => booking.status == BookingStatus.completed)
      .toList()
    ..sort((a, b) => b.bookingDate.compareTo(a.bookingDate));

  List<BookingModel> get pendingBookings => _allBookings
      .where((booking) => booking.status == BookingStatus.pending)
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  // Tutors (unique tutors from bookings)
  List<UserModel> get tutors {
    final tutorIds = <String>{};
    final uniqueTutors = <UserModel>[];

    for (final booking in _allBookings) {
      if (!tutorIds.contains(booking.tutorId)) {
        tutorIds.add(booking.tutorId);
        final tutor = _tutorCache[booking.tutorId];
        if (tutor != null) {
          uniqueTutors.add(tutor);
        }
      }
    }

    return uniqueTutors;
  }

  // Statistics
  int get totalSessions => _allBookings.length;
  int get completedSessions => completedBookings.length;
  int get upcomingSessions => upcomingBookings.length;
  int get assignedTutorsCount => tutors.length;

  String get studentName => _studentUser?.name ?? 'Student';
  String get studentGrade => _student?.grade ?? 'N/A';
  String get parentName => _parent?.name ?? 'N/A';

  // ---------- Initialize ----------
  Future<void> initialize() async {
    if (_isDisposed) return;

    _setLoading(true);
    _errorMessage = null;

    try {
      final user = _auth.currentUser;
      if (user == null) {
        _errorMessage = 'User not authenticated';
        _setLoading(false);
        notifyListeners();
        return;
      }

      // Load student user data
      _studentUser = await _userService.getUserById(user.uid);
      if (_studentUser == null) {
        _errorMessage = 'Student data not found';
        _setLoading(false);
        notifyListeners();
        return;
      }

      // Load student model
      _student = await _studentService.getStudentById(user.uid);

      // Load parent data
      if (_student != null && _student!.parentId.isNotEmpty) {
        _parent = await _userService.getUserById(_student!.parentId);
      }

      // Load bookings where this student is included
      await _loadBookings(user.uid);

      // Load tutor data for all bookings
      await _loadTutors();

    } catch (e) {
      if (!_isDisposed) {
        _errorMessage = 'Failed to load dashboard: ${e.toString()}';
        if (kDebugMode) {
          print('Error loading student dashboard: $e');
        }
      }
    } finally {
      if (!_isDisposed) {
        _setLoading(false);
        notifyListeners();
      }
    }
  }

  // Load bookings where studentId is in childrenIds
  Future<void> _loadBookings(String studentId) async {
    try {
      // Get all bookings - we'll filter client-side
      // Note: This could be optimized with a Cloud Function or composite index
      final allBookings = await _bookingService.getBookingsByParentId(
        _student?.parentId ?? '',
      );

      // Filter bookings where this student is included
      _allBookings = allBookings
          .where((booking) =>
              booking.childrenIds != null &&
              booking.childrenIds!.contains(studentId))
          .toList();

      // Sort by date (newest first)
      _allBookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      if (kDebugMode) {
        print('Error loading bookings: $e');
      }
      _allBookings = [];
    }
  }

  // Load tutor information for all bookings
  Future<void> _loadTutors() async {
    try {
      final tutorIds = _allBookings
          .map((booking) => booking.tutorId)
          .toSet()
          .toList();

      for (final tutorId in tutorIds) {
        if (!_tutorCache.containsKey(tutorId)) {
          final tutor = await _userService.getUserById(tutorId);
          if (tutor != null) {
            _tutorCache[tutorId] = tutor;
          }
        }
      }

      _tutors = _tutorCache.values.toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading tutors: $e');
      }
    }
  }

  // Get tutor for a booking
  UserModel? getTutorForBooking(String tutorId) {
    return _tutorCache[tutorId];
  }

  // Refresh data
  Future<void> refresh() async {
    await initialize();
  }

  // ---------- Helper Methods ----------
  void _setLoading(bool value) {
    if (!_isDisposed) {
      _isLoading = value;
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
