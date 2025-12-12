// lib/tutor_viewmodels/tutor_profile_vm.dart
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/models/user_model.dart';
import '../data/models/tutor_model.dart';
import '../data/services/user_services.dart';
import '../data/services/tutor_services.dart';

class TutorProfileViewModel extends ChangeNotifier {
  final UserService _userService;
  final TutorService _tutorService;
  final FirebaseAuth _auth;

  TutorProfileViewModel({
    UserService? userService,
    TutorService? tutorService,
    FirebaseAuth? auth,
  })  : _userService = userService ?? UserService(),
        _tutorService = tutorService ?? TutorService(),
        _auth = auth ?? FirebaseAuth.instance;

  // Loading state
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Error message
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // User and Tutor data
  UserModel? _user;
  TutorModel? _tutor;
  UserModel? get user => _user;
  TutorModel? get tutor => _tutor;

  // Form controllers (will be initialized in screen)
  String _fullName = '';
  String _professionalHeadline = '';
  String _aboutMe = '';
  List<String> _areasOfExpertise = [];
  String _education = '';
  List<String> _certifications = [];
  List<String> _portfolioDocuments = [];

  // Getters
  String get fullName => _fullName;
  String get professionalHeadline => _professionalHeadline;
  String get aboutMe => _aboutMe;
  List<String> get areasOfExpertise => _areasOfExpertise;
  String get education => _education;
  List<String> get certifications => _certifications;
  List<String> get portfolioDocuments => _portfolioDocuments;

  // Expandable sections state
  bool _isExpertiseExpanded = true;
  bool _isEducationExpanded = false;
  bool _isCertificationsExpanded = false;
  bool _isPortfolioExpanded = false;

  bool get isExpertiseExpanded => _isExpertiseExpanded;
  bool get isEducationExpanded => _isEducationExpanded;
  bool get isCertificationsExpanded => _isCertificationsExpanded;
  bool get isPortfolioExpanded => _isPortfolioExpanded;

  // Initialize and load data
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

      // Initialize form fields
      // _user and _tutor are guaranteed to be non-null here (checked above)
      _fullName = _user!.name;
      _professionalHeadline = _tutor!.qualification ?? '';
      _aboutMe = _tutor!.bio ?? '';
      _areasOfExpertise = List<String>.from(_tutor!.subjects);
      _education = _tutor!.qualification ?? '';
      // Certifications and portfolio are not in current model, so empty for now
      _certifications = [];
      _portfolioDocuments = [];

      _setLoading(false);
    } catch (e) {
      _errorMessage = 'Failed to load profile: ${e.toString()}';
      _setLoading(false);
    }
  }

  // Update methods
  void updateFullName(String value) {
    _fullName = value;
    notifyListeners();
  }

  void updateProfessionalHeadline(String value) {
    _professionalHeadline = value;
    notifyListeners();
  }

  void updateAboutMe(String value) {
    _aboutMe = value;
    notifyListeners();
  }

  void updateEducation(String value) {
    _education = value;
    notifyListeners();
  }

  void addExpertise(String expertise) {
    if (expertise.trim().isNotEmpty && !_areasOfExpertise.contains(expertise.trim())) {
      _areasOfExpertise.add(expertise.trim());
      notifyListeners();
    }
  }

  void removeExpertise(String expertise) {
    _areasOfExpertise.remove(expertise);
    notifyListeners();
  }

  void addCertification(String certification) {
    if (certification.trim().isNotEmpty && !_certifications.contains(certification.trim())) {
      _certifications.add(certification.trim());
      notifyListeners();
    }
  }

  void removeCertification(String certification) {
    _certifications.remove(certification);
    notifyListeners();
  }

  void addPortfolioDocument(String document) {
    if (document.trim().isNotEmpty && !_portfolioDocuments.contains(document.trim())) {
      _portfolioDocuments.add(document.trim());
      notifyListeners();
    }
  }

  void removePortfolioDocument(String document) {
    _portfolioDocuments.remove(document);
    notifyListeners();
  }

  // Toggle expandable sections
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

  // Save profile
  Future<bool> saveProfile() async {
    if (_user == null || _tutor == null) {
      _errorMessage = 'Profile data not loaded';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    _errorMessage = null;

    try {
      // Update user name
      final updatedUser = _user!.copyWith(name: _fullName);
      await _userService.updateUser(updatedUser);
      _user = updatedUser;

      // Update tutor data
      final updatedTutor = _tutor!.copyWith(
        subjects: _areasOfExpertise,
        qualification: _education.isNotEmpty ? _education : null,
        bio: _aboutMe.isNotEmpty ? _aboutMe : null,
      );
      await _tutorService.updateTutor(updatedTutor);
      _tutor = updatedTutor;

      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to save profile: ${e.toString()}';
      _setLoading(false);
      return false;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}

