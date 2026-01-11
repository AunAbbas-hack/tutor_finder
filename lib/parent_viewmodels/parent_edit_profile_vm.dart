// lib/parent_viewmodels/parent_edit_profile_vm.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/models/user_model.dart';
import '../data/models/parent_model.dart';
import '../data/services/user_services.dart';
import '../data/services/parent_services.dart';
import '../core/services/storage_service_cloudinary.dart';
import '../core/services/image_picker_service.dart';
import '../core/utils/debug_logger.dart';

class ParentEditProfileViewModel extends ChangeNotifier {
  final UserService _userService;
  final ParentService _parentService;
  final FirebaseAuth _auth;
  final StorageService _storageService;
  final ImagePickerService _imagePickerService;

  ParentEditProfileViewModel({
    UserService? userService,
    ParentService? parentService,
    FirebaseAuth? auth,
    StorageService? storageService,
    ImagePickerService? imagePickerService,
  })  : _userService = userService ?? UserService(),
        _parentService = parentService ?? ParentService(),
        _auth = auth ?? FirebaseAuth.instance,
        _storageService = storageService ?? StorageService(),
        _imagePickerService = imagePickerService ?? ImagePickerService();

  // ---------- State ----------
  bool _isLoading = false;
  String? _errorMessage;
  UserModel? _user;
  ParentModel? _parent;
  double? _latitude;
  double? _longitude;

  // Editable fields
  String _fullName = '';
  String _email = '';
  String _location = '';
  String? _imageUrl;
  File? _selectedImageFile;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get fullName => _fullName;
  String get email => _email;
  String get location => _location;
  String? get imageUrl => _imageUrl;
  File? get selectedImageFile => _selectedImageFile;
  double? get latitude => _latitude;
  double? get longitude => _longitude;
  bool get hasChanges => _hasChanges();

  // ---------- Initialize ----------
  Future<void> initialize() async {
    // #region agent log
    await DebugLogger.log(location: 'parent_edit_profile_vm.dart:50', message: 'Initializing edit profile', data: {'userId': _auth.currentUser?.uid}, hypothesisId: 'EDIT-PROFILE-1');
    // #endregion
    _setLoading(true);
    _errorMessage = null;

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        _errorMessage = 'User not authenticated';
        _setLoading(false);
        return;
      }

      // Load user data
      _user = await _userService.getUserById(currentUser.uid);
      // #region agent log
      await DebugLogger.log(location: 'parent_edit_profile_vm.dart:63', message: 'User data loaded', data: {'found': _user != null, 'name': _user?.name}, hypothesisId: 'EDIT-PROFILE-1');
      // #endregion
      if (_user != null) {
        _fullName = _user!.name;
        _email = _user!.email;
        _imageUrl = _user!.imageUrl;
        _latitude = _user!.latitude;
        _longitude = _user!.longitude;
      }

