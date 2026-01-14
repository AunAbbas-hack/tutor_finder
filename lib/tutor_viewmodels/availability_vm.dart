// lib/tutor_viewmodels/availability_vm.dart
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/services/availability_service.dart';
import '../data/models/availability_model.dart';

class AvailabilityViewModel extends ChangeNotifier {
  final AvailabilityService _availabilityService;
  final FirebaseAuth _auth;

  AvailabilityViewModel({
    AvailabilityService? availabilityService,
    FirebaseAuth? auth,
  })  : _availabilityService = availabilityService ?? AvailabilityService(),
        _auth = auth ?? FirebaseAuth.instance;

  // ---------- State ----------
  bool _isDisposed = false;
  bool _isLoading = false;
  String? _errorMessage;
  AvailabilityModel? _availability;
  
  // Default time slots (common options)
  final List<String> _defaultStartTimes = [
    '09:00', '10:00', '11:00', '12:00', '13:00',
    '14:00', '15:00', '16:00', '17:00', '18:00', '19:00', '20:00'
  ];
  final List<String> _defaultEndTimes = [
    '10:00', '11:00', '12:00', '13:00', '14:00',
    '15:00', '16:00', '17:00', '18:00', '19:00', '20:00', '21:00'
  ];

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  AvailabilityModel? get availability => _availability;
  List<String> get defaultStartTimes => _defaultStartTimes;
  List<String> get defaultEndTimes => _defaultEndTimes;

  // Get availability for a day (1-7, Monday-Sunday)
  DayAvailability? getDayAvailability(int dayOfWeek) {
    return _availability?.getDayAvailability(dayOfWeek);
  }

  // ---------- Initialize ----------
  Future<void> initialize() async {
    if (_isDisposed) return;

    _setLoading(true);
    _errorMessage = null;

    try {
      final user = _auth.currentUser;
      if (user == null) {
        _errorMessage = 'User not authenticated';
        _setLoading(false);
        notifyListeners();
        return;
      }

      await loadAvailability(user.uid);
    } catch (e) {
      if (!_isDisposed) {
        _errorMessage = 'Failed to load availability: ${e.toString()}';
        if (kDebugMode) {
          print('Error loading availability: $e');
        }
      }
    } finally {
      if (!_isDisposed) {
        _setLoading(false);
        notifyListeners();
      }
    }
  }

  // ---------- Load Availability ----------
  Future<void> loadAvailability(String tutorId) async {
    try {
      _availability = await _availabilityService.getAvailabilityByTutorId(tutorId);
      
      // If no availability exists, create default structure
      if (_availability == null) {
        _availability = AvailabilityModel(
          availabilityId: '',
          tutorId: tutorId,
          weeklySchedule: _createDefaultSchedule(),
          createdAt: DateTime.now(),
        );
      }
    } catch (e) {
      if (!_isDisposed) {
        _errorMessage = 'Failed to load availability: ${e.toString()}';
      }
    }
  }

  // Create default schedule (empty, all days unavailable)
  List<DayAvailability> _createDefaultSchedule() {
    return List.generate(7, (index) {
      return DayAvailability(
        dayOfWeek: index + 1, // 1-7 (Monday-Sunday)
        isAvailable: false,
        timeSlots: [],
      );
    });
  }

  // ---------- Update Day Availability ----------
  Future<void> updateDayAvailability({
    required String tutorId,
    required int dayOfWeek,
    required bool isAvailable,
    List<TimeSlot>? timeSlots,
  }) async {
    if (_isDisposed) return;

    _setLoading(true);
    _errorMessage = null;

    try {
      final dayAvailability = DayAvailability(
        dayOfWeek: dayOfWeek,
        isAvailable: isAvailable,
        timeSlots: timeSlots ?? [],
      );

      await _availabilityService.updateDayAvailability(
        tutorId: tutorId,
        dayAvailability: dayAvailability,
      );

      // Reload availability
      await loadAvailability(tutorId);
    } catch (e) {
      if (!_isDisposed) {
        _errorMessage = 'Failed to update availability: ${e.toString()}';
      }
    } finally {
      if (!_isDisposed) {
        _setLoading(false);
        notifyListeners();
      }
    }
  }

