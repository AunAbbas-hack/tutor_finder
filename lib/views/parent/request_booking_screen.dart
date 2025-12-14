// lib/views/parent/request_booking_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_text.dart';
import '../../core/widgets/app_primary_button.dart';
import '../../core/widgets/app_textfield.dart';
import '../../parent_viewmodels/request_booking_vm.dart';
import '../../data/models/booking_model.dart';
import '../../data/models/student_model.dart';
import '../../data/services/user_services.dart';

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
        backgroundColor: AppColors.background,
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
          backgroundColor: AppColors.background,
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

                  // Select Subjects
                  _buildSelectSubjects(vm),
                  const SizedBox(height: 24),

                  // Select Children
                  _buildSelectChildren(vm),
                  const SizedBox(height: 24),

                  // Booking Type
                  _buildBookingType(vm),
                  const SizedBox(height: 24),

                  // Monthly Schedule (if monthly booking)
                  if (vm.bookingType == BookingType.monthlyBooking) ...[
                    _buildMonthlySchedule(vm, context),
                    const SizedBox(height: 24),
                  ],

                  // Single Session Schedule (if single session)
                  if (vm.bookingType == BookingType.singleSession) ...[
                    _buildSingleSessionSchedule(vm, context),
                    const SizedBox(height: 24),
                  ],

                  // Monthly Budget (if monthly booking)
                  if (vm.bookingType == BookingType.monthlyBooking) ...[
                    _buildMonthlyBudget(vm),
                    const SizedBox(height: 24),
                  ],

                  // Hourly Budget (if single session)
                  if (vm.bookingType == BookingType.singleSession) ...[
                    _buildHourlyBudget(vm),
                    const SizedBox(height: 24),
                  ],

                  // Additional Notes
                  _buildAdditionalNotes(vm),
                  const SizedBox(height: 32),

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

  Widget _buildSelectSubjects(RequestBookingViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppText(
          'Select Subjects',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tutorSubjects.map((subject) {
            final isSelected = vm.isSubjectSelected(subject);
            return GestureDetector(
              onTap: () => vm.toggleSubject(subject),
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
      ],
    );
  }

  Widget _buildSelectChildren(RequestBookingViewModel vm) {
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
            // TODO: Navigate to add child screen
            Get.snackbar(
              'Add Child',
              'Navigate to add child screen',
              snackPosition: SnackPosition.BOTTOM,
            );
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

  Widget _buildMonthlySchedule(
    RequestBookingViewModel vm,
    BuildContext context,
  ) {
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
            'Monthly Schedule',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 16),

          // Start Date
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: vm.startDate ?? DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) {
                vm.setStartDate(picked);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 20, color: AppColors.iconGrey),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppText(
                      vm.startDate != null
                          ? DateFormat('dd/MM/yyyy').format(vm.startDate!)
                          : 'Select start date',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Recurring Days
          const AppText(
            'Recurring Days',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
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
          const SizedBox(height: 16),

          // Time Slots
          const AppText(
            'Time Slot',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: vm.availableTimeSlots.map((timeSlot) {
              final isSelected = vm.selectedTimeSlot == timeSlot;
              return GestureDetector(
                onTap: () => vm.setTimeSlot(timeSlot),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected)
                        const Icon(Icons.check, size: 16, color: Colors.white)
                      else
                        const SizedBox(width: 16),
                      AppText(
                        timeSlot,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? Colors.white : AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
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

  Widget _buildMonthlyBudget(RequestBookingViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const AppText(
              'Monthly Budget',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            AppText(
              vm.formatBudget(vm.monthlyBudget),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Slider(
          value: vm.monthlyBudget,
          min: 2000.0, // ₹2000
          max: 12000.0, // ₹12000
          divisions: 50,
          activeColor: AppColors.primary,
          onChanged: (value) => vm.setMonthlyBudget(value),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const AppText(
              '₹2,000/mo',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textGrey,
              ),
            ),
            const AppText(
              '₹12,000/mo',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textGrey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.lightBackground,
            borderRadius: BorderRadius.circular(8),
          ),
          child: AppText(
            'Based on ${vm.sessionsPerMonth} sessions (${vm.formatPricePerSession()})',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textGrey,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSingleSessionSchedule(
    RequestBookingViewModel vm,
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Preferred Date
          const AppText(
            'Preferred Date',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: vm.preferredDate ?? DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) {
                vm.setPreferredDate(picked);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 20, color: AppColors.iconGrey),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppText(
                      vm.preferredDate != null
                          ? DateFormat('MM/dd/yyyy').format(vm.preferredDate!)
                          : 'Select preferred date',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Choose a Time
          const AppText(
            'Choose a Time',
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
                child: _buildTimePreferenceButton(
                  vm,
                  'Morning',
                  vm.isTimePreferenceSelected('Morning'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTimePreferenceButton(
                  vm,
                  'Afternoon',
                  vm.isTimePreferenceSelected('Afternoon'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTimePreferenceButton(
                  vm,
                  'Evening',
                  vm.isTimePreferenceSelected('Evening'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const AppText(
            'The tutor will confirm the final time.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimePreferenceButton(
    RequestBookingViewModel vm,
    String label,
    bool isSelected,
  ) {
    return GestureDetector(
      onTap: () => vm.setTimePreference(label),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
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

  Widget _buildHourlyBudget(RequestBookingViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const AppText(
              'Your Budget',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            AppText(
              vm.formatHourlyBudget(vm.hourlyBudget),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Slider(
          value: vm.hourlyBudget,
          min: 1000.0, // ₹1000/hr (converted from $25/hr)
          max: 12000.0, // ₹12000/hr (converted from $150/hr)
          divisions: 44,
          activeColor: AppColors.primary,
          onChanged: (value) => vm.setHourlyBudget(value),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const AppText(
              '₹1,000/hr',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textGrey,
              ),
            ),
            const AppText(
              '₹12,000/hr',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textGrey,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAdditionalNotes(RequestBookingViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppText(
          'Additional Notes',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          onChanged: vm.updateNotes,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Add any specific topics or questions...',
            hintStyle: const TextStyle(color: AppColors.textGrey),
            filled: true,
            fillColor: AppColors.lightBackground,
            contentPadding: const EdgeInsets.all(16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(
    RequestBookingViewModel vm,
    BuildContext context,
  ) {
    final buttonText = vm.bookingType == BookingType.monthlyBooking
        ? 'Request Monthly Plan'
        : 'Send Booking Request';

    return AppPrimaryButton(
      label: buttonText,
      isLoading: vm.isLoading,
      isDisabled: !vm.canSubmit,
      onPressed: () async {
        final success = await vm.submitBooking();
        if (success) {
          Get.snackbar(
            'Success',
            'Booking request submitted successfully',
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
}

