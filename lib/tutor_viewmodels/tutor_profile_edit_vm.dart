// lib/tutor_viewmodels/tutor_profile_edit_vm.dart
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../data/models/user_model.dart';
import '../data/models/tutor_model.dart';
import '../data/services/user_services.dart';
import '../data/services/tutor_services.dart';
import '../../core/services/file_picker_service.dart';
import '../../core/services/storage_service.dart';

class TutorProfileViewModel extends ChangeNotifier {
  final UserService _userService;
  final TutorService _tutorService;
  final FirebaseAuth _auth;
  final FilePickerService _filePickerService;
  final StorageService _storageService;

  TutorProfileViewModel({
    UserService? userService,
    TutorService? tutorService,
    FirebaseAuth? auth,
    FilePickerService? filePickerService,
    StorageService? storageService,
  })  : _userService = userService ?? UserService(),
        _tutorService = tutorService ?? TutorService(),
        _auth = auth ?? FirebaseAuth.instance,
        _filePickerService = filePickerService ?? FilePickerService(),
        _storageService = storageService ?? StorageService();

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
  List<CertificationEntry> _certifications = [];
  List<PortfolioDocument> _portfolioDocuments = [];

  // Certification input fields
  String _certificationTitle = '';
  String _certificationIssuer = '';
  String _certificationYear = '';

  // Getters
  String get fullName => _fullName;
  String get professionalHeadline => _professionalHeadline;
  String get aboutMe => _aboutMe;
  List<String> get areasOfExpertise => _areasOfExpertise;
  String get education => _education;
  List<CertificationEntry> get certifications => _certifications;
  List<PortfolioDocument> get portfolioDocuments => _portfolioDocuments;
  
  // Certification input getters
  String get certificationTitle => _certificationTitle;
  String get certificationIssuer => _certificationIssuer;
  String get certificationYear => _certificationYear;

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
      // Certifications and portfolio
      _certifications = List<CertificationEntry>.from(_tutor!.certifications);
      _portfolioDocuments = List<PortfolioDocument>.from(_tutor!.portfolioDocuments);

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

  // Certification input methods
  void updateCertificationTitle(String value) {
    _certificationTitle = value;
    notifyListeners();
  }

  void updateCertificationIssuer(String value) {
    _certificationIssuer = value;
    notifyListeners();
  }

  void updateCertificationYear(String value) {
    _certificationYear = value;
    notifyListeners();
  }

  void addCertification() {
    if (_certificationTitle.trim().isNotEmpty) {
      final cert = CertificationEntry(
        title: _certificationTitle.trim(),
        issuer: _certificationIssuer.trim(),
        year: _certificationYear.trim().isNotEmpty 
            ? _certificationYear.trim() 
            : DateTime.now().year.toString(),
      );
      _certifications.add(cert);
      // Clear input fields
      _certificationTitle = '';
      _certificationIssuer = '';
      _certificationYear = '';
      notifyListeners();
    }
  }

  void removeCertification(CertificationEntry certification) {
    _certifications.remove(certification);
    notifyListeners();
  }

  /// Upload and add portfolio document from file picker
  Future<bool> uploadPortfolioDocument() async {
    try {
      // Pick document file
      final file = await _filePickerService.pickDocument();
      if (file == null || file.path == null) {
        return false; // User cancelled
      }

      final filePath = file.path!;
      final fileName = file.name;
      final fileSize = file.size;

      // Upload to Firebase Storage
      _setLoading(true);
      final downloadUrl = await _storageService.uploadFile(
        filePath: filePath,
        folderPath: 'tutor_portfolio',
        fileName: fileName,
      );

      if (downloadUrl == null) {
        _errorMessage = 'Failed to upload document';
        _setLoading(false);
        notifyListeners();
        return false;
      }

      // Get file extension
      final extension = fileName.split('.').last.toLowerCase();
      final fileType = extension == 'pdf' ? 'pdf' : 'doc';

      // Create PortfolioDocument
      final portfolioDoc = PortfolioDocument(
        fileName: fileName,
        fileUrl: downloadUrl,
        fileSize: _filePickerService.getFileSize(fileSize),
        fileType: fileType,
      );

      // Add to list
      _portfolioDocuments.add(portfolioDoc);
      _setLoading(false);
      notifyListeners();

      return true;
    } catch (e) {
      _errorMessage = 'Error uploading document: ${e.toString()}';
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  void removePortfolioDocument(PortfolioDocument document) {
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

      // Certifications are already CertificationEntry objects

      // Update tutor data
      final updatedTutor = _tutor!.copyWith(
        subjects: _areasOfExpertise,
        qualification: _professionalHeadline.isNotEmpty ? _professionalHeadline : null,
        bio: _aboutMe.isNotEmpty ? _aboutMe : null,
        certifications: certifications,
        portfolioDocuments: _portfolioDocuments,
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

