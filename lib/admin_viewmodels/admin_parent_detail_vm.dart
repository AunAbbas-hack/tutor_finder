// lib/admin_viewmodels/admin_parent_detail_vm.dart
import 'package:flutter/foundation.dart';
import '../data/models/user_model.dart';
import '../data/models/parent_model.dart';
import '../data/models/student_model.dart';
import '../data/models/booking_model.dart';
import '../data/services/user_services.dart';
import '../data/services/parent_services.dart';
import '../data/services/student_services.dart';
import '../data/services/booking_services.dart';
import '../data/services/notification_service.dart';

class AdminParentDetailViewModel extends ChangeNotifier {
  final UserService _userService;
  final ParentService _parentService;
  final StudentService _studentService;
  final BookingService _bookingService;
  final NotificationService _notificationService;

  AdminParentDetailViewModel({
    UserService? userService,
    ParentService? parentService,
    StudentService? studentService,
    BookingService? bookingService,
    NotificationService? notificationService,
  })  : _userService = userService ?? UserService(),
        _parentService = parentService ?? ParentService(),
        _studentService = studentService ?? StudentService(),
        _bookingService = bookingService ?? BookingService(),
        _notificationService = notificationService ?? NotificationService();

  // ---------- State ----------
  bool _isDisposed = false;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? _user;
  ParentModel? _parent;
  List<StudentModel> _children = [];
  List<BookingModel> _bookings = [];
  Map<String, UserModel> _tutorUsers = {}; // tutorId -> UserModel

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  UserModel? get user => _user;
  ParentModel? get parent => _parent;
  List<StudentModel> get children => _children;
  List<BookingModel> get bookings => _bookings;

  // Stats
  int get bookingsCount => _bookings.length;
  int get childrenCount => _children.length;
  
  // Calculate total spent (from completed bookings with paid status)
  double get totalSpent {
    return _bookings
        .where((b) => 
            b.status == BookingStatus.completed && 
            b.paymentStatus == 'paid')
        .fold<double>(0.0, (sum, booking) {
      // For monthly bookings, use monthlyBudget
      if (booking.bookingType == BookingType.monthlyBooking && 
          booking.monthlyBudget != null) {
        return sum + booking.monthlyBudget!;
      }
      // For single session, we don't have amount in booking model
      // So we'll return count for now (can be enhanced later)
      return sum;
    });
  }

  // Get recent bookings (last 3)
  List<BookingModel> get recentBookings {
    return _bookings.take(3).toList();
  }

  // Get tutor name by tutorId
  String getTutorName(String tutorId) {
    return _tutorUsers[tutorId]?.name ?? 'Unknown Tutor';
  }

  // ---------- Initialize ----------
  Future<void> loadParentData(String parentId) async {
    if (_isDisposed) return;

    _setLoading(true);
    _errorMessage = null;

    try {
      // Load user data
      _user = await _userService.getUserById(parentId);
      if (_user == null) {
        _errorMessage = 'Parent data not found';
        _setLoading(false);
        return;
      }

      // Load parent data
      _parent = await _parentService.getParentById(parentId);

      // Load children
      _children = await _studentService.getStudentsByParentId(parentId);

      // Load bookings
      _bookings = await _bookingService.getBookingsByParentId(parentId);

      // Load tutor users for booking display
      final tutorIds = _bookings.map((b) => b.tutorId).toSet();
      for (final tutorId in tutorIds) {
        final tutorUser = await _userService.getUserById(tutorId);
        if (tutorUser != null) {
          _tutorUsers[tutorId] = tutorUser;
        }
      }

      if (!_isDisposed) {
        _setLoading(false);
      }
    } catch (e) {
      if (!_isDisposed) {
        _errorMessage = 'Failed to load parent data: ${e.toString()}';
        if (kDebugMode) {
          print('Error loading parent data: $e');
        }
        _setLoading(false);
      }
    }
  }

  // ---------- Actions ----------
  Future<bool> suspendAccount() async {
    if (_isDisposed || _user == null) return false;

    _setLoading(true);
    _errorMessage = null;

    try {
      final updatedUser = _user!.copyWith(status: UserStatus.suspended);
      await _userService.updateUser(updatedUser);

      if (!_isDisposed) {
        _user = updatedUser;
        _setLoading(false);
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error suspending account: $e');
      }
      if (!_isDisposed) {
        _errorMessage = 'Failed to suspend account: ${e.toString()}';
        _setLoading(false);
        _safeNotifyListeners();
      }
      return false;
    }
  }

  Future<bool> sendNotification(String message) async {
    if (_isDisposed || _user == null) return false;

    try {
      await _notificationService.createNotification(
        userId: _user!.userId,
        message: message,
        type: 'admin_notification',
      );

      // Also send push notification
      await _notificationService.sendPushNotification(
        userId: _user!.userId,
        title: 'Admin Notification',
        message: message,
      );

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error sending notification: $e');
      }
      if (!_isDisposed) {
        _errorMessage = 'Failed to send notification: ${e.toString()}';
        _safeNotifyListeners();
      }
      return false;
    }
  }

  Future<void> refresh() async {
    if (_user != null) {
      await loadParentData(_user!.userId);
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
