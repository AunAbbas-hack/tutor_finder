import 'package:cloud_firestore/cloud_firestore.dart';

enum BookingStatus {
  pending,
  approved,
  rejected,
  completed,
  cancelled,
}

enum BookingType {
  singleSession,
  monthlyBooking,
}

class BookingModel {
  final String bookingId;
  final String parentId; // FK -> UserModel.userId
  final String tutorId; // FK -> UserModel.userId
  final String subject; // For backward compatibility - use subjects list for new bookings
  final List<String> subjects; // Multiple subjects support
  final DateTime bookingDate;
  final String bookingTime; // e.g., "4:00 PM"
  final BookingStatus status;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;
  
  // Monthly booking fields
  final BookingType bookingType;
  final DateTime? startDate; // For monthly bookings
  final List<int>? recurringDays; // 1=Monday, 2=Tuesday, etc. (1-7)
  final double? monthlyBudget; // In rupees
  final List<String>? childrenIds; // Selected children for this booking
  
  // Payment fields
  final String? paymentStatus; // 'pending', 'paid', 'failed', null if not paid yet
  final String? paymentId; // Stripe payment intent/session ID or PaymentModel.paymentId
  final DateTime? paymentDate; // Date when payment was completed

  const BookingModel({
    required this.bookingId,
    required this.parentId,
    required this.tutorId,
    required this.subject,
    this.subjects = const [],
    required this.bookingDate,
    required this.bookingTime,
    required this.status,
    this.notes,
    required this.createdAt,
    this.updatedAt,
    this.bookingType = BookingType.singleSession,
    this.startDate,
    this.recurringDays,
    this.monthlyBudget,
    this.childrenIds,
    this.paymentStatus,
    this.paymentId,
    this.paymentDate,
  });

  BookingModel copyWith({
    String? bookingId,
    String? parentId,
    String? tutorId,
    String? subject,
    List<String>? subjects,
    DateTime? bookingDate,
    String? bookingTime,
    BookingStatus? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    BookingType? bookingType,
    DateTime? startDate,
    List<int>? recurringDays,
    double? monthlyBudget,
    List<String>? childrenIds,
    String? paymentStatus,
    String? paymentId,
    DateTime? paymentDate,
  }) {
    return BookingModel(
      bookingId: bookingId ?? this.bookingId,
      parentId: parentId ?? this.parentId,
      tutorId: tutorId ?? this.tutorId,
      subject: subject ?? this.subject,
      subjects: subjects ?? this.subjects,
      bookingDate: bookingDate ?? this.bookingDate,
      bookingTime: bookingTime ?? this.bookingTime,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      bookingType: bookingType ?? this.bookingType,
      startDate: startDate ?? this.startDate,
      recurringDays: recurringDays ?? this.recurringDays,
      monthlyBudget: monthlyBudget ?? this.monthlyBudget,
      childrenIds: childrenIds ?? this.childrenIds,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentId: paymentId ?? this.paymentId,
      paymentDate: paymentDate ?? this.paymentDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bookingId': bookingId,
      'parentId': parentId,
      'tutorId': tutorId,
      'subject': subject, // Keep for backward compatibility
      'subjects': subjects.isNotEmpty ? subjects : [subject], // Use subjects if available
      'bookingDate': bookingDate.toIso8601String(),
      'bookingTime': bookingTime,
      'status': statusToString(status),
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'bookingType': _bookingTypeToString(bookingType),
      'startDate': startDate?.toIso8601String(),
      'recurringDays': recurringDays,
      'monthlyBudget': monthlyBudget,
      'childrenIds': childrenIds,
      'paymentStatus': paymentStatus,
      'paymentId': paymentId,
      'paymentDate': paymentDate?.toIso8601String(),
    };
  }

  factory BookingModel.fromMap(Map<String, dynamic> map) {
    final subjectsList = (map['subjects'] as List?)?.cast<String>() ?? [];
    final subject = map['subject'] as String? ?? '';
    
    return BookingModel(
      bookingId: map['bookingId'] as String,
      parentId: map['parentId'] as String,
      tutorId: map['tutorId'] as String,
      subject: subjectsList.isNotEmpty ? subjectsList.first : subject,
      subjects: subjectsList.isNotEmpty ? subjectsList : (subject.isNotEmpty ? [subject] : []),
      bookingDate: DateTime.parse(map['bookingDate'] as String),
      bookingTime: map['bookingTime'] as String,
      status: _statusFromString(map['status'] as String?),
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
      bookingType: _bookingTypeFromString(map['bookingType'] as String?),
      startDate: map['startDate'] != null
          ? DateTime.parse(map['startDate'] as String)
          : null,
      recurringDays: (map['recurringDays'] as List?)?.cast<int>(),
      monthlyBudget: (map['monthlyBudget'] as num?)?.toDouble(),
      childrenIds: (map['childrenIds'] as List?)?.cast<String>(),
      paymentStatus: map['paymentStatus'] as String?,
      paymentId: map['paymentId'] as String?,
      paymentDate: map['paymentDate'] != null
          ? DateTime.parse(map['paymentDate'] as String)
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

  static String _bookingTypeToString(BookingType type) {
    switch (type) {
      case BookingType.singleSession:
        return 'singleSession';
      case BookingType.monthlyBooking:
        return 'monthlyBooking';
    }
  }

  static BookingType _bookingTypeFromString(String? value) {
    switch (value) {
      case 'monthlyBooking':
        return BookingType.monthlyBooking;
      case 'singleSession':
      default:
        return BookingType.singleSession;
    }
  }
}

