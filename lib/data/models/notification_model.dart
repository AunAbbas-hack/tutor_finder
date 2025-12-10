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

  const NotificationModel({
    required this.notificationId,
    required this.userId,
    required this.message,
    required this.dateTime,
    required this.status,
  });

  NotificationModel copyWith({
    String? notificationId,
    String? userId,
    String? message,
    DateTime? dateTime,
    NotificationStatus? status,
  }) {
    return NotificationModel(
      notificationId: notificationId ?? this.notificationId,
      userId: userId ?? this.userId,
      message: message ?? this.message,
      dateTime: dateTime ?? this.dateTime,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'notificationId': notificationId,
      'userId': userId,
      'message': message,
      'dateTime': Timestamp.fromDate(dateTime),
      'status': _statusToString(status),
    };
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      notificationId: map['notificationId'] as String,
      userId: map['userId'] as String,
      message: map['message'] as String? ?? '',
      dateTime: _dateTimeFromDynamic(map['dateTime']),
      status: _statusFromString(map['status'] as String?),
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