      // Load parent data for address
      _parent = await _parentService.getParentById(currentUser.uid);
      // #region agent log
      await DebugLogger.log(location: 'parent_edit_profile_vm.dart:72', message: 'Parent data loaded', data: {'found': _parent != null, 'address': _parent?.address}, hypothesisId: 'EDIT-PROFILE-1');
      // #endregion
      if (_parent != null) {
        _location = _parent!.address;
      }

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      // #region agent log
      await DebugLogger.log(location: 'parent_edit_profile_vm.dart:80', message: 'Error initializing edit profile', data: {'error': e.toString()}, hypothesisId: 'EDIT-PROFILE-1');
      // #endregion
      _errorMessage = 'Failed to load profile: ${e.toString()}';
      _setLoading(false);
      notifyListeners();
    }
  }

  // ---------- Update Fields ----------
  void updateFullName(String value) {
    _fullName = value.trim();
    notifyListeners();
  }

  void updateLocation(String value, {double? latitude, double? longitude}) {
    _location = value.trim();
    if (latitude != null && longitude != null) {
      _latitude = latitude;
      _longitude = longitude;
    }
    notifyListeners();
  }

  void updateSelectedImage(File imageFile) {
    _selectedImageFile = imageFile;
    notifyListeners();
  }

  // ---------- Image Picker ----------
  Future<void> pickImage() async {
    // #region agent log
    await DebugLogger.log(location: 'parent_edit_profile_vm.dart:100', message: 'Pick image called', data: {}, hypothesisId: 'EDIT-PROFILE-2');
    // #endregion
    try {
      final imageFile = await _imagePickerService.pickImage();
      if (imageFile != null) {
        _selectedImageFile = imageFile;
        // #region agent log
        await DebugLogger.log(location: 'parent_edit_profile_vm.dart:106', message: 'Image selected', data: {'path': imageFile.path}, hypothesisId: 'EDIT-PROFILE-2');
        // #endregion
        notifyListeners();
      }
    } catch (e) {
      // #region agent log
      await DebugLogger.log(location: 'parent_edit_profile_vm.dart:111', message: 'Error picking image', data: {'error': e.toString()}, hypothesisId: 'EDIT-PROFILE-2');
      // #endregion
      _errorMessage = 'Failed to pick image: ${e.toString()}';
      notifyListeners();
    }
  }

  // ---------- Save Profile ----------
  Future<bool> saveProfile() async {
    // #region agent log
    await DebugLogger.log(location: 'parent_edit_profile_vm.dart:119', message: 'Save profile called', data: {'hasImage': _selectedImageFile != null, 'name': _fullName, 'location': _location}, hypothesisId: 'EDIT-PROFILE-3');
    // #endregion
    if (_user == null) {
      _errorMessage = 'User data not loaded';
      notifyListeners();
      return false;
    }

    // Validate
    if (_fullName.isEmpty) {
      _errorMessage = 'Full name is required';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    _errorMessage = null;

    try {
      String? newImageUrl = _imageUrl;

      // Upload image if selected
      if (_selectedImageFile != null) {
        // #region agent log
        await DebugLogger.log(location: 'parent_edit_profile_vm.dart:138', message: 'Uploading image', data: {}, hypothesisId: 'EDIT-PROFILE-3');
        // #endregion
        final uploadedUrl = await _storageService.uploadImageFile(
          imageFile: _selectedImageFile!,
          folderPath: 'profile_pictures',
        );
        if (uploadedUrl != null) {
          newImageUrl = uploadedUrl;
          // #region agent log
          await DebugLogger.log(location: 'parent_edit_profile_vm.dart:146', message: 'Image uploaded successfully', data: {'url': uploadedUrl}, hypothesisId: 'EDIT-PROFILE-3');
          // #endregion
        } else {
          // #region agent log
          await DebugLogger.log(location: 'parent_edit_profile_vm.dart:149', message: 'Image upload failed', data: {}, hypothesisId: 'EDIT-PROFILE-3');
          // #endregion
          _errorMessage = 'Failed to upload image';
          _setLoading(false);
          notifyListeners();
          return false;
        }
      }

      // Update user model
      final updatedUser = _user!.copyWith(
        name: _fullName,
        imageUrl: newImageUrl,
        latitude: _latitude,
        longitude: _longitude,
      );
      await _userService.updateUser(updatedUser);
      // #region agent log
      await DebugLogger.log(location: 'parent_edit_profile_vm.dart:161', message: 'User updated', data: {'name': _fullName}, hypothesisId: 'EDIT-PROFILE-3');
      // #endregion

      // Update parent model (address/location)
      if (_parent != null) {
        final updatedParent = _parent!.copyWith(
          address: _location,
        );
        await _parentService.updateParent(updatedParent);
        _parent = updatedParent; // Update local state
        // #region agent log
        await DebugLogger.log(location: 'parent_edit_profile_vm.dart:171', message: 'Parent updated', data: {'address': _location}, hypothesisId: 'EDIT-PROFILE-3');
        // #endregion
      } else {
        // Create parent if doesn't exist
        final newParent = ParentModel(
          parentId: _user!.userId,
          address: _location,
        );
        await _parentService.createParent(newParent);
        _parent = newParent; // Update local state
        // #region agent log
        await DebugLogger.log(location: 'parent_edit_profile_vm.dart:180', message: 'Parent created', data: {'address': _location}, hypothesisId: 'EDIT-PROFILE-3');
        // #endregion
      }

      _user = updatedUser;
      _imageUrl = newImageUrl;
      _selectedImageFile = null;
      _setLoading(false);
      // #region agent log
      await DebugLogger.log(location: 'parent_edit_profile_vm.dart:188', message: 'Profile saved successfully', data: {}, hypothesisId: 'EDIT-PROFILE-3');
      // #endregion
      notifyListeners();
      return true;
    } catch (e) {
      // #region agent log
      await DebugLogger.log(location: 'parent_edit_profile_vm.dart:193', message: 'Error saving profile', data: {'error': e.toString()}, hypothesisId: 'EDIT-PROFILE-3');
      // #endregion
      _errorMessage = 'Failed to save profile: ${e.toString()}';
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // ---------- Helpers ----------
  bool _hasChanges() {
    if (_user == null) return false;
    
    final nameChanged = _fullName != _user!.name;
    final locationChanged = _location != (_parent?.address ?? '');
    final imageChanged = _selectedImageFile != null;
    final latitudeChanged = _latitude != _user!.latitude;
    final longitudeChanged = _longitude != _user!.longitude;
    
    return nameChanged || locationChanged || imageChanged || latitudeChanged || longitudeChanged;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

