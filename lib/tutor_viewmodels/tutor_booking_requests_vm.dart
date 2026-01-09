import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/models/booking_model.dart';
import '../data/models/user_model.dart';
import '../data/services/booking_services.dart';
import '../data/services/user_services.dart';
import '../data/services/notification_service.dart';

/// Model for displaying booking request with parent info
class BookingRequestDisplay {
  final BookingModel booking;
  final UserModel parent;
  final String parentImageUrl;

  BookingRequestDisplay({
    required this.booking,
    required this.parent,
    this.parentImageUrl = '',
  });
}

class TutorBookingRequestsViewModel extends ChangeNotifier {
  final BookingService _bookingService;
  final UserService _userService;
  final FirebaseAuth _auth;

  TutorBookingRequestsViewModel({
    BookingService? bookingService,
    UserService? userService,
    FirebaseAuth? auth,
  })  : _bookingService = bookingService ?? BookingService(),
        _userService = userService ?? UserService(),
        _auth = auth ?? FirebaseAuth.instance;

  // ---------- State ----------
  bool _isDisposed = false;
  bool _isLoading = false;
  String? _errorMessage;
  List<BookingRequestDisplay> _pendingBookings = [];

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<BookingRequestDisplay> get pendingBookings => _pendingBookings;

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
        return;
      }

      await loadPendingBookings();
    } catch (e) {
      if (!_isDisposed) {
        _errorMessage = 'Failed to load booking requests: ${e.toString()}';
        if (kDebugMode) {
          print('Error loading tutor booking requests: $e');
        }
      }
    } finally {
      if (!_isDisposed) {
        _setLoading(false);
      }
    }
  }

  // ---------- Load Pending Bookings ----------
  Future<void> loadPendingBookings() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Get pending bookings
      final pendingBookings = await _bookingService.getBookingsByTutorAndStatus(
        user.uid,
        BookingStatus.pending,
      );

      // Load parent info for each booking
      final List<BookingRequestDisplay> bookingDisplays = [];
      for (final booking in pendingBookings) {
        try {
          final parent = await _userService.getUserById(booking.parentId);
          if (parent != null) {
            bookingDisplays.add(
              BookingRequestDisplay(
                booking: booking,
                parent: parent,
                parentImageUrl: parent.imageUrl ?? '',
              ),
            );
          } else {
            if (kDebugMode) {
              print('Parent not found for booking ${booking.bookingId}, parentId: ${booking.parentId}');
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error loading parent for booking ${booking.bookingId}: $e');
          }
          // Continue with other bookings even if one fails
        }
      }

      if (!_isDisposed) {
        _pendingBookings = bookingDisplays;
        _safeNotifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading pending bookings: $e');
      }
      if (!_isDisposed) {
        _errorMessage = 'Failed to load bookings: ${e.toString()}';
        _safeNotifyListeners();
      }
    }
  }

  // ---------- Accept Booking ----------
  Future<bool> acceptBooking(String bookingId) async {
    if (_isDisposed) return false;

    _setLoading(true);
    _errorMessage = null;

    try {
      await _bookingService.updateBookingStatus(
        bookingId,
        BookingStatus.approved,
      );

      // Send notification to parent
      try {
        final booking = await _bookingService.getBookingById(bookingId);
        if (booking != null) {
          final notificationService = NotificationService();
          final tutor = await _userService.getUserById(_auth.currentUser?.uid ?? '');
          final parent = await _userService.getUserById(booking.parentId);
          
          if (tutor != null) {
            // Send approval notification to parent
            await notificationService.sendBookingApprovalToParent(
              parentId: booking.parentId,
              tutorName: tutor.name,
              bookingId: bookingId,
            );
            
            // Send self-confirmation notification to tutor
            if (parent != null) {
              await notificationService.sendBookingAcceptedConfirmationToTutor(
                tutorId: _auth.currentUser!.uid,
                parentName: parent.name,
              );
            }
          }
        }
      } catch (e) {
        // Don't fail booking if notification fails
        if (kDebugMode) {
          print('⚠️ Failed to send approval notification: $e');
        }
      }

      // Reload pending bookings
      await loadPendingBookings();

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
        _safeNotifyListeners();
      }
      return false;
    }
  }

  // ---------- Reject Booking ----------
  Future<bool> rejectBooking(String bookingId) async {
    if (_isDisposed) return false;

    _setLoading(true);
    _errorMessage = null;

    try {
      await _bookingService.updateBookingStatus(
        bookingId,
        BookingStatus.rejected,
      );

      // Send notification to parent
      try {
        final booking = await _bookingService.getBookingById(bookingId);
        if (booking != null) {
          final notificationService = NotificationService();
          final tutor = await _userService.getUserById(_auth.currentUser?.uid ?? '');
          final parent = await _userService.getUserById(booking.parentId);
          
          if (tutor != null) {
            // Send rejection notification to parent
            await notificationService.sendBookingRejectionToParent(
              parentId: booking.parentId,
              tutorName: tutor.name,
              bookingId: bookingId,
            );
            
            // Send self-confirmation notification to tutor
            if (parent != null) {
              await notificationService.sendBookingRejectedConfirmationToTutor(
                tutorId: _auth.currentUser!.uid,
                parentName: parent.name,
              );
            }
          }
        }
      } catch (e) {
        // Don't fail booking if notification fails
        if (kDebugMode) {
          print('⚠️ Failed to send rejection notification: $e');
        }
      }

      // Reload pending bookings
      await loadPendingBookings();

      if (!_isDisposed) {
        _setLoading(false);
        _safeNotifyListeners();
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
        _safeNotifyListeners();
      }
      return false;
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

