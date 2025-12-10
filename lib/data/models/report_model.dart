// lib/data/models/report_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ReportModel {
  final String reportId;
  final String adminId; // FK -> UserModel.userId (Admin)
  final String bookingId; // FK -> BookingModel.bookingId
  final String description;
  final String type; // e.g. 'payment_issue', 'abuse', 'quality'
  final DateTime date;

  final String createdByUser; // FK -> UserModel.userId
  final String againstUser; // FK -> UserModel.userId
  final String? handledBy; // Admin userId who handled it

  const ReportModel({
    required this.reportId,
    required this.adminId,
    required this.bookingId,
    required this.description,
    required this.type,
    required this.date,
    required this.createdByUser,
    required this.againstUser,
    this.handledBy,
  });

  ReportModel copyWith({
    String? reportId,
    String? adminId,
    String? bookingId,
    String? description,
    String? type,
    DateTime? date,
    String? createdByUser,
    String? againstUser,
    String? handledBy,
  }) {
    return ReportModel(
      reportId: reportId ?? this.reportId,
      adminId: adminId ?? this.adminId,
      bookingId: bookingId ?? this.bookingId,
      description: description ?? this.description,
      type: type ?? this.type,
      date: date ?? this.date,
      createdByUser: createdByUser ?? this.createdByUser,
      againstUser: againstUser ?? this.againstUser,
      handledBy: handledBy ?? this.handledBy,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reportId': reportId,
      'adminId': adminId,
      'bookingId': bookingId,
      'description': description,
      'type': type,
      'date': Timestamp.fromDate(date),
      'createdByUser': createdByUser,
      'againstUser': againstUser,
      'handledBy': handledBy,
    };
  }

  factory ReportModel.fromMap(Map<String, dynamic> map) {
    return ReportModel(
      reportId: map['reportId'] as String,
      adminId: map['adminId'] as String,
      bookingId: map['bookingId'] as String,
      description: map['description'] as String? ?? '',
      type: map['type'] as String? ?? '',
      date: _dateTimeFromDynamic(map['date']),
      createdByUser: map['createdByUser'] as String,
      againstUser: map['againstUser'] as String,
      handledBy: map['handledBy'] as String?,
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
}
