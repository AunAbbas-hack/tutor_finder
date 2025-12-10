import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_model.dart';

class BookingService {
  final FirebaseFirestore _firestore;

  BookingService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _bookingsCol =>
      _firestore.collection('bookings');

  /// Create a new booking
  Future<void> createBooking(BookingModel booking) async {
    await _bookingsCol.doc(booking.bookingId).set(booking.toMap());
  }

  /// Get booking by ID
  Future<BookingModel?> getBookingById(String bookingId) async {
    final doc = await _bookingsCol.doc(bookingId).get();
    if (!doc.exists) return null;
    return BookingModel.fromFirestore(doc);
  }

  /// Get all bookings for a parent
  Future<List<BookingModel>> getBookingsByParentId(String parentId) async {
    try {
      final snapshot = await _bookingsCol
          .where('parentId', isEqualTo: parentId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => BookingModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Get bookings by status for a parent
  Future<List<BookingModel>> getBookingsByParentAndStatus(
    String parentId,
    BookingStatus status,
  ) async {
    try {
      final snapshot = await _bookingsCol
          .where('parentId', isEqualTo: parentId)
          .where('status', isEqualTo: BookingModel.statusToString(status))
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => BookingModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Update booking status
  Future<void> updateBookingStatus(
    String bookingId,
    BookingStatus status,
  ) async {
    await _bookingsCol.doc(bookingId).update({
      'status': BookingModel.statusToString(status),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  /// Cancel booking
  Future<void> cancelBooking(String bookingId) async {
    await updateBookingStatus(bookingId, BookingStatus.cancelled);
  }

  /// Delete booking
  Future<void> deleteBooking(String bookingId) async {
    await _bookingsCol.doc(bookingId).delete();
  }
}

