// lib/parent_viewmodels/manage_children_vm.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/models/student_model.dart';
import '../data/models/user_model.dart';
import '../data/services/student_services.dart';
import '../data/services/user_services.dart';

/// Combined model for displaying child information
class ChildProfile {
  final StudentModel student;
  final UserModel user;

  ChildProfile({
    required this.student,
    required this.user,
  });
}

class ManageChildrenViewModel extends ChangeNotifier {
  final StudentService _studentService;
  final UserService _userService;
  final FirebaseAuth _auth;

  ManageChildrenViewModel({
    StudentService? studentService,
    UserService? userService,
    FirebaseAuth? auth,
  })  : _studentService = studentService ?? StudentService(),
        _userService = userService ?? UserService(),
        _auth = auth ?? FirebaseAuth.instance;

  // ---------- State ----------
  bool _isLoading = false;
  String? _errorMessage;
  List<ChildProfile> _children = [];
  StreamSubscription<List<StudentModel>>? _studentsSubscription;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<ChildProfile> get children => _children;

  @override
  void dispose() {
    _studentsSubscription?.cancel();
    super.dispose();
  }

  // ---------- Initialize with Real-time Stream ----------
  Future<void> loadChildren() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      _errorMessage = 'User not authenticated';
      _setLoading(false);
      notifyListeners();
      return;
    }

    // Cancel existing subscription
    await _studentsSubscription?.cancel();

    _setLoading(true);
    _errorMessage = null;
    notifyListeners();

    try {
      // Use real-time stream for automatic updates
      _studentsSubscription = _studentService
          .getStudentsByParentIdStream(currentUser.uid)
          .listen(
        (students) async {
          // Fetch user data for each student
          // Filter out the parent's own student record (created during signup where studentId = parentId)
          final List<ChildProfile> childProfiles = [];
          for (var student in students) {
            // Skip if studentId equals parentId (this is the parent's own record, not a real child)
            if (student.studentId == currentUser.uid) {
              continue;
            }
            
            final user = await _userService.getUserById(student.studentId);
            if (user != null) {
              childProfiles.add(ChildProfile(student: student, user: user));
            }
          }

          _children = childProfiles;
          _setLoading(false);
          notifyListeners();
        },
        onError: (error) {
          _errorMessage = 'Failed to load children: ${error.toString()}';
          _setLoading(false);
          notifyListeners();
        },
      );
    } catch (e) {
      _errorMessage = 'Failed to load children: ${e.toString()}';
      _setLoading(false);
      notifyListeners();
    }
  }

  // ---------- Delete Child ----------
  Future<bool> deleteChild(String studentId) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      await _studentService.deleteStudent(studentId);
      // Remove from local list
      _children.removeWhere((child) => child.student.studentId == studentId);
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete child: ${e.toString()}';
      _setLoading(false);
      return false;
    }
  }

  // ---------- Refresh ----------
  Future<void> refresh() async {
    await loadChildren();
  }

  // ---------- Helpers ----------
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}

