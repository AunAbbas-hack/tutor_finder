import 'package:flutter/foundation.dart';

import '../data/models/user_model.dart';
import '../data/models/tutor_model.dart';
import '../data/models/parent_model.dart';
import '../data/repositories/auth_repository.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;

  AuthViewModel({AuthRepository? authRepository})
      : _authRepository = authRepository ?? AuthRepository();

  // ---------- Role Selection ----------
  UserRole? _selectedRole;
  UserRole? get selectedRole => _selectedRole;

  void selectRole(UserRole role) {
    _selectedRole = role;
    notifyListeners();
  }

  void clearRole() {
    _selectedRole = null;
    notifyListeners();
  }

  bool get hasSelectedRole => _selectedRole != null;

  // ---------- Login State ----------
  String _emailOrPhone = '';
  String _password = '';
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String? _errorMessage;

  String get emailOrPhone => _emailOrPhone;
  String get password => _password;
  bool get isPasswordVisible => _isPasswordVisible;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void updateEmailOrPhone(String value) {
    _emailOrPhone = value.trim();
    _errorMessage = null;
    notifyListeners();
  }

  void updatePassword(String value) {
    _password = value;
    _errorMessage = null;
    notifyListeners();
  }

  void togglePasswordVisibility() {
    _isPasswordVisible = !_isPasswordVisible;
    notifyListeners();
  }

  bool get canSubmitLogin =>
      _emailOrPhone.isNotEmpty && _password.isNotEmpty && !_isLoading;

  Future<bool> login() async {
    if (!canSubmitLogin) return false;

    if (!_emailOrPhone.contains('@')) {
      _errorMessage = 'Please enter a valid email address.';
      notifyListeners();
      return false;
    }

    try {
      _setLoading(true);
      _errorMessage = null;

      await _authRepository.loginWithEmail(
        email: _emailOrPhone,
        password: _password,
      );

      _setLoading(false);
      return true;
    } on Exception catch (e) {
      _setLoading(false);
      _errorMessage = _mapFirebaseError(e);
      return false;
    }
  }

  // ========== TUTOR SIGNUP ==========

  String _tutorFullName = '';
  String _tutorEmail = '';
  String _tutorPassword = '';
  String _tutorPhone = '';
  String _tutorSubjectsExp = '';

  String get tutorFullName => _tutorFullName;
  String get tutorEmail => _tutorEmail;
  String get tutorPassword => _tutorPassword;
  String get tutorPhone => _tutorPhone;
  String get tutorSubjectsExp => _tutorSubjectsExp;

  void updateTutorFullName(String value) {
    _tutorFullName = value.trim();
    _errorMessage = null;
    notifyListeners();
  }

  void updateTutorEmail(String value) {
    _tutorEmail = value.trim();
    _errorMessage = null;
    notifyListeners();
  }

  void updateTutorPassword(String value) {
    _tutorPassword = value;
    _errorMessage = null;
    notifyListeners();
  }

  void updateTutorPhone(String value) {
    _tutorPhone = value.trim();
    _errorMessage = null;
    notifyListeners();
  }

  void updateTutorSubjectsExp(String value) {
    _tutorSubjectsExp = value.trim();
    _errorMessage = null;
    notifyListeners();
  }

  bool get canSubmitTutorSignup =>
      _tutorFullName.isNotEmpty &&
          _tutorEmail.isNotEmpty &&
          _tutorPassword.length >= 6 &&
          _tutorPhone.isNotEmpty &&
          _tutorSubjectsExp.isNotEmpty &&
          !_isLoading;

  Future<bool> registerTutor() async {
    if (!canSubmitTutorSignup) return false;

    try {
      _setLoading(true);
      _errorMessage = null;

      final baseUser = UserModel(
        userId: '',
        name: _tutorFullName,
        email: _tutorEmail,
        password: null,
        phone: _tutorPhone,
        role: UserRole.tutor,
        status: UserStatus.pending,
        latitude: null,
        longitude: null,
      );

      // Parse subjects from comma-separated string
      // e.g., "Math, Physics, Chemistry" -> ["Math", "Physics", "Chemistry"]
      final subjectsList = _tutorSubjectsExp
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      // If no subjects parsed, use the whole string as one subject
      final subjects = subjectsList.isEmpty ? [_tutorSubjectsExp] : subjectsList;

      final tutor = TutorModel(
        tutorId: '',
        subjects: subjects,
        qualification: null,
        experience: null, // TODO: Add experience field in UI
        bio: _tutorSubjectsExp, // TODO: Add separate bio field in UI
      );

      await _authRepository.registerTutor(
        baseUser: baseUser,
        tutor: tutor,
        password: _tutorPassword,
      );

      _setLoading(false);
      return true;
    } on Exception catch (e) {
      _setLoading(false);
      _errorMessage = _mapFirebaseError(e);
      return false;
    }
  }

  // ========== SIMPLE PARENT SIGNUP (single-step) ==========

  String _parentFullName = '';
  String _parentEmail = '';
  String _parentPassword = '';
  String _parentPhone = '';
  String _parentAddress = '';

  String get parentFullName => _parentFullName;
  String get parentEmail => _parentEmail;
  String get parentPassword => _parentPassword;
  String get parentPhone => _parentPhone;
  String get parentAddress => _parentAddress;

  void updateParentFullName(String value) {
    _parentFullName = value.trim();
    _errorMessage = null;
    notifyListeners();
  }

  void updateParentEmail(String value) {
    _parentEmail = value.trim();
    _errorMessage = null;
    notifyListeners();
  }

  void updateParentPassword(String value) {
    _parentPassword = value;
    _errorMessage = null;
    notifyListeners();
  }

  void updateParentPhone(String value) {
    _parentPhone = value.trim();
    _errorMessage = null;
    notifyListeners();
  }

  void updateParentAddress(String value) {
    _parentAddress = value.trim();
    _errorMessage = null;
    notifyListeners();
  }

  bool get canSubmitParentSignup =>
      _parentFullName.isNotEmpty &&
          _parentEmail.isNotEmpty &&
          _parentPassword.length >= 6 &&
          _parentPhone.isNotEmpty &&
          _parentAddress.isNotEmpty &&
          !_isLoading;

  Future<bool> registerParent() async {
    if (!canSubmitParentSignup) return false;

    try {
      _setLoading(true);
      _errorMessage = null;

      final baseUser = UserModel(
        userId: '',
        name: _parentFullName,
        email: _parentEmail,
        password: null,
        phone: _parentPhone,
        role: UserRole.parent,
        status: UserStatus.pending,
        latitude: null,
        longitude: null,
      );

      final parent = ParentModel(
        parentId: '',
        address: _parentAddress,
      );

      await _authRepository.registerParent(
        baseUser: baseUser,
        parent: parent,
        password: _parentPassword,
      );

      _setLoading(false);
      return true;
    } on Exception catch (e) {
      _setLoading(false);
      _errorMessage = _mapFirebaseError(e);
      return false;
    }
  }

  // ---------- LOGOUT ----------
  Future<bool> logout() async {
    try {
      _setLoading(true);
      await _authRepository.logout();
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _errorMessage = 'Failed to logout: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // ---------- Helpers ----------

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  String _mapFirebaseError(Exception e) {
    final message = e.toString();
    if (message.contains('email-already-in-use')) {
      return 'This email is already registered.';
    } else if (message.contains('weak-password')) {
      return 'Password is too weak.';
    } else if (message.contains('invalid-email')) {
      return 'Invalid email address.';
    }
    if (kDebugMode) {
      print('Firebase error: $message');
    }
    return 'Something went wrong. Please try again.';
  }
}
