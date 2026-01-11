// lib/views/parent/request_booking_screen.dart
import 'package:flutter/material.dart';
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

                  // Select Subjects
                  _buildSelectSubjects(vm),
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
                // Booking Date
                const SizedBox(height: 8),
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
                  children: vm.availableTimeSlots.map((time) {
                    final isSelected = details.timeSlot == time;
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
                  }).toList(),
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
}

