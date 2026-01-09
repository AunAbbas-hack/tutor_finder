// lib/data/models/notification_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationStatus {
  unread,
  read,
}

class NotificationModel {
  final String notificationId;
  final String userId; // FK -> UserModel.userId
  final String message;
  final DateTime dateTime;
  final NotificationStatus status;
  final String? type; // e.g., 'booking_request', 'message', 'booking_approved', etc.
  final String? relatedId; // e.g., bookingId, tutorId, parentId, chatId, etc.
  final Map<String, dynamic>? actionData; // Additional data for navigation

  const NotificationModel({
    required this.notificationId,
    required this.userId,
    required this.message,
    required this.dateTime,
    required this.status,
    this.type,
    this.relatedId,
    this.actionData,
  });

  NotificationModel copyWith({
    String? notificationId,
    String? userId,
    String? message,
    DateTime? dateTime,
    NotificationStatus? status,
    String? type,
    String? relatedId,
    Map<String, dynamic>? actionData,
  }) {
    return NotificationModel(
      notificationId: notificationId ?? this.notificationId,
      userId: userId ?? this.userId,
      message: message ?? this.message,
      dateTime: dateTime ?? this.dateTime,
      status: status ?? this.status,
      type: type ?? this.type,
      relatedId: relatedId ?? this.relatedId,
      actionData: actionData ?? this.actionData,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'notificationId': notificationId,
      'userId': userId,
      'message': message,
      'dateTime': Timestamp.fromDate(dateTime),
      'status': _statusToString(status),
      if (type != null) 'type': type,
      if (relatedId != null) 'relatedId': relatedId,
      if (actionData != null && actionData!.isNotEmpty) 'actionData': actionData,
    };
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      notificationId: map['notificationId'] as String,
      userId: map['userId'] as String,
      message: map['message'] as String? ?? '',
      dateTime: _dateTimeFromDynamic(map['dateTime']),
      status: _statusFromString(map['status'] as String?),
      type: map['type'] as String?,
      relatedId: map['relatedId'] as String?,
      actionData: map['actionData'] != null
          ? Map<String, dynamic>.from(map['actionData'] as Map)
          : null,
    );
  }

  static DateTime _dateTimeFromDynamic(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is DateTime) {
      return value;
    } else if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return DateTime.now();
  }

  static String _statusToString(NotificationStatus status) {
    switch (status) {
      case NotificationStatus.unread:
        return 'unread';
      case NotificationStatus.read:
        return 'read';
    }
  }

  static NotificationStatus _statusFromString(String? value) {
    switch (value) {
      case 'read':
        return NotificationStatus.read;
      case 'unread':
      default:
        return NotificationStatus.unread;
    }
  }
}
