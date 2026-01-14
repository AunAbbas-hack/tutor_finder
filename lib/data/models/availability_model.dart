// lib/data/models/availability_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single time slot in a day
class TimeSlot {
  final String startTime; // e.g., "09:00" (24-hour format)
  final String endTime; // e.g., "17:00" (24-hour format)
  final bool isAvailable;

  const TimeSlot({
    required this.startTime,
    required this.endTime,
    this.isAvailable = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'startTime': startTime,
      'endTime': endTime,
      'isAvailable': isAvailable,
    };
  }

  factory TimeSlot.fromMap(Map<String, dynamic> map) {
    return TimeSlot(
      startTime: map['startTime'] as String,
      endTime: map['endTime'] as String,
      isAvailable: map['isAvailable'] as bool? ?? true,
    );
  }

  // Convert 24-hour format to 12-hour format for display
  String get displayStartTime {
    return _formatTo12Hour(startTime);
  }

  String get displayEndTime {
    return _formatTo12Hour(endTime);
  }

  String _formatTo12Hour(String time24) {
    try {
      final parts = time24.split(':');
      final hour = int.parse(parts[0]);
      final minute = parts[1];
      
      if (hour == 0) {
        return '12:$minute AM';
      } else if (hour < 12) {
        return '$hour:$minute AM';
      } else if (hour == 12) {
        return '12:$minute PM';
      } else {
        return '${hour - 12}:$minute PM';
      }
    } catch (e) {
      return time24;
    }
  }
}

/// Day of week availability (Monday = 1, Sunday = 7)
class DayAvailability {
  final int dayOfWeek; // 1 = Monday, 2 = Tuesday, ..., 7 = Sunday
  final bool isAvailable;
  final List<TimeSlot> timeSlots;

  const DayAvailability({
    required this.dayOfWeek,
    this.isAvailable = false,
    this.timeSlots = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'dayOfWeek': dayOfWeek,
      'isAvailable': isAvailable,
      'timeSlots': timeSlots.map((slot) => slot.toMap()).toList(),
    };
  }

  factory DayAvailability.fromMap(Map<String, dynamic> map) {
    return DayAvailability(
      dayOfWeek: map['dayOfWeek'] as int,
      isAvailable: map['isAvailable'] as bool? ?? false,
      timeSlots: (map['timeSlots'] as List?)
              ?.map((slot) => TimeSlot.fromMap(slot as Map<String, dynamic>))
              .toList() ??
          <TimeSlot>[],
    );
  }

  String get dayName {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[dayOfWeek - 1];
  }
}

/// Tutor Availability Model
class AvailabilityModel {
  final String availabilityId;
  final String tutorId; // FK -> UserModel.userId
  final List<DayAvailability> weeklySchedule; // 7 days (Monday to Sunday)
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive; // Can temporarily disable availability

  const AvailabilityModel({
    required this.availabilityId,
    required this.tutorId,
    this.weeklySchedule = const [],
    required this.createdAt,
    this.updatedAt,
    this.isActive = true,
  });

  AvailabilityModel copyWith({
    String? availabilityId,
    String? tutorId,
    List<DayAvailability>? weeklySchedule,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return AvailabilityModel(
      availabilityId: availabilityId ?? this.availabilityId,
      tutorId: tutorId ?? this.tutorId,
      weeklySchedule: weeklySchedule ?? this.weeklySchedule,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'availabilityId': availabilityId,
      'tutorId': tutorId,
      'weeklySchedule': weeklySchedule.map((day) => day.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isActive': isActive,
    };
  }

  factory AvailabilityModel.fromMap(Map<String, dynamic> map) {
    return AvailabilityModel(
      availabilityId: map['availabilityId'] as String,
      tutorId: map['tutorId'] as String,
      weeklySchedule: (map['weeklySchedule'] as List?)
              ?.map((day) =>
                  DayAvailability.fromMap(day as Map<String, dynamic>))
              .toList() ??
          <DayAvailability>[],
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
      isActive: map['isActive'] as bool? ?? true,
    );
  }

  factory AvailabilityModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return AvailabilityModel.fromMap({
      ...data,
      'availabilityId': data['availabilityId'] ?? doc.id,
    });
  }

  /// Get availability for a specific day (1-7)
  DayAvailability? getDayAvailability(int dayOfWeek) {
    try {
      return weeklySchedule.firstWhere((day) => day.dayOfWeek == dayOfWeek);
    } catch (e) {
      return null;
    }
  }

  /// Get all available time slots for a specific date
  List<TimeSlot> getAvailableTimeSlotsForDate(DateTime date) {
    if (!isActive) return [];
    
    final dayOfWeek = date.weekday; // DateTime.weekday: Monday = 1, Sunday = 7
    final dayAvailability = getDayAvailability(dayOfWeek);
    
    if (dayAvailability == null || !dayAvailability.isAvailable) {
      return [];
    }
    
    return dayAvailability.timeSlots.where((slot) => slot.isAvailable).toList();
  }

  /// Check if tutor is available on a specific date and time
  bool isAvailableAt(DateTime date, String time24) {
    if (!isActive) return false;
    
    final dayOfWeek = date.weekday;
    final dayAvailability = getDayAvailability(dayOfWeek);
    
    if (dayAvailability == null || !dayAvailability.isAvailable) {
      return false;
    }
    
    // Check if time falls within any available time slot
    for (final slot in dayAvailability.timeSlots) {
      if (!slot.isAvailable) continue;
      
      if (_isTimeInRange(time24, slot.startTime, slot.endTime)) {
        return true;
      }
    }
    
    return false;
  }

  bool _isTimeInRange(String time, String start, String end) {
    try {
      final timeValue = _timeToMinutes(time);
      final startValue = _timeToMinutes(start);
      final endValue = _timeToMinutes(end);
      
      return timeValue >= startValue && timeValue <= endValue;
    } catch (e) {
      return false;
    }
  }

  int _timeToMinutes(String time24) {
    final parts = time24.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    return hour * 60 + minute;
  }
}
