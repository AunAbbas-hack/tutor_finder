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

  /// Mark session as completed (with notification support)
  /// This method should be used instead of updateBookingStatus for completing sessions
  Future<void> completeSession(String bookingId) async {
    await updateBookingStatus(bookingId, BookingStatus.completed);
    // Note: Notifications will be sent from the calling ViewModel
    // to have access to user names
  }

  /// Delete booking
  Future<void> deleteBooking(String bookingId) async {
    await _bookingsCol.doc(bookingId).delete();
  }

  /// Get all bookings for a tutor
  /// Note: Fetches all bookings and sorts client-side to avoid index requirement
  Future<List<BookingModel>> getBookingsByTutorId(String tutorId) async {
    try {
      // First try with orderBy (if index exists)
      try {
        final snapshot = await _bookingsCol
            .where('tutorId', isEqualTo: tutorId)
            .orderBy('createdAt', descending: true)
            .get();

        return snapshot.docs
            .map((doc) => BookingModel.fromFirestore(doc))
            .toList();
      } catch (e) {
        // If index doesn't exist, fetch without orderBy and sort client-side
        if (e.toString().contains('index')) {
          final snapshot = await _bookingsCol
              .where('tutorId', isEqualTo: tutorId)
              .get();

          final bookings = snapshot.docs
              .map((doc) => BookingModel.fromFirestore(doc))
              .toList();

          // Sort by createdAt descending (newest first)
          bookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return bookings;
        }
        rethrow;
      }
    } catch (e) {
      return [];
    }
  }

  /// Get bookings by status for a tutor
  /// Note: Fetches and filters client-side to avoid complex index requirement
  Future<List<BookingModel>> getBookingsByTutorAndStatus(
    String tutorId,
    BookingStatus status,
  ) async {
    try {
      // First try with orderBy (if index exists)
      try {
        final snapshot = await _bookingsCol
            .where('tutorId', isEqualTo: tutorId)
            .where('status', isEqualTo: BookingModel.statusToString(status))
            .orderBy('createdAt', descending: true)
            .get();

        return snapshot.docs
            .map((doc) => BookingModel.fromFirestore(doc))
            .toList();
      } catch (e) {
        // If index doesn't exist, fetch without orderBy and filter/sort client-side
        if (e.toString().contains('index')) {
          final snapshot = await _bookingsCol
              .where('tutorId', isEqualTo: tutorId)
              .get();

          final bookings = snapshot.docs
              .map((doc) => BookingModel.fromFirestore(doc))
              .where((booking) => booking.status == status)
              .toList();

          // Sort by createdAt descending (newest first)
          bookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return bookings;
        }
        rethrow;
      }
    } catch (e) {
      return [];
    }
  }

  /// Get upcoming bookings for a tutor (approved and future dates)
  /// Note: Fetches and filters client-side to avoid complex index requirement
  Future<List<BookingModel>> getUpcomingBookingsForTutor(String tutorId) async {
    try {
      final now = DateTime.now();
      
      // First try with orderBy (if index exists)
      try {
        final snapshot = await _bookingsCol
            .where('tutorId', isEqualTo: tutorId)
            .where('status', isEqualTo: BookingModel.statusToString(BookingStatus.approved))
            .orderBy('bookingDate', descending: false)
            .get();

        return snapshot.docs
            .map((doc) => BookingModel.fromFirestore(doc))
            .where((booking) => booking.bookingDate.isAfter(now))
            .toList();
      } catch (e) {
        // If index doesn't exist, fetch without orderBy and filter/sort client-side
        if (e.toString().contains('index')) {
          final snapshot = await _bookingsCol
              .where('tutorId', isEqualTo: tutorId)
              .get();

          final bookings = snapshot.docs
              .map((doc) => BookingModel.fromFirestore(doc))
              .where((booking) => 
                  booking.status == BookingStatus.approved &&
                  booking.bookingDate.isAfter(now))
              .toList();

          // Sort by bookingDate ascending (earliest first)
          bookings.sort((a, b) => a.bookingDate.compareTo(b.bookingDate));
          return bookings;
        }
        rethrow;
      }
    } catch (e) {
      return [];
    }
  }
}

