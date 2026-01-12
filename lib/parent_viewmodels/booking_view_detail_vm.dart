import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import '../data/models/booking_model.dart';
import '../data/models/user_model.dart';
import '../data/models/parent_model.dart';
import '../data/models/student_model.dart';
import '../data/services/booking_services.dart';
import '../data/services/user_services.dart';
import '../data/services/parent_services.dart';
import '../data/services/student_services.dart';
import '../data/services/payment_service.dart';
import '../data/services/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookingViewDetailViewModel extends ChangeNotifier {
  final BookingService _bookingService;
  final UserService _userService;
  final ParentService _parentService;
  final StudentService _studentService;
  final PaymentService _paymentService;
  final FirebaseAuth _auth;

  BookingViewDetailViewModel({
    BookingService? bookingService,
    UserService? userService,
    ParentService? parentService,
    StudentService? studentService,
    PaymentService? paymentService,
    FirebaseAuth? auth,
  })  : _bookingService = bookingService ?? BookingService(),
        _userService = userService ?? UserService(),
        _parentService = parentService ?? ParentService(),
        _studentService = studentService ?? StudentService(),
        _paymentService = paymentService ?? PaymentService(),
        _auth = auth ?? FirebaseAuth.instance;

  // ---------- State ----------
  bool _isLoading = false;
  String? _errorMessage;
  BookingModel? _booking;
  UserModel? _tutor;
  UserModel? _parent;
  List<StudentModel> _students = [];
  Map<String, UserModel> _studentUsers = {}; // studentId -> UserModel
  String? _tutorLocationAddress;
  String? _tutorImageUrl;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  BookingModel? get booking => _booking;
  UserModel? get tutor => _tutor;
  UserModel? get parent => _parent;
  List<StudentModel> get students => _students;
  Map<String, UserModel> get studentUsers => _studentUsers;
  String? get tutorLocationAddress => _tutorLocationAddress;
  String? get tutorImageUrl => _tutorImageUrl;

  // Convenience getters
  bool get hasTutorLocation => _tutor?.latitude != null && _tutor?.longitude != null;
  double? get tutorLatitude => _tutor?.latitude;
  double? get tutorLongitude => _tutor?.longitude;

  // ---------- Initialize ----------
  Future<void> initialize(String bookingId) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      // Load booking
      _booking = await _bookingService.getBookingById(bookingId);
      if (_booking == null) {
        _errorMessage = 'Booking not found';
        _setLoading(false);
        return;
      }

      // Load tutor info
      _tutor = await _userService.getUserById(_booking!.tutorId);
      if (_tutor != null) {
        _tutorImageUrl = _tutor!.imageUrl ?? '';
        
        // Fetch address from coordinates if location is available
        if (_tutor!.latitude != null && _tutor!.longitude != null) {
          await _fetchAddressFromCoordinates(
            _tutor!.latitude!,
            _tutor!.longitude!,
          );
        }
      }

      // Load parent info
      _parent = await _userService.getUserById(_booking!.parentId);

      // Load students if childrenIds exist
      if (_booking!.childrenIds != null && _booking!.childrenIds!.isNotEmpty) {
        final studentsList = <StudentModel>[];
        final studentUsersMap = <String, UserModel>{};
        
        for (final studentId in _booking!.childrenIds!) {
          final student = await _studentService.getStudentById(studentId);
          if (student != null) {
            studentsList.add(student);
            
            // Also fetch user info for student name
            final studentUser = await _userService.getUserById(studentId);
            if (studentUser != null) {
              studentUsersMap[studentId] = studentUser;
            }
          }
        }
        _students = studentsList;
        _studentUsers = studentUsersMap;
      }
    } catch (e) {
      _errorMessage = 'Failed to load booking details: ${e.toString()}';
      if (kDebugMode) {
        print('Error loading booking details: $e');
      }
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Fetch address from coordinates using geocoding
  Future<void> _fetchAddressFromCoordinates(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        _tutorLocationAddress = _formatAddress(place);
        notifyListeners();
      }
    } catch (e) {
      // Silently fail - address is optional
      if (kDebugMode) {
        print('Error fetching address: $e');
      }
      _tutorLocationAddress = null;
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
    if (place.administrativeArea != null &&
        place.administrativeArea!.isNotEmpty) {
      parts.add(place.administrativeArea!);
    }
    if (place.country != null && place.country!.isNotEmpty) {
      parts.add(place.country!);
    }

    return parts.isNotEmpty ? parts.join(', ') : 'Unknown location';
  }

  // ---------- Payment ----------
  
  /// Get booking amount for payment
  double getBookingAmount() {
    if (_booking == null) return 0.0;
    
    // For monthly booking, use monthlyBudget
    if (_booking!.bookingType == BookingType.monthlyBooking && _booking!.monthlyBudget != null) {
      return _booking!.monthlyBudget!;
    }
    
    // For single session, use monthlyBudget if available, otherwise default
    // Note: Single session bookings should store amount in monthlyBudget field
    if (_booking!.monthlyBudget != null) {
      return _booking!.monthlyBudget!;
    }
    
    // Default amount if not set
    return 500.0;
  }

  /// Check if payment is needed (approved booking without payment)
  bool get needsPayment {
    if (_booking == null) return false;
    
    // Payment needed if:
    // 1. Booking is approved
    // 2. Payment status is null, 'pending', or 'failed' (not 'paid')
    final isApproved = _booking!.status == BookingStatus.approved;
    final paymentStatus = _booking!.paymentStatus;
    final isNotPaid = paymentStatus == null || 
                      paymentStatus == 'pending' || 
                      paymentStatus == 'failed';
    
    return isApproved && isNotPaid;
  }

  /// Process payment for this booking
  Future<bool> processPayment() async {
    if (_booking == null) {
      _errorMessage = 'Booking not found';
      notifyListeners();
      return false;
    }

    // Validation: Check if payment is needed
    if (!needsPayment) {
      if (_booking!.paymentStatus == 'paid') {
        _errorMessage = 'Payment already completed for this booking';
      } else if (_booking!.status != BookingStatus.approved) {
        _errorMessage = 'Booking must be approved before payment';
      } else {
        _errorMessage = 'Payment not required for this booking';
      }
      notifyListeners();
      return false;
    }

    // Validation: Check amount
    final amount = getBookingAmount();
    if (amount <= 0) {
      _errorMessage = 'Invalid payment amount';
      notifyListeners();
      return false;
    }

    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      _errorMessage = 'User not authenticated';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    _errorMessage = null;
    notifyListeners();

    try {
      final paymentSuccess = await _paymentService.createCheckoutAndRedirect(
        amount: amount,
        bookingId: _booking!.bookingId,
        tutorId: _booking!.tutorId,
        parentId: currentUser.uid,
        currency: 'inr', // INR for Indian Rupees
      );

      // Payment redirect successful - notification will be sent after payment completes
      // (via webhook or payment success callback)
      // Note: Actual payment completion will be handled by Stripe webhook
      
      _setLoading(false);
      return paymentSuccess;
    } catch (e) {
      _errorMessage = 'Failed to process payment: ${e.toString()}';
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  /// Send payment notification to tutor (called after payment is confirmed)
  Future<void> sendPaymentNotificationToTutor() async {
    if (_booking == null || _parent == null) return;

    try {
      final notificationService = NotificationService();
      await notificationService.sendPaymentNotificationToTutor(
        tutorId: _booking!.tutorId,
        parentName: _parent!.name,
        bookingDate: _booking!.bookingDate,
        bookingTime: _booking!.bookingTime,
        bookingId: _booking!.bookingId,
      );
    } catch (e) {
      // Don't fail payment if notification fails
      if (kDebugMode) {
        print('⚠️ Failed to send payment notification: $e');
      }
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
