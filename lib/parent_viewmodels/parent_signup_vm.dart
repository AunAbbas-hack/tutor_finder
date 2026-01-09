import 'package:flutter/foundation.dart';

import '../data/models/user_model.dart';
import '../data/models/student_model.dart';
import '../data/models/parent_model.dart';
import '../data/repositories/auth_repository.dart';

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

  String get parentName => _parentName;
  String get email => _email;
  String get password => _password;
  String get confirmPassword => _confirmPassword;
  String get phone => _phone;

  void updateParentName(String value) {
    _parentName = value.trim();
    clearError();
  }

  void updateEmail(String value) {
    _email = value.trim();
    clearError();
  }

  void updatePassword(String value) {
    _password = value;
    clearError();
  }

  void updateConfirmPassword(String value) {
    _confirmPassword = value;
    clearError();
  }

  void updatePhone(String value) {
    _phone = value.trim();
    clearError();
  }

  bool get isStep1Valid {
    if (_parentName.isEmpty ||
        _email.isEmpty ||
        _password.isEmpty ||
        _confirmPassword.isEmpty ||
        _phone.isEmpty) {
      return false;
    }
    if (!_email.contains('@')) return false;
    if (_password.length < 6) return false;
    if (_password != _confirmPassword) return false;
    return true;
  }

  bool continueFromStep1() {
    if (!isStep1Valid) {
      if (_parentName.isEmpty ||
          _email.isEmpty ||
          _password.isEmpty ||
          _confirmPassword.isEmpty ||
          _phone.isEmpty) {
        _errorMessage = 'Please fill all fields.';
      } else if (!_email.contains('@')) {
        _errorMessage = 'Please enter a valid email address.';
      } else if (_password.length < 6) {
        _errorMessage = 'Password must be at least 6 characters.';
      } else if (_password != _confirmPassword) {
        _errorMessage = 'Passwords do not match.';
      } else {
        _errorMessage = 'Please check your details.';
      }
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

  String get childName => _childName;
  String get childGrade => _childGrade;
  String get childSchool => _childSchool;

  void updateChildName(String value) {
    _childName = value.trim();
    clearError();
  }

  void updateChildGrade(String value) {
    _childGrade = value.trim();
    clearError();
  }

  void updateChildSchool(String value) {
    _childSchool = value.trim();
    clearError();
  }

  bool get isStep2Valid {
    return _childName.isNotEmpty &&
        _childGrade.isNotEmpty &&
        _childSchool.isNotEmpty;
  }

  bool continueFromStep2() {
    if (!isStep2Valid) {
      _errorMessage = 'Please enter your child\'s details.';
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

  String get address => _address;
  String get notes => _notes;

  void updateAddress(String value) {
    _address = value.trim();
    clearError();
  }

  void updateNotes(String value) {
    _notes = value.trim();
    clearError();
  }

  bool get isStep3Valid => _address.isNotEmpty;

  bool continueFromStep3() {
    if (!isStep3Valid) {
      _errorMessage = 'Please enter your address.';
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

      await _authRepository.registerParentWithStudent(
        baseUser: baseUser,
        parent: parent,
        student: student,
        password: _password,
      );

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
