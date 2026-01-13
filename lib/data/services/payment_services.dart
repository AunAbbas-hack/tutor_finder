// lib/data/services/payment_services.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payment_model.dart';

class PaymentService {
  final FirebaseFirestore _firestore;

  PaymentService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _paymentsCol =>
      _firestore.collection('payments');

  /// Create a new payment record
  Future<void> createPayment(PaymentModel payment) async {
    await _paymentsCol.doc(payment.paymentId).set(payment.toMap());
  }

  /// Get payment by ID
  Future<PaymentModel?> getPaymentById(String paymentId) async {
    final doc = await _paymentsCol.doc(paymentId).get();
    if (!doc.exists) return null;
    return PaymentModel.fromFirestore(doc);
  }

  /// Get all payments (for admin)
  Future<List<PaymentModel>> getAllPayments() async {
    try {
      final snapshot = await _paymentsCol
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => PaymentModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Get payments by booking ID
  Future<List<PaymentModel>> getPaymentsByBookingId(String bookingId) async {
    try {
      final snapshot = await _paymentsCol
          .where('bookingId', isEqualTo: bookingId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => PaymentModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Get payments by parent ID
  Future<List<PaymentModel>> getPaymentsByParentId(String parentId) async {
    try {
      final snapshot = await _paymentsCol
          .where('parentId', isEqualTo: parentId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => PaymentModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Get payments by tutor ID
  Future<List<PaymentModel>> getPaymentsByTutorId(String tutorId) async {
    try {
      final snapshot = await _paymentsCol
          .where('tutorId', isEqualTo: tutorId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => PaymentModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Get payments by status
  Future<List<PaymentModel>> getPaymentsByStatus(PaymentStatus status) async {
    try {
      final snapshot = await _paymentsCol
          .where('status', isEqualTo: PaymentModel.statusToString(status))
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => PaymentModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Update payment status
  Future<void> updatePaymentStatus(
    String paymentId,
    PaymentStatus status, {
    String? failureReason,
  }) async {
    final updateData = <String, dynamic>{
      'status': PaymentModel.statusToString(status),
      'updatedAt': DateTime.now().toIso8601String(),
    };

    if (status == PaymentStatus.completed) {
      updateData['completedAt'] = DateTime.now().toIso8601String();
    }

    if (failureReason != null) {
      updateData['failureReason'] = failureReason;
    }

    await _paymentsCol.doc(paymentId).update(updateData);
  }

  /// Mark payment as paid to tutor (admin action)
  Future<void> markAsPaidToTutor(String paymentId) async {
    await _paymentsCol.doc(paymentId).update({
      'tutorPaid': true,
      'tutorPaidAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  /// Get total revenue (sum of all completed payments)
  Future<double> getTotalRevenue() async {
    try {
      final completedPayments = await getPaymentsByStatus(PaymentStatus.completed);
      double total = 0.0;
      for (final payment in completedPayments) {
        total += payment.amount;
      }
      return total;
    } catch (e) {
      return 0.0;
    }
  }

  /// Get pending payments (completed but not paid to tutor)
  Future<List<PaymentModel>> getPendingTutorPayments() async {
    try {
      final snapshot = await _paymentsCol
          .where('status', isEqualTo: PaymentModel.statusToString(PaymentStatus.completed))
          .where('tutorPaid', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => PaymentModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      // If tutorPaid field doesn't exist, get all completed payments
      return await getPaymentsByStatus(PaymentStatus.completed);
    }
  }
}
