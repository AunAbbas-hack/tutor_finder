// lib/data/services/availability_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/availability_model.dart';
import '../models/booking_model.dart';
import 'booking_services.dart';

class AvailabilityService {
  final FirebaseFirestore _firestore;
  final BookingService _bookingService;

  AvailabilityService({
    FirebaseFirestore? firestore,
    BookingService? bookingService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _bookingService = bookingService ?? BookingService();

  CollectionReference<Map<String, dynamic>> get _availabilityCol =>
      _firestore.collection('availability');

  // ---------- CREATE/UPDATE ----------

  /// Create or update tutor availability
  Future<void> saveAvailability(AvailabilityModel availability) async {
    try {
      final now = DateTime.now();
      final availabilityData = availability.copyWith(
        updatedAt: now,
      ).toMap();

      await _availabilityCol
          .doc(availability.availabilityId)
          .set(availabilityData, SetOptions(merge: true));

      if (kDebugMode) {
        print('✅ Availability saved: ${availability.availabilityId}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error saving availability: $e');
      }
      rethrow;
    }
  }

  /// Update weekly schedule for a tutor
  Future<void> updateWeeklySchedule({
    required String tutorId,
    required List<DayAvailability> weeklySchedule,
  }) async {
    try {
      // Get existing availability or create new
      final availability = await getAvailabilityByTutorId(tutorId);
      
      final availabilityId = availability?.availabilityId ?? 
          _availabilityCol.doc().id;

      final now = DateTime.now();
      final updatedAvailability = AvailabilityModel(
        availabilityId: availabilityId,
        tutorId: tutorId,
        weeklySchedule: weeklySchedule,
        createdAt: availability?.createdAt ?? now,
        updatedAt: now,
        isActive: availability?.isActive ?? true,
      );

      await saveAvailability(updatedAvailability);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating weekly schedule: $e');
      }
      rethrow;
    }
  }

  /// Update single day availability
  Future<void> updateDayAvailability({
    required String tutorId,
    required DayAvailability dayAvailability,
  }) async {
    try {
      final availability = await getAvailabilityByTutorId(tutorId);
      
      if (availability == null) {
        // Create new availability with this day
        final availabilityId = _availabilityCol.doc().id;
        final now = DateTime.now();
        final newAvailability = AvailabilityModel(
          availabilityId: availabilityId,
          tutorId: tutorId,
          weeklySchedule: [dayAvailability],
          createdAt: now,
          updatedAt: now,
        );
        await saveAvailability(newAvailability);
      } else {
        // Update existing availability
        final updatedSchedule = List<DayAvailability>.from(availability.weeklySchedule);
        final existingIndex = updatedSchedule.indexWhere(
          (day) => day.dayOfWeek == dayAvailability.dayOfWeek,
        );

        if (existingIndex >= 0) {
          updatedSchedule[existingIndex] = dayAvailability;
        } else {
          updatedSchedule.add(dayAvailability);
        }

        await updateWeeklySchedule(
          tutorId: tutorId,
          weeklySchedule: updatedSchedule,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating day availability: $e');
      }
      rethrow;
    }
  }

  /// Toggle availability active/inactive
  Future<void> toggleAvailability({
    required String tutorId,
    required bool isActive,
  }) async {
    try {
      final availability = await getAvailabilityByTutorId(tutorId);
      
      if (availability == null) {
        throw Exception('Availability not found for tutor');
      }

      final updated = availability.copyWith(
        isActive: isActive,
        updatedAt: DateTime.now(),
      );

      await saveAvailability(updated);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error toggling availability: $e');
      }
      rethrow;
    }
  }

  // ---------- READ ----------

  /// Get availability by tutor ID
  Future<AvailabilityModel?> getAvailabilityByTutorId(String tutorId) async {
    try {
      final snapshot = await _availabilityCol
          .where('tutorId', isEqualTo: tutorId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return AvailabilityModel.fromFirestore(snapshot.docs.first);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching availability: $e');
      }
      return null;
    }
  }

  /// Get available time slots for a specific date
  /// Excludes already booked slots
  Future<List<TimeSlot>> getAvailableTimeSlotsForDate({
    required String tutorId,
    required DateTime date,
    bool excludeBooked = true,
  }) async {
    try {
      final availability = await getAvailabilityByTutorId(tutorId);
      
      if (availability == null || !availability.isActive) {
        return [];
      }

      // Get time slots from availability
      final allSlots = availability.getAvailableTimeSlotsForDate(date);
      
      if (!excludeBooked) {
        return allSlots;
      }

      // Get booked slots for this date
      final bookings = await _bookingService.getBookingsByTutorId(tutorId);
      final dateBookings = bookings.where((booking) {
        final bookingDate = booking.bookingDate;
        return bookingDate.year == date.year &&
            bookingDate.month == date.month &&
            bookingDate.day == date.day &&
            (booking.status == BookingStatus.approved ||
                booking.status == BookingStatus.pending);
      }).toList();

      // Filter out booked time slots
      final bookedTimes = dateBookings
          .map((b) => _timeStringTo24Hour(b.bookingTime))
          .where((time) => time != null)
          .toList();

      return allSlots.where((slot) {
        // Check if slot overlaps with any booked time
        for (final bookedTime in bookedTimes) {
          if (bookedTime != null &&
              availability.isAvailableAt(date, bookedTime)) {
            // Check if this slot contains the booked time
            if (_isTimeInSlot(bookedTime, slot)) {
              return false; // Slot is booked
            }
          }
        }
        return true; // Slot is available
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting available time slots: $e');
      }
      return [];
    }
  }

  /// Convert time string (e.g., "4:00 PM") to 24-hour format (e.g., "16:00")
  String? _timeStringTo24Hour(String timeString) {
    try {
      // Remove spaces and convert to uppercase
      final cleanTime = timeString.trim().toUpperCase();
      
      // Check if it's already in 24-hour format
      if (cleanTime.contains(':')) {
        final parts = cleanTime.split(':');
        if (parts.length == 2) {
          var hour = int.parse(parts[0]);
          var minute = parts[1].replaceAll(RegExp(r'[^0-9]'), '');
          
          // Check for AM/PM
          if (cleanTime.contains('PM') && hour != 12) {
            hour += 12;
          } else if (cleanTime.contains('AM') && hour == 12) {
            hour = 0;
          }
          
          return '${hour.toString().padLeft(2, '0')}:${minute.padLeft(2, '0')}';
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  bool _isTimeInSlot(String? time24, TimeSlot slot) {
    if (time24 == null) return false;
    
    try {
      final timeValue = _timeToMinutes(time24);
      final startValue = _timeToMinutes(slot.startTime);
      final endValue = _timeToMinutes(slot.endTime);
      
      return timeValue >= startValue && timeValue <= endValue;
    } catch (e) {
      return false;
    }
  }

  int _timeToMinutes(String time24) {
    final parts = time24.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts.length > 1 ? parts[1] : '0');
    return hour * 60 + minute;
  }

  /// Check if tutor is available at specific date and time
  Future<bool> isTutorAvailableAt({
    required String tutorId,
    required DateTime date,
    required String time24, // 24-hour format "HH:MM"
  }) async {
    try {
      final availability = await getAvailabilityByTutorId(tutorId);
      
      if (availability == null || !availability.isActive) {
        return false;
      }

      if (!availability.isAvailableAt(date, time24)) {
        return false;
      }

      // Check if already booked
      final bookings = await _bookingService.getBookingsByTutorId(tutorId);
      final conflictingBooking = bookings.any((booking) {
        final bookingDate = booking.bookingDate;
        final isSameDate = bookingDate.year == date.year &&
            bookingDate.month == date.month &&
            bookingDate.day == date.day;
        
        if (!isSameDate) return false;
        
        final bookingTime24 = _timeStringTo24Hour(booking.bookingTime);
        if (bookingTime24 == null) return false;
        
        final bookingMinutes = _timeToMinutes(bookingTime24);
        final requestedMinutes = _timeToMinutes(time24);
        
        // Consider same hour as conflict
        return (booking.status == BookingStatus.approved ||
                booking.status == BookingStatus.pending) &&
            bookingMinutes == requestedMinutes;
      });

      return !conflictingBooking;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error checking availability: $e');
      }
      return false;
    }
  }

  // ---------- STREAM ----------

  /// Stream of availability for real-time updates
  Stream<AvailabilityModel?> getAvailabilityStream(String tutorId) {
    return _availabilityCol
        .where('tutorId', isEqualTo: tutorId)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return AvailabilityModel.fromFirestore(snapshot.docs.first);
    });
  }
}
