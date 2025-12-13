import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/models/booking_model.dart';
import '../data/models/user_model.dart';
import '../data/services/booking_services.dart';
import '../data/services/user_services.dart';
import '../core/utils/debug_logger.dart';

/// Model for displaying booking with tutor info
class BookingDisplayModel {
  final BookingModel booking;
  final UserModel tutor;
  final String tutorImageUrl;

  BookingDisplayModel({
    required this.booking,
    required this.tutor,
    this.tutorImageUrl = '',
  });
}

class BookingsNavbarViewModel extends ChangeNotifier {
  final BookingService _bookingService;
  final UserService _userService;
  final FirebaseAuth _auth;

  BookingsNavbarViewModel({
    BookingService? bookingService,
    UserService? userService,
    FirebaseAuth? auth,
  })  : _bookingService = bookingService ?? BookingService(),
        _userService = userService ?? UserService(),
        _auth = auth ?? FirebaseAuth.instance;

  // ---------- State ----------
  bool _isLoading = false;
  String? _errorMessage;
  BookingStatus _selectedTab = BookingStatus.pending; // Default to All (we'll handle All separately)
  bool _showAll = true; // Show all bookings by default

  List<BookingDisplayModel> _allBookings = [];
  List<BookingDisplayModel> _pendingBookings = [];
  List<BookingDisplayModel> _approvedBookings = [];
  List<BookingDisplayModel> _rejectedBookings = [];

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  BookingStatus get selectedTab => _selectedTab;
  bool get showAll => _showAll;

  List<BookingDisplayModel> get displayedBookings {
    if (_showAll) return _allBookings;
    switch (_selectedTab) {
      case BookingStatus.pending:
        return _pendingBookings;
      case BookingStatus.approved:
        return _approvedBookings;
      case BookingStatus.rejected:
        return _rejectedBookings;
      default:
        return _allBookings;
    }
  }

  // ---------- Initialize ----------
  Future<void> initialize() async {
    _setLoading(true);
    try {
      await loadBookings();
    } catch (e) {
      _errorMessage = 'Failed to load bookings: ${e.toString()}';
    } finally {
      _setLoading(false);
    }
  }

  // ---------- Load Bookings ----------
  Future<void> loadBookings() async {
    // #region agent log
    await DebugLogger.log(location: 'bookings_navbar_vm.dart:78', message: 'Loading bookings for parent', data: {'parentId': _auth.currentUser?.uid}, hypothesisId: 'BOOKING-1');
    // #endregion
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Get all bookings for current parent
      final bookings = await _bookingService.getBookingsByParentId(user.uid);
      // #region agent log
      await DebugLogger.log(location: 'bookings_navbar_vm.dart:84', message: 'Bookings loaded from Firestore', data: {'bookingCount': bookings.length, 'statuses': bookings.map((b) => b.status.toString()).toList()}, hypothesisId: 'BOOKING-1');
      // #endregion

      // Get tutor info for each booking
      final allBookingsList = <BookingDisplayModel>[];
      final pendingList = <BookingDisplayModel>[];
      final approvedList = <BookingDisplayModel>[];
      final rejectedList = <BookingDisplayModel>[];

      for (final booking in bookings) {
        final tutor = await _userService.getUserById(booking.tutorId);
        if (tutor != null) {
          final displayModel = BookingDisplayModel(
            booking: booking,
            tutor: tutor,
            tutorImageUrl: tutor.imageUrl ?? '',
          );

          allBookingsList.add(displayModel);

          // Categorize by status
          switch (booking.status) {
            case BookingStatus.pending:
              pendingList.add(displayModel);
              break;
            case BookingStatus.approved:
              approvedList.add(displayModel);
              break;
            case BookingStatus.rejected:
              rejectedList.add(displayModel);
              break;
            default:
              break;
          }
        }
      }

      _allBookings = allBookingsList;
      _pendingBookings = pendingList;
      _approvedBookings = approvedList;
      _rejectedBookings = rejectedList;
      // #region agent log
      await DebugLogger.log(location: 'bookings_navbar_vm.dart:123', message: 'Bookings categorized by status', data: {'all': _allBookings.length, 'pending': _pendingBookings.length, 'approved': _approvedBookings.length, 'rejected': _rejectedBookings.length}, hypothesisId: 'BOOKING-1');
      // #endregion

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading bookings: $e');
      }
      _errorMessage = 'Failed to load bookings: ${e.toString()}';
      notifyListeners();
    }
  }

  // ---------- Tab Selection ----------
  void selectTab(BookingStatus? status) {
    if (status == null) {
      _showAll = true;
      _selectedTab = BookingStatus.pending; // Dummy value
    } else {
      _showAll = false;
      _selectedTab = status;
    }
    notifyListeners();
  }

  // ---------- Cancel Booking ----------
  Future<bool> cancelBooking(String bookingId) async {
    // #region agent log
    await DebugLogger.log(location: 'bookings_navbar_vm.dart:148', message: 'Cancelling booking', data: {'bookingId': bookingId}, hypothesisId: 'BOOKING-2');
    // #endregion
    try {
      _setLoading(true);
      await _bookingService.cancelBooking(bookingId);
      // #region agent log
      await DebugLogger.log(location: 'bookings_navbar_vm.dart:151', message: 'Booking cancelled successfully', data: {'bookingId': bookingId}, hypothesisId: 'BOOKING-2');
      // #endregion
      await loadBookings(); // Reload bookings
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _errorMessage = 'Failed to cancel booking: ${e.toString()}';
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
}

