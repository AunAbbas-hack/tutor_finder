// lib/data/models/payment_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum PaymentStatus {
  pending,
  processing,
  completed,
  failed,
  refunded,
  cancelled,
}

enum PaymentMethod {
  card,
  upi,
  netbanking,
  wallet,
  other,
}

class PaymentModel {
  final String paymentId;
  final String bookingId; // FK -> BookingModel.bookingId
  final String parentId; // FK -> UserModel.userId
  final String tutorId; // FK -> UserModel.userId
  final double amount; // Payment amount in rupees
  final String currency; // e.g., 'inr', 'usd'
  final PaymentStatus status;
  final PaymentMethod paymentMethod;
  final String? stripeSessionId; // Stripe checkout session ID
  final String? stripePaymentIntentId; // Stripe payment intent ID
  final String? transactionId; // Transaction ID from payment gateway
  final String? failureReason; // Reason if payment failed
  final DateTime createdAt;
  final DateTime? completedAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? metadata; // Additional payment data

  const PaymentModel({
    required this.paymentId,
    required this.bookingId,
    required this.parentId,
    required this.tutorId,
    required this.amount,
    this.currency = 'inr',
    required this.status,
    this.paymentMethod = PaymentMethod.card,
    this.stripeSessionId,
    this.stripePaymentIntentId,
    this.transactionId,
    this.failureReason,
    required this.createdAt,
    this.completedAt,
    this.updatedAt,
    this.metadata,
  });

  PaymentModel copyWith({
    String? paymentId,
    String? bookingId,
    String? parentId,
    String? tutorId,
    double? amount,
    String? currency,
    PaymentStatus? status,
    PaymentMethod? paymentMethod,
    String? stripeSessionId,
    String? stripePaymentIntentId,
    String? transactionId,
    String? failureReason,
    DateTime? createdAt,
    DateTime? completedAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return PaymentModel(
      paymentId: paymentId ?? this.paymentId,
      bookingId: bookingId ?? this.bookingId,
      parentId: parentId ?? this.parentId,
      tutorId: tutorId ?? this.tutorId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      stripeSessionId: stripeSessionId ?? this.stripeSessionId,
      stripePaymentIntentId: stripePaymentIntentId ?? this.stripePaymentIntentId,
      transactionId: transactionId ?? this.transactionId,
      failureReason: failureReason ?? this.failureReason,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'paymentId': paymentId,
      'bookingId': bookingId,
      'parentId': parentId,
      'tutorId': tutorId,
      'amount': amount,
      'currency': currency,
      'status': _statusToString(status),
      'paymentMethod': _paymentMethodToString(paymentMethod),
      'stripeSessionId': stripeSessionId,
      'stripePaymentIntentId': stripePaymentIntentId,
      'transactionId': transactionId,
      'failureReason': failureReason,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory PaymentModel.fromMap(Map<String, dynamic> map) {
    return PaymentModel(
      paymentId: map['paymentId'] as String,
      bookingId: map['bookingId'] as String,
      parentId: map['parentId'] as String,
      tutorId: map['tutorId'] as String,
      amount: (map['amount'] as num).toDouble(),
      currency: map['currency'] as String? ?? 'inr',
      status: _statusFromString(map['status'] as String?),
      paymentMethod: _paymentMethodFromString(map['paymentMethod'] as String?),
      stripeSessionId: map['stripeSessionId'] as String?,
      stripePaymentIntentId: map['stripePaymentIntentId'] as String?,
      transactionId: map['transactionId'] as String?,
      failureReason: map['failureReason'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      completedAt: map['completedAt'] != null
          ? DateTime.parse(map['completedAt'] as String)
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  factory PaymentModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return PaymentModel.fromMap({
      ...data,
      'paymentId': data['paymentId'] ?? doc.id,
    });
  }

  static String _statusToString(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return 'pending';
      case PaymentStatus.processing:
        return 'processing';
      case PaymentStatus.completed:
        return 'completed';
      case PaymentStatus.failed:
        return 'failed';
      case PaymentStatus.refunded:
        return 'refunded';
      case PaymentStatus.cancelled:
        return 'cancelled';
    }
  }

  static PaymentStatus _statusFromString(String? value) {
    switch (value) {
      case 'pending':
        return PaymentStatus.pending;
      case 'processing':
        return PaymentStatus.processing;
      case 'completed':
        return PaymentStatus.completed;
      case 'failed':
        return PaymentStatus.failed;
      case 'refunded':
        return PaymentStatus.refunded;
      case 'cancelled':
        return PaymentStatus.cancelled;
      default:
        return PaymentStatus.pending;
    }
  }

  static String _paymentMethodToString(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.card:
        return 'card';
      case PaymentMethod.upi:
        return 'upi';
      case PaymentMethod.netbanking:
        return 'netbanking';
      case PaymentMethod.wallet:
        return 'wallet';
      case PaymentMethod.other:
        return 'other';
    }
  }

  static PaymentMethod _paymentMethodFromString(String? value) {
    switch (value) {
      case 'card':
        return PaymentMethod.card;
      case 'upi':
        return PaymentMethod.upi;
      case 'netbanking':
        return PaymentMethod.netbanking;
      case 'wallet':
        return PaymentMethod.wallet;
      case 'other':
      default:
        return PaymentMethod.other;
    }
  }

  // Helper getters
  bool get isCompleted => status == PaymentStatus.completed;
  bool get isPending => status == PaymentStatus.pending;
  bool get isFailed => status == PaymentStatus.failed;
  bool get isProcessing => status == PaymentStatus.processing;
}
