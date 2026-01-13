// lib/data/models/review_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String reviewId;
  final String tutorId; // FK -> UserModel.userId (tutor)
  final String parentId; // FK -> UserModel.userId (parent who wrote review)
  final String? bookingId; // FK -> BookingModel.bookingId (optional - can review without booking)
  final int rating; // 1-5 stars
  final String? comment; // Review text (optional)
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isVisible; // Admin can hide inappropriate reviews
  final String? reply; // Tutor's reply to review (optional)
  final DateTime? repliedAt; // When tutor replied

  const ReviewModel({
    required this.reviewId,
    required this.tutorId,
    required this.parentId,
    this.bookingId,
    required this.rating,
    this.comment,
    required this.createdAt,
    this.updatedAt,
    this.isVisible = true,
    this.reply,
    this.repliedAt,
  });

  ReviewModel copyWith({
    String? reviewId,
    String? tutorId,
    String? parentId,
    String? bookingId,
    int? rating,
    String? comment,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isVisible,
    String? reply,
    DateTime? repliedAt,
  }) {
    return ReviewModel(
      reviewId: reviewId ?? this.reviewId,
      tutorId: tutorId ?? this.tutorId,
      parentId: parentId ?? this.parentId,
      bookingId: bookingId ?? this.bookingId,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isVisible: isVisible ?? this.isVisible,
      reply: reply ?? this.reply,
      repliedAt: repliedAt ?? this.repliedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reviewId': reviewId,
      'tutorId': tutorId,
      'parentId': parentId,
      'bookingId': bookingId,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isVisible': isVisible,
      'reply': reply,
      'repliedAt': repliedAt?.toIso8601String(),
    };
  }

  factory ReviewModel.fromMap(Map<String, dynamic> map) {
    return ReviewModel(
      reviewId: map['reviewId'] as String,
      tutorId: map['tutorId'] as String,
      parentId: map['parentId'] as String,
      bookingId: map['bookingId'] as String?,
      rating: map['rating'] as int,
      comment: map['comment'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
      isVisible: map['isVisible'] as bool? ?? true,
      reply: map['reply'] as String?,
      repliedAt: map['repliedAt'] != null
          ? DateTime.parse(map['repliedAt'] as String)
          : null,
    );
  }

  factory ReviewModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return ReviewModel.fromMap({
      ...data,
      'reviewId': data['reviewId'] ?? doc.id,
    });
  }

  // Helper getters
  bool get hasComment => comment != null && comment!.isNotEmpty;
  bool get hasReply => reply != null && reply!.isNotEmpty;
  bool get isValidRating => rating >= 1 && rating <= 5;
}
