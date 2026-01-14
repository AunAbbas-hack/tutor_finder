// lib/admin_viewmodels/reports_vm.dart
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/services/report_service.dart';
import '../data/services/user_services.dart';
import '../data/models/report_model.dart';
import '../data/models/user_model.dart';
import '../core/theme/app_colors.dart';

class ReportsViewModel extends ChangeNotifier {
  final ReportService _reportService;
  final UserService _userService;
  final FirebaseAuth _auth;

  ReportsViewModel({
    ReportService? reportService,
    UserService? userService,
    FirebaseAuth? auth,
  })  : _reportService = reportService ?? ReportService(),
        _userService = userService ?? UserService(),
        _auth = auth ?? FirebaseAuth.instance;

  // ---------- State ----------
  bool _isDisposed = false;
  bool _isLoading = false;
  String? _errorMessage;
  List<ReportModel> _allReports = [];
  List<ReportModel> _filteredReports = [];
  ReportStatus? _selectedStatus;
  String _searchQuery = '';

  // User info cache
  final Map<String, UserModel> _userCache = {};

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<ReportModel> get reports => _filteredReports;
  ReportStatus? get selectedStatus => _selectedStatus;
  String get searchQuery => _searchQuery;
  int get totalReports => _allReports.length;
  int get pendingCount => _allReports.where((r) => r.status == ReportStatus.pending).length;

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
        notifyListeners();
        return;
      }

      await loadReports();
    } catch (e) {
      if (!_isDisposed) {
        _errorMessage = 'Failed to load reports: ${e.toString()}';
        if (kDebugMode) {
          print('Error loading reports: $e');
        }
      }
    } finally {
      if (!_isDisposed) {
        _setLoading(false);
        notifyListeners();
      }
    }
  }

  // ---------- Load Reports ----------
  Future<void> loadReports() async {
    try {
      _allReports = await _reportService.getAllReports();
      _applyFilters();
    } catch (e) {
      if (!_isDisposed) {
        _errorMessage = 'Failed to load reports: ${e.toString()}';
      }
    }
  }

  // ---------- Filter Methods ----------
  void setStatusFilter(ReportStatus? status) {
    _selectedStatus = status;
    _applyFilters();
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query.trim().toLowerCase();
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    List<ReportModel> filtered = List.from(_allReports);

    // Apply status filter
    if (_selectedStatus != null) {
      filtered = filtered.where((r) => r.status == _selectedStatus).toList();
    }

    // Apply search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((r) {
        final type = ReportModel.typeToString(r.type).toLowerCase();
        final description = r.description.toLowerCase();
        final reportId = r.reportId.toLowerCase();
        return type.contains(_searchQuery) ||
            description.contains(_searchQuery) ||
            reportId.contains(_searchQuery);
      }).toList();
    }

    _filteredReports = filtered;
  }

  // ---------- Update Report Status ----------
  Future<bool> updateReportStatus({
    required String reportId,
    required ReportStatus status,
    String? adminNotes,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      await _reportService.updateReportStatus(
        reportId: reportId,
        status: status,
        handledBy: user.uid,
        adminNotes: adminNotes,
      );

      // Reload reports
      await loadReports();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating report status: $e');
      }
      return false;
    }
  }

  // ---------- Get User Info (with cache) ----------
  Future<UserModel?> getUserInfo(String userId) async {
    if (_userCache.containsKey(userId)) {
      return _userCache[userId];
    }

    try {
      final user = await _userService.getUserById(userId);
      if (user != null) {
        _userCache[userId] = user;
      }
      return user;
    } catch (e) {
      if (kDebugMode) {
        print('Error loading user info: $e');
      }
      return null;
    }
  }

  // ---------- Refresh ----------
  Future<void> refresh() async {
    _userCache.clear();
    await loadReports();
  }

  // ---------- Helper Methods ----------
  void _setLoading(bool value) {
    if (!_isDisposed) {
      _isLoading = value;
    }
  }

  String formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    }
  }

  Color getStatusColor(ReportStatus status) {
    switch (status) {
      case ReportStatus.pending:
        return AppColors.warning;
      case ReportStatus.inProgress:
        return AppColors.primary;
      case ReportStatus.resolved:
        return AppColors.success;
      case ReportStatus.rejected:
        return AppColors.error;
    }
  }

  String getStatusText(ReportStatus status) {
    switch (status) {
      case ReportStatus.pending:
        return 'Pending';
      case ReportStatus.inProgress:
        return 'In Progress';
      case ReportStatus.resolved:
        return 'Resolved';
      case ReportStatus.rejected:
        return 'Rejected';
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}

// Import AppColors
