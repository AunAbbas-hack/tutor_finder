import 'package:flutter/foundation.dart';

import '../data/models/user_model.dart';
import '../data/models/tutor_model.dart';
import '../data/models/parent_model.dart';
import '../data/repositories/auth_repository.dart';
import '../core/utils/debug_logger.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;
  bool _isDisposed = false;

  AuthViewModel({AuthRepository? authRepository})
      : _authRepository = authRepository ?? AuthRepository();

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  // Safe notify listeners - won't throw if disposed
  void _safeNotifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  // ---------- Role Selection ----------
  UserRole? _selectedRole;
  UserRole? get selectedRole => _selectedRole;

  void selectRole(UserRole role) {
    if (_isDisposed) return;
    _selectedRole = role;
    _safeNotifyListeners();
  }

  void clearRole() {
    if (_isDisposed) return;
    _selectedRole = null;
    _safeNotifyListeners();
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
    if (_isDisposed) return;
    _emailOrPhone = value.trim();
    _errorMessage = null;
    _safeNotifyListeners();
  }

  void updatePassword(String value) {
    if (_isDisposed) return;
    _password = value;
    _errorMessage = null;
    _safeNotifyListeners();
  }

  void togglePasswordVisibility() {
    if (_isDisposed) return;
    _isPasswordVisible = !_isPasswordVisible;
    _safeNotifyListeners();
  }

  bool get canSubmitLogin =>
      _emailOrPhone.isNotEmpty && _password.isNotEmpty && !_isLoading;

  Future<bool> login() async {
    // #region agent log
    await DebugLogger.log(location: 'auth_vm.dart:63', message: 'Parent login attempt', data: {'email': _emailOrPhone, 'hasPassword': _password.isNotEmpty}, hypothesisId: 'AUTH-1');
    // #endregion
    if (!canSubmitLogin) return false;

    if (!_emailOrPhone.contains('@')) {
      if (_isDisposed) return false;
      _errorMessage = 'Please enter a valid email address.';
      _safeNotifyListeners();
      return false;
    }

    try {
      _setLoading(true);
      _errorMessage = null;

      await _authRepository.loginWithEmail(
        email: _emailOrPhone,
        password: _password,
      );

      // #region agent log
      await DebugLogger.log(location: 'auth_vm.dart:82', message: 'Parent login success', data: {'email': _emailOrPhone}, hypothesisId: 'AUTH-1');
      // #endregion
      _setLoading(false);
      return true;
    } on Exception catch (e) {
      // #region agent log
      await DebugLogger.log(location: 'auth_vm.dart:87', message: 'Parent login failed', data: {'email': _emailOrPhone, 'error': e.toString()}, hypothesisId: 'AUTH-1');
      // #endregion
      if (!_isDisposed) {
        _setLoading(false);
        _errorMessage = _mapFirebaseError(e);
        _safeNotifyListeners();
      }
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
    if (_isDisposed) return;
    _tutorFullName = value.trim();
    _errorMessage = null;
    _safeNotifyListeners();
  }

  void updateTutorEmail(String value) {
    if (_isDisposed) return;
    _tutorEmail = value.trim();
    _errorMessage = null;
    _safeNotifyListeners();
  }

  void updateTutorPassword(String value) {
    if (_isDisposed) return;
    _tutorPassword = value;
    _errorMessage = null;
    _safeNotifyListeners();
  }

  void updateTutorPhone(String value) {
    if (_isDisposed) return;
    _tutorPhone = value.trim();
    _errorMessage = null;
    _safeNotifyListeners();
  }

  void updateTutorSubjectsExp(String value) {
    if (_isDisposed) return;
    _tutorSubjectsExp = value.trim();
    _errorMessage = null;
    _safeNotifyListeners();
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
      if (!_isDisposed) {
        _setLoading(false);
        _errorMessage = _mapFirebaseError(e);
        _safeNotifyListeners();
      }
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
    if (_isDisposed) return;
    _parentFullName = value.trim();
    _errorMessage = null;
    _safeNotifyListeners();
  }

  void updateParentEmail(String value) {
    if (_isDisposed) return;
    _parentEmail = value.trim();
    _errorMessage = null;
    _safeNotifyListeners();
  }

  void updateParentPassword(String value) {
    if (_isDisposed) return;
    _parentPassword = value;
    _errorMessage = null;
    _safeNotifyListeners();
  }

  void updateParentPhone(String value) {
    if (_isDisposed) return;
    _parentPhone = value.trim();
    _errorMessage = null;
    _safeNotifyListeners();
  }

  void updateParentAddress(String value) {
    if (_isDisposed) return;
    _parentAddress = value.trim();
    _errorMessage = null;
    _safeNotifyListeners();
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
      if (!_isDisposed) {
        _setLoading(false);
        _errorMessage = _mapFirebaseError(e);
        _safeNotifyListeners();
      }
      return false;
    }
  }

  // ---------- LOGOUT ----------
  Future<bool> logout() async {
    try {
      _setLoading(true);
      await _authRepository.logout();
      if (!_isDisposed) {
        _setLoading(false);
      }
      return true;
    } catch (e) {
      if (!_isDisposed) {
        _setLoading(false);
        _errorMessage = 'Failed to logout: ${e.toString()}';
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
