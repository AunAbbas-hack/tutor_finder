// lib/views/parent/request_booking_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_text.dart';
import '../../core/widgets/app_primary_button.dart';
import '../../parent_viewmodels/request_booking_vm.dart';
import '../../data/models/booking_model.dart';
import '../../data/models/student_model.dart';
import '../../data/services/user_services.dart';
import 'new_child_sheet.dart';

class RequestBookingScreen extends StatelessWidget {
  final String tutorId;
  final String tutorName;
  final String? tutorImageUrl;
  final List<String> tutorSubjects;

  const RequestBookingScreen({
    super.key,
    required this.tutorId,
    required this.tutorName,
    this.tutorImageUrl,
    required this.tutorSubjects,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final vm = RequestBookingViewModel(
          tutorId: tutorId,
          tutorName: tutorName,
          tutorImageUrl: tutorImageUrl,
          tutorSubjects: tutorSubjects,
        );
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
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const AppText(
            'Request Booking',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: AppColors.lightBackground,
        ),
        body: Consumer<RequestBookingViewModel>(
          builder: (context, vm, _) {
            if (vm.isLoading && vm.children.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tutor Info Card
                  _buildTutorInfoCard(vm),
                  const SizedBox(height: 24),

                  // Booking Type
                  _buildBookingType(vm),
                  const SizedBox(height: 24),

                  // Select Children
                  _buildSelectChildren(vm, context),
                  const SizedBox(height: 24),

                  // Booking Details per Child (Expansion Tiles)
                  ...vm.selectedChildrenIds.map((childId) =>
                    _buildChildBookingExpansionTile(vm, childId, context),
                  ),

                  // Recurring Days (for monthly booking - shared)
                  if (vm.bookingType == BookingType.monthlyBooking && vm.selectedChildrenIds.isNotEmpty) ...[
                    _buildRecurringDays(vm),
                    const SizedBox(height: 24),
                  ],

                  // Total Estimated Cost
                  if (vm.selectedChildrenIds.isNotEmpty) ...[
                    _buildTotalEstimate(vm),
                    const SizedBox(height: 32),
                  ],

                  // Submit Button
                  _buildSubmitButton(vm, context),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTutorInfoCard(RequestBookingViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Profile Picture
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.lightBackground,
              border: Border.all(color: AppColors.border, width: 1),
              image: tutorImageUrl != null && tutorImageUrl!.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(tutorImageUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: tutorImageUrl == null || tutorImageUrl!.isEmpty
                ? const Icon(Icons.person, size: 30, color: AppColors.iconGrey)
                : null,
          ),
          const SizedBox(width: 16),
          // Name and Subjects
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  tutorName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                AppText(
                  tutorSubjects.join(' & '),
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textGrey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectChildren(RequestBookingViewModel vm, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppText(
          'Select Children',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 12),
        if (vm.children.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.lightBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const AppText(
              'No children added yet. Please add children from your profile.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textGrey,
              ),
            ),
          )
        else
          ...vm.children.map((child) {
            final isSelected = vm.isChildSelected(child.studentId);
            return _buildChildCheckbox(vm, child, isSelected);
          }),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () {
            _showAddChildSheet(context, vm);
          },
          child: const AppText(
            '+ Add another child',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChildCheckbox(
    RequestBookingViewModel vm,
    StudentModel child,
    bool isSelected,
  ) {
    final userService = UserService();
    return FutureBuilder(
      future: userService.getUserById(child.studentId),
      builder: (context, snapshot) {
        final childName = snapshot.data?.name ?? 'Unknown';
        final grade = child.grade ?? 'N/A';

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.lightBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Checkbox(
                value: isSelected,
                onChanged: (_) => vm.toggleChild(child.studentId),
                activeColor: AppColors.primary,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      childName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    AppText(
                      'Grade $grade',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBookingType(RequestBookingViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppText(
          'Booking Type',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildBookingTypeButton(
                vm,
                'Single Session',
                BookingType.singleSession,
                vm.bookingType == BookingType.singleSession,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildBookingTypeButton(
                vm,
                'Monthly Booking',
                BookingType.monthlyBooking,
                vm.bookingType == BookingType.monthlyBooking,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBookingTypeButton(
    RequestBookingViewModel vm,
    String label,
    BookingType type,
    bool isSelected,
  ) {
    return GestureDetector(
      onTap: () => vm.setBookingType(type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : AppColors.lightBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: AppText(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? AppColors.primary : AppColors.textDark,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDayButton(RequestBookingViewModel vm, String label, int day) {
    final isSelected = vm.isRecurringDaySelected(day);
    return GestureDetector(
      onTap: () => vm.toggleRecurringDay(day),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: AppText(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : AppColors.textDark,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChildBookingExpansionTile(
    RequestBookingViewModel vm,
    String childId,
    BuildContext context,
  ) {
    final child = vm.children.firstWhere((c) => c.studentId == childId);
    final userService = UserService();
    final details = vm.getChildBookingDetails(childId);

    if (details == null) return const SizedBox.shrink();

    return FutureBuilder(
      future: userService.getUserById(childId),
      builder: (context, snapshot) {
        final childName = snapshot.data?.name ?? 'Unknown';
        final grade = child.grade ?? 'N/A';

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: true,
              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              childrenPadding: const EdgeInsets.all(16),
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withOpacity(0.1),
                ),
                child: const Icon(Icons.person, color: AppColors.primary, size: 20),
              ),
              title: AppText(
                childName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              subtitle: AppText(
                'Grade $grade',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textGrey,
                ),
              ),
              children: [
                // Select Subjects (per child)
                const AppText(
                  'SELECT SUBJECTS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textGrey,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: tutorSubjects.map((subject) {
                    final isSelected = vm.isChildSubjectSelected(childId, subject);
                    return GestureDetector(
                      onTap: () => vm.toggleChildSubject(childId, subject),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : AppColors.lightBackground,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.border,
                            width: 1,
                          ),
                        ),
                        child: AppText(
                          subject,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isSelected ? Colors.white : AppColors.textDark,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Booking Date
                const AppText(
                  'BOOKING DATE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textGrey,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: details.bookingDate ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      vm.setChildBookingDate(childId, picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.lightBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 20, color: AppColors.primary),
                        const SizedBox(width: 12),
                        AppText(
                          details.bookingDate != null
                              ? DateFormat('dd/MM/yyyy').format(details.bookingDate!)
                              : 'Select date',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Time Slot
                const AppText(
                  'TIME SLOT',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textGrey,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                // Same time slots for both Single Session and Monthly Booking
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // Predefined time slots
                    ...vm.availableTimeSlots.map((time) {
                      final isSelected = details.timeSlot == time && !vm.isCustomTimeSlot(details.timeSlot);
                      return GestureDetector(
                        onTap: () => vm.setChildTimeSlot(childId, time),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : AppColors.lightBackground,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : AppColors.border,
                            ),
                          ),
                          child: AppText(
                            time,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isSelected ? Colors.white : AppColors.textDark,
                            ),
                          ),
                        ),
                      );
                    }),
                    // Custom time slot button
                    GestureDetector(
                      onTap: () => _showCustomTimeSlotSheet(context, vm, childId, details.timeSlot),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: vm.isCustomTimeSlot(details.timeSlot) ? AppColors.primary : AppColors.lightBackground,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: vm.isCustomTimeSlot(details.timeSlot) ? AppColors.primary : AppColors.border,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: AppText(
                                vm.isCustomTimeSlot(details.timeSlot) && details.timeSlot != null
                                    ? (details.timeSlot!.length > 20 
                                        ? '${details.timeSlot!.substring(0, 17)}...' 
                                        : details.timeSlot!)
                                    : 'CUSTOM',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: vm.isCustomTimeSlot(details.timeSlot) ? Colors.white : AppColors.textDark,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.edit,
                              size: 14,
                              color: vm.isCustomTimeSlot(details.timeSlot) ? Colors.white : AppColors.textGrey,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Budget
                const AppText(
                  'BUDGET',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textGrey,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppText(
                      vm.formatBudget(details.budget),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    if (vm.bookingType == BookingType.monthlyBooking)
                      AppText(
                        vm.formatPricePerSession(vm.getChildPricePerSession(childId)),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textGrey,
                        ),
                      ),
                  ],
                ),
                Slider(
                  value: details.budget,
                  min: vm.bookingType == BookingType.singleSession ? 500.0 : 2000.0,
                  max: 12000.0,
                  divisions: 50,
                  activeColor: AppColors.primary,
                  onChanged: (value) => vm.setChildBudget(childId, value),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppText(
                      vm.bookingType == BookingType.singleSession ? '500 Rs.' : '2,000 Rs.',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textGrey,
                      ),
                    ),
                    const AppText(
                      '12,000 Rs.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecurringDays(RequestBookingViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppText(
            'Recurring Days (applies to all children)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildDayButton(vm, 'M', 1),
              _buildDayButton(vm, 'T', 2),
              _buildDayButton(vm, 'W', 3),
              _buildDayButton(vm, 'T', 4),
              _buildDayButton(vm, 'F', 5),
              _buildDayButton(vm, 'S', 6),
              _buildDayButton(vm, 'S', 7),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotalEstimate(RequestBookingViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const AppText(
            'Total Estimated',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          AppText(
            '${vm.totalEstimatedCost.toStringAsFixed(0)} Rs.',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(
    RequestBookingViewModel vm,
    BuildContext context,
  ) {
    final buttonText = vm.bookingType == BookingType.monthlyBooking
        ? 'Confirm Booking'
        : 'Confirm Booking';

    return AppPrimaryButton(
      label: buttonText,
      isLoading: vm.isLoading,
      isDisabled: !vm.canSubmit,
      onPressed: () async {
        final success = await vm.submitBooking();
        if (success) {
          Get.snackbar(
            'Success',
            'Booking requests submitted successfully',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppColors.success,
            colorText: Colors.white,
            duration: const Duration(seconds: 2),
          );
          Navigator.of(context).pop();
        } else {
          Get.snackbar(
            'Error',
            vm.errorMessage ?? 'Failed to submit booking',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppColors.error,
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
          );
        }
      },
    );
  }

  void _showAddChildSheet(BuildContext context, RequestBookingViewModel vm) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NewChildSheet(
        onChildAdded: () {
          // Refresh children list after child is added
          vm.refreshChildren();
        },
      ),
    );
  }

  void _showCustomTimeSlotSheet(
    BuildContext context,
    RequestBookingViewModel vm,
    String childId,
    String? currentTimeSlot,
  ) {
    // Deselect any predefined slots when custom is opened
    if (currentTimeSlot != null && !vm.isCustomTimeSlot(currentTimeSlot)) {
      // Clear the selected predefined slot
      vm.setChildTimeSlot(childId, '');
    }
    
    // Parse current time range if it's custom, otherwise start with null
    TimeOfDay? initialStartTime;
    TimeOfDay? initialEndTime;
    
    if (currentTimeSlot != null && vm.isCustomTimeSlot(currentTimeSlot)) {
      // Try to parse the custom time range (e.g., "4:00 PM to 5:30 PM")
      final times = _parseTimeRange(currentTimeSlot);
      if (times != null) {
        initialStartTime = times['start'];
        initialEndTime = times['end'];
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CustomTimeRangeSheet(
        initialStartTime: initialStartTime,
        initialEndTime: initialEndTime,
        onTimeRangeSelected: (TimeOfDay? start, TimeOfDay? end) {
          if (start != null && end != null) {
            final formattedRange = '${_formatTimeOfDay(start)} to ${_formatTimeOfDay(end)}';
            vm.setChildTimeSlot(childId, formattedRange);
          }
        },
      ),
    );
  }

  Map<String, TimeOfDay>? _parseTimeRange(String timeRange) {
    try {
      // Parse format like "4:00 PM to 5:30 PM"
      final parts = timeRange.split(' to ');
      if (parts.length == 2) {
        return {
          'start': _parseTimeString(parts[0].trim()),
          'end': _parseTimeString(parts[1].trim()),
        };
      }
    } catch (e) {
      // Return null if parsing fails
    }
    return null;
  }

  TimeOfDay _parseTimeString(String timeStr) {
    try {
      final parts = timeStr.replaceAll(' ', '').toUpperCase().split(':');
      if (parts.length == 2) {
        int hour = int.parse(parts[0]);
        final minuteParts = parts[1].split(RegExp(r'[AP]'));
        int minute = minuteParts.isNotEmpty ? int.parse(minuteParts[0]) : 0;
        final isPM = timeStr.toUpperCase().contains('PM');
        if (isPM && hour != 12) hour += 12;
        if (!isPM && hour == 12) hour = 0;
        return TimeOfDay(hour: hour, minute: minute);
      }
    } catch (e) {
      // Return default if parsing fails
    }
    return const TimeOfDay(hour: 16, minute: 0);
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
}

// Custom Time Range Bottom Sheet Widget
class _CustomTimeRangeSheet extends StatefulWidget {
  final TimeOfDay? initialStartTime;
  final TimeOfDay? initialEndTime;
  final Function(TimeOfDay? start, TimeOfDay? end) onTimeRangeSelected;

  const _CustomTimeRangeSheet({
    this.initialStartTime,
    this.initialEndTime,
    required this.onTimeRangeSelected,
  });

  @override
  State<_CustomTimeRangeSheet> createState() => _CustomTimeRangeSheetState();
}

class _CustomTimeRangeSheetState extends State<_CustomTimeRangeSheet> {
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _isStartSelected = true;

  @override
  void initState() {
    super.initState();
    _startTime = widget.initialStartTime;
    _endTime = widget.initialEndTime;
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  String _formatTimeRange() {
    if (_startTime == null && _endTime == null) {
      return '00:00 to 00:00';
    } else if (_startTime != null && _endTime != null) {
      return '${_formatTimeOfDay(_startTime!)} to ${_formatTimeOfDay(_endTime!)}';
    } else if (_startTime != null) {
      return '${_formatTimeOfDay(_startTime!)} to 00:00';
    } else {
      return '00:00 to ${_formatTimeOfDay(_endTime!)}';
    }
  }

  String _calculateDuration() {
    if (_startTime == null || _endTime == null) {
      return '0h';
    }
    
    final startMinutes = _startTime!.hour * 60 + _startTime!.minute;
    final endMinutes = _endTime!.hour * 60 + _endTime!.minute;
    int diffMinutes = endMinutes - startMinutes;
    
    if (diffMinutes < 0) {
      diffMinutes += 24 * 60; // Handle next day
    }
    
    final hours = diffMinutes ~/ 60;
    final minutes = diffMinutes % 60;
    
    if (hours > 0 && minutes > 0) {
      return '${hours}h ${minutes}m';
    } else if (hours > 0) {
      return '${hours}h';
    } else {
      return '${minutes}m';
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 700;
    final isTablet = screenWidth > 600;
    
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      constraints: BoxConstraints(
        maxHeight: screenHeight * 0.85,
        minHeight: isSmallScreen ? 500 : 600,
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + (isSmallScreen ? 16 : 24),
          left: isTablet ? 32 : 20,
          right: isTablet ? 32 : 20,
          top: isSmallScreen ? 16 : 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: EdgeInsets.only(bottom: isSmallScreen ? 16 : 20),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            
            // Header Section - Selected Time Range
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppText(
                  'SELECTED TIME RANGE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textGrey,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                AppText(
                  _formatTimeRange(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                AppText(
                  'Duration: ${_calculateDuration()}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            
            SizedBox(height: isSmallScreen ? 20 : 24),
            
            // Tab Bar for Start/End
            Container(
              decoration: BoxDecoration(
                color: AppColors.lightBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildTabButton('Start', _isStartSelected, () {
                      setState(() => _isStartSelected = true);
                    }),
                  ),
                  Expanded(
                    child: _buildTabButton('End', !_isStartSelected, () {
                      setState(() => _isStartSelected = false);
                    }),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: isSmallScreen ? 16 : 20),
            
            // Time Picker
            Container(
              height: isSmallScreen ? 200 : 240,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: CupertinoTheme(
                data: CupertinoThemeData(
                  primaryColor: AppColors.primary,
                  textTheme: CupertinoTextThemeData(
                    dateTimePickerTextStyle: TextStyle(
                      fontSize: isSmallScreen ? 20 : 22,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                    pickerTextStyle: TextStyle(
                      fontSize: isSmallScreen ? 20 : 22,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                child: CupertinoDatePicker(
                  key: ValueKey(_isStartSelected ? 'start_${_startTime?.hour}_${_startTime?.minute}' : 'end_${_endTime?.hour}_${_endTime?.minute}'),
                  mode: CupertinoDatePickerMode.time,
                  initialDateTime: DateTime(
                    2024,
                    1,
                    1,
                    _isStartSelected 
                        ? (_startTime?.hour ?? 0)
                        : (_endTime?.hour ?? 0),
                    _isStartSelected 
                        ? (_startTime?.minute ?? 0)
                        : (_endTime?.minute ?? 0),
                  ),
                  use24hFormat: false,
                  itemExtent: isSmallScreen ? 40 : 44,
                  onDateTimeChanged: (DateTime newDateTime) {
                    setState(() {
                      final newTime = TimeOfDay.fromDateTime(newDateTime);
                      if (_isStartSelected) {
                        _startTime = newTime;
                        // If end time exists and is before or equal to start time, adjust it
                        if (_endTime != null) {
                          if (_endTime!.hour * 60 + _endTime!.minute <= 
                              _startTime!.hour * 60 + _startTime!.minute) {
                            _endTime = TimeOfDay(
                              hour: (_startTime!.hour + 1) % 24,
                              minute: _startTime!.minute,
                            );
                          }
                        }
                      } else {
                        _endTime = newTime;
                        // If start time exists and end time is before or equal to start time, adjust start
                        if (_startTime != null) {
                          if (_endTime!.hour * 60 + _endTime!.minute <= 
                              _startTime!.hour * 60 + _startTime!.minute) {
                            _startTime = TimeOfDay(
                              hour: (_endTime!.hour - 1 + 24) % 24,
                              minute: _endTime!.minute,
                            );
                          }
                        }
                      }
                    });
                  },
                ),
              ),
            ),
            
            SizedBox(height: isSmallScreen ? 16 : 24),
            
            // Action Buttons
            Column(
              children: [
                // Set Time Range Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _startTime != null && _endTime != null
                        ? () {
                            widget.onTimeRangeSelected(_startTime, _endTime);
                            Navigator.of(context).pop();
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 14 : 16),
                      backgroundColor: _startTime != null && _endTime != null
                          ? AppColors.primary
                          : AppColors.border,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: AppText(
                      'Set Time Range',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _startTime != null && _endTime != null
                            ? Colors.white
                            : AppColors.textGrey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Cancel Button
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 12 : 14),
                    ),
                    child: const AppText(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: isSmallScreen ? 8 : 12),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            AppText(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.primary : AppColors.textGrey,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              height: 3,
              width: 40,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

