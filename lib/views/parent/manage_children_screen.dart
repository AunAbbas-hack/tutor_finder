// lib/views/parent/manage_children_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_text.dart';
import '../../core/widgets/app_primary_button.dart';
import '../../parent_viewmodels/manage_children_vm.dart';
import 'new_child_sheet.dart';

class ManageChildrenScreen extends StatefulWidget {
  const ManageChildrenScreen({super.key});

  @override
  State<ManageChildrenScreen> createState() => _ManageChildrenScreenState();
}

class _ManageChildrenScreenState extends State<ManageChildrenScreen> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final vm = ManageChildrenViewModel();
        // Initialize data after first frame
        WidgetsBinding.instance.addPostFrameCallback((_) {
          vm.loadChildren();
        });
        return vm;
      },
      child: _ManageChildrenContent(),
    );
  }
}

class _ManageChildrenContent extends StatefulWidget {
  const _ManageChildrenContent();

  @override
  State<_ManageChildrenContent> createState() => _ManageChildrenContentState();
}

class _ManageChildrenContentState extends State<_ManageChildrenContent> {
  @override
  void initState() {
    super.initState();
    // Ensure data loads when screen is first shown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final vm = Provider.of<ManageChildrenViewModel>(context, listen: false);
        vm.loadChildren();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildAppBar(),
        body: Consumer<ManageChildrenViewModel>(
          builder: (context, vm, _) {
            if (vm.isLoading && vm.children.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              );
            }

            if (vm.errorMessage != null && vm.children.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AppText(
                      vm.errorMessage!,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => vm.loadChildren(),
                      child: const AppText('Retry'),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () => vm.refresh(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Heading
                    const AppText(
                      'Child Profiles',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Description
                    AppText(
                      'Manage the profiles linked to your account. You can add new children or edit existing details for tutoring sessions.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textGrey,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Children List
                    if (vm.children.isEmpty)
                      _buildEmptyState()
                    else
                      ...vm.children.map((child) => _buildChildCard(child, vm)),
                    const SizedBox(height: 24),
                    // Add New Child Button
                    AppPrimaryButton(
                      label: 'Add New Child',
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => NewChildSheet(
                            onChildAdded: () {
                              // Refresh children list
                              vm.refresh();
                            },
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        ),
      );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back,
          color: AppColors.textDark,
        ),
        onPressed: () => Get.back(),
      ),
      title: const AppText(
        'Manage Children',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.textDark,
        ),
      ),
      centerTitle: false,
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.child_care_outlined,
            size: 64,
            color: AppColors.textLight,
          ),
          const SizedBox(height: 16),
          AppText(
            'No children added yet',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textGrey,
            ),
          ),
          const SizedBox(height: 8),
          AppText(
            'Add your first child to get started',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChildCard(ChildProfile child, ManageChildrenViewModel vm) {
    final user = child.user;
    final student = child.student;
    final initial = user.name.isNotEmpty ? user.name[0].toUpperCase() : '?';
    
    // Get color based on initial (for avatar)
    final avatarColor = _getAvatarColor(initial);
    
    // Build grade and subjects text
    final gradeText = student.grade ?? 'Grade not set';
    final subjectsText = student.subjects ?? 'No subjects specified';
    final detailText = '$gradeText • $subjectsText';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          // Open edit child bottom sheet
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => NewChildSheet(
              childToEdit: child,
              onChildAdded: () {
                // Refresh children list
                vm.refresh();
              },
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: avatarColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: AppText(
                    initial,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: avatarColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Name and Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      user.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    AppText(
                      detailText,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
              // Arrow Icon
              const Icon(
                Icons.chevron_right,
                color: AppColors.iconGrey,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getAvatarColor(String initial) {
    // Generate consistent color based on initial
    final colors = [
      const Color(0xFF1A73E8), // Blue
      const Color(0xFFFF9800), // Orange
      const Color(0xFF9C27B0), // Purple
      const Color(0xFF4CAF50), // Green
      const Color(0xFFE91E63), // Pink
      const Color(0xFF00BCD4), // Cyan
    ];
    
    final index = initial.codeUnitAt(0) % colors.length;
    return colors[index];
  }
}


