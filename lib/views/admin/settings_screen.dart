// lib/views/admin/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_text.dart';
import '../../admin_viewmodels/admin_settings_vm.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final vm = AdminSettingsViewModel();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          vm.initialize();
        });
        return vm;
      },
      child: Scaffold(
        backgroundColor: AppColors.lightBackground,
        body: SafeArea(
          child: Consumer<AdminSettingsViewModel>(
            builder: (context, vm, _) {
              return Column(
                children: [
                  // Header
                  _buildHeader(context),
                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          const SizedBox(height: 24),
                          // Profile Section
                          _buildProfileSection(context, vm),
                          const SizedBox(height: 32),
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
  Widget _buildHeader(BuildContext context) {
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
      child: const Row(
        children: [
          Expanded(
            child: AppText(
              'Settings',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Profile Section ----------
  Widget _buildProfileSection(
      BuildContext context, AdminSettingsViewModel vm) {
    return Column(
      children: [
        // Profile Picture
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
                  Icons.admin_panel_settings,
                  size: 60,
                  color: AppColors.iconGrey,
                )
              : null,
        ),
        const SizedBox(height: 16),
        // Name
        AppText(
          vm.name.isNotEmpty ? vm.name : 'Admin',
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
        if (vm.phone != null && vm.phone!.isNotEmpty) ...[
          const SizedBox(height: 4),
          AppText(
            vm.phone!,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textGrey,
            ),
          ),
        ],
      ],
    );
  }

  // ---------- General Section ----------


  // ---------- Support & Legal Section ----------
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
  Widget _buildLogoutButton(
      BuildContext context, AdminSettingsViewModel vm) {
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
  Widget _buildAppVersion(AdminSettingsViewModel vm) {
    return AppText(
      'App Version ${vm.appVersion}',
      style: const TextStyle(
        fontSize: 12,
        color: AppColors.textLight,
      ),
    );
  }
}