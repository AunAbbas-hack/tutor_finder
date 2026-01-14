// lib/views/tutor/availability_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_text.dart';
import '../../tutor_viewmodels/availability_vm.dart';
import '../../data/models/availability_model.dart';

class AvailabilityScreen extends StatefulWidget {
  const AvailabilityScreen({super.key});

  @override
  State<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends State<AvailabilityScreen> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final vm = AvailabilityViewModel();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          vm.initialize();
        });
        return vm;
      },
      child: Scaffold(
        backgroundColor: AppColors.lightBackground,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
            onPressed: () => Get.back(),
          ),
          title: const AppText(
            'Manage Availability',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: AppColors.lightBackground,
          actions: [
            Consumer<AvailabilityViewModel>(
              builder: (context, vm, _) {
                return Switch(
                  value: vm.availability?.isActive ?? false,
                  onChanged: (value) async {
                    final user = vm.availability?.tutorId;
                    if (user != null) {
                      await vm.toggleAvailabilityActive(
                        tutorId: user,
                        isActive: value,
                      );
                      if (vm.errorMessage == null) {
                        Get.snackbar(
                          'Success',
                          value
                              ? 'Availability enabled'
                              : 'Availability disabled',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: AppColors.success,
                          colorText: Colors.white,
                          duration: const Duration(seconds: 2),
                        );
                      }
                    }
                  },
                  activeColor: AppColors.primary,
                );
              },
            ),
            const SizedBox(width: 16),
          ],
        ),
        body: Consumer<AvailabilityViewModel>(
          builder: (context, vm, _) {
            if (vm.isLoading && vm.availability == null) {
              return const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              );
            }

            if (vm.errorMessage != null && vm.availability == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: 16),
                      AppText(
                        vm.errorMessage!,
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.textGrey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => vm.initialize(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: const AppText('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: AppColors.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppText(
                            'Set your weekly availability. Parents will see available time slots when booking.',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textDark,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Days List
                  ...List.generate(7, (index) {
                    final dayOfWeek = index + 1; // 1 = Monday, 7 = Sunday
                    return _buildDayCard(context, vm, dayOfWeek);
                  }),

                  const SizedBox(height: 24),

                  // Error Message
                  if (vm.errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.error.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: AppColors.error,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: AppText(
                              vm.errorMessage!,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: vm.isLoading
                          ? null
                          : () async {
                              // Availability is saved automatically when updated
                              Get.snackbar(
                                'Success',
                                'Availability saved successfully',
                                snackPosition: SnackPosition.BOTTOM,
                                backgroundColor: AppColors.success,
                                colorText: Colors.white,
                                duration: const Duration(seconds: 2),
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: vm.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const AppText(
                              'Availability Saved',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDayCard(
    BuildContext context,
    AvailabilityViewModel vm,
    int dayOfWeek,
  ) {
    final dayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    final dayName = dayNames[dayOfWeek - 1];
    final dayAvailability = vm.getDayAvailability(dayOfWeek);
    final isAvailable = dayAvailability?.isAvailable ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day Header
          Row(
            children: [
              Expanded(
                child: AppText(
                  dayName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              // Toggle Switch
              Switch(
                value: isAvailable,
                onChanged: (value) async {
                  final tutorId = vm.availability?.tutorId;
                  if (tutorId != null) {
                    await vm.toggleDayAvailability(
                      tutorId: tutorId,
                      dayOfWeek: dayOfWeek,
                    );
                  }
                },
                activeColor: AppColors.primary,
              ),
            ],
          ),

          // Time Slots (if available)
          if (isAvailable) ...[
            const SizedBox(height: 12),
            if (dayAvailability!.timeSlots.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: AppText(
                  'No time slots added',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textGrey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              )
            else
              ...dayAvailability.timeSlots.asMap().entries.map((entry) {
                final index = entry.key;
                final slot = entry.value;
                return _buildTimeSlotItem(
                  context,
                  vm,
                  dayOfWeek,
                  index,
                  slot,
                );
              }),
            const SizedBox(height: 8),
            // Add Time Slot Button
            OutlinedButton.icon(
              onPressed: () => _showAddTimeSlotDialog(context, vm, dayOfWeek),
              icon: const Icon(Icons.add, size: 18),
              label: const AppText('Add Time Slot'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeSlotItem(
    BuildContext context,
    AvailabilityViewModel vm,
    int dayOfWeek,
    int slotIndex,
    TimeSlot slot,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.lightBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: AppText(
              '${slot.displayStartTime} - ${slot.displayEndTime}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline,
              color: AppColors.error,
              size: 20,
            ),
            onPressed: vm.isLoading
                ? null
                : () async {
                    final tutorId = vm.availability?.tutorId;
                    if (tutorId != null) {
                      await vm.removeTimeSlot(
                        tutorId: tutorId,
                        dayOfWeek: dayOfWeek,
                        slotIndex: slotIndex,
                      );
                    }
                  },
          ),
        ],
      ),
    );
  }

  void _showAddTimeSlotDialog(
    BuildContext context,
    AvailabilityViewModel vm,
    int dayOfWeek,
  ) {
    String? selectedStartTime;
    String? selectedEndTime;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const AppText(
            'Add Time Slot',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Start Time Dropdown
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Start Time',
                  border: OutlineInputBorder(),
                ),
                value: selectedStartTime,
                items: vm.defaultStartTimes.map((time) {
                  final displayTime = _formatTo12Hour(time);
                  return DropdownMenuItem(
                    value: time,
                    child: AppText(displayTime),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedStartTime = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              // End Time Dropdown
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'End Time',
                  border: OutlineInputBorder(),
                ),
                value: selectedEndTime,
                items: vm.defaultEndTimes
                    .where((time) {
                      // Filter: end time must be after start time
                      if (selectedStartTime == null) return true;
                      return _timeToMinutes(time) > _timeToMinutes(selectedStartTime!);
                    })
                    .map((time) {
                  final displayTime = _formatTo12Hour(time);
                  return DropdownMenuItem(
                    value: time,
                    child: AppText(displayTime),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedEndTime = value;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const AppText('Cancel'),
            ),
            ElevatedButton(
              onPressed: (selectedStartTime != null && selectedEndTime != null)
                  ? () async {
                      final tutorId = vm.availability?.tutorId;
                      if (tutorId != null) {
                        await vm.addTimeSlot(
                          tutorId: tutorId,
                          dayOfWeek: dayOfWeek,
                          startTime: selectedStartTime!,
                          endTime: selectedEndTime!,
                        );
                        if (context.mounted && vm.errorMessage == null) {
                          Get.back();
                        }
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const AppText('Add'),
            ),
          ],
        ),
      ),
    );
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

  int _timeToMinutes(String time24) {
    try {
      final parts = time24.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts.length > 1 ? parts[1] : '0');
      return hour * 60 + minute;
    } catch (e) {
      return 0;
    }
  }
}
