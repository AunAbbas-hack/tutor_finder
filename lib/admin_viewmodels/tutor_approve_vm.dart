// lib/admin_viewmodels/tutor_approve_vm.dart
import 'package:flutter/foundation.dart';
import '../data/models/user_model.dart';
import '../data/models/tutor_model.dart';
import '../data/services/user_services.dart';
import '../data/services/tutor_services.dart';

class TutorApproveViewModel extends ChangeNotifier {
  final UserService _userService;
  final TutorService _tutorService;

  TutorApproveViewModel({
    UserService? userService,
    TutorService? tutorService,
  })  : _userService = userService ?? UserService(),
        _tutorService = tutorService ?? TutorService();

  // ---------- State ----------
  bool _isDisposed = false;
  bool _isLoading = false;
  String? _errorMessage;
  
  UserModel? _user;
  TutorModel? _tutor;
  String? _rejectionReason;

  // Document status tracking
  bool _cnicApproved = false;
  bool _cnicRejected = false;
  bool _academicApproved = false;
  bool _academicRejected = false;
  bool _certificationApproved = false;
  bool _certificationRejected = false;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  UserModel? get user => _user;
  TutorModel? get tutor => _tutor;
  String? get rejectionReason => _rejectionReason;
  
  bool get cnicApproved => _cnicApproved;
  bool get cnicRejected => _cnicRejected;
  bool get academicApproved => _academicApproved;
  bool get academicRejected => _academicRejected;
  bool get certificationApproved => _certificationApproved;
  bool get certificationRejected => _certificationRejected;

  // ---------- Initialize ----------
  Future<void> loadTutorData(String tutorId) async {
    if (_isDisposed) return;

    _setLoading(true);
    _errorMessage = null;

    try {
      // Load user and tutor data in parallel
      final results = await Future.wait([
        _userService.getUserById(tutorId),
        _tutorService.getTutorById(tutorId),
      ]);

      final user = results[0] as UserModel?;
      final tutor = results[1] as TutorModel?;

      if (user == null || tutor == null) {
        _errorMessage = 'Tutor data not found';
        _setLoading(false);
        return;
      }

      if (!_isDisposed) {
        _user = user;
        _tutor = tutor;
        _setLoading(false);
      }
    } catch (e) {
      if (!_isDisposed) {
        _errorMessage = 'Failed to load tutor data: ${e.toString()}';
        if (kDebugMode) {
          print('Error loading tutor data: $e');
        }
        _setLoading(false);
      }
    }
  }

  // ---------- Document Actions ----------
  void approveCnic() {
    _cnicApproved = true;
    _cnicRejected = false;
    _safeNotifyListeners();
  }

  void rejectCnic() {
    _cnicRejected = true;
    _cnicApproved = false;
    _safeNotifyListeners();
  }

  void approveAcademic() {
    _academicApproved = true;
    _academicRejected = false;
    _safeNotifyListeners();
  }

  void rejectAcademic() {
    _academicRejected = true;
    _academicApproved = false;
    _safeNotifyListeners();
  }

  void approveCertification() {
    _certificationApproved = true;
    _certificationRejected = false;
    _safeNotifyListeners();
  }

  void rejectCertification() {
    _certificationRejected = true;
    _certificationApproved = false;
    _safeNotifyListeners();
  }

  void setRejectionReason(String? reason) {
    _rejectionReason = reason;
    _safeNotifyListeners();
  }

  // ---------- Tutor Actions ----------
  Future<bool> approveTutor() async {
    if (_isDisposed || _user == null) return false;

    _setLoading(true);
    _errorMessage = null;

    try {
      // Update user status to active
      final updatedUser = _user!.copyWith(status: UserStatus.active);
      await _userService.updateUser(updatedUser);

      if (!_isDisposed) {
        _user = updatedUser;
        _setLoading(false);
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error approving tutor: $e');
      }
      if (!_isDisposed) {
        _errorMessage = 'Failed to approve tutor: ${e.toString()}';
        _setLoading(false);
        _safeNotifyListeners();
      }
      return false;
    }
  }

  Future<bool> rejectTutor() async {
    if (_isDisposed || _user == null) return false;

    _setLoading(true);
    _errorMessage = null;

    try {
      // Update user status to suspended (rejected)
      final updatedUser = _user!.copyWith(status: UserStatus.suspended);
      await _userService.updateUser(updatedUser);

      if (!_isDisposed) {
        _user = updatedUser;
        _setLoading(false);
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error rejecting tutor: $e');
      }
      if (!_isDisposed) {
        _errorMessage = 'Failed to reject tutor: ${e.toString()}';
        _setLoading(false);
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

  void clearError() {
    if (_isDisposed) return;
    _errorMessage = null;
    _safeNotifyListeners();
  }

  void _safeNotifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
