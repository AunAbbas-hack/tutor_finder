import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/models/booking_model.dart';
import '../data/models/user_model.dart';
import '../data/services/booking_services.dart';
import '../data/services/user_services.dart';
import '../data/services/notification_service.dart';

/// Model for displaying session with parent/student info
class SessionDisplayModel {
  final BookingModel booking;
  final UserModel parent;
  final String parentImageUrl;
  final String location; // Session location
  final double duration; // Duration in hours

  SessionDisplayModel({
    required this.booking,
    required this.parent,
    this.parentImageUrl = '',
    this.location = 'Location TBD',
    this.duration = 1.0, // Default 1 hour
  });
}

/// Model for grouping sessions by date
class SessionsByDate {
  final String dateLabel; // "TODAY, OCT 24" or "TOMORROW, OCT 25"
  final DateTime date;
  final List<SessionDisplayModel> sessions;

  SessionsByDate({
    required this.dateLabel,
    required this.date,
    required this.sessions,
  });
}

class TutorSessionViewModel extends ChangeNotifier {
  final BookingService _bookingService;
  final UserService _userService;
  final FirebaseAuth _auth;

  TutorSessionViewModel({
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
  bool _showUpcoming = true; // true = Upcoming, false = Past
  String _userName = '';
  String _userImageUrl = '';

  List<SessionDisplayModel> _upcomingSessions = [];
  List<SessionDisplayModel> _pastSessions = [];

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get showUpcoming => _showUpcoming;
  String get userName => _userName;
  String get userImageUrl => _userImageUrl;

  List<SessionDisplayModel> get displayedSessions {
    return _showUpcoming ? _upcomingSessions : _pastSessions;
  }

  List<SessionsByDate> get sessionsGroupedByDate {
    final sessions = displayedSessions;
    if (sessions.isEmpty) return [];

    // Group sessions by date
    final Map<String, List<SessionDisplayModel>> grouped = {};
    final now = DateTime.now();

    for (final session in sessions) {
      final sessionDate = DateTime(
        session.booking.bookingDate.year,
        session.booking.bookingDate.month,
        session.booking.bookingDate.day,
      );

      String dateLabel;
      if (_showUpcoming) {
        // For upcoming sessions
        final today = DateTime(now.year, now.month, now.day);
        final tomorrow = today.add(const Duration(days: 1));

        if (sessionDate == today) {
          dateLabel = _formatDateLabel(sessionDate, 'TODAY');
        } else if (sessionDate == tomorrow) {
          dateLabel = _formatDateLabel(sessionDate, 'TOMORROW');
        } else {
          dateLabel = _formatDateLabel(sessionDate, null);
        }
      } else {
        // For past sessions
        dateLabel = _formatDateLabel(sessionDate, null);
      }

      if (!grouped.containsKey(dateLabel)) {
        grouped[dateLabel] = [];
      }
      grouped[dateLabel]!.add(session);
    }

    // Convert to list and sort by date
    final result = grouped.entries.map((entry) {
      // Get the first session's date for sorting
      final firstSession = entry.value.first;
      final sessionDate = DateTime(
        firstSession.booking.bookingDate.year,
        firstSession.booking.bookingDate.month,
        firstSession.booking.bookingDate.day,
      );

      return SessionsByDate(
        dateLabel: entry.key,
        date: sessionDate,
        sessions: entry.value
          ..sort((a, b) => a.booking.bookingTime.compareTo(b.booking.bookingTime)),
      );
    }).toList();

    // Sort by date
    result.sort((a, b) => a.date.compareTo(b.date));
    if (!_showUpcoming) {
      result.reversed.toList(); // Past sessions: newest first
    }

    return result;
  }

  String _formatDateLabel(DateTime date, String? prefix) {
    final months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC'
    ];

    final month = months[date.month - 1];
    final day = date.day;

    if (prefix != null) {
      return '$prefix, $month $day';
    }
    return '${month} $day, ${date.year}';
  }

  // ---------- Initialize ----------
  Future<void> initialize() async {
    if (_isDisposed) return;

    _setLoading(true);
    try {
      final user = _auth.currentUser;
      if (user == null) {
        _errorMessage = 'User not authenticated';
        _setLoading(false);
        return;
      }

      // Load user data
      final userModel = await _userService.getUserById(user.uid);
      if (userModel != null && !_isDisposed) {
        _userName = userModel.name;
        _userImageUrl = userModel.imageUrl ?? '';
      }

      if (_isDisposed) return;

      await loadSessions();
    } catch (e) {
      if (!_isDisposed) {
        _errorMessage = 'Failed to load sessions: ${e.toString()}';
        if (kDebugMode) {
          print('Error loading tutor sessions: $e');
        }
      }
    } finally {
      if (!_isDisposed) {
        _setLoading(false);
      }
    }
  }

  // ---------- Load Sessions ----------
  Future<void> loadSessions() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final now = DateTime.now();

      // Get upcoming sessions (approved and future dates)
      final upcomingBookings = await _bookingService.getUpcomingBookingsForTutor(
        user.uid,
      );

      // Get past sessions (completed or past approved bookings)
      final allTutorBookings = await _bookingService.getBookingsByTutorId(
        user.uid,
      );

      final upcomingList = <SessionDisplayModel>[];
      final pastList = <SessionDisplayModel>[];

      // Process upcoming sessions
      for (final booking in upcomingBookings) {
        final parent = await _userService.getUserById(booking.parentId);
        if (parent != null) {
          // TODO: Get actual location and duration from booking notes or separate field
          // For now, using mock data
          final location = booking.notes?.isNotEmpty == true
              ? booking.notes!
              : 'Location TBD';
          final duration = 1.0; // Default 1 hour, can be extracted from notes

          upcomingList.add(
            SessionDisplayModel(
              booking: booking,
              parent: parent,
              parentImageUrl: parent.imageUrl ?? '',
              location: location,
              duration: duration,
            ),
          );
        }
      }

      // Process past sessions
      for (final booking in allTutorBookings) {
        // Past sessions: completed or approved bookings with past dates
        if (booking.status == BookingStatus.completed ||
            (booking.status == BookingStatus.approved &&
                booking.bookingDate.isBefore(now))) {
          final parent = await _userService.getUserById(booking.parentId);
          if (parent != null) {
            final location = booking.notes?.isNotEmpty == true
                ? booking.notes!
                : 'Location TBD';
            final duration = 1.0;

            pastList.add(
              SessionDisplayModel(
                booking: booking,
                parent: parent,
                parentImageUrl: parent.imageUrl ?? '',
                location: location,
                duration: duration,
              ),
            );
          }
        }
      }

      // Sort upcoming by date and time
      upcomingList.sort((a, b) {
        final dateCompare = a.booking.bookingDate.compareTo(b.booking.bookingDate);
        if (dateCompare != 0) return dateCompare;
        return a.booking.bookingTime.compareTo(b.booking.bookingTime);
      });

      // Sort past by date and time (newest first)
      pastList.sort((a, b) {
        final dateCompare = b.booking.bookingDate.compareTo(a.booking.bookingDate);
        if (dateCompare != 0) return dateCompare;
        return b.booking.bookingTime.compareTo(a.booking.bookingTime);
      });

      if (!_isDisposed) {
        _upcomingSessions = upcomingList;
        _pastSessions = pastList;
        _safeNotifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading sessions: $e');
      }
      if (!_isDisposed) {
        _errorMessage = 'Failed to load sessions: ${e.toString()}';
        _safeNotifyListeners();
      }
    }
  }

  // ---------- Tab Selection ----------
  void selectTab(bool isUpcoming) {
    if (_isDisposed) return;
    _showUpcoming = isUpcoming;
    _safeNotifyListeners();
  }

  // ---------- Mark Session as Completed ----------
  Future<bool> markSessionAsCompleted(String bookingId) async {
    if (_isDisposed) return false;

    _setLoading(true);
    _errorMessage = null;

    try {
      // Get booking details before updating
      final booking = await _bookingService.getBookingById(bookingId);
      if (booking == null) {
        _setLoading(false);
        _errorMessage = 'Booking not found';
        _safeNotifyListeners();
        return false;
      }

      // Update booking status to completed
      await _bookingService.completeSession(bookingId);

      // Send notification to parent
      try {
        final notificationService = NotificationService();
        final tutor = await _userService.getUserById(_auth.currentUser?.uid ?? '');
        
        if (tutor != null) {
          await notificationService.sendSessionCompletedToParent(
            parentId: booking.parentId,
            tutorName: tutor.name,
          );
        }
      } catch (e) {
        // Don't fail session completion if notification fails
        if (kDebugMode) {
          print('⚠️ Failed to send session completed notification: $e');
        }
      }

      // Reload sessions
      await loadSessions();

      if (!_isDisposed) {
        _setLoading(false);
        _safeNotifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error marking session as completed: $e');
      }
      if (!_isDisposed) {
        _errorMessage = 'Failed to mark session as completed: ${e.toString()}';
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

