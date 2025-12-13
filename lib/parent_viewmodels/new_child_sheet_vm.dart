// lib/parent_viewmodels/new_child_sheet_vm.dart
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/student_model.dart';
import '../data/models/user_model.dart';
import '../data/services/student_services.dart';
import '../data/services/user_services.dart';

enum Gender { boy, girl, other }

class NewChildSheetViewModel extends ChangeNotifier {
  final StudentService _studentService;
  final UserService _userService;
  final FirebaseAuth _auth;

  // Edit mode
  final String? _existingStudentId;
  final String? _existingUserId;
  bool get isEditMode => _existingStudentId != null;

  NewChildSheetViewModel({
    StudentService? studentService,
    UserService? userService,
    FirebaseAuth? auth,
    String? existingStudentId,
    String? existingUserId,
  })  : _studentService = studentService ?? StudentService(),
        _userService = userService ?? UserService(),
        _auth = auth ?? FirebaseAuth.instance,
        _existingStudentId = existingStudentId,
        _existingUserId = existingUserId;

  // ---------- State ----------
  bool _isLoading = false;
  String? _errorMessage;

  // Form fields
  String _name = '';
  String? _selectedGrade;
  List<String> _subjects = [];
  Gender? _selectedGender;

  // Grade options
  static const List<String> gradeOptions = [
    'Pre-K',
    'Kindergarten',
    '1st Grade',
    '2nd Grade',
    '3rd Grade',
    '4th Grade',
    '5th Grade',
    '6th Grade',
    '7th Grade',
    '8th Grade',
    '9th Grade',
    '10th Grade',
    '11th Grade',
    '12th Grade',
    'O-Levels',
    'A-Levels',
    'Undergraduate',
    'Graduate',
  ];

  // Common subjects
  static const List<String> commonSubjects = [
    'Mathematics',
    'Science',
    'English',
    'Reading',
    'Writing',
    'History',
    'Geography',
    'Physics',
    'Chemistry',
    'Biology',
    'Computer Science',
    'Art',
    'Music',
    'Physical Education',
  ];

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get name => _name;
  String? get selectedGrade => _selectedGrade;
  List<String> get subjects => _subjects;
  Gender? get selectedGender => _selectedGender;
  List<String> get gradeOptionsList => gradeOptions;
  List<String> get commonSubjectsList => commonSubjects;

  bool get isValid {
    return _name.trim().isNotEmpty && _selectedGrade != null;
  }

  // ---------- Update Methods ----------
  void updateName(String value) {
    _name = value;
    notifyListeners();
  }

  void updateGrade(String? value) {
    _selectedGrade = value;
    notifyListeners();
  }

  void addSubject(String subject) {
    if (!_subjects.contains(subject)) {
      _subjects.add(subject);
      notifyListeners();
    }
  }

  void removeSubject(String subject) {
    _subjects.remove(subject);
    notifyListeners();
  }

  void updateGender(Gender? value) {
    _selectedGender = value;
    notifyListeners();
  }

  // ---------- Initialize for Edit Mode ----------
  Future<void> initializeForEdit() async {
    if (!isEditMode || _existingUserId == null || _existingStudentId == null) {
      return;
    }

    _setLoading(true);
    _errorMessage = null;

    try {
      final user = await _userService.getUserById(_existingUserId!);
      final student = await _studentService.getStudentById(_existingStudentId!);

      if (user != null && student != null) {
        _name = user.name;
        _selectedGrade = student.grade;
        if (student.subjects != null && student.subjects!.isNotEmpty) {
          _subjects = student.subjects!
              .split(',')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList();
        }
        notifyListeners();
      } else {
        _errorMessage = 'Child data not found';
      }
    } catch (e) {
      _errorMessage = 'Failed to load child data: ${e.toString()}';
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  // ---------- Create Child ----------
  Future<bool> createChild() async {
    if (!isValid) {
      _errorMessage = 'Please fill in all required fields';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    _errorMessage = null;

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        _errorMessage = 'User not authenticated';
        _setLoading(false);
        return false;
      }

      // Generate unique student ID using Firestore document reference
      final studentDocRef = FirebaseFirestore.instance.collection('users').doc();
      final studentId = studentDocRef.id;

      // Create UserModel for student
      final userModel = UserModel(
        userId: studentId,
        name: _name.trim(),
        email: '', // Students don't need email
        role: UserRole.student,
        status: UserStatus.active,
      );

      // Create StudentModel
      final subjectsText = _subjects.join(', ');
      final studentModel = StudentModel(
        studentId: studentId,
        parentId: currentUser.uid,
        grade: _selectedGrade,
        subjects: subjectsText.isNotEmpty ? subjectsText : null,
      );

      // Save to Firestore
      await _userService.createUser(userModel);
      await _studentService.createStudent(studentModel);

      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to create child: ${e.toString()}';
      _setLoading(false);
      return false;
    }
  }

  // ---------- Update Child ----------
  Future<bool> updateChild() async {
    if (!isEditMode || _existingStudentId == null || _existingUserId == null) {
      _errorMessage = 'Invalid edit mode';
      return false;
    }

    if (!isValid) {
      _errorMessage = 'Please fill in all required fields';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    _errorMessage = null;

    try {
      // Update UserModel
      final existingUser = await _userService.getUserById(_existingUserId!);
      if (existingUser == null) {
        _errorMessage = 'User not found';
        _setLoading(false);
        return false;
      }

      final updatedUser = existingUser.copyWith(name: _name.trim());
      await _userService.updateUser(updatedUser);

      // Update StudentModel
      final existingStudent = await _studentService.getStudentById(_existingStudentId!);
      if (existingStudent == null) {
        _errorMessage = 'Student not found';
        _setLoading(false);
        return false;
      }

      final subjectsText = _subjects.join(', ');
      final updatedStudent = existingStudent.copyWith(
        grade: _selectedGrade,
        subjects: subjectsText.isNotEmpty ? subjectsText : null,
      );
      await _studentService.updateStudent(updatedStudent);

      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update child: ${e.toString()}';
      _setLoading(false);
      return false;
    }
  }

  // ---------- Reset ----------
  void reset() {
    _name = '';
    _selectedGrade = null;
    _subjects = [];
    _selectedGender = null;
    _errorMessage = null;
    notifyListeners();
  }

  // ---------- Helpers ----------
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}

