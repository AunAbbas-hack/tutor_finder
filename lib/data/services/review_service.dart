// lib/data/services/review_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/review_model.dart';

class ReviewService {
  final FirebaseFirestore _firestore;

  ReviewService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _reviewsCol =>
      _firestore.collection('reviews');

  // ---------- CREATE ----------

  /// Create a new review
  Future<String> createReview({
    required String tutorId,
    required String parentId,
    required int rating,
    String? bookingId,
    String? comment,
  }) async {
    try {
      // Validate rating
      if (rating < 1 || rating > 5) {
        throw Exception('Rating must be between 1 and 5');
      }

      final reviewId = _reviewsCol.doc().id;
      final now = DateTime.now();

      final review = ReviewModel(
        reviewId: reviewId,
        tutorId: tutorId,
        parentId: parentId,
        bookingId: bookingId,
        rating: rating,
        comment: comment,
        createdAt: now,
        updatedAt: now,
        isVisible: true,
      );

      await _reviewsCol.doc(reviewId).set(review.toMap());

      if (kDebugMode) {
        print('✅ Review created: $reviewId');
      }

      return reviewId;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error creating review: $e');
      }
      rethrow;
    }
  }

  // ---------- READ ----------

  /// Get review by ID
  Future<ReviewModel?> getReviewById(String reviewId) async {
    try {
      final doc = await _reviewsCol.doc(reviewId).get();
      if (!doc.exists) return null;
      return ReviewModel.fromFirestore(doc);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching review: $e');
      }
      return null;
    }
  }

  /// Get all reviews for a tutor
  Future<List<ReviewModel>> getReviewsByTutorId(String tutorId) async {
    try {
      final snapshot = await _reviewsCol
          .where('tutorId', isEqualTo: tutorId)
          .where('isVisible', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ReviewModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching reviews by tutor: $e');
      }
      return [];
    }
  }

  /// Get reviews by parent ID
  Future<List<ReviewModel>> getReviewsByParentId(String parentId) async {
    try {
      final snapshot = await _reviewsCol
          .where('parentId', isEqualTo: parentId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ReviewModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching reviews by parent: $e');
      }
      return [];
    }
  }

  /// Get review by booking ID (if parent reviewed after booking)
  Future<ReviewModel?> getReviewByBookingId(String bookingId) async {
    try {
      final snapshot = await _reviewsCol
          .where('bookingId', isEqualTo: bookingId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      return ReviewModel.fromFirestore(snapshot.docs.first);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching review by booking: $e');
      }
      return null;
    }
  }

  /// Get average rating for a tutor
  Future<double> getAverageRating(String tutorId) async {
    try {
      final reviews = await getReviewsByTutorId(tutorId);
      if (reviews.isEmpty) return 0.0;

      final totalRating = reviews.fold<int>(
        0,
        (sum, review) => sum + review.rating,
      );

      return totalRating / reviews.length;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error calculating average rating: $e');
      }
      return 0.0;
    }
  }

  /// Get review count for a tutor
  Future<int> getReviewCount(String tutorId) async {
    try {
      final reviews = await getReviewsByTutorId(tutorId);
      return reviews.length;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting review count: $e');
      }
      return 0;
    }
  }

  /// Get rating distribution for a tutor (how many 5-star, 4-star, etc.)
  Future<Map<int, int>> getRatingDistribution(String tutorId) async {
    try {
      final reviews = await getReviewsByTutorId(tutorId);
      final distribution = <int, int>{
        5: 0,
        4: 0,
        3: 0,
        2: 0,
        1: 0,
      };

      for (final review in reviews) {
        distribution[review.rating] = (distribution[review.rating] ?? 0) + 1;
      }

      return distribution;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting rating distribution: $e');
      }
      return {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    }
  }

  // ---------- UPDATE ----------

  /// Update a review (parent can edit their own review)
  Future<void> updateReview({
    required String reviewId,
    int? rating,
    String? comment,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': DateTime.now().toIso8601String(),
      };

      if (rating != null) {
        if (rating < 1 || rating > 5) {
          throw Exception('Rating must be between 1 and 5');
        }
        updates['rating'] = rating;
      }

      if (comment != null) {
        updates['comment'] = comment;
      }

      await _reviewsCol.doc(reviewId).update(updates);

      if (kDebugMode) {
        print('✅ Review updated: $reviewId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating review: $e');
      }
      rethrow;
    }
  }

  /// Add tutor reply to a review
  Future<void> addReply({
    required String reviewId,
    required String reply,
  }) async {
    try {
      await _reviewsCol.doc(reviewId).update({
        'reply': reply,
        'repliedAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });

      if (kDebugMode) {
        print('✅ Reply added to review: $reviewId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error adding reply: $e');
      }
      rethrow;
    }
  }

  /// Update tutor reply
  Future<void> updateReply({
    required String reviewId,
    required String reply,
  }) async {
    try {
      await _reviewsCol.doc(reviewId).update({
        'reply': reply,
        'repliedAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });

      if (kDebugMode) {
        print('✅ Reply updated for review: $reviewId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating reply: $e');
      }
      rethrow;
    }
  }

  // ---------- DELETE ----------

  /// Delete a review (soft delete - set isVisible to false)
  Future<void> deleteReview(String reviewId) async {
    try {
      await _reviewsCol.doc(reviewId).update({
        'isVisible': false,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      if (kDebugMode) {
        print('✅ Review deleted (hidden): $reviewId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error deleting review: $e');
      }
      rethrow;
    }
  }

  /// Permanently delete a review (admin only)
  Future<void> permanentlyDeleteReview(String reviewId) async {
    try {
      await _reviewsCol.doc(reviewId).delete();

      if (kDebugMode) {
        print('✅ Review permanently deleted: $reviewId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error permanently deleting review: $e');
      }
      rethrow;
    }
  }

  // ---------- STREAMS (Real-time) ----------

  /// Stream of reviews for a tutor (real-time updates)
  Stream<List<ReviewModel>> getReviewsByTutorIdStream(String tutorId) {
    return _reviewsCol
        .where('tutorId', isEqualTo: tutorId)
        .where('isVisible', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReviewModel.fromFirestore(doc))
            .toList());
  }

  // ---------- VALIDATION ----------

  /// Check if parent has already reviewed this tutor
  Future<bool> hasParentReviewedTutor({
    required String parentId,
    required String tutorId,
  }) async {
    try {
      final snapshot = await _reviewsCol
          .where('parentId', isEqualTo: parentId)
          .where('tutorId', isEqualTo: tutorId)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error checking if parent reviewed tutor: $e');
      }
      return false;
    }
  }

  /// Check if parent has already reviewed this booking
  Future<bool> hasParentReviewedBooking(String bookingId) async {
    try {
      final review = await getReviewByBookingId(bookingId);
      return review != null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error checking if parent reviewed booking: $e');
      }
      return false;
    }
  }
}