  // ---------- Toggle Day Availability ----------
  Future<void> toggleDayAvailability({
    required String tutorId,
    required int dayOfWeek,
  }) async {
    final currentDay = getDayAvailability(dayOfWeek);
    final newIsAvailable = !(currentDay?.isAvailable ?? false);

    await updateDayAvailability(
      tutorId: tutorId,
      dayOfWeek: dayOfWeek,
      isAvailable: newIsAvailable,
      timeSlots: currentDay?.timeSlots ?? [],
    );
  }

  // ---------- Add Time Slot ----------
  Future<void> addTimeSlot({
    required String tutorId,
    required int dayOfWeek,
    required String startTime, // 24-hour format "HH:MM"
    required String endTime, // 24-hour format "HH:MM"
  }) async {
    final currentDay = getDayAvailability(dayOfWeek);
    final existingSlots = List<TimeSlot>.from(currentDay?.timeSlots ?? []);
    
    // Check if slot already exists
    final slotExists = existingSlots.any((slot) =>
        slot.startTime == startTime && slot.endTime == endTime);

    if (slotExists) {
      _errorMessage = 'This time slot already exists';
      notifyListeners();
      return;
    }

    // Add new slot
    existingSlots.add(TimeSlot(
      startTime: startTime,
      endTime: endTime,
      isAvailable: true,
    ));

    // Sort slots by start time
    existingSlots.sort((a, b) => a.startTime.compareTo(b.startTime));

    await updateDayAvailability(
      tutorId: tutorId,
      dayOfWeek: dayOfWeek,
      isAvailable: true,
      timeSlots: existingSlots,
    );
  }

  // ---------- Remove Time Slot ----------
  Future<void> removeTimeSlot({
    required String tutorId,
    required int dayOfWeek,
    required int slotIndex,
  }) async {
    final currentDay = getDayAvailability(dayOfWeek);
    final existingSlots = List<TimeSlot>.from(currentDay?.timeSlots ?? []);

    if (slotIndex < 0 || slotIndex >= existingSlots.length) {
      return;
    }

    existingSlots.removeAt(slotIndex);

    await updateDayAvailability(
      tutorId: tutorId,
      dayOfWeek: dayOfWeek,
      isAvailable: existingSlots.isNotEmpty,
      timeSlots: existingSlots,
    );
  }

  // ---------- Toggle Availability Active/Inactive ----------
  Future<void> toggleAvailabilityActive({
    required String tutorId,
    required bool isActive,
  }) async {
    if (_isDisposed) return;

    _setLoading(true);
    _errorMessage = null;

    try {
      await _availabilityService.toggleAvailability(
        tutorId: tutorId,
        isActive: isActive,
      );

      await loadAvailability(tutorId);
    } catch (e) {
      if (!_isDisposed) {
        _errorMessage = 'Failed to toggle availability: ${e.toString()}';
      }
    } finally {
      if (!_isDisposed) {
        _setLoading(false);
        notifyListeners();
      }
    }
  }

  // ---------- Save Complete Schedule ----------
  Future<bool> saveSchedule({
    required String tutorId,
    required List<DayAvailability> weeklySchedule,
  }) async {
    if (_isDisposed) return false;

    _setLoading(true);
    _errorMessage = null;

    try {
      await _availabilityService.updateWeeklySchedule(
        tutorId: tutorId,
        weeklySchedule: weeklySchedule,
      );

      await loadAvailability(tutorId);
      return true;
    } catch (e) {
      if (!_isDisposed) {
        _errorMessage = 'Failed to save schedule: ${e.toString()}';
      }
      return false;
    } finally {
      if (!_isDisposed) {
        _setLoading(false);
        notifyListeners();
      }
    }
  }

  // ---------- Helper Methods ----------
  void _setLoading(bool value) {
    if (!_isDisposed) {
      _isLoading = value;
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
