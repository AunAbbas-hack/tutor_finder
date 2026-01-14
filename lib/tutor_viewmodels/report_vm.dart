// lib/tutor_viewmodels/report_vm.dart
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/services/report_service.dart';
import '../data/models/report_model.dart';

class TutorReportViewModel extends ChangeNotifier {
  final ReportService _reportService;
  final FirebaseAuth _auth;

  TutorReportViewModel({
    ReportService? reportService,
    FirebaseAuth? auth,
  })  : _reportService = reportService ?? ReportService(),
        _auth = auth ?? FirebaseAuth.instance;

  // ---------- State ----------
  bool _isDisposed = false;
  bool _isLoading = false;
  String? _errorMessage;
  ReportType? _selectedType;
  String _description = '';
  List<String> _imageUrls = [];

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  ReportType? get selectedType => _selectedType;
  String get description => _description;
  List<String> get imageUrls => _imageUrls;
  bool get canSubmit => _selectedType != null && _description.trim().isNotEmpty;

  // ---------- Set Report Type ----------
  void setReportType(ReportType type) {
    _selectedType = type;
    notifyListeners();
  }

  // ---------- Set Description ----------
  void setDescription(String description) {
    _description = description.trim();
    notifyListeners();
  }

  // ---------- Add Image URL ----------
  void addImageUrl(String url) {
    _imageUrls.add(url);
    notifyListeners();
  }

  // ---------- Remove Image URL ----------
  void removeImageUrl(String url) {
    _imageUrls.remove(url);
    notifyListeners();
  }

  // ---------- Submit Report ----------
  Future<bool> submitReport({
    String? againstUser,
    String? bookingId,
  }) async {
    if (_isDisposed || !canSubmit) return false;

    _setLoading(true);
    _errorMessage = null;

    try {
      final user = _auth.currentUser;
      if (user == null) {
        _errorMessage = 'User not authenticated';
        _setLoading(false);
        notifyListeners();
        return false;
      }

      // Create report
      await _reportService.createReport(
        createdByUser: user.uid,
        type: _selectedType!,
        description: _description,
        againstUser: againstUser,
        bookingId: bookingId,
        imageUrls: _imageUrls.isEmpty ? null : _imageUrls,
      );

      if (!_isDisposed) {
        _setLoading(false);
        notifyListeners();
      }

      return true;
    } catch (e) {
      if (!_isDisposed) {
        _errorMessage = 'Failed to submit report: ${e.toString()}';
        _setLoading(false);
        notifyListeners();
      }
      return false;
    }
  }

  // ---------- Helper Methods ----------
  void _setLoading(bool value) {
    if (!_isDisposed) {
      _isLoading = value;
    }
  }

  void reset() {
    _selectedType = null;
    _description = '';
    _imageUrls = [];
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
