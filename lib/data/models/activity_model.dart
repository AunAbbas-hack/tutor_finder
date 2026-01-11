// lib/data/models/activity_model.dart
import 'package:flutter/material.dart';

/// Activity types for admin dashboard
enum ActivityType {
  newTutorSignup,
  newReportSubmitted,
  bookingCompleted,
  userSuspended,
  paymentReceived,
  other,
}

/// Model for recent activity items in admin dashboard
class ActivityModel {
  final String activityId;
  final ActivityType type;
  final String title;
  final String description;
  final DateTime timestamp;
  final String? relatedUserId;
  final String? relatedBookingId;

  const ActivityModel({
    required this.activityId,
    required this.type,
    required this.title,
    required this.description,
    required this.timestamp,
    this.relatedUserId,
    this.relatedBookingId,
  });

  ActivityModel copyWith({
    String? activityId,
    ActivityType? type,
    String? title,
    String? description,
    DateTime? timestamp,
    String? relatedUserId,
    String? relatedBookingId,
  }) {
    return ActivityModel(
      activityId: activityId ?? this.activityId,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      timestamp: timestamp ?? this.timestamp,
      relatedUserId: relatedUserId ?? this.relatedUserId,
      relatedBookingId: relatedBookingId ?? this.relatedBookingId,
    );
  }

  /// Get icon for activity type
  IconData get icon {
    switch (type) {
      case ActivityType.newTutorSignup:
        return Icons.person_add;
      case ActivityType.newReportSubmitted:
        return Icons.report_problem;
      case ActivityType.bookingCompleted:
        return Icons.check_circle;
      case ActivityType.userSuspended:
        return Icons.block;
      case ActivityType.paymentReceived:
        return Icons.payment;
      case ActivityType.other:
        return Icons.notifications;
    }
  }

  /// Get icon color for activity type
  Color get iconColor {
    switch (type) {
      case ActivityType.newTutorSignup:
        return Colors.blue;
      case ActivityType.newReportSubmitted:
        return Colors.red;
      case ActivityType.bookingCompleted:
        return Colors.green;
      case ActivityType.userSuspended:
        return Colors.orange;
      case ActivityType.paymentReceived:
        return Colors.purple;
      case ActivityType.other:
        return Colors.grey;
    }
  }

  /// Get formatted time ago string (e.g., "2m ago", "1h ago")
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }
}
