import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/models/booking_model.dart';
import '../data/models/user_model.dart';
import '../data/services/booking_services.dart';
import '../data/services/user_services.dart';
import '../data/services/chat_service.dart';
import '../data/services/notification_service.dart';
import 'package:firebase_database/firebase_database.dart';

/// Model for student feedback display
class StudentFeedback {
  final String studentId;
  final String studentName;
  final String subject;
  final int rating; // 1-5 stars
  final String feedback;
  final String? studentImageUrl;
  final DateTime date;

  StudentFeedback({
    required this.studentId,
    required this.studentName,
    required this.subject,
    required this.rating,
    required this.feedback,
    this.studentImageUrl,
    required this.date,
  });
}

/// Model for earnings data
class EarningsData {
  final double thisWeekEarnings;
  final double lastWeekEarnings;
  final Map<String, double> dailyEarnings; // Day of week -> amount

  EarningsData({
    required this.thisWeekEarnings,
    required this.lastWeekEarnings,
    required this.dailyEarnings,
  });

  double get percentageChange {
    if (lastWeekEarnings == 0) return 0.0;
    return ((thisWeekEarnings - lastWeekEarnings) / lastWeekEarnings) * 100;
  }
}

class TutorDashboardViewModel extends ChangeNotifier {
  final BookingService _bookingService;
  final UserService _userService;
  final ChatService _chatService;
  final FirebaseAuth _auth;
  final DatabaseReference _database;

  TutorDashboardViewModel({
    BookingService? bookingService,
    UserService? userService,
    ChatService? chatService,
    FirebaseAuth? auth,
    DatabaseReference? database,
  })  : _bookingService = bookingService ?? BookingService(),
        _userService = userService ?? UserService(),
        _chatService = chatService ?? ChatService(),
        _auth = auth ?? FirebaseAuth.instance,
        _database = database ?? 
        FirebaseDatabase.instanceFor(
          app: FirebaseDatabase.instance.app,
          databaseURL: 'https://tutor-finder-0468-default-rtdb.asia-southeast1.firebasedatabase.app',
        ).ref();

  // ---------- State ----------
  bool _isDisposed = false;
  bool _isLoading = false;
  String? _errorMessage;
  String _userName = '';
  String _userImageUrl = '';

  // Dashboard metrics
  int _newRequestsCount = 0;
  int _upcomingCount = 0;
  int _messagesCount = 0;

  // Earnings
  EarningsData? _earningsData;

  // Feedback
  List<StudentFeedback> _latestFeedback = [];

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get userName => _userName;
  String get userImageUrl => _userImageUrl;
  int get newRequestsCount => _newRequestsCount;
  int get upcomingCount => _upcomingCount;
  int get messagesCount => _messagesCount;
  EarningsData? get earningsData => _earningsData;
  List<StudentFeedback> get latestFeedback => _latestFeedback;

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

      // Load all dashboard data in parallel
      await Future.wait([
        loadBookings(),
        loadMessagesCount(),
        loadEarnings(),
        loadFeedback(),
      ]);
      
