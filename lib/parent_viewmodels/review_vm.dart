// lib/parent_viewmodels/review_vm.dart
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/services/review_service.dart';
import '../data/services/user_services.dart';

class ReviewViewModel extends ChangeNotifier {
  final ReviewService _reviewService;
  final UserService _userService;
  final FirebaseAuth _auth;

  ReviewViewModel({
    ReviewService? reviewService,
    UserService? userService,
    FirebaseAuth? auth,
  })  : _reviewService = reviewService ?? ReviewService(),
        _userService = userService ?? UserService(),
        _auth = auth ?? FirebaseAuth.instance;

  // ---------- State ----------
  bool _isDisposed = false;
  bool _isLoading = false;
  String? _errorMessage;
  int _selectedRating = 0;
  String _comment = '';
  bool _hasReviewed = false;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get selectedRating => _selectedRating;
  String get comment => _comment;
  bool get hasReviewed => _hasReviewed;
  bool get canSubmit => _selectedRating > 0 && _selectedRating <= 5;

  // ---------- Set Rating ----------
  void setRating(int rating) {
    if (rating >= 1 && rating <= 5) {
      _selectedRating = rating;
      notifyListeners();
    }
  }

  // ---------- Set Comment ----------
  void setComment(String comment) {
    _comment = comment.trim();
    notifyListeners();
  }

  // ---------- Check if Already Reviewed ----------
  Future<void> checkIfReviewed({
    required String tutorId,
    String? bookingId,
  }) async {
    if (_isDisposed) return;

    try {
      final user = _auth.currentUser;
      if (user == null) return;

      bool reviewed = false;
      if (bookingId != null) {
        reviewed = await _reviewService.hasParentReviewedBooking(bookingId);
      } else {
        reviewed = await _reviewService.hasParentReviewedTutor(
          parentId: user.uid,
          tutorId: tutorId,
        );
      }

      if (!_isDisposed) {
        _hasReviewed = reviewed;
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error checking review status: $e');
      }
    }
  }

  // ---------- Submit Review ----------
  Future<bool> submitReview({
    required String tutorId,
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

      // Check if already reviewed
      await checkIfReviewed(tutorId: tutorId, bookingId: bookingId);
      if (_hasReviewed) {
        _errorMessage = 'You have already reviewed this tutor';
        _setLoading(false);
        notifyListeners();
        return false;
      }

      // Create review
      await _reviewService.createReview(
        tutorId: tutorId,
        parentId: user.uid,
        rating: _selectedRating,
        bookingId: bookingId,
        comment: _comment.isEmpty ? null : _comment,
      );

      if (!_isDisposed) {
        _setLoading(false);
        _hasReviewed = true;
        notifyListeners();
      }

      return true;
    } catch (e) {
      if (!_isDisposed) {
        _errorMessage = 'Failed to submit review: ${e.toString()}';
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
    _selectedRating = 0;
    _comment = '';
    _errorMessage = null;
    _hasReviewed = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
