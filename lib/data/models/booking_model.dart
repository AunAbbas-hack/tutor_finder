import 'package:cloud_firestore/cloud_firestore.dart';

enum BookingStatus {
  pending,
  approved,
  rejected,
  completed,
  cancelled,
}

class BookingModel {
  final String bookingId;
  final String parentId; // FK -> UserModel.userId
  final String tutorId; // FK -> UserModel.userId
  final String subject;
  final DateTime bookingDate;
  final String bookingTime; // e.g., "4:00 PM"
  final BookingStatus status;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const BookingModel({
    required this.bookingId,
    required this.parentId,
    required this.tutorId,
    required this.subject,
    required this.bookingDate,
    required this.bookingTime,
    required this.status,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  BookingModel copyWith({
    String? bookingId,
    String? parentId,
    String? tutorId,
    String? subject,
    DateTime? bookingDate,
    String? bookingTime,
    BookingStatus? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BookingModel(
      bookingId: bookingId ?? this.bookingId,
      parentId: parentId ?? this.parentId,
      tutorId: tutorId ?? this.tutorId,
      subject: subject ?? this.subject,
      bookingDate: bookingDate ?? this.bookingDate,
      bookingTime: bookingTime ?? this.bookingTime,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bookingId': bookingId,
      'parentId': parentId,
      'tutorId': tutorId,
      'subject': subject,
      'bookingDate': bookingDate.toIso8601String(),
      'bookingTime': bookingTime,
      'status': statusToString(status),
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory BookingModel.fromMap(Map<String, dynamic> map) {
    return BookingModel(
      bookingId: map['bookingId'] as String,
      parentId: map['parentId'] as String,
      tutorId: map['tutorId'] as String,
      subject: map['subject'] as String,
      bookingDate: DateTime.parse(map['bookingDate'] as String),
      bookingTime: map['bookingTime'] as String,
      status: _statusFromString(map['status'] as String?),
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
    );
  }

  factory BookingModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return BookingModel.fromMap({
      ...data,
      'bookingId': data['bookingId'] ?? doc.id,
    });
  }

  static String statusToString(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return 'pending';
      case BookingStatus.approved:
        return 'approved';
      case BookingStatus.rejected:
        return 'rejected';
      case BookingStatus.completed:
        return 'completed';
      case BookingStatus.cancelled:
        return 'cancelled';
    }
  }

  static BookingStatus _statusFromString(String? value) {
    switch (value) {
      case 'pending':
        return BookingStatus.pending;
      case 'approved':
        return BookingStatus.approved;
      case 'rejected':
        return BookingStatus.rejected;
      case 'completed':
        return BookingStatus.completed;
      case 'cancelled':
        return BookingStatus.cancelled;
      default:
        return BookingStatus.pending;
    }
  }
}

