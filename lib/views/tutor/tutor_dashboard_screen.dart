import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'package:tutor_finder/views/auth/login_screen.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_text.dart';
import '../../tutor_viewmodels/tutor_dashboard_vm.dart';
import 'tutor_booking_requests_screen.dart';
import 'notifications_screen.dart';

class TutorDashboardScreen extends StatefulWidget {
  const TutorDashboardScreen({super.key});

  @override
  State<TutorDashboardScreen> createState() => _TutorDashboardScreenState();
}

class _TutorDashboardScreenState extends State<TutorDashboardScreen> {
  bool _hasShownPendingSnackbar = false;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final vm = TutorDashboardViewModel();
        // Initialize dashboard data after first frame
        WidgetsBinding.instance.addPostFrameCallback((_) {
          vm.initialize();
        });
        return vm;
      },
      child: Container(
        color: AppColors.lightBackground,
        child: SafeArea(
          child: Consumer<TutorDashboardViewModel>(
            builder: (context, vm, _) {
              // Reset flag if profile is no longer pending
              if (!vm.isLoading && !vm.isProfilePending) {
                _hasShownPendingSnackbar = false;
              }
              
              // Show snackbar if profile is pending (only once per session)
              if (!vm.isLoading && vm.isProfilePending && !_hasShownPendingSnackbar) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() {
                      _hasShownPendingSnackbar = true;
                    });
                    Get.snackbar(
                      'Profile Pending',
                      'Complete your profile first, So that you can verify from the Admin',
                      snackPosition: SnackPosition.TOP,
                      backgroundColor: AppColors.primary,
                      colorText: Colors.white,
                      duration: const Duration(seconds: 4),
                      margin: const EdgeInsets.all(16),
                      borderRadius: 12,
                      icon: const Icon(Icons.info_outline, color: Colors.white),
                      shouldIconPulse: true,
                      isDismissible: true,
                      dismissDirection: DismissDirection.horizontal,
                    );
                  }
                });
              }

              if (vm.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              return RefreshIndicator(
                onRefresh: () => vm.initialize(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      // Header Section
                      _buildHeader(context, vm),
                      const SizedBox(height: 24),
                      // Greeting
                      _buildGreeting(vm),
                      const SizedBox(height: 24),
                      // Metrics Cards
                      _buildMetricsCards(vm),
                      const SizedBox(height: 24),
                      // Earnings Overview
                      _buildEarningsOverview(vm),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ---------- Header Section ----------
  Widget _buildHeader(BuildContext context, TutorDashboardViewModel vm) {
    return Row(
      children: [
        // Profile Picture
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.lightBackground,
            border: Border.all(color: AppColors.border, width: 2),
            image: vm.userImageUrl.isNotEmpty
                ? DecorationImage(
                    image: NetworkImage(vm.userImageUrl),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: vm.userImageUrl.isEmpty
              ? const Icon(
                  Icons.person,
                  size: 24,
                  color: AppColors.iconGrey,
                )
              : null,
        ),
        const SizedBox(width: 16),
        // Dashboard Title
        const Expanded(
          child: Center(
            child: AppText(
              'Dashboard',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ),
        ),
        // Notification Bell
        Stack(
          children: [
            IconButton(
              icon: const Icon(
                Icons.notifications_outlined,
                color: AppColors.textDark,
                size: 28,
              ),
              onPressed: () {
                Get.to(() => const TutorNotificationsScreen());
              },
            ),
            // Notification badge could be added here if needed
          ],
        ),
      ],
    );
  }

  // ---------- Greeting Section ----------
  Widget _buildGreeting(TutorDashboardViewModel vm) {
    return AppText(
      '${vm.getGreeting()}, ${vm.userName.isNotEmpty ? vm.userName : "Tutor"}!',
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
      ),
    );
  }

  // ---------- Metrics Cards Section ----------
  Widget _buildMetricsCards(TutorDashboardViewModel vm) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            label: 'New Requests',
            value: vm.newRequestsCount.toString(),
            color: AppColors.primary,
            onTap: vm.newRequestsCount > 0
                ? () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TutorBookingRequestsScreen(),
                      ),
                    );
                    // Refresh dashboard when returning
                    if (mounted) {
                      vm.initialize();
                    }
                  }
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            label: 'Upcoming',
            value: vm.upcomingCount.toString(),
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            label: 'Messages',
            value: vm.messagesCount.toString(),
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String label,
    required String value,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textGrey,
              ),
            ),
            const SizedBox(height: 8),
            AppText(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Earnings Overview Section ----------
  Widget _buildEarningsOverview(TutorDashboardViewModel vm) {
    final earnings = vm.earningsData;
    if (earnings == null) {
      return const SizedBox.shrink();
    }

    final percentageChange = earnings.percentageChange;
    final isPositive = percentageChange >= 0;
    final currentDay = DateTime.now().weekday;
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppText(
          'Earnings Overview',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppText(
                'Today\'s Earnings',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              AppText(
                '${earnings.thisWeekEarnings.toStringAsFixed(2)}Rs.',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    isPositive ? Icons.trending_up : Icons.trending_down,
                    color: isPositive ? AppColors.success : AppColors.error,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  AppText(
                    '${isPositive ? '+' : ''}${percentageChange.toStringAsFixed(0)}% vs last week',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isPositive ? AppColors.success : AppColors.error,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Days Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 2.5,
                ),
                itemCount: dayNames.length,
                itemBuilder: (context, index) {
                  final dayName = dayNames[index];
                  final isCurrentDay = (index + 1) == currentDay;
                  return Container(
                    decoration: BoxDecoration(
                      color: isCurrentDay
                          ? AppColors.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isCurrentDay
                            ? AppColors.primary
                            : AppColors.border,
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: AppText(
                        dayName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isCurrentDay
                              ? Colors.white
                              : AppColors.textGrey,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

}

