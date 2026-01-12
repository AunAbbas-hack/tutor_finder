import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/models/booking_model.dart';
import '../data/models/user_model.dart';
import '../data/services/booking_services.dart';
import '../data/services/user_services.dart';
import '../data/services/notification_service.dart';

/// Filter options for past bookings
enum PastBookingFilter {
  all, // All past bookings
  completed, // Only completed bookings (admin paid)
  pastIncomplete, // Past bookings that are not completed
}

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
  int _selectedTabIndex = 0; // 0 = Upcoming, 1 = Approved, 2 = Past
  String _userName = '';
  String _userImageUrl = '';

  // Filter state for past bookings
  PastBookingFilter _pastBookingFilter = PastBookingFilter.all;

  List<SessionDisplayModel> _upcomingSessions = [];
  List<SessionDisplayModel> _approvedSessions = []; // Approved but payment not done
  List<SessionDisplayModel> _pastSessions = [];
  List<SessionDisplayModel> _completedSessions = [];
  List<SessionDisplayModel> _pastIncompleteSessions = [];

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get selectedTabIndex => _selectedTabIndex;
  bool get showUpcoming => _selectedTabIndex == 0;
  String get userName => _userName;
  String get userImageUrl => _userImageUrl;
  PastBookingFilter get pastBookingFilter => _pastBookingFilter;

  List<SessionDisplayModel> get displayedSessions {
    switch (_selectedTabIndex) {
      case 0: // Upcoming
        return _upcomingSessions;
      case 1: // Approved
        return _approvedSessions;
      case 2: // Past
        // Apply filter for past bookings
        switch (_pastBookingFilter) {
          case PastBookingFilter.completed:
            return _completedSessions;
          case PastBookingFilter.pastIncomplete:
            return _pastIncompleteSessions;
          case PastBookingFilter.all:
          default:
            return _pastSessions;
        }
      default:
        return _upcomingSessions;
    }
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
      if (_selectedTabIndex == 0) {
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
      } else if (_selectedTabIndex == 1) {
        // For approved sessions (show TODAY/TOMORROW if applicable)
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
          ..sort((a, b) {
            final aDateTime = _getBookingDateTime(a.booking.bookingDate, a.booking.bookingTime);
            final bDateTime = _getBookingDateTime(b.booking.bookingDate, b.booking.bookingTime);
            return aDateTime.compareTo(bDateTime);
          }),
      );
    }).toList();

    // Sort by date
    if (_selectedTabIndex == 0 || _selectedTabIndex == 1) {
      // Upcoming/Approved: oldest first (earliest sessions first)
      result.sort((a, b) => a.date.compareTo(b.date));
    } else {
      // Past: newest first (most recent sessions first)
      result.sort((a, b) => b.date.compareTo(a.date));
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

  // ---------- Helper: Parse booking time string to DateTime ----------
  /// Parses time string like "4:00 PM" and combines with booking date
  DateTime _getBookingDateTime(DateTime bookingDate, String bookingTime) {
    try {
      // Parse time string (format: "4:00 PM" or "16:00")
      final timeParts = bookingTime.trim().split(' ');
      String timeStr = timeParts[0]; // "4:00" or "16:00"
      bool isPM = timeParts.length > 1 && timeParts[1].toUpperCase() == 'PM';

      final hourMinute = timeStr.split(':');
      int hour = int.parse(hourMinute[0]);
      int minute = hourMinute.length > 1 ? int.parse(hourMinute[1]) : 0;

      // Convert to 24-hour format if needed
      if (isPM && hour != 12) {
        hour += 12;
      } else if (!isPM && hour == 12) {
        hour = 0;
      }

      // Combine date and time
      return DateTime(
        bookingDate.year,
        bookingDate.month,
        bookingDate.day,
        hour,
        minute,
      );
    } catch (e) {
      // If parsing fails, use booking date at midnight
      return DateTime(
        bookingDate.year,
        bookingDate.month,
        bookingDate.day,
      );
    }
  }

  // ---------- Load Sessions ----------
  Future<void> loadSessions() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final now = DateTime.now();

      // Get all bookings for tutor
      final allTutorBookings = await _bookingService.getBookingsByTutorId(
        user.uid,
      );

      final upcomingList = <SessionDisplayModel>[];
      final approvedList = <SessionDisplayModel>[]; // Approved but payment not done
      final pastList = <SessionDisplayModel>[];
      final completedList = <SessionDisplayModel>[];
      final pastIncompleteList = <SessionDisplayModel>[];

      // Process all bookings and categorize by date + time and payment status
      for (final booking in allTutorBookings) {
        // Skip cancelled and rejected bookings
        if (booking.status == BookingStatus.cancelled ||
            booking.status == BookingStatus.rejected) {
          continue;
        }

        // Get full booking DateTime (date + time)
        final bookingDateTime = _getBookingDateTime(
          booking.bookingDate,
          booking.bookingTime,
        );

        final parent = await _userService.getUserById(booking.parentId);
        if (parent == null) continue;

        final location = booking.notes?.isNotEmpty == true
            ? booking.notes!
            : 'Location TBD';
        final duration = 1.0; // Default 1 hour

        final sessionModel = SessionDisplayModel(
          booking: booking,
          parent: parent,
          parentImageUrl: parent.imageUrl ?? '',
          location: location,
          duration: duration,
        );

        // Categorize bookings:
        // - Upcoming: completed (payment done) + future date+time
        // - Approved: approved (payment NOT done) - regardless of date
        // - Past: completed (payment done) + past date OR approved (payment NOT done) + past date
        if (booking.status == BookingStatus.completed) {
          // Payment done (completed status)
          if (bookingDateTime.isAfter(now)) {
            // Future booking with payment done - upcoming
            upcomingList.add(sessionModel);
          } else {
            // Past booking with payment done - past
            pastList.add(sessionModel);
            completedList.add(sessionModel);
          }
        } else if (booking.status == BookingStatus.approved) {
          // Payment NOT done (approved status)
          if (bookingDateTime.isAfter(now)) {
            // Future booking without payment - approved tab
            approvedList.add(sessionModel);
          } else {
            // Past booking without payment - past tab (incomplete)
            pastList.add(sessionModel);
            pastIncompleteList.add(sessionModel);
          }
        }
        // Note: pending bookings are not shown in sessions (they're in booking requests)
      }

      // Sort upcoming by date and time (earliest first)
      upcomingList.sort((a, b) {
        final aDateTime = _getBookingDateTime(a.booking.bookingDate, a.booking.bookingTime);
        final bDateTime = _getBookingDateTime(b.booking.bookingDate, b.booking.bookingTime);
        return aDateTime.compareTo(bDateTime);
      });

      // Sort approved by date and time (earliest first)
      approvedList.sort((a, b) {
        final aDateTime = _getBookingDateTime(a.booking.bookingDate, a.booking.bookingTime);
        final bDateTime = _getBookingDateTime(b.booking.bookingDate, b.booking.bookingTime);
        return aDateTime.compareTo(bDateTime);
      });

      // Sort past by date and time (newest first)
      pastList.sort((a, b) {
        final aDateTime = _getBookingDateTime(a.booking.bookingDate, a.booking.bookingTime);
        final bDateTime = _getBookingDateTime(b.booking.bookingDate, b.booking.bookingTime);
        return bDateTime.compareTo(aDateTime);
      });

      if (!_isDisposed) {
        _upcomingSessions = upcomingList;
        _approvedSessions = approvedList;
        _pastSessions = pastList;
        _completedSessions = completedList;
        _pastIncompleteSessions = pastIncompleteList;
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
  void selectTab(int tabIndex) {
    if (_isDisposed) return;
    _selectedTabIndex = tabIndex;
    // Reset filter when switching away from past tab
    if (tabIndex != 2) {
      _pastBookingFilter = PastBookingFilter.all;
    }
    _safeNotifyListeners();
  }

  // ---------- Filter Selection ----------
  void setPastBookingFilter(PastBookingFilter filter) {
    if (_isDisposed) return;
    _pastBookingFilter = filter;
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

