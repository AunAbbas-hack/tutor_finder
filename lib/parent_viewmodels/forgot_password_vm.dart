// lib/parent_viewmodels/forgot_password_vm.dart
import 'package:flutter/foundation.dart';
import '../data/services/auth_services.dart';

class ForgotPasswordViewModel extends ChangeNotifier {
  final AuthService _authService;

  ForgotPasswordViewModel({AuthService? authService})
      : _authService = authService ?? AuthService();

  // State
  String _email = '';
  bool _isLoading = false;
  String? _errorMessage;
  bool _isEmailSent = false;

  // Getters
  String get email => _email;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isEmailSent => _isEmailSent;

  // Email validation
  bool get isValidEmail {
    if (_email.isEmpty) return false;
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(_email);
  }

  // Update email
  void updateEmail(String value) {
    _email = value.trim();
    _errorMessage = null;
    notifyListeners();
  }

  // Send reset link
  Future<bool> sendResetLink() async {
    if (!isValidEmail) {
      _errorMessage = 'Please enter a valid email address';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    _errorMessage = null;
    _isEmailSent = false;
    notifyListeners();

    try {
      await _authService.sendPasswordResetEmail(_email);
      _isEmailSent = true;
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _getErrorMessage(e.toString());
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Get user-friendly error message
  String _getErrorMessage(String error) {
    if (error.contains('user-not-found')) {
      return 'No account found with this email address';
    } else if (error.contains('invalid-email')) {
      return 'Invalid email address';
    } else if (error.contains('network')) {
      return 'Network error. Please check your connection';
    } else {
      return 'Failed to send reset link. Please try again';
    }
  }

  // Reset state
  void reset() {
    _email = '';
    _isLoading = false;
    _errorMessage = null;
    _isEmailSent = false;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}

