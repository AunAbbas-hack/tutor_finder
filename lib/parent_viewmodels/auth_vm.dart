import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/models/user_model.dart';
import '../data/models/tutor_model.dart';
import '../data/models/parent_model.dart';
import '../data/repositories/auth_repository.dart';
import '../data/services/fcm_service.dart';
import '../data/services/notification_service.dart';
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
  String? _emailOrPhoneError;
  String? _passwordError;

  String get emailOrPhone => _emailOrPhone;
  String get password => _password;
  bool get isPasswordVisible => _isPasswordVisible;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get emailOrPhoneError => _emailOrPhoneError;
  String? get passwordError => _passwordError;

  void updateEmailOrPhone(String value) {
    if (_isDisposed) return;
    _emailOrPhone = value.trim();
    _errorMessage = null;
    _emailOrPhoneError = _validateEmailOrPhone(_emailOrPhone);
    _safeNotifyListeners();
  }

  void updatePassword(String value) {
    if (_isDisposed) return;
    _password = value;
    _errorMessage = null;
    _passwordError = _validatePassword(_password);
    _safeNotifyListeners();
  }

  String? _validateEmailOrPhone(String value) {
    if (value.isEmpty) return null;
    // Email regex pattern: xxx@xxx.xx format
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address.';
    }
    return null;
  }

  String? _validatePassword(String value) {
    // Login password validation - just check if not empty
    if (value.isEmpty) return null;
    return null;
  }

  String? _validateStrongPassword(String value) {
    // Strong password validation for signup
    if (value.isEmpty) return null;
    
    if (value.length < 8) {
      return 'Password must be at least 8 characters long.';
    }
    
    // Check for capital letter
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one capital letter.';
    }
    
    // Check for number
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number.';
    }
    
    // Check for special symbol
    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain at least one special symbol.';
    }
    
    return null;
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
    
    // Validate fields
    _emailOrPhoneError = _validateEmailOrPhone(_emailOrPhone);
    _passwordError = _validatePassword(_password);
    
    if (_emailOrPhone.isEmpty) {
      _emailOrPhoneError = 'Email is required.';
    }
    if (_password.isEmpty) {
      _passwordError = 'Password is required.';
    }
    
    if (_emailOrPhoneError != null || _passwordError != null) {
      _safeNotifyListeners();
      return false;
    }
    
    if (_isDisposed) return false;

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

      // Initialize FCM token after successful login
      try {
        final fcmService = FCMService();
        await fcmService.initializeToken();
      } catch (e) {
        // Don't fail login if FCM initialization fails
        if (kDebugMode) {
          print('⚠️ Failed to initialize FCM token: $e');
        }
      }

      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      // #region agent log
      await DebugLogger.log(location: 'auth_vm.dart:87', message: 'Parent login failed', data: {'email': _emailOrPhone, 'error': e.code}, hypothesisId: 'AUTH-1');
      // #endregion
      if (!_isDisposed) {
        _setLoading(false);
        _errorMessage = _mapFirebaseAuthError(e);
        _safeNotifyListeners();
      }
      return false;
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
  String _tutorConfirmPassword = '';
  String _tutorPhone = '';
  String _tutorSubjectsExp = '';
  String? _tutorFullNameError;
  String? _tutorEmailError;
  String? _tutorPasswordError;
  String? _tutorConfirmPasswordError;
  String? _tutorPhoneError;
  String? _tutorSubjectsExpError;

  String get tutorFullName => _tutorFullName;
  String get tutorEmail => _tutorEmail;
  String get tutorPassword => _tutorPassword;
  String get tutorConfirmPassword => _tutorConfirmPassword;
  String get tutorPhone => _tutorPhone;
  String get tutorSubjectsExp => _tutorSubjectsExp;
  String? get tutorFullNameError => _tutorFullNameError;
  String? get tutorEmailError => _tutorEmailError;
  String? get tutorPasswordError => _tutorPasswordError;
  String? get tutorConfirmPasswordError => _tutorConfirmPasswordError;
  String? get tutorPhoneError => _tutorPhoneError;
  String? get tutorSubjectsExpError => _tutorSubjectsExpError;

  void updateTutorFullName(String value) {
    if (_isDisposed) return;
    _tutorFullName = value.trim();
    _errorMessage = null;
    _tutorFullNameError = _validateTutorFullName(_tutorFullName);
    _safeNotifyListeners();
  }

  void updateTutorEmail(String value) {
    if (_isDisposed) return;
    _tutorEmail = value.trim();
    _errorMessage = null;
    _tutorEmailError = _validateTutorEmail(_tutorEmail);
    _safeNotifyListeners();
  }

  void updateTutorPassword(String value) {
    if (_isDisposed) return;
    _tutorPassword = value;
    _errorMessage = null;
    _tutorPasswordError = _validateTutorPassword(_tutorPassword);
    // Re-validate confirm password when password changes
    if (_tutorConfirmPassword.isNotEmpty) {
      _tutorConfirmPasswordError = _validateTutorConfirmPassword(_tutorConfirmPassword);
    }
    _safeNotifyListeners();
  }

  void updateTutorConfirmPassword(String value) {
    if (_isDisposed) return;
    _tutorConfirmPassword = value;
    _errorMessage = null;
    _tutorConfirmPasswordError = _validateTutorConfirmPassword(_tutorConfirmPassword);
    _safeNotifyListeners();
  }

  void updateTutorPhone(String value) {
    if (_isDisposed) return;
    _tutorPhone = value.trim();
    _errorMessage = null;
    _tutorPhoneError = _validateTutorPhone(_tutorPhone);
    _safeNotifyListeners();
  }

  void updateTutorSubjectsExp(String value) {
    if (_isDisposed) return;
    _tutorSubjectsExp = value.trim();
    _errorMessage = null;
    _tutorSubjectsExpError = _validateTutorSubjectsExp(_tutorSubjectsExp);
    _safeNotifyListeners();
  }

  String? _validateTutorFullName(String value) {
    if (value.isEmpty) return null;
    return null;
  }

  String? _validateTutorEmail(String value) {
    if (value.isEmpty) return null;
    // Email regex pattern: xxx@xxx.xx format
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address.';
    }
    return null;
  }

  String? _validateTutorPassword(String value) {
    return _validateStrongPassword(value);
  }

  String? _validateTutorConfirmPassword(String value) {
    if (value.isEmpty) return null;
    if (value != _tutorPassword) {
      return 'Passwords do not match.';
    }
    return null;
  }

  String? _validateTutorPhone(String value) {
    if (value.isEmpty) return null;
    return null;
  }

  String? _validateTutorSubjectsExp(String value) {
    if (value.isEmpty) return null;
    return null;
  }

  bool get canSubmitTutorSignup =>
      _tutorFullName.isNotEmpty &&
          _tutorEmail.isNotEmpty &&
          _tutorPassword.length >= 8 &&
          _tutorPhone.isNotEmpty &&
          _tutorSubjectsExp.isNotEmpty &&
          !_isLoading;

  Future<bool> registerTutor() async {
    // Validate all fields
    _tutorFullNameError = _tutorFullName.isEmpty ? 'Full name is required.' : null;
    _tutorEmailError = _tutorEmail.isEmpty 
        ? 'Email is required.' 
        : _validateTutorEmail(_tutorEmail);
    _tutorPasswordError = _tutorPassword.isEmpty 
        ? 'Password is required.' 
        : _validateStrongPassword(_tutorPassword);
    _tutorConfirmPasswordError = _tutorConfirmPassword.isEmpty 
        ? 'Please confirm your password.' 
        : _validateTutorConfirmPassword(_tutorConfirmPassword);
    _tutorPhoneError = _tutorPhone.isEmpty ? 'Phone number is required.' : null;
    _tutorSubjectsExpError = _tutorSubjectsExp.isEmpty ? 'Subjects & experience is required.' : null;
    
    if (_tutorFullNameError != null || 
        _tutorEmailError != null || 
        _tutorPasswordError != null || 
        _tutorConfirmPasswordError != null ||
        _tutorPhoneError != null || 
        _tutorSubjectsExpError != null) {
      _safeNotifyListeners();
      return false;
    }
    
    if (_isDisposed) return false;

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

      final user = await _authRepository.registerTutor(
        baseUser: baseUser,
        tutor: tutor,
        password: _tutorPassword,
      );

      // Initialize FCM token after successful signup
      if (user != null) {
        try {
          final fcmService = FCMService();
          await fcmService.initializeToken();
          
          if (kDebugMode) {
            print('✅ FCM token initialized for new tutor: ${user.uid}');
          }
          
          // Wait a moment for Firestore to propagate the token
          await Future.delayed(const Duration(milliseconds: 1500));
        } catch (e) {
          // Don't fail signup if FCM initialization fails
          if (kDebugMode) {
            print('⚠️ Failed to initialize FCM token: $e');
          }
        }

        // Send profile under review notification
        try {
          final notificationService = NotificationService();
          
          if (kDebugMode) {
            print('📤 Sending profile under review notification to tutor: ${user.uid}');
          }
          
          await notificationService.sendProfileUnderReviewToTutor(
            tutorId: user.uid,
          );
          
          if (kDebugMode) {
            print('✅ Profile under review notification sent successfully');
          }
        } catch (e) {
          // Don't fail signup if notification fails
          if (kDebugMode) {
            print('⚠️ Failed to send profile under review notification: $e');
          }
        }
      }

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

      final user = await _authRepository.registerParent(
        baseUser: baseUser,
        parent: parent,
        password: _parentPassword,
      );

      // Send welcome notification
      if (user != null) {
        try {
          final notificationService = NotificationService();
          await notificationService.sendWelcomeNotificationToParent(
            parentId: user.uid,
          );
        } catch (e) {
          // Don't fail signup if notification fails
          if (kDebugMode) {
            print('⚠️ Failed to send welcome notification: $e');
          }
        }
      }

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

  String _mapFirebaseAuthError(FirebaseAuthException e) {
    // Check error code - order matters! Check user-not-found FIRST
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email address. Please sign up first.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-credential':
        // In newer Firebase versions, invalid-credential can mean either user-not-found or wrong-password
        // Since we can't differentiate, show a generic message
        return 'Invalid email or password. Please check your credentials.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'weak-password':
        return 'Password is too weak.';
      default:
        if (kDebugMode) {
          print('Firebase Auth error code: ${e.code}');
          print('Firebase Auth error message: ${e.message}');
        }
        return 'Something went wrong. Please try again.';
    }
  }

  String _mapFirebaseError(Exception e) {
    final message = e.toString();
    if (message.contains('email-already-in-use')) {
      return 'This email is already registered.';
    } else if (message.contains('weak-password')) {
      return 'Password is too weak.';
    } else if (message.contains('invalid-email')) {
      return 'Invalid email address.';
    } else if (message.contains('wrong-password') || message.contains('invalid-credential')) {
      return 'Incorrect password. Please try again.';
    } else if (message.contains('user-not-found')) {
      return 'No account found with this email address. Please sign up first.';
    } else if (message.contains('user-disabled')) {
      return 'This account has been disabled. Please contact support.';
    } else if (message.contains('too-many-requests')) {
      return 'Too many failed attempts. Please try again later.';
    }
    if (kDebugMode) {
      print('Firebase error: $message');
    }
    return 'Something went wrong. Please try again.';
  }
}
