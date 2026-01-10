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
import '../../core/services/storage_service_cloudinary.dart';
import '../../core/services/image_picker_service.dart';

class TutorProfileViewModel extends ChangeNotifier {
  final UserService _userService;
  final TutorService _tutorService;
  final FirebaseAuth _auth;
  final FilePickerService _filePickerService;
  final StorageService _storageService;
  final ImagePickerService _imagePickerService;

  TutorProfileViewModel({
    UserService? userService,
    TutorService? tutorService,
    FirebaseAuth? auth,
    FilePickerService? filePickerService,
    StorageService? storageService,
    ImagePickerService? imagePickerService,
  })  : _userService = userService ?? UserService(),
        _tutorService = tutorService ?? TutorService(),
        _auth = auth ?? FirebaseAuth.instance,
        _filePickerService = filePickerService ?? FilePickerService(),
        _storageService = storageService ?? StorageService(),
        _imagePickerService = imagePickerService ?? ImagePickerService();

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
  List<EducationEntry> _education = [];
  List<CertificationEntry> _certifications = [];
  List<PortfolioDocument> _portfolioDocuments = [];

  // Location fields
  double? _latitude;
  double? _longitude;
  String? _selectedAddress;
  
  // Profile picture
  File? _selectedImageFile;
  File? get selectedImageFile => _selectedImageFile;

  // CNIC images
  File? _selectedCnicFrontFile;
  File? _selectedCnicBackFile;
  String? _cnicFrontUrl;
  String? _cnicBackUrl;
  File? get selectedCnicFrontFile => _selectedCnicFrontFile;
  File? get selectedCnicBackFile => _selectedCnicBackFile;
  String? get cnicFrontUrl => _cnicFrontUrl;
  String? get cnicBackUrl => _cnicBackUrl;

  // Certification input fields
  String _certificationTitle = '';
  String _certificationIssuer = '';
  String _certificationYear = '';

  // Education input fields
  String _educationDegree = '';
  String _educationInstitution = '';
  String _educationPeriod = '';

  // Fee fields
  double? _hourlyFee;
  double? _monthlyFee;

  // Getters
  String get fullName => _fullName;
  String get professionalHeadline => _professionalHeadline;
  String get aboutMe => _aboutMe;
  List<String> get areasOfExpertise => _areasOfExpertise;
  List<EducationEntry> get education => _education;
  List<CertificationEntry> get certifications => _certifications;
  List<PortfolioDocument> get portfolioDocuments => _portfolioDocuments;
  
  // Location getters
  double? get latitude => _latitude;
  double? get longitude => _longitude;
  String? get selectedAddress => _selectedAddress;
  
  // Certification input getters
  String get certificationTitle => _certificationTitle;
  String get certificationIssuer => _certificationIssuer;
  String get certificationYear => _certificationYear;

  // Education input getters
  String get educationDegree => _educationDegree;
  String get educationInstitution => _educationInstitution;
  String get educationPeriod => _educationPeriod;

  // Fee getters
  double? get hourlyFee => _hourlyFee;
  double? get monthlyFee => _monthlyFee;

  // Expandable sections state
  bool _isExpertiseExpanded = true;
  bool _isEducationExpanded = false;
  bool _isCertificationsExpanded = false;
  bool _isPortfolioExpanded = false;
  bool _isFeesExpanded = false;
  bool _isIdentityVerificationExpanded = false;

  bool get isExpertiseExpanded => _isExpertiseExpanded;
  bool get isEducationExpanded => _isEducationExpanded;
  bool get isCertificationsExpanded => _isCertificationsExpanded;
  bool get isPortfolioExpanded => _isPortfolioExpanded;
  bool get isFeesExpanded => _isFeesExpanded;
  bool get isIdentityVerificationExpanded => _isIdentityVerificationExpanded;

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
      _education = List<EducationEntry>.from(_tutor!.education);
      // Location
      _latitude = _user!.latitude;
      _longitude = _user!.longitude;
      // Certifications and portfolio
      _certifications = List<CertificationEntry>.from(_tutor!.certifications);
      _portfolioDocuments = List<PortfolioDocument>.from(_tutor!.portfolioDocuments);
      // Fees
      _hourlyFee = _tutor!.hourlyFee;
      _monthlyFee = _tutor!.monthlyFee;
      // CNIC
      _cnicFrontUrl = _tutor!.cnicFrontUrl;
      _cnicBackUrl = _tutor!.cnicBackUrl;

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

  // Education input methods
  void updateEducationDegree(String value) {
    _educationDegree = value;
    notifyListeners();
  }

  void updateEducationInstitution(String value) {
    _educationInstitution = value;
    notifyListeners();
  }

  void updateEducationPeriod(String value) {
    _educationPeriod = value;
    notifyListeners();
  }

  void addEducation() {
    if (_educationDegree.trim().isNotEmpty && _educationInstitution.trim().isNotEmpty) {
      final education = EducationEntry(
        degree: _educationDegree.trim(),
        institution: _educationInstitution.trim(),
        period: _educationPeriod.trim().isNotEmpty 
            ? _educationPeriod.trim() 
            : 'N/A',
      );
      _education.add(education);
      // Clear input fields
      _educationDegree = '';
      _educationInstitution = '';
      _educationPeriod = '';
      notifyListeners();
    }
  }

  void removeEducation(EducationEntry education) {
    _education.remove(education);
    notifyListeners();
  }

