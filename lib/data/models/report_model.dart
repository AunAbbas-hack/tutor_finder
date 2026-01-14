// lib/data/models/report_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum ReportType {
  tutor,      // Report about a tutor
  booking,    // Report about a booking
  payment,    // Report about payment issue
  other,      // Other issues
}

enum ReportStatus {
  pending,    // Report submitted, waiting for admin review
  inProgress, // Admin is reviewing/investigating
  resolved,   // Report resolved
  rejected,   // Report rejected (not valid)
}

class ReportModel {
  final String reportId;
  final String createdByUser; // FK -> UserModel.userId (who created the report)
  final String? againstUser; // FK -> UserModel.userId (who the report is against - optional)
  final String? bookingId; // FK -> BookingModel.bookingId (optional - if report is about a booking)
  final ReportType type;
  final String description;
  final ReportStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? handledBy; // Admin userId who handled it
  final String? adminNotes; // Admin's notes/resolution
  final List<String>? imageUrls; // Optional image attachments
  final String? adminId; // FK -> UserModel.userId (Admin who will handle - can be null initially)

  const ReportModel({
    required this.reportId,
    required this.createdByUser,
    this.againstUser,
    this.bookingId,
    required this.type,
    required this.description,
    this.status = ReportStatus.pending,
    required this.createdAt,
    this.updatedAt,
    this.handledBy,
    this.adminNotes,
    this.imageUrls,
    this.adminId,
  });

  ReportModel copyWith({
    String? reportId,
    String? createdByUser,
    String? againstUser,
    String? bookingId,
    ReportType? type,
    String? description,
    ReportStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? handledBy,
    String? adminNotes,
    List<String>? imageUrls,
    String? adminId,
  }) {
    return ReportModel(
      reportId: reportId ?? this.reportId,
      createdByUser: createdByUser ?? this.createdByUser,
      againstUser: againstUser ?? this.againstUser,
      bookingId: bookingId ?? this.bookingId,
      type: type ?? this.type,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      handledBy: handledBy ?? this.handledBy,
      adminNotes: adminNotes ?? this.adminNotes,
      imageUrls: imageUrls ?? this.imageUrls,
      adminId: adminId ?? this.adminId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reportId': reportId,
      'createdByUser': createdByUser,
      'againstUser': againstUser,
      'bookingId': bookingId,
      'type': typeToString(type),
      'description': description,
      'status': statusToString(status),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'handledBy': handledBy,
      'adminNotes': adminNotes,
      'imageUrls': imageUrls,
      'adminId': adminId,
    };
  }

  factory ReportModel.fromMap(Map<String, dynamic> map) {
    return ReportModel(
      reportId: map['reportId'] as String,
      createdByUser: map['createdByUser'] as String,
      againstUser: map['againstUser'] as String?,
      bookingId: map['bookingId'] as String?,
      type: stringToType(map['type'] as String? ?? 'other'),
      description: map['description'] as String? ?? '',
      status: stringToStatus(map['status'] as String? ?? 'pending'),
      createdAt: _dateTimeFromDynamic(map['createdAt']),
      updatedAt: map['updatedAt'] != null
          ? _dateTimeFromDynamic(map['updatedAt'])
          : null,
      handledBy: map['handledBy'] as String?,
      adminNotes: map['adminNotes'] as String?,
      imageUrls: map['imageUrls'] != null
          ? List<String>.from(map['imageUrls'] as List)
          : null,
      adminId: map['adminId'] as String?,
    );
  }

  factory ReportModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return ReportModel.fromMap({
      ...data,
      'reportId': data['reportId'] ?? doc.id,
    });
  }

  // Helper methods for enum conversion
  static String typeToString(ReportType type) {
    switch (type) {
      case ReportType.tutor:
        return 'tutor';
      case ReportType.booking:
        return 'booking';
      case ReportType.payment:
        return 'payment';
      case ReportType.other:
        return 'other';
    }
  }

  static ReportType stringToType(String type) {
    switch (type.toLowerCase()) {
      case 'tutor':
        return ReportType.tutor;
      case 'booking':
        return ReportType.booking;
      case 'payment':
        return ReportType.payment;
      default:
        return ReportType.other;
    }
  }

  static String statusToString(ReportStatus status) {
    switch (status) {
      case ReportStatus.pending:
        return 'pending';
      case ReportStatus.inProgress:
        return 'inProgress';
      case ReportStatus.resolved:
        return 'resolved';
      case ReportStatus.rejected:
        return 'rejected';
    }
  }

  static ReportStatus stringToStatus(String status) {
    switch (status.toLowerCase()) {
      case 'inprogress':
      case 'in_progress':
        return ReportStatus.inProgress;
      case 'resolved':
        return ReportStatus.resolved;
      case 'rejected':
        return ReportStatus.rejected;
      default:
        return ReportStatus.pending;
    }
  }

  static DateTime _dateTimeFromDynamic(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is DateTime) {
      return value;
    } else if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return DateTime.now();
      }
    } else if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return DateTime.now();
  }
}
