// lib/views/parent/report_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_text.dart';
import '../../parent_viewmodels/report_vm.dart';
import '../../data/models/report_model.dart';

class ReportScreen extends StatefulWidget {
  final String? againstUserId; // Optional - if reporting a user
  final String? bookingId; // Optional - if reporting a booking
  final String? contextName; // Optional - name for context (e.g., "John Doe" if reporting a tutor)

  const ReportScreen({
    super.key,
    this.againstUserId,
    this.bookingId,
    this.contextName,
  });

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final vm = ReportViewModel();
        // Auto-select report type based on context
        if (widget.againstUserId != null && widget.bookingId == null) {
          // Reporting a user (tutor) - auto-select tutor type
          WidgetsBinding.instance.addPostFrameCallback((_) {
            vm.setReportType(ReportType.tutor);
          });
        } else if (widget.bookingId != null) {
          // Reporting a booking - auto-select booking type
          WidgetsBinding.instance.addPostFrameCallback((_) {
            vm.setReportType(ReportType.booking);
          });
        }
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
            'Report Issue',
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
        body: Consumer<ReportViewModel>(
          builder: (context, vm, _) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Context Info Card (if reporting a user/booking)
                  if (widget.contextName != null) ...[
                    _buildContextCard(vm),
                    const SizedBox(height: 24),
                  ],

                  // Report Type Section (only show if not pre-selected)
                  if (widget.againstUserId == null && widget.bookingId == null)
                    _buildReportTypeSection(vm),
                  if (widget.againstUserId == null && widget.bookingId == null)
                    const SizedBox(height: 24),
                  // Show selected type info if pre-selected
                  if (widget.againstUserId != null || widget.bookingId != null) ...[
                    _buildPreSelectedTypeInfo(vm),
                    const SizedBox(height: 24),
                  ],

                  // Description Section
                  _buildDescriptionSection(vm),
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

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: vm.canSubmit && !vm.isLoading
                          ? () async {
                              final success = await vm.submitReport(
                                againstUser: widget.againstUserId,
                                bookingId: widget.bookingId,
                              );

                              if (success && context.mounted) {
                                Get.back(result: true);
                                Get.snackbar(
                                  'Success',
                                  'Report submitted successfully. We will review it soon.',
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor: AppColors.success,
                                  colorText: Colors.white,
                                  duration: const Duration(seconds: 3),
                                );
                              }
                            }
                          : null,
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
                              'Submit Report',
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

  // ---------- Context Card ----------
  Widget _buildContextCard(ReportViewModel vm) {
    return Container(
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
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.lightBackground,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              size: 24,
              color: AppColors.warning,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppText(
                  'Reporting',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textGrey,
                  ),
                ),
                const SizedBox(height: 4),
                AppText(
                  widget.contextName!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Report Type Section ----------
  Widget _buildReportTypeSection(ReportViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppText(
          'What would you like to report?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 16),
        _buildTypeOption(
          vm,
          type: ReportType.tutor,
          icon: Icons.person_outline,
          title: 'Tutor',
          description: 'Report issues with a tutor',
        ),
        const SizedBox(height: 12),
        _buildTypeOption(
          vm,
          type: ReportType.booking,
          icon: Icons.calendar_today_outlined,
          title: 'Booking',
          description: 'Report issues with a booking',
        ),
        const SizedBox(height: 12),
        _buildTypeOption(
          vm,
          type: ReportType.payment,
          icon: Icons.payment_outlined,
          title: 'Payment',
          description: 'Report payment-related issues',
        ),
        const SizedBox(height: 12),
        _buildTypeOption(
          vm,
          type: ReportType.other,
          icon: Icons.report_problem_outlined,
          title: 'Other',
          description: 'Report other issues',
        ),
      ],
    );
  }

  // ---------- Pre-Selected Type Info ----------
  Widget _buildPreSelectedTypeInfo(ReportViewModel vm) {
    ReportType? preSelectedType;
    String typeTitle = '';
    String typeDescription = '';
    IconData typeIcon = Icons.report_problem_outlined;

    if (widget.againstUserId != null && widget.bookingId == null) {
      preSelectedType = ReportType.tutor;
      typeTitle = 'Tutor';
      typeDescription = 'You are reporting a tutor';
      typeIcon = Icons.person_outline;
    } else if (widget.bookingId != null) {
      preSelectedType = ReportType.booking;
      typeTitle = 'Booking';
      typeDescription = 'You are reporting a booking issue';
      typeIcon = Icons.calendar_today_outlined;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              typeIcon,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  typeTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                AppText(
                  typeDescription,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textGrey,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.check_circle,
            color: AppColors.primary,
            size: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildTypeOption(
    ReportViewModel vm, {
    required ReportType type,
    required IconData icon,
    required String title,
    required String description,
  }) {
    final isSelected = vm.selectedType == type;

    return InkWell(
      onTap: () => vm.setReportType(type),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withOpacity(0.2)
                    : AppColors.lightBackground,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? AppColors.primary : AppColors.iconGrey,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w600,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  AppText(
                    description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textGrey,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  // ---------- Description Section ----------
  Widget _buildDescriptionSection(ReportViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppText(
          'Describe the issue *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 12),
        Container(
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
          child: TextField(
            controller: _descriptionController,
            maxLines: 6,
            decoration: InputDecoration(
              hintText: 'Please provide details about the issue...',
              hintStyle: const TextStyle(
                fontSize: 14,
                color: AppColors.textLight,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textDark,
            ),
            onChanged: (value) => vm.setDescription(value),
          ),
        ),
        const SizedBox(height: 8),
        AppText(
          '${_descriptionController.text.length}/1000',
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textLight,
          ),
        ),
      ],
    );
  }
}
