// lib/views/parent/new_child_sheet.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_text.dart';
import '../../core/widgets/app_textfield.dart';
import '../../core/widgets/app_primary_button.dart';
import '../../parent_viewmodels/new_child_sheet_vm.dart';
import '../../parent_viewmodels/manage_children_vm.dart';

class NewChildSheet extends StatefulWidget {
  final VoidCallback? onChildAdded;
  final ChildProfile? childToEdit; // For edit mode

  const NewChildSheet({
    super.key,
    this.onChildAdded,
    this.childToEdit,
  });

  @override
  State<NewChildSheet> createState() => _NewChildSheetState();
}

class _NewChildSheetState extends State<NewChildSheet> {
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final vm = NewChildSheetViewModel(
          existingStudentId: widget.childToEdit?.student.studentId,
          existingUserId: widget.childToEdit?.user.userId,
        );
        // Initialize for edit mode
        if (widget.childToEdit != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            await vm.initializeForEdit();
            // Update controller after data is loaded
            if (mounted) {
              _nameController.text = vm.name;
            }
          });
        }
        return vm;
      },
      child: Consumer<NewChildSheetViewModel>(
        builder: (context, vm, _) {
          // Update controller when name changes (for edit mode)
          if (vm.isEditMode && _nameController.text != vm.name && vm.name.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _nameController.text != vm.name) {
                _nameController.text = vm.name;
              }
            });
          }

          return DraggableScrollableSheet(
            initialChildSize: 0.9,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    // Drag handle
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Row(
                        children: [
                          AppText(
                            vm.isEditMode ? 'Edit Child' : 'Add New Child',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: AppColors.iconGrey,
                            ),
                            onPressed: () => Get.back(),
                          ),
                        ],
                      ),
                    ),
                    // Content
                    Expanded(
                      child: SingleChildScrollView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Name Field
                            AppTextField(
                              label: 'Name',
                              hintText: 'e.g. Alex Johnson',
                              controller: _nameController,
                              onChanged: vm.updateName,
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: 20),

                            // Grade Level Dropdown
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const AppText(
                                  'Grade Level',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.lightBackground,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: DropdownButtonFormField<String>(
                                    value: vm.selectedGrade,
                                    decoration: InputDecoration(
                                      hintText: 'Select grade level',
                                      hintStyle: TextStyle(
                                        color: Colors.grey[600],
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 14,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide.none,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide.none,
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: const BorderSide(
                                          color: AppColors.primary,
                                          width: 2,
                                        ),
                                      ),
                                      suffixIcon: const Icon(
                                        Icons.keyboard_arrow_down,
                                        color: AppColors.iconGrey,
                                      ),
                                    ),
                                    items: vm.gradeOptionsList
                                        .map((grade) => DropdownMenuItem(
                                              value: grade,
                                              child: AppText(grade),
                                            ))
                                        .toList(),
                                    onChanged: vm.updateGrade,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Subjects
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const AppText(
                                  'Subjects',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Subject Tags
                                if (vm.subjects.isNotEmpty)
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: vm.subjects.map((subject) {
                                      return _buildSubjectTag(
                                        subject,
                                        onRemove: () => vm.removeSubject(subject),
                                      );
                                    }).toList(),
                                  ),
                                const SizedBox(height: 8),
                                // Add Subject Button
                                _buildAddSubjectButton(context, vm),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Gender (Optional)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const AppText(
                                  'Gender (Optional)',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    _buildGenderButton(
                                      'Boy',
                                      '👦',
                                      Gender.boy,
                                      vm.selectedGender == Gender.boy,
                                      () => vm.updateGender(Gender.boy),
                                    ),
                                    const SizedBox(width: 12),
                                    _buildGenderButton(
                                      'Girl',
                                      '👧',
                                      Gender.girl,
                                      vm.selectedGender == Gender.girl,
                                      () => vm.updateGender(Gender.girl),
                                    ),
                                    const SizedBox(width: 12),
                                    _buildGenderButton(
                                      'Other',
                                      '👤',
                                      Gender.other,
                                      vm.selectedGender == Gender.other,
                                      () => vm.updateGender(Gender.other),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),

                            // Error Message
                            if (vm.errorMessage != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: AppText(
                                  vm.errorMessage!,
                                  style: const TextStyle(
                                    color: AppColors.error,
                                    fontSize: 14,
                                  ),
                                ),
                              ),

                            // Add/Update Child Button
                            AppPrimaryButton(
                              label: vm.isEditMode ? 'Update Child' : 'Add Child',
                              isLoading: vm.isLoading,
                              isDisabled: !vm.isValid,
                              onPressed: () async {
                                final success = vm.isEditMode
                                    ? await vm.updateChild()
                                    : await vm.createChild();
                                if (success) {
                                  vm.reset();
                                  Get.back();
                                  if (widget.onChildAdded != null) {
                                    widget.onChildAdded!();
                                  }
                                  Get.snackbar(
                                    'Success',
                                    vm.isEditMode
                                        ? 'Child updated successfully'
                                        : 'Child added successfully',
                                    snackPosition: SnackPosition.BOTTOM,
                                    backgroundColor: AppColors.success,
                                    colorText: Colors.white,
                                    borderRadius: 12,
                                    margin: const EdgeInsets.all(16),
                                    duration: const Duration(seconds: 2),
                                  );
                                } else if (vm.errorMessage != null) {
                                  Get.snackbar(
                                    'Error',
                                    vm.errorMessage!,
                                    snackPosition: SnackPosition.BOTTOM,
                                    backgroundColor: AppColors.error,
                                    colorText: Colors.white,
                                    borderRadius: 12,
                                    margin: const EdgeInsets.all(16),
                                    duration: const Duration(seconds: 3),
                                  );
                                }
                              },
                            ),
                            const SizedBox(height: 12),

                            // Cancel Button
                            Center(
                              child: TextButton(
                                onPressed: () {
                                  vm.reset();
                                  Get.back();
                                },
                                child: const AppText(
                                  'Cancel',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: AppColors.textGrey,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ],
                ));
            },
          );
        },
      ),
    );
  }

  Widget _buildSubjectTag(String subject, {required VoidCallback onRemove}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppText(
            subject,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(
              Icons.close,
              size: 16,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddSubjectButton(
      BuildContext context, NewChildSheetViewModel vm) {
    return InkWell(
      onTap: () => _showSubjectPicker(context, vm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: AppColors.border,
            style: BorderStyle.solid,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.add,
              color: AppColors.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            AppText(
              'Add...',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSubjectPicker(BuildContext context, NewChildSheetViewModel vm) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.lightBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppText(
              'Select Subjects',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: vm.commonSubjectsList.length,
                itemBuilder: (context, index) {
                  final subject = vm.commonSubjectsList[index];
                  final isSelected = vm.subjects.contains(subject);
                  return ListTile(
                    title: AppText(subject),
                    trailing: isSelected
                        ? const Icon(
                            Icons.check_circle,
                            color: AppColors.primary,
                          )
                        : null,
                    onTap: () {
                      if (isSelected) {
                        vm.removeSubject(subject);
                      } else {
                        vm.addSubject(subject);
                      }
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            AppPrimaryButton(
              label: 'Done',
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderButton(
    String label,
    String emoji,
    Gender gender,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withOpacity(0.1)
                : AppColors.lightBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              AppText(
                emoji,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(height: 4),
              AppText(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? AppColors.primary : AppColors.textGrey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

