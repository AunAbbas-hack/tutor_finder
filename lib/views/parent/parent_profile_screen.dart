// lib/views/parent/parent_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_text.dart';
import '../../core/widgets/app_primary_button.dart';
import '../../parent_viewmodels/parent_profile_vm.dart';
import 'manage_children_screen.dart';
import 'parent_edit_profile_screen.dart';
import 'payment_history_screen.dart';
import 'report_screen.dart';


class ParentProfileScreen extends StatefulWidget {
  /// If true, shows back button (when navigated from dashboard)
  /// If false, hides back button (when opened from bottom navigation)
  final bool showBackButton;

  const ParentProfileScreen({
    super.key,
    this.showBackButton = true, // Default: show back button
  });

  @override
  State<ParentProfileScreen> createState() => _ParentProfileScreenState();
}

class _ParentProfileScreenState extends State<ParentProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final vm = ParentProfileViewModel();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          vm.initialize();
        });
        return vm;
      },
      child: Scaffold(
        backgroundColor: AppColors.lightBackground,
        body: SafeArea(
          child: Consumer<ParentProfileViewModel>(
            builder: (context, vm, _) {
              return Column(
                children: [
                  // Header
                  _buildHeader(context, vm),
                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          const SizedBox(height: 24),
                          // Profile Section
                          _buildProfileSection(context, vm),
                          const SizedBox(height: 32),
                          // Account Section
                          _buildAccountSection(context),
                          const SizedBox(height: 24),
                          // Notifications Section
                          // _buildNotificationsSection(context, vm),
                          // const SizedBox(height: 24),
                          // Support & Legal Section
                          _buildSupportSection(context),
                          const SizedBox(height: 32),
                          // Log Out Button
                          _buildLogoutButton(context, vm),
                          const SizedBox(height: 16),
                          // App Version
                          _buildAppVersion(vm),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ---------- Header ----------
  Widget _buildHeader(BuildContext context, ParentProfileViewModel vm) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(
            color: AppColors.border,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          const Expanded(
            child: AppText(
              'Profile & Settings',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ),
          // Save Button
          // TextButton(
          //   onPressed: vm.isLoading
          //       ? null
          //       : () async {
          //           final saved = await vm.saveProfile();
          //           if (saved && mounted) {
          //             Get.snackbar(
          //               'Success',
          //               'Profile saved successfully',
          //               snackPosition: SnackPosition.BOTTOM,
          //                 backgroundColor: AppColors.success,
          //               colorText: Colors.white,
          //               borderRadius: 12,
          //               margin: const EdgeInsets.all(16),
          //               duration: const Duration(seconds: 2),
          //               icon: const Icon(Icons.check_circle, color: Colors.white),
          //             );
          //           } else if (mounted && vm.errorMessage != null) {
          //             Get.snackbar(
          //               'Error',
          //               vm.errorMessage!,
          //               snackPosition: SnackPosition.BOTTOM,
          //                 backgroundColor: AppColors.error,
          //               colorText: Colors.white,
          //               borderRadius: 12,
          //               margin: const EdgeInsets.all(16),
          //               duration: const Duration(seconds: 3),
          //               icon: const Icon(Icons.error, color: Colors.white),
          //             );
          //           }
          //         },
          //   child: const AppText(
          //     'Save',
          //     style: TextStyle(
          //       fontSize: 16,
          //       fontWeight: FontWeight.w600,
          //       color: AppColors.primary,
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }

  // ---------- Profile Section ----------
  Widget _buildProfileSection(
      BuildContext context, ParentProfileViewModel vm) {
    return Column(
      children: [
        // Profile Picture
        Stack(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.lightBackground,
                border: Border.all(
                  color: AppColors.border,
                  width: 3,
                ),
                image: vm.imageUrl != null && vm.imageUrl!.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(vm.imageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: vm.imageUrl == null || vm.imageUrl!.isEmpty
                  ? const Icon(
                      Icons.person,
                      size: 60,
                      color: AppColors.iconGrey,
                    )
                  : null,
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Name
        AppText(
          vm.name.isNotEmpty ? vm.name : 'User',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 4),
        // Email
        AppText(
          vm.email,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textGrey,
          ),
        ),
        const SizedBox(height: 16),
        // Edit Profile Button
        SizedBox(
          width: 140,
          child: AppPrimaryButton(
            label: 'Edit Profile',
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ParentEditProfileScreen(),
                ),
              );
              
              // Refresh profile if changes were saved
              if (result == true) {
                vm.initialize();
              }
            },
          ),
        ),
      ],
    );
  }

  // ---------- Account Section ----------
  Widget _buildAccountSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: AppText(
            'ACCOUNT',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textGrey,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildSettingsItem(
          context,
          icon: Icons.people_outline,
          title: 'Manage Children\'s Profiles',
          onTap: () {
            Get.to(() => const ManageChildrenScreen());
          },
        ),
        _buildSettingsItem(
          context,
          icon: Icons.receipt_long,
          title: 'Payment History',
          onTap: () {
            Get.to(() => const PaymentHistoryScreen());
          },
        ),
        _buildSettingsItem(
          context,
          icon: Icons.report_problem_outlined,
          title: 'Report Issue',
          onTap: () {
            Get.to(() => const ReportScreen());
          },
        ),
        // _buildSettingsItem(
        //   context,
        //   icon: Icons.payment,
        //   title: 'Payment Methods',
        //   onTap: () {
        //     // TODO: Navigate to payment methods
        //     Get.snackbar(
        //       'Coming Soon',
        //       'Payment Methods feature will be available soon',
        //       snackPosition: SnackPosition.BOTTOM,
        //       backgroundColor: AppColors.primary,
        //       colorText: Colors.white,
        //       borderRadius: 12,
        //       margin: const EdgeInsets.all(16),
        //       duration: const Duration(seconds: 2),
        //     );
        //   },
        // ),
      ],
    );
  }

  // ---------- Notifications Section ----------
  Widget _buildNotificationsSection(
      BuildContext context, ParentProfileViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: AppText(
            'NOTIFICATIONS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textGrey,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildToggleItem(
          context,
          icon: Icons.notifications_outlined,
          title: 'Push Notifications',
          value: vm.pushNotificationsEnabled,
          onChanged: (value) => vm.togglePushNotifications(value),
        ),
        _buildToggleItem(
          context,
          icon: Icons.email_outlined,
          title: 'Email Notifications',
          value: vm.emailNotificationsEnabled,
          onChanged: (value) => vm.toggleEmailNotifications(value),
        ),
      ],
    );
  }

  // ---------- Support Section ----------
  Widget _buildSupportSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: AppText(
            'SUPPORT & LEGAL',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textGrey,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildSettingsItem(
          context,
          icon: Icons.help_outline,
          title: 'Help Center',
          onTap: () {
            // TODO: Navigate to help center
            Get.snackbar(
              'Coming Soon',
              'Help Center will be available soon',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: AppColors.primary,
              colorText: Colors.white,
              borderRadius: 12,
              margin: const EdgeInsets.all(16),
              duration: const Duration(seconds: 2),
            );
          },
        ),
        _buildSettingsItem(
          context,
          icon: Icons.description_outlined,
          title: 'Terms of Service',
          onTap: () {
            // TODO: Navigate to terms
            Get.snackbar(
              'Coming Soon',
              'Terms of Service will be available soon',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: AppColors.primary,
              colorText: Colors.white,
              borderRadius: 12,
              margin: const EdgeInsets.all(16),
              duration: const Duration(seconds: 2),
            );
          },
        ),
        _buildSettingsItem(
          context,
          icon: Icons.privacy_tip_outlined,
          title: 'Privacy Policy',
          onTap: () {
            // TODO: Navigate to privacy policy
            Get.snackbar(
              'Coming Soon',
              'Privacy Policy will be available soon',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: AppColors.primary,
              colorText: Colors.white,
              borderRadius: 12,
              margin: const EdgeInsets.all(16),
              duration: const Duration(seconds: 2),
            );
          },
        ),
      ],
    );
  }

  // ---------- Settings Item ----------
  Widget _buildSettingsItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        color: AppColors.background,
        child: Row(
          children: [
            Icon(
              icon,
              size: 24,
              color: AppColors.iconGrey,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: AppText(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textDark,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.iconGrey,
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Toggle Item ----------
  Widget _buildToggleItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      color: AppColors.background,
      child: Row(
        children: [
          Icon(
            icon,
            size: 24,
            color: AppColors.iconGrey,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: AppText(
              title,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textDark,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  // ---------- Logout Button ----------
  Widget _buildLogoutButton(BuildContext context, ParentProfileViewModel vm) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: vm.isLoading
              ? null
              : () async {
                  final shouldLogout = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const AppText('Log Out'),
                      content: const AppText(
                        'Are you sure you want to log out?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const AppText('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const AppText(
                            'Log Out',
                            style: TextStyle(color: AppColors.error),
                          ),
                        ),
                      ],
                    ),
                  );

                  if (shouldLogout == true && mounted) {
                    final loggedOut = await vm.logout();
                    if (loggedOut && mounted) {
                      // Navigation will be handled by AuthWrapper
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        '/',
                        (route) => false,
                      );
                    }
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error.withOpacity(0.1),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: const AppText(
            'Log Out',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.error,
            ),
          ),
        ),
      ),
    );
  }

  // ---------- App Version ----------
  Widget _buildAppVersion(ParentProfileViewModel vm) {
    return AppText(
      'App Version ${vm.appVersion}',
      style: const TextStyle(
        fontSize: 12,
        color: AppColors.textLight,
      ),
    );
  }
}

