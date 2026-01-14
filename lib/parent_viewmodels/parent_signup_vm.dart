import 'package:flutter/foundation.dart';

import '../data/models/user_model.dart';
import '../data/models/student_model.dart';
import '../data/models/parent_model.dart';
import '../data/repositories/auth_repository.dart';
import '../data/services/notification_service.dart';

enum ParentSignupStep {
  account,      // Step 1: parent account (already made)
  childDetails, // Step 2: this reply
  preferences,  // Step 3: this reply
  summary,      // Step 4: later
}

class ParentSignupViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;

  ParentSignupViewModel({AuthRepository? authRepository})
      : _authRepository = authRepository ?? AuthRepository();

  // ------------- STEP CONTROL -------------

  ParentSignupStep _currentStep = ParentSignupStep.account;

  ParentSignupStep get currentStep => _currentStep;
  int get currentStepIndex => ParentSignupStep.values.indexOf(_currentStep);
  int get totalSteps => ParentSignupStep.values.length;

  bool get isFirstStep => _currentStep == ParentSignupStep.account;
  bool get isLastStep => _currentStep == ParentSignupStep.summary;

  void goToStep(ParentSignupStep step) {
    _currentStep = step;
    notifyListeners();
  }

  void nextStep() {
    final currentIndex = currentStepIndex;
    if (currentIndex < totalSteps - 1) {
      _currentStep = ParentSignupStep.values[currentIndex + 1];
      notifyListeners();
    }
  }

  void previousStep() {
    final currentIndex = currentStepIndex;
    if (currentIndex > 0) {
      _currentStep = ParentSignupStep.values[currentIndex - 1];
      notifyListeners();
    }
  }

  // ------------- COMMON STATE -------------

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ------------- STEP 1: ACCOUNT INFO -------------

  String _parentName = '';
  String _email = '';
  String _password = '';
  String _confirmPassword = '';
  String _phone = '';
  String? _parentNameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;
  String? _phoneError;

  String get parentName => _parentName;
  String get email => _email;
  String get password => _password;
  String get confirmPassword => _confirmPassword;
  String get phone => _phone;
  String? get parentNameError => _parentNameError;
  String? get emailError => _emailError;
  String? get passwordError => _passwordError;
  String? get confirmPasswordError => _confirmPasswordError;
  String? get phoneError => _phoneError;

  void updateParentName(String value) {
    _parentName = value.trim();
    clearError();
    _parentNameError = _validateParentName(_parentName);
    notifyListeners();
  }

  void updateEmail(String value) {
    _email = value.trim();
    clearError();
    _emailError = _validateEmail(_email);
    notifyListeners();
  }

  void updatePassword(String value) {
    _password = value;
    clearError();
    _passwordError = _validatePassword(_password);
    // Revalidate confirm password if it's not empty
    if (_confirmPassword.isNotEmpty) {
      _confirmPasswordError = _validateConfirmPassword(_confirmPassword, _password);
    }
    notifyListeners();
  }

  void updateConfirmPassword(String value) {
    _confirmPassword = value;
    clearError();
    _confirmPasswordError = _validateConfirmPassword(_confirmPassword, _password);
    notifyListeners();
  }

  void updatePhone(String value) {
    _phone = value.trim();
    clearError();
    _phoneError = _validatePhone(_phone);
    notifyListeners();
  }

  String? _validateParentName(String value) {
    if (value.isEmpty) return null;
    return null;
  }

  String? _validateEmail(String value) {
    if (value.isEmpty) return null;
    // Email regex pattern: xxx@xxx.xx format
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address.';
    }
    return null;
  }

  String? _validatePassword(String value) {
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

  String? _validateConfirmPassword(String value, String password) {
    if (value.isEmpty) return null;
    if (value != password) {
      return 'Passwords do not match.';
    }
    return null;
  }

  String? _validatePhone(String value) {
    if (value.isEmpty) return null;
    return null;
  }

  bool get isStep1Valid {
    if (_parentName.isEmpty ||
        _email.isEmpty ||
        _password.isEmpty ||
        _confirmPassword.isEmpty ||
        _phone.isEmpty) {
      return false;
    }
    // Use regex for email validation
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$');
    if (!emailRegex.hasMatch(_email)) return false;
    if (_password.length < 8) return false;
    if (_password != _confirmPassword) return false;
    // Check strong password requirements
    if (!_password.contains(RegExp(r'[A-Z]'))) return false;
    if (!_password.contains(RegExp(r'[0-9]'))) return false;
    if (!_password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) return false;
    return true;
  }

  bool continueFromStep1() {
    // Validate all fields
    _parentNameError = _parentName.isEmpty ? 'Full name is required.' : null;
    _emailError = _email.isEmpty 
        ? 'Email is required.' 
        : _validateEmail(_email);
    _passwordError = _password.isEmpty 
        ? 'Password is required.' 
        : _validatePassword(_password);
    _confirmPasswordError = _confirmPassword.isEmpty 
        ? 'Please confirm your password.' 
        : (_confirmPassword == _password ? null : 'Passwords do not match.');
    _phoneError = _phone.isEmpty ? 'Phone number is required.' : null;
    
    if (_parentNameError != null || 
        _emailError != null || 
        _passwordError != null || 
        _confirmPasswordError != null || 
        _phoneError != null) {
      notifyListeners();
      return false;
    }
    
    _errorMessage = null;
    nextStep();
    return true;
  }

  // ------------- STEP 2: CHILD DETAILS -------------

  String _childName = '';
  String _childGrade = '';
  String _childSchool = '';
  String? _childNameError;
  String? _childGradeError;
  String? _childSchoolError;

  String get childName => _childName;
  String get childGrade => _childGrade;
  String get childSchool => _childSchool;
  String? get childNameError => _childNameError;
  String? get childGradeError => _childGradeError;
  String? get childSchoolError => _childSchoolError;

  void updateChildName(String value) {
    _childName = value.trim();
    clearError();
    _childNameError = _validateChildName(_childName);
    notifyListeners();
  }

  void updateChildGrade(String value) {
    _childGrade = value.trim();
    clearError();
    _childGradeError = _validateChildGrade(_childGrade);
    notifyListeners();
  }

  void updateChildSchool(String value) {
    _childSchool = value.trim();
    clearError();
    _childSchoolError = _validateChildSchool(_childSchool);
    notifyListeners();
  }

  String? _validateChildName(String value) {
    if (value.isEmpty) return null;
    return null;
  }

  String? _validateChildGrade(String value) {
    if (value.isEmpty) return null;
    return null;
  }

  String? _validateChildSchool(String value) {
    if (value.isEmpty) return null;
    return null;
  }

  bool get isStep2Valid {
    return _childName.isNotEmpty &&
        _childGrade.isNotEmpty &&
        _childSchool.isNotEmpty;
  }

  bool continueFromStep2() {
    // Validate all fields
    _childNameError = _childName.isEmpty ? 'Child\'s name is required.' : null;
    _childGradeError = _childGrade.isEmpty ? 'Grade/Class is required.' : null;
    _childSchoolError = _childSchool.isEmpty ? 'School/College is required.' : null;
    
    if (_childNameError != null || _childGradeError != null || _childSchoolError != null) {
      notifyListeners();
      return false;
    }
    
    _errorMessage = null;
    nextStep();
    return true;
  }

  // ------------- STEP 3: PREFERENCES / ADDRESS -------------

  String _address = '';
  String _notes = '';
  String? _addressError;

  String get address => _address;
  String get notes => _notes;
  String? get addressError => _addressError;

  void updateAddress(String value) {
    _address = value.trim();
    clearError();
    _addressError = _validateAddress(_address);
    notifyListeners();
  }

  void updateNotes(String value) {
    _notes = value.trim();
    clearError();
    notifyListeners();
  }

  String? _validateAddress(String value) {
    if (value.isEmpty) return null;
    return null;
  }

  bool get isStep3Valid => _address.isNotEmpty;

  bool continueFromStep3() {
    // Validate address field
    _addressError = _address.isEmpty ? 'Address is required.' : null;
    
    if (_addressError != null) {
      notifyListeners();
      return false;
    }
    
    _errorMessage = null;
    nextStep(); // goes to summary
    return true;
  }

  // ------------- BUILD MODELS (for final submit) -------------

  UserModel buildParentUserBase({double? latitude, double? longitude}) {
    return UserModel(
      userId: '',
      name: _parentName,
      email: _email,
      password: null,
      phone: _phone,
      role: UserRole.parent,
      status: UserStatus.pending,
      latitude: latitude,
      longitude: longitude,
    );
  }

  ParentModel buildParentModel(String userId) {
    return ParentModel(
      parentId: userId,
      address: _address,
    );
  }

  StudentModel buildStudentModel(String userId, {String? parentId}) {
    return StudentModel(
      studentId: userId,
      parentId: parentId ?? userId, // Default to userId if parentId not provided (for signup, studentId = parentId initially)
      schoolCollege: _childSchool,
      grade: _childGrade,
    );
  }

  String get parentAddress => _address;

  // ------------- COMPLETE PARENT SIGNUP SUBMIT -------------
  /// Location step se call hoga with latitude/longitude
  Future<bool> submitParentSignup({
    double? latitude,
    double? longitude,
  }) async {
    if (!isStep1Valid || !isStep2Valid || !isStep3Valid) {
      _errorMessage = 'Please complete all steps.';
      notifyListeners();
      return false;
    }

    if (kDebugMode) {
      print('📍 ParentSignupViewModel.submitParentSignup:');
      print('   Received latitude: $latitude');
      print('   Received longitude: $longitude');
    }

    try {
      _setLoading(true);
      _errorMessage = null;

      final baseUser = buildParentUserBase(
        latitude: latitude,
        longitude: longitude,
      );
      
      if (kDebugMode) {
        print('📍 Built baseUser:');
        print('   UserModel latitude: ${baseUser.latitude}');
        print('   UserModel longitude: ${baseUser.longitude}');
      }
      
      final parent = buildParentModel('');
      final student = buildStudentModel('');

      final user = await _authRepository.registerParentWithStudent(
        baseUser: baseUser,
        parent: parent,
        student: student,
        password: _password,
        childName: _childName, // Pass child name for UserModel
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
    } catch (e) {
      _setLoading(false);
      _errorMessage = e.toString().contains('email-already-in-use')
          ? 'This email is already registered.'
          : 'Something went wrong. Please try again.';
      notifyListeners();
      return false;
    }
  }
}
