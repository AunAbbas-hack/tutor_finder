// lib/admin_viewmodels/admin_dashboard_vm.dart
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/models/dashboard_metrics_model.dart';
import '../data/models/activity_model.dart';
import '../data/models/pending_approval_model.dart';
import '../data/models/user_model.dart';
import '../data/models/tutor_model.dart';
import '../data/models/booking_model.dart';
import '../data/services/user_services.dart';
import '../data/services/tutor_services.dart';
import '../data/services/booking_services.dart';

class AdminDashboardViewModel extends ChangeNotifier {
  final UserService _userService;
  final TutorService _tutorService;
  final BookingService _bookingService;
  final FirebaseAuth _auth;

  AdminDashboardViewModel({
    UserService? userService,
    TutorService? tutorService,
    BookingService? bookingService,
    FirebaseAuth? auth,
  })  : _userService = userService ?? UserService(),
        _tutorService = tutorService ?? TutorService(),
        _bookingService = bookingService ?? BookingService(),
        _auth = auth ?? FirebaseAuth.instance;

  // ---------- State ----------
  bool _isDisposed = false;
  bool _isLoading = false;
  String? _errorMessage;

  // Dashboard metrics
  DashboardMetricsModel? _metrics;

  // Recent activity
  List<ActivityModel> _recentActivity = [];

  // Pending approvals
  List<PendingApprovalModel> _pendingApprovals = [];

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DashboardMetricsModel? get metrics => _metrics;
  List<ActivityModel> get recentActivity => _recentActivity;
  List<PendingApprovalModel> get pendingApprovals => _pendingApprovals;

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

      // Verify admin role
      final userModel = await _userService.getUserById(user.uid);
      if (userModel == null || userModel.role != UserRole.admin) {
        _errorMessage = 'Access denied. Admin privileges required.';
        _setLoading(false);
        return;
      }

