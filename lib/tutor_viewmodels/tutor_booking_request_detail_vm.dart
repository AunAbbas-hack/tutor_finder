// lib/tutor_viewmodels/tutor_booking_request_detail_vm.dart
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geocoding/geocoding.dart';
import '../data/models/booking_model.dart';
import '../data/models/user_model.dart';
import '../data/models/student_model.dart';
import '../data/services/booking_services.dart';
import '../data/services/user_services.dart';
import '../data/services/student_services.dart';
import '../data/services/notification_service.dart';
import '../core/utils/distance_calculator.dart';

class TutorBookingRequestDetailViewModel extends ChangeNotifier {
  final BookingService _bookingService;
  final UserService _userService;
  final StudentService _studentService;
  final FirebaseAuth _auth;

  TutorBookingRequestDetailViewModel({
    BookingService? bookingService,
    UserService? userService,
    StudentService? studentService,
    FirebaseAuth? auth,
  })  : _bookingService = bookingService ?? BookingService(),
        _userService = userService ?? UserService(),
        _studentService = studentService ?? StudentService(),
        _auth = auth ?? FirebaseAuth.instance;

  // ---------- State ----------
  bool _isDisposed = false;
  bool _isLoading = false;
  String? _errorMessage;

  BookingModel? _booking;
  UserModel? _parent;
  UserModel? _tutor;
  String _parentImageUrl = '';
  String? _parentLocationAddress;
  double? _distanceInKm;
  List<StudentModel> _students = [];
  Map<String, UserModel> _studentUsers = {};

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  BookingModel? get booking => _booking;
  UserModel? get parent => _parent;
  UserModel? get tutor => _tutor;
  String get parentImageUrl => _parentImageUrl;
  String? get parentLocationAddress => _parentLocationAddress;
  double? get distanceInKm => _distanceInKm;
  String? get distanceText {
    if (_distanceInKm == null) return null;
    return DistanceCalculator.formatDistanceInKm(_distanceInKm!);
  }
  List<StudentModel> get students => _students;
  Map<String, UserModel> get studentUsers => _studentUsers;

  bool get hasParentLocation => _parent?.latitude != null && _parent?.longitude != null;
  bool get hasTutorLocation => _tutor?.latitude != null && _tutor?.longitude != null;
  double? get parentLatitude => _parent?.latitude;
  double? get parentLongitude => _parent?.longitude;

  // ---------- Initialize ----------
  Future<void> initialize(String bookingId) async {
    if (_isDisposed) return;

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

      // Load parent info
      _parent = await _userService.getUserById(_booking!.parentId);
      if (_parent != null) {
        _parentImageUrl = _parent!.imageUrl ?? '';
        
        // Fetch address from coordinates if location is available
        if (_parent!.latitude != null && _parent!.longitude != null) {
          await _fetchAddressFromCoordinates(
            _parent!.latitude!,
            _parent!.longitude!,
          );
        }
      }

      // Load tutor info (current user)
      final tutorId = _auth.currentUser?.uid;
      if (tutorId != null) {
        _tutor = await _userService.getUserById(tutorId);
      }

      // Calculate distance if both locations are available
      if (hasParentLocation && hasTutorLocation) {
        _distanceInKm = DistanceCalculator.calculateDistanceInKm(
          _parent!.latitude!,
          _parent!.longitude!,
          _tutor!.latitude!,
          _tutor!.longitude!,
        );
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
        print('Error loading booking request details: $e');
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
        _parentLocationAddress = _formatAddress(place);
        notifyListeners();
      }
    } catch (e) {
      // Silently fail - address is optional
      if (kDebugMode) {
        print('Error fetching address: $e');
      }
      _parentLocationAddress = null;
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

  // ---------- Accept Booking ----------
  Future<bool> acceptBooking() async {
    if (_isDisposed || _booking == null) return false;

    _setLoading(true);
    _errorMessage = null;

    try {
      await _bookingService.updateBookingStatus(
        _booking!.bookingId,
        BookingStatus.approved,
      );

      // Send notification to parent
      try {
        final notificationService = NotificationService();
        if (_tutor != null && _parent != null) {
          // Send approval notification to parent
          await notificationService.sendBookingApprovalToParent(
            parentId: _booking!.parentId,
            tutorName: _tutor!.name,
            bookingId: _booking!.bookingId,
          );
          
          // Send self-confirmation notification to tutor
          await notificationService.sendBookingAcceptedConfirmationToTutor(
            tutorId: _auth.currentUser!.uid,
            parentName: _parent!.name,
          );
        }
      } catch (e) {
        // Don't fail booking if notification fails
        if (kDebugMode) {
          print('⚠️ Failed to send approval notification: $e');
        }
      }

      if (!_isDisposed) {
        _setLoading(false);
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error accepting booking: $e');
      }
      if (!_isDisposed) {
        _errorMessage = 'Failed to accept booking: ${e.toString()}';
        _setLoading(false);
        notifyListeners();
      }
      return false;
    }
  }

  // ---------- Reject Booking ----------
  Future<bool> rejectBooking() async {
    if (_isDisposed || _booking == null) return false;

    _setLoading(true);
    _errorMessage = null;

    try {
      await _bookingService.updateBookingStatus(
        _booking!.bookingId,
        BookingStatus.rejected,
      );

      // Send notification to parent
      try {
        final notificationService = NotificationService();
        if (_tutor != null) {
          await notificationService.sendBookingRejectionToParent(
            parentId: _booking!.parentId,
            tutorName: _tutor!.name,
            bookingId: _booking!.bookingId,
          );
        }
      } catch (e) {
        // Don't fail booking if notification fails
        if (kDebugMode) {
          print('⚠️ Failed to send rejection notification: $e');
        }
      }

      if (!_isDisposed) {
        _setLoading(false);
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error rejecting booking: $e');
      }
      if (!_isDisposed) {
        _errorMessage = 'Failed to reject booking: ${e.toString()}';
        _setLoading(false);
        notifyListeners();
      }
      return false;
    }
  }

  // ---------- Helpers ----------
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
