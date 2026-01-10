// lib/admin_viewmodels/user_management_vm.dart
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/models/user_model.dart';
import '../data/models/tutor_model.dart';
import '../data/services/user_services.dart';
import '../data/services/tutor_services.dart';

/// Enum for filter tabs
enum UserFilterTab {
  all,
  tutors,
  parents,
}

/// Model for displaying user in list with additional info
class UserDisplayModel {
  final UserModel user;
  final List<String> subjects; // For tutors
  final String statusDisplay; // VERIFIED, PENDING, SUSPENDED
  final Color statusColor;
  final Color statusBgColor;

  UserDisplayModel({
    required this.user,
    this.subjects = const [],
    required this.statusDisplay,
    required this.statusColor,
    required this.statusBgColor,
  });
}

class UserManagementViewModel extends ChangeNotifier {
  final UserService _userService;
  final TutorService _tutorService;
  final FirebaseAuth _auth;

  UserManagementViewModel({
    UserService? userService,
    TutorService? tutorService,
    FirebaseAuth? auth,
  })  : _userService = userService ?? UserService(),
        _tutorService = tutorService ?? TutorService(),
        _auth = auth ?? FirebaseAuth.instance;

  // ---------- State ----------
  bool _isDisposed = false;
  bool _isLoading = false;
  String? _errorMessage;

  // Filter and search
  UserFilterTab _selectedTab = UserFilterTab.all;
  String _searchQuery = '';

  // Data
  List<UserModel> _allUsers = [];
  List<TutorModel> _allTutors = [];
  List<UserDisplayModel> _displayUsers = [];

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  UserFilterTab get selectedTab => _selectedTab;
  String get searchQuery => _searchQuery;
  List<UserDisplayModel> get displayUsers => _displayUsers;

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

      // Load all data
      await Future.wait([
        loadAllUsers(),
        loadAllTutors(),
      ]);

      // Apply filters
      _applyFilters();
    } catch (e) {
      if (!_isDisposed) {
        _errorMessage = 'Failed to load users: ${e.toString()}';
        if (kDebugMode) {
          print('Error loading user management: $e');
        }
      }
    } finally {
      if (!_isDisposed) {
        _setLoading(false);
      }
    }
  }

  // ---------- Load Data ----------
  Future<void> loadAllUsers() async {
    try {
      _allUsers = await _userService.getAllUsers();
      if (_isDisposed) return;
      _safeNotifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading all users: $e');
      }
      if (!_isDisposed) {
        _allUsers = [];
        _safeNotifyListeners();
      }
    }
  }

  Future<void> loadAllTutors() async {
    try {
      _allTutors = await _tutorService.getAllTutors();
      if (_isDisposed) return;
    } catch (e) {
      if (kDebugMode) {
        print('Error loading all tutors: $e');
      }
      if (!_isDisposed) {
        _allTutors = [];
      }
    }
  }

  // ---------- Filter and Search ----------
  void setSelectedTab(UserFilterTab tab) {
    if (_isDisposed) return;
    if (_selectedTab == tab) return;

    _selectedTab = tab;
    _applyFilters();
  }

  void setSearchQuery(String query) {
    if (_isDisposed) return;
    _searchQuery = query.trim();
    _applyFilters();
  }

  void _applyFilters() {
    if (_isDisposed) return;

    List<UserModel> filteredUsers = [];

    // Filter by role
    switch (_selectedTab) {
      case UserFilterTab.all:
        filteredUsers = List.from(_allUsers);
        break;
      case UserFilterTab.tutors:
        filteredUsers = _allUsers
            .where((u) => u.role == UserRole.tutor)
            .toList();
        break;
      case UserFilterTab.parents:
        filteredUsers = _allUsers
            .where((u) => u.role == UserRole.parent)
            .toList();
        break;
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filteredUsers = filteredUsers.where((user) {
        final query = _searchQuery.toLowerCase();
        
        // Search by name
        if (user.name.toLowerCase().contains(query)) {
          return true;
        }
        
        // Search by email
        if (user.email.toLowerCase().contains(query)) {
          return true;
        }
        
        // Search by subject (for tutors)
        if (user.role == UserRole.tutor) {
          final tutor = _allTutors.firstWhere(
            (t) => t.tutorId == user.userId,
            orElse: () => TutorModel(tutorId: user.userId, subjects: []),
          );
          if (tutor.subjects.any((subject) => 
              subject.toLowerCase().contains(query))) {
            return true;
          }
        }
        
        return false;
      }).toList();
    }

    // Convert to UserDisplayModel
    _displayUsers = filteredUsers.map((user) {
      // Get tutor subjects if tutor
      List<String> subjects = [];
      if (user.role == UserRole.tutor) {
        final tutor = _allTutors.firstWhere(
          (t) => t.tutorId == user.userId,
          orElse: () => TutorModel(tutorId: user.userId, subjects: []),
        );
        subjects = tutor.subjects;
      }

      // Map status to display
      String statusDisplay;
      Color statusColor;
      Color statusBgColor;

      switch (user.status) {
        case UserStatus.active:
          statusDisplay = 'VERIFIED';
          statusColor = const Color(0xFF16A34A); // Green
          statusBgColor = const Color(0xFFDCFCE7); // Light green
          break;
        case UserStatus.pending:
          statusDisplay = 'PENDING';
          statusColor = const Color(0xFFEA580C); // Orange
          statusBgColor = const Color(0xFFFFEDD5); // Light orange
          break;
        case UserStatus.suspended:
          statusDisplay = 'SUSPENDED';
          statusColor = const Color(0xFFDC2626); // Red
          statusBgColor = const Color(0xFFFEE2E2); // Light red
          break;
        case UserStatus.inactive:
          statusDisplay = 'INACTIVE';
          statusColor = const Color(0xFF6B7280); // Grey
          statusBgColor = const Color(0xFFF3F4F6); // Light grey
          break;
      }

      return UserDisplayModel(
        user: user,
        subjects: subjects,
        statusDisplay: statusDisplay,
        statusColor: statusColor,
        statusBgColor: statusBgColor,
      );
    }).toList();

    _safeNotifyListeners();
  }

  // ---------- Actions ----------
  Future<void> refresh() async {
    await initialize();
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