      // Load all dashboard data in parallel
      await Future.wait([
        loadMetrics(),
        loadRecentActivity(),
        loadPendingApprovals(),
      ]);
    } catch (e) {
      if (!_isDisposed) {
        _errorMessage = 'Failed to load dashboard: ${e.toString()}';
        if (kDebugMode) {
          print('Error loading admin dashboard: $e');
        }
      }
    } finally {
      if (!_isDisposed) {
        _setLoading(false);
      }
    }
  }

  // ---------- Load Metrics ----------
  Future<void> loadMetrics() async {
    try {
      // Get all users
      final allUsers = await _getAllUsers();
      if (_isDisposed) return;

      final totalUsers = allUsers.length;

      // Get pending verifications (tutors with pending status)
      final pendingUsers = allUsers.where((u) => 
        u.role == UserRole.tutor && u.status == UserStatus.pending
      ).toList();
      final pendingVerifications = pendingUsers.length;

      // Get active bookings (approved bookings with future dates)
      final now = DateTime.now();
      final allBookings = await _bookingService.getAllBookings();
      if (_isDisposed) return;

      final activeBookings = allBookings.where((booking) {
        return booking.status == BookingStatus.approved &&
            booking.bookingDate.isAfter(now);
      }).length;

      // Calculate revenue (placeholder - will be implemented with payment integration)
      // TODO: Replace with actual payment data when payment system is integrated
      final totalRevenue = 0.0; // Placeholder

      // Calculate growth percentages (mock data for now)
      // TODO: Replace with actual comparison data
      final usersGrowthPercentage = 12.0; // Mock: +12%
      final newBookingsToday = 8; // Mock: 8 new today
      final revenueGrowthPercentage = 5.0; // Mock: +5%

      if (!_isDisposed) {
        _metrics = DashboardMetricsModel(
          totalUsers: totalUsers,
          pendingVerifications: pendingVerifications,
          activeBookings: activeBookings,
          totalRevenue: totalRevenue,
          usersGrowthPercentage: usersGrowthPercentage,
          newBookingsToday: newBookingsToday,
          revenueGrowthPercentage: revenueGrowthPercentage,
          pendingVerifStatus: pendingVerifications > 0 
              ? 'Requires action' 
              : null,
        );
        _safeNotifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading metrics: $e');
      }
      if (!_isDisposed) {
        _errorMessage = 'Failed to load metrics: ${e.toString()}';
        _safeNotifyListeners();
      }
    }
  }

  // ---------- Load Recent Activity ----------
  Future<void> loadRecentActivity() async {
    try {
      // Get recent bookings
      final recentBookings = await _bookingService.getAllBookings();
      if (_isDisposed) return;

      // Get recent users (tutors)
      final allUsers = await _getAllUsers();
      if (_isDisposed) return;

      final activities = <ActivityModel>[];

      // Get recent tutor signups (last 24 hours)
      final recentTutorSignups = allUsers.where((u) {
        if (u.role != UserRole.tutor) return false;
        // TODO: Get actual creation date from Firestore
        return true; // Mock for now
      }).take(1).toList();

      for (final user in recentTutorSignups) {
        final subject = await _getTutorSubjects(user.userId);
        if (_isDisposed) return;
        
        activities.add(ActivityModel(
          activityId: 'tutor_${user.userId}',
          type: ActivityType.newTutorSignup,
          title: 'New Tutor Signup',
          description: '${user.name} registered as $subject tutor',
          timestamp: DateTime.now().subtract(const Duration(minutes: 2)), // Mock
          relatedUserId: user.userId,
        ));
      }

      // Get recent reports (mock for now)
      // TODO: Implement when ReportService is available
      activities.add(ActivityModel(
        activityId: 'report_1',
        type: ActivityType.newReportSubmitted,
        title: 'New Report Submitted',
        description: 'Reported user: David Miller',
        timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
      ));

      // Get recent completed bookings
      final completedBookings = recentBookings
          .where((b) => b.status == BookingStatus.completed)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      if (completedBookings.isNotEmpty) {
        final booking = completedBookings.first;
        activities.add(ActivityModel(
          activityId: 'booking_${booking.bookingId}',
          type: ActivityType.bookingCompleted,
          title: 'Booking Completed',
          description: '${booking.subject} session ID #${booking.bookingId.substring(0, 4)}',
          timestamp: DateTime.now().subtract(const Duration(hours: 1)), // Mock
          relatedBookingId: booking.bookingId,
        ));
      }

      // Sort by timestamp (most recent first)
      activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      if (!_isDisposed) {
        _recentActivity = activities.take(10).toList(); // Limit to 10 most recent
        _safeNotifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading recent activity: $e');
      }
      if (!_isDisposed) {
        _recentActivity = [];
        _safeNotifyListeners();
      }
    }
  }

  // ---------- Load Pending Approvals ----------
  Future<void> loadPendingApprovals() async {
    try {
      // Get all pending tutors
      final allUsers = await _getAllUsers();
      if (_isDisposed) return;

      final pendingUsers = allUsers.where((u) => 
        u.role == UserRole.tutor && u.status == UserStatus.pending
      ).toList();

      final approvals = <PendingApprovalModel>[];

      for (final user in pendingUsers) {
        // Get tutor details
        final tutor = await _tutorService.getTutorById(user.userId);
        if (tutor == null) continue;

        // Create pending approval model
        final approval = PendingApprovalModel.fromTutorAndUser(
          tutor: tutor,
          user: user,
        );

        approvals.add(approval);
      }

      if (!_isDisposed) {
        _pendingApprovals = approvals;
        _safeNotifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading pending approvals: $e');
      }
      if (!_isDisposed) {
        _pendingApprovals = [];
        _safeNotifyListeners();
      }
    }
  }

  // ---------- Approve Tutor ----------
  Future<bool> approveTutor(String tutorId) async {
    if (_isDisposed) return false;

    _setLoading(true);
    _errorMessage = null;

    try {
      // Get user
      final user = await _userService.getUserById(tutorId);
      if (user == null) {
        _errorMessage = 'Tutor not found';
        _setLoading(false);
        return false;
      }

      // Update status to active
      final updatedUser = user.copyWith(status: UserStatus.active);
      await _userService.updateUser(updatedUser);

      // Reload data
      await Future.wait([
        loadMetrics(),
        loadPendingApprovals(),
        loadRecentActivity(),
      ]);

      if (!_isDisposed) {
        _setLoading(false);
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error approving tutor: $e');
      }
      if (!_isDisposed) {
        _errorMessage = 'Failed to approve tutor: ${e.toString()}';
        _setLoading(false);
        _safeNotifyListeners();
      }
      return false;
    }
  }

  // ---------- Reject Tutor ----------
  Future<bool> rejectTutor(String tutorId) async {
    if (_isDisposed) return false;

    _setLoading(true);
    _errorMessage = null;

    try {
      // Get user
      final user = await _userService.getUserById(tutorId);
      if (user == null) {
        _errorMessage = 'Tutor not found';
        _setLoading(false);
        return false;
      }

      // Update status to suspended
      final updatedUser = user.copyWith(status: UserStatus.suspended);
      await _userService.updateUser(updatedUser);

      // Reload data
      await Future.wait([
        loadMetrics(),
        loadPendingApprovals(),
        loadRecentActivity(),
      ]);

      if (!_isDisposed) {
        _setLoading(false);
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error rejecting tutor: $e');
      }
      if (!_isDisposed) {
        _errorMessage = 'Failed to reject tutor: ${e.toString()}';
        _setLoading(false);
        _safeNotifyListeners();
      }
      return false;
    }
  }

  // ---------- Helper Methods ----------

  /// Get all users (helper method)
  /// TODO: Implement pagination when user count grows large
  Future<List<UserModel>> _getAllUsers() async {
    try {
      return await _userService.getAllUsers();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting all users: $e');
      }
      return [];
    }
  }

  /// Get tutor subjects (helper method)
  Future<String> _getTutorSubjects(String tutorId) async {
    try {
      final tutor = await _tutorService.getTutorById(tutorId);
      if (tutor != null && tutor.subjects.isNotEmpty) {
        return tutor.subjects.first;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting tutor subjects: $e');
      }
    }
    return 'Tutor'; // Default fallback
  }

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
