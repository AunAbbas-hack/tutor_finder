// lib/admin_viewmodels/admin_settings_vm.dart
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/models/user_model.dart';
import '../data/services/user_services.dart';
import '../data/repositories/auth_repository.dart';

class AdminSettingsViewModel extends ChangeNotifier {
  final UserService _userService;
  final FirebaseAuth _auth;
  final AuthRepository _authRepository;

  AdminSettingsViewModel({
    UserService? userService,
    FirebaseAuth? auth,
    AuthRepository? authRepository,
  })  : _userService = userService ?? UserService(),
        _auth = auth ?? FirebaseAuth.instance,
        _authRepository = authRepository ?? AuthRepository();

  // ---------- State ----------
  bool _isLoading = false;
  String? _errorMessage;
  UserModel? _user;
  
  // Profile fields
  String _name = '';
  String _email = '';
  String? _phone;
  String? _imageUrl;

  // Notification settings
  bool _pushNotificationsEnabled = false;
  bool _emailNotificationsEnabled = true;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  UserModel? get user => _user;
  String get name => _name;
  String get email => _email;
  String? get phone => _phone;
  String? get imageUrl => _imageUrl;
  bool get pushNotificationsEnabled => _pushNotificationsEnabled;
  bool get emailNotificationsEnabled => _emailNotificationsEnabled;

  // ---------- Initialize ----------
  Future<void> initialize() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        _errorMessage = 'User not authenticated';
        _setLoading(false);
        return;
      }

      final userModel = await _userService.getUserById(currentUser.uid);
      if (userModel != null) {
        _user = userModel;
        _name = userModel.name;
        _email = userModel.email;
        _phone = userModel.phone;
        _imageUrl = userModel.imageUrl;
        
        // Load notification preferences
        // TODO: Load from SharedPreferences or Firestore
      } else {
        _errorMessage = 'User data not found';
      }
    } catch (e) {
      _errorMessage = 'Failed to load profile: ${e.toString()}';
    } finally {
      _setLoading(false);
    }
  }

  // ---------- Notification Settings ----------
  void togglePushNotifications(bool value) {
    _pushNotificationsEnabled = value;
    notifyListeners();
    // TODO: Save to SharedPreferences or Firestore
  }

  void toggleEmailNotifications(bool value) {
    _emailNotificationsEnabled = value;
    notifyListeners();
    // TODO: Save to SharedPreferences or Firestore
  }

  // ---------- Logout ----------
  Future<bool> logout() async {
    try {
      _setLoading(true);
      await _authRepository.logout();
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to logout: ${e.toString()}';
      _setLoading(false);
      return false;
    }
  }

  // ---------- Helpers ----------
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Get app version
  String get appVersion => '1.0.0'; // TODO: Get from package_info_plus
}