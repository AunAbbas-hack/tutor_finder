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

  // ---------- State ----------
  bool _isLoading = false;
  String? _errorMessage;
  UserModel? _user;
  TutorModel? _tutor;

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

      // Education, certifications, and portfolio are now loaded from TutorModel
      // No need for mock data
    } catch (e) {
      _errorMessage = 'Failed to load profile: ${e.toString()}';
    } finally {
      _setLoading(false);
    }
  }


  // ---------- Refresh ----------
  Future<void> refresh() async {
    await initialize();
  }

  // ---------- Helpers ----------
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}