      // Check and send reminders for upcoming sessions
      if (_isDisposed) return;
      try {
        final notificationService = NotificationService();
        await notificationService.checkAndSendReminders();
      } catch (e) {
        // Don't fail dashboard load if reminder check fails
        if (kDebugMode) {
          print('⚠️ Failed to check reminders: $e');
        }
      }
    } catch (e) {
      if (!_isDisposed) {
        _errorMessage = 'Failed to load dashboard: ${e.toString()}';
        if (kDebugMode) {
          print('Error loading tutor dashboard: $e');
        }
      }
    } finally {
      if (!_isDisposed) {
        _setLoading(false);
      }
    }
  }

  // ---------- Load Bookings ----------
  Future<void> loadBookings() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Get pending bookings (new requests)
      final pendingBookings = await _bookingService.getBookingsByTutorAndStatus(
        user.uid,
        BookingStatus.pending,
      );

      // Get upcoming bookings (approved and future dates)
      final upcomingBookings = await _bookingService.getUpcomingBookingsForTutor(
        user.uid,
      );

      if (!_isDisposed) {
        _newRequestsCount = pendingBookings.length;
        _upcomingCount = upcomingBookings.length;
        _safeNotifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading bookings: $e');
      }
      if (!_isDisposed) {
        _errorMessage = 'Failed to load bookings: ${e.toString()}';
        _safeNotifyListeners();
      }
    }
  }

  // ---------- Load Messages Count ----------
  Future<void> loadMessagesCount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Get all conversations for the tutor
      final conversationsStream = _chatService.getConversationsStream();
      
      // Listen to the stream once to get current count
      await conversationsStream.first.then((conversations) {
        if (_isDisposed) return;

        int totalUnread = 0;
        for (final chat in conversations) {
          totalUnread += chat.getUnreadCountForUser(user.uid);
        }

        _messagesCount = totalUnread;
        _safeNotifyListeners();
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error loading messages count: $e');
      }
      // Set default value if error
      if (!_isDisposed) {
        _messagesCount = 0;
        _safeNotifyListeners();
      }
    }
  }

  // ---------- Load Earnings ----------
  Future<void> loadEarnings() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Get all completed bookings for the tutor
      final completedBookings = await _bookingService.getBookingsByTutorAndStatus(
        user.uid,
        BookingStatus.completed,
      );

      // Calculate this week's earnings
      final now = DateTime.now();
      final startOfThisWeek = DateTime(
        now.year,
        now.month,
        now.day - (now.weekday - 1),
        0,
        0,
        0,
      );
      final startOfLastWeek = startOfThisWeek.subtract(const Duration(days: 7));

      double thisWeekTotal = 0.0;
      double lastWeekTotal = 0.0;
      final Map<String, double> dailyEarnings = {
        'Mon': 0.0,
        'Tue': 0.0,
        'Wed': 0.0,
        'Thu': 0.0,
        'Fri': 0.0,
        'Sat': 0.0,
        'Sun': 0.0,
      };

      // TODO: Get actual payment amounts from PaymentService
      // For now, using a mock hourly rate
      const double hourlyRate = 50.0; // Mock rate
      const double sessionDuration = 1.0; // Mock 1 hour sessions

      for (final booking in completedBookings) {
        final bookingDate = booking.bookingDate;
        final amount = hourlyRate * sessionDuration;

        // Check if booking is in this week
        if (bookingDate.isAfter(startOfThisWeek.subtract(const Duration(days: 1))) &&
            bookingDate.isBefore(startOfThisWeek.add(const Duration(days: 7)))) {
          thisWeekTotal += amount;

          // Add to daily earnings
          final dayName = _getDayName(bookingDate.weekday);
          dailyEarnings[dayName] = (dailyEarnings[dayName] ?? 0.0) + amount;
        }
        // Check if booking is in last week
        else if (bookingDate.isAfter(startOfLastWeek.subtract(const Duration(days: 1))) &&
                 bookingDate.isBefore(startOfThisWeek)) {
          lastWeekTotal += amount;
        }
      }

      if (!_isDisposed) {
        _earningsData = EarningsData(
          thisWeekEarnings: thisWeekTotal,
          lastWeekEarnings: lastWeekTotal,
          dailyEarnings: dailyEarnings,
        );
        _safeNotifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading earnings: $e');
      }
      // Set default earnings if error
      if (!_isDisposed) {
        _earningsData = EarningsData(
          thisWeekEarnings: 0.0,
          lastWeekEarnings: 0.0,
          dailyEarnings: {
            'Mon': 0.0,
            'Tue': 0.0,
            'Wed': 0.0,
            'Thu': 0.0,
            'Fri': 0.0,
            'Sat': 0.0,
            'Sun': 0.0,
          },
        );
        _safeNotifyListeners();
      }
    }
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Mon';
      case 2:
        return 'Tue';
      case 3:
        return 'Wed';
      case 4:
        return 'Thu';
      case 5:
        return 'Fri';
      case 6:
        return 'Sat';
      case 7:
        return 'Sun';
      default:
        return 'Mon';
    }
  }

  // ---------- Load Feedback ----------
  Future<void> loadFeedback() async {
    try {
      // TODO: Implement actual feedback/review fetching from Firestore
      // For now, using mock data based on the image
      if (!_isDisposed) {
        _latestFeedback = [
          StudentFeedback(
            studentId: 'student1',
            studentName: 'Alex Johnson',
            subject: 'Algebra II',
            rating: 5,
            feedback: 'Sarah is an amazing tutor! She explains complex concepts in a way that\'s easy to understand.',
            date: DateTime.now().subtract(const Duration(days: 2)),
          ),
          StudentFeedback(
            studentId: 'student2',
            studentName: 'Emily Chen',
            subject: 'Chemistry',
            rating: 5,
            feedback: 'My grades have improved so much since I started sessions with Sarah. Highly recommend!',
            date: DateTime.now().subtract(const Duration(days: 5)),
          ),
        ];
        _safeNotifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading feedback: $e');
      }
      if (!_isDisposed) {
        _latestFeedback = [];
        _safeNotifyListeners();
      }
    }
  }

  // ---------- Get Greeting ----------
  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning';
    } else if (hour < 17) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
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

