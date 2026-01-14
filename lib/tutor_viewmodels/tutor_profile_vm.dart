// lib/tutor_viewmodels/tutor_profile_vm.dart
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geocoding/geocoding.dart';
import '../data/models/user_model.dart';
import '../data/models/tutor_model.dart';
import '../data/services/user_services.dart';
import '../data/services/tutor_services.dart';
import '../data/repositories/auth_repository.dart';

class TutorProfileViewModel extends ChangeNotifier {
  final UserService _userService;
  final TutorService _tutorService;
  final FirebaseAuth _auth;
  final AuthRepository _authRepository;

  TutorProfileViewModel({
    UserService? userService,
    TutorService? tutorService,
    FirebaseAuth? auth,
    AuthRepository? authRepository,
  })  : _userService = userService ?? UserService(),
        _tutorService = tutorService ?? TutorService(),
        _auth = auth ?? FirebaseAuth.instance,
        _authRepository = authRepository ?? AuthRepository();

  // ---------- State ----------
  bool _isLoading = false;
  String? _errorMessage;
  UserModel? _user;
  TutorModel? _tutor;
  String? _locationAddress;

  // Expandable sections state
  bool _isExpertiseExpanded = true;
  bool _isEducationExpanded = false;
  bool _isCertificationsExpanded = false;
  bool _isPortfolioExpanded = false;
  bool _isFeesExpanded = false;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  UserModel? get user => _user;
  TutorModel? get tutor => _tutor;
  List<EducationEntry> get education => _tutor?.education ?? [];
  List<CertificationEntry> get certifications => _tutor?.certifications ?? [];
  List<PortfolioDocument> get portfolioDocuments => _tutor?.portfolioDocuments ?? [];

  String get name => _user?.name ?? '';
  String get professionalHeadline => _tutor?.qualification ?? '';
  String get aboutMe => _tutor?.bio ?? '';
  String get imageUrl => _user?.imageUrl ?? '';
  List<String> get areasOfExpertise => _tutor?.subjects ?? [];
  double? get latitude => _user?.latitude;
  double? get longitude => _user?.longitude;
  bool get hasLocation => _user?.latitude != null && _user?.longitude != null;
  String? get locationAddress => _locationAddress;
  double? get hourlyFee => _tutor?.hourlyFee;
  double? get monthlyFee => _tutor?.monthlyFee;
  bool get hasFees => _tutor?.hourlyFee != null || _tutor?.monthlyFee != null;
  
  // Calculate savings percentage when monthly fee is available
  // Uses standard assumption of 4 sessions per week (16 sessions per month)
  double? get monthlySavingsPercentage {
    final hourly = hourlyFee;
    final monthly = monthlyFee;
    
    if (hourly == null || hourly == 0 || monthly == null) {
      return null;
    }
    
    // Standard assumption: 4 sessions per week, 4 weeks per month = 16 sessions
    const hoursPerMonth = 16; // 4 weeks * 4 sessions
    
    final hourlyTotal = hourly * hoursPerMonth;
    if (hourlyTotal == 0) return null;
    
    final savings = ((hourlyTotal - monthly) / hourlyTotal) * 100;
    return savings > 0 ? savings : 0;
  }

  // Expandable sections getters
  bool get isExpertiseExpanded => _isExpertiseExpanded;
  bool get isEducationExpanded => _isEducationExpanded;
  bool get isCertificationsExpanded => _isCertificationsExpanded;
  bool get isPortfolioExpanded => _isPortfolioExpanded;
  bool get isFeesExpanded => _isFeesExpanded;

  // ---------- Initialize ----------
  Future<void> initialize() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        _errorMessage = 'User not authenticated';
        _setLoading(false);
        return;
      }

      // Load user data
      _user = await _userService.getUserById(userId);
      if (_user == null) {
        _errorMessage = 'User data not found';
        _setLoading(false);
        return;
      }

      // Load tutor data
      _tutor = await _tutorService.getTutorById(userId);
      if (_tutor == null) {
        _errorMessage = 'Tutor profile not found';
        _setLoading(false);
        return;
      }

      // Fetch address from coordinates if location is available
      if (_user?.latitude != null && _user?.longitude != null) {
        await _fetchAddressFromCoordinates(_user!.latitude!, _user!.longitude!);
      }

      // Auto-expand sections if they have data
      if (_tutor!.education.isNotEmpty) {
        _isEducationExpanded = true;
      }
      if (_tutor!.certifications.isNotEmpty) {
        _isCertificationsExpanded = true;
      }
      if (_tutor!.portfolioDocuments.isNotEmpty) {
        _isPortfolioExpanded = true;
      }
      if (_tutor!.hourlyFee != null || _tutor!.monthlyFee != null) {
        _isFeesExpanded = true;
      }

      // Education, certifications, and portfolio are now loaded from TutorModel
      // No need for mock data
    } catch (e) {
      _errorMessage = 'Failed to load profile: ${e.toString()}';
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Fetch address from coordinates using geocoding
  Future<void> _fetchAddressFromCoordinates(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        _locationAddress = _formatAddress(place);
        notifyListeners();
      }
    } catch (e) {
      // Silently fail - address is optional
      _locationAddress = null;
    }
  }

  /// Format address from Placemark
  String _formatAddress(Placemark place) {
    List<String> parts = [];
    
    if (place.street != null && place.street!.isNotEmpty) {
      parts.add(place.street!);
    }
    if (place.subLocality != null && place.subLocality!.isNotEmpty) {
      parts.add(place.subLocality!);
    }
    if (place.locality != null && place.locality!.isNotEmpty) {
      parts.add(place.locality!);
    }
    if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
      parts.add(place.administrativeArea!);
    }
    if (place.country != null && place.country!.isNotEmpty) {
      parts.add(place.country!);
    }
    
    return parts.isNotEmpty ? parts.join(', ') : 'Unknown location';
  }


  // ---------- Refresh ----------
  Future<void> refresh() async {
    // Reset expansion states before reloading
    _isEducationExpanded = false;
    _isCertificationsExpanded = false;
    _isPortfolioExpanded = false;
    _isFeesExpanded = false;
    await initialize();
  }

  // ---------- Toggle Expandable Sections ----------
  void toggleExpertise() {
    _isExpertiseExpanded = !_isExpertiseExpanded;
    notifyListeners();
  }

  void toggleEducation() {
    _isEducationExpanded = !_isEducationExpanded;
    notifyListeners();
  }

  void toggleCertifications() {
    _isCertificationsExpanded = !_isCertificationsExpanded;
    notifyListeners();
  }

  void togglePortfolio() {
    _isPortfolioExpanded = !_isPortfolioExpanded;
    notifyListeners();
  }

  void toggleFees() {
    _isFeesExpanded = !_isFeesExpanded;
    notifyListeners();
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
}