  // Location update methods
  void updateLocation(double lat, double lng, String? address) {
    _latitude = lat;
    _longitude = lng;
    _selectedAddress = address;
    notifyListeners();
  }

  void clearLocation() {
    _latitude = null;
    _longitude = null;
    _selectedAddress = null;
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

  void toggleFees() {
    _isFeesExpanded = !_isFeesExpanded;
    notifyListeners();
  }

  void toggleIdentityVerification() {
    _isIdentityVerificationExpanded = !_isIdentityVerificationExpanded;
    notifyListeners();
  }

  // Fee update methods
  void updateHourlyFee(String value) {
    if (value.isEmpty) {
      _hourlyFee = null;
    } else {
      final fee = double.tryParse(value);
      _hourlyFee = fee;
    }
    notifyListeners();
  }

  void updateMonthlyFee(String value) {
    if (value.isEmpty) {
      _monthlyFee = null;
    } else {
      final fee = double.tryParse(value);
      _monthlyFee = fee;
    }
    notifyListeners();
  }

  // ---------- Image Picker ----------
  Future<void> pickImage() async {
    try {
      final imageFile = await _imagePickerService.pickImage();
      if (imageFile != null) {
        _selectedImageFile = imageFile;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to pick image: ${e.toString()}';
      notifyListeners();
    }
  }

  void updateSelectedImage(File imageFile) {
    _selectedImageFile = imageFile;
    notifyListeners();
  }

  // ---------- CNIC Image Picker ----------
  Future<void> pickCnicFrontImage() async {
    try {
      final imageFile = await _imagePickerService.pickImage();
      if (imageFile != null) {
        _selectedCnicFrontFile = imageFile;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to pick CNIC front image: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> pickCnicBackImage() async {
    try {
      final imageFile = await _imagePickerService.pickImage();
      if (imageFile != null) {
        _selectedCnicBackFile = imageFile;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to pick CNIC back image: ${e.toString()}';
      notifyListeners();
    }
  }

  void updateSelectedCnicFrontImage(File imageFile) {
    _selectedCnicFrontFile = imageFile;
    notifyListeners();
  }

  void updateSelectedCnicBackImage(File imageFile) {
    _selectedCnicBackFile = imageFile;
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
      String? newImageUrl = _user!.imageUrl;

      // Upload image if selected
      if (_selectedImageFile != null) {
        final uploadedUrl = await _storageService.uploadImageFile(
          imageFile: _selectedImageFile!,
          folderPath: 'profile_pictures',
        );
        if (uploadedUrl != null) {
          newImageUrl = uploadedUrl;
        } else {
          _errorMessage = 'Failed to upload image';
          _setLoading(false);
          notifyListeners();
          return false;
        }
      }

      // Update user name, location, and image
      final updatedUser = _user!.copyWith(
        name: _fullName,
        latitude: _latitude,
        longitude: _longitude,
        imageUrl: newImageUrl,
      );
      await _userService.updateUser(updatedUser);
      _user = updatedUser;
      
      // Clear selected image after successful upload
      _selectedImageFile = null;

      // Upload CNIC images if selected
      String? newCnicFrontUrl = _cnicFrontUrl;
      String? newCnicBackUrl = _cnicBackUrl;

      if (_selectedCnicFrontFile != null) {
        final uploadedUrl = await _storageService.uploadImageFile(
          imageFile: _selectedCnicFrontFile!,
          folderPath: 'tutor_identity_verification',
        );
        if (uploadedUrl != null) {
          newCnicFrontUrl = uploadedUrl;
          _cnicFrontUrl = uploadedUrl;
        } else {
          _errorMessage = 'Failed to upload CNIC front image';
          _setLoading(false);
          notifyListeners();
          return false;
        }
      }

      if (_selectedCnicBackFile != null) {
        final uploadedUrl = await _storageService.uploadImageFile(
          imageFile: _selectedCnicBackFile!,
          folderPath: 'tutor_identity_verification',
        );
        if (uploadedUrl != null) {
          newCnicBackUrl = uploadedUrl;
          _cnicBackUrl = uploadedUrl;
        } else {
          _errorMessage = 'Failed to upload CNIC back image';
          _setLoading(false);
          notifyListeners();
          return false;
        }
      }

      // Clear selected CNIC images after successful upload
      _selectedCnicFrontFile = null;
      _selectedCnicBackFile = null;

      // Certifications are already CertificationEntry objects

      // Update tutor data
      // Ensure education list is properly set (even if empty, it should be an empty list, not null)
      final updatedTutor = _tutor!.copyWith(
        subjects: _areasOfExpertise,
        qualification: _professionalHeadline.isNotEmpty ? _professionalHeadline : null,
        bio: _aboutMe.isNotEmpty ? _aboutMe : null,
        education: _education, // This should be a list (empty or with items)
        certifications: certifications,
        portfolioDocuments: _portfolioDocuments,
        hourlyFee: _hourlyFee,
        monthlyFee: _monthlyFee,
        cnicFrontUrl: newCnicFrontUrl,
        cnicBackUrl: newCnicBackUrl,
      );
      
      // Debug: Print education list before saving
      print('DEBUG: Saving education list with ${_education.length} items');
      for (var edu in _education) {
        print('DEBUG: Education - ${edu.degree} from ${edu.institution}');
      }
      
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

