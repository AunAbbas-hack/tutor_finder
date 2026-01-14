import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
import '../data/services/directions_service.dart';
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
  GoogleMapController? _mapController;
  bool _isMapReady = false;
  
  // Route/Polyline state
  Set<Polyline> _polylines = {};
  bool _isLoadingRoute = false;
  String? _routeDistance;
  String? _routeDuration;
  final DirectionsService _directionsService = DirectionsService();

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
  GoogleMapController? get mapController => _mapController;
  bool get isMapReady => _isMapReady;
  Set<Polyline> get polylines => _polylines;
  bool get isLoadingRoute => _isLoadingRoute;
  String? get routeDistance => _routeDistance;
  String? get routeDuration => _routeDuration;

  // Convenience getters
  bool get hasTutorLocation => _tutor?.latitude != null && _tutor?.longitude != null;
  double? get tutorLatitude => _tutor?.latitude;
  double? get tutorLongitude => _tutor?.longitude;
  bool get hasParentLocation => _parent?.latitude != null && _parent?.longitude != null;
  double? get parentLatitude => _parent?.latitude;
  double? get parentLongitude => _parent?.longitude;
  
  // Check if booking can be cancelled (only approved bookings can be cancelled by parent)
  bool get canCancelBooking => _booking?.status == BookingStatus.approved;

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

      // Load route if both locations are available
      if (_parent?.latitude != null && 
          _parent?.longitude != null &&
          _tutor?.latitude != null && 
          _tutor?.longitude != null) {
        await _loadRoute();
      }

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
      notifyListeners();
      return paymentSuccess;
    } catch (e) {
      String errorMsg = e.toString();
      // Remove "Exception: " prefix if present
      if (errorMsg.startsWith('Exception: ')) {
        errorMsg = errorMsg.substring(11);
      }
      _errorMessage = errorMsg;
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

  /// Check if booking can be marked as completed
  bool get canCompleteBooking {
    if (_booking == null) return false;
    
    // Can complete if:
    // 1. Booking is approved
    // 2. Payment status is 'paid' or 'completed'
    // 3. Booking status is not already completed
    final isApproved = _booking!.status == BookingStatus.approved;
    final paymentStatus = _booking!.paymentStatus;
    final isPaid = paymentStatus == 'paid' || paymentStatus == 'completed';
    final isNotCompleted = _booking!.status != BookingStatus.completed;
    
    return isApproved && isPaid && isNotCompleted;
  }

  /// Mark booking as completed
  Future<bool> completeBooking() async {
    if (_booking == null) {
      _errorMessage = 'Booking not found';
      notifyListeners();
      return false;
    }

    if (!canCompleteBooking) {
      if (_booking!.paymentStatus != 'paid' && _booking!.paymentStatus != 'completed') {
        _errorMessage = 'Payment must be completed before marking booking as complete';
      } else if (_booking!.status == BookingStatus.completed) {
        _errorMessage = 'Booking is already completed';
      } else {
        _errorMessage = 'Cannot complete this booking';
      }
      notifyListeners();
      return false;
    }

    _setLoading(true);
    _errorMessage = null;
    notifyListeners();

    try {
      await _bookingService.completeSession(_booking!.bookingId);
      
      // Reload booking to get updated status
      _booking = await _bookingService.getBookingById(_booking!.bookingId);
      
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to complete booking: ${e.toString()}';
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // ---------- Route/Polyline ----------
  
  /// Load route between parent and tutor locations
  Future<void> _loadRoute() async {
    if (_parent?.latitude == null || 
        _parent?.longitude == null ||
        _tutor?.latitude == null || 
        _tutor?.longitude == null) {
      return;
    }

    _isLoadingRoute = true;
    notifyListeners();

    try {
      final origin = LatLng(_parent!.latitude!, _parent!.longitude!);
      final destination = LatLng(_tutor!.latitude!, _tutor!.longitude!);
      
      final directions = await _directionsService.getDirections(
        origin: origin,
        destination: destination,
      );

      if (directions != null && directions.polylinePoints.isNotEmpty) {
        _polylines = {
          Polyline(
            polylineId: const PolylineId('route'),
            points: directions.polylinePoints,
            color: const Color(0xFF2196F3), // Blue color
            width: 5,
            patterns: [],
          ),
        };
        _routeDistance = directions.distance;
        _routeDuration = directions.duration;
      } else {
        // Clear polylines if route not found
        _polylines = {};
        _routeDistance = null;
        _routeDuration = null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading route: $e');
      }
      _polylines = {};
      _routeDistance = null;
      _routeDuration = null;
    } finally {
      _isLoadingRoute = false;
      notifyListeners();
    }
  }

  // ---------- Map Controller ----------
  void setMapController(GoogleMapController controller) async {
    _mapController = controller;
    _isMapReady = false;
    
    // Wait for map to fully initialize before positioning
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Ensure map is properly positioned after creation
    if (_tutor?.latitude != null && _tutor?.longitude != null) {
      try {
        await _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(_tutor!.latitude!, _tutor!.longitude!),
              zoom: 14.0,
            ),
          ),
        );
        // Wait a bit more for map tiles to load
        await Future.delayed(const Duration(milliseconds: 300));
        _isMapReady = true;
        notifyListeners();
      } catch (e) {
        if (kDebugMode) {
          print('Error animating camera: $e');
        }
        // Still mark as ready even if animation fails
        _isMapReady = true;
        notifyListeners();
      }
    } else {
      _isMapReady = true;
      notifyListeners();
    }
  }

  // ---------- Refresh ----------
  /// Refresh booking details (reload from Firestore)
  Future<void> refresh() async {
    if (_booking == null) return;
    await initialize(_booking!.bookingId);
  }

  // ---------- Cancel Booking ----------
  Future<bool> cancelBooking() async {
    if (_booking == null || _booking!.status != BookingStatus.approved) {
      _errorMessage = 'Only approved bookings can be cancelled';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    _errorMessage = null;

    try {
      // Cancel booking
      await _bookingService.cancelBooking(_booking!.bookingId);

      // Send notification to tutor
      if (_tutor != null && _parent != null) {
        try {
          final notificationService = NotificationService();
          await notificationService.sendBookingCancellationToTutor(
            tutorId: _tutor!.userId,
            parentName: _parent!.name,
          );
        } catch (e) {
          // Don't fail cancellation if notification fails
          if (kDebugMode) {
            print('⚠️ Failed to send cancellation notification: $e');
          }
        }
      }

      // Reload booking to reflect cancelled status
      await initialize(_booking!.bookingId);

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to cancel booking: ${e.toString()}';
      _setLoading(false);
      notifyListeners();
      return false;
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

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
