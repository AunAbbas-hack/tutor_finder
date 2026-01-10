// lib/views/admin/admin_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../admin_viewmodels/admin_dashboard_vm.dart';
import '../../core/widgets/app_text.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/activity_model.dart';
import '../../data/models/pending_approval_model.dart';
import '../../data/models/dashboard_metrics_model.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final vm = AdminDashboardViewModel();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          vm.initialize();
        });
        return vm;
      },
      child: Scaffold(
        backgroundColor: AppColors.lightBackground,
        body: SafeArea(
          child: Consumer<AdminDashboardViewModel>(
            builder: (context, vm, _) {
              if (vm.isLoading && vm.metrics == null) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                );
              }

              if (vm.errorMessage != null && vm.metrics == null) {
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
                        onPressed: () => vm.initialize(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                        ),
                        child: const AppText(
                          'Retry',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () => vm.initialize(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.width * 0.05,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Section
                      _buildHeader(context, vm),
                      const SizedBox(height: 24),
                      // Summary Cards
                      _buildSummaryCards(context, vm),
                      const SizedBox(height: 32),
                      // Recent Activity Section
                      _buildRecentActivitySection(context, vm),
                      const SizedBox(height: 32),
                      // Pending Approvals Section
                      _buildPendingApprovalsSection(context, vm),
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

  // ---------- Header ----------
  Widget _buildHeader(BuildContext context, AdminDashboardViewModel vm) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                'Hello, Admin',
                style: TextStyle(
                  fontSize: isTablet ? 32 : 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 4),
              AppText(
                "Here's what's happening today",
                style: TextStyle(
                  fontSize: isTablet ? 16 : 14,
                  color: AppColors.textGrey,
                ),
              ),
            ],
          ),
        ),
        // Notification Bell
        IconButton(
          icon: const Icon(
            Icons.notifications_outlined,
            color: AppColors.textDark,
            size: 28,
          ),
          onPressed: () {
            // TODO: Navigate to notifications screen
          },
        ),
      ],
    );
  }

  // ---------- Summary Cards ----------
  Widget _buildSummaryCards(BuildContext context, AdminDashboardViewModel vm) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final cardSpacing = isTablet ? 16.0 : 12.0;
    final crossAxisCount = isTablet ? 4 : 2;

    if (vm.metrics == null) {
      return const SizedBox.shrink();
    }

    final metrics = vm.metrics!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - (cardSpacing * (crossAxisCount - 1))) / crossAxisCount;
        
        return Wrap(
          spacing: cardSpacing,
          runSpacing: cardSpacing,
          children: [
            _buildSummaryCard(
              context,
              title: 'Total Users',
              value: _formatNumber(metrics.totalUsers),
              icon: Icons.people,
              subtitle: metrics.formattedUsersGrowth ?? '',
              subtitleColor: AppColors.success,
              cardWidth: cardWidth,
            ),
            _buildSummaryCard(
              context,
              title: 'Pending Verif.',
              value: '${metrics.pendingVerifications}',
              icon: Icons.verified_user_outlined,
              subtitle: metrics.pendingVerifStatus ?? '',
              subtitleColor: AppColors.textGrey,
              cardWidth: cardWidth,
            ),
            _buildSummaryCard(
              context,
              title: 'Active Bookings',
              value: '${metrics.activeBookings}',
              icon: Icons.calendar_today,
              subtitle: metrics.newBookingsToday != null 
                  ? '${metrics.newBookingsToday} new today'
                  : '',
              subtitleColor: AppColors.success,
              cardWidth: cardWidth,
            ),
            _buildSummaryCard(
              context,
              title: 'Total Revenue',
              value: metrics.formattedRevenue,
              icon: Icons.account_balance_wallet,
              subtitle: metrics.formattedRevenueGrowth ?? '',
              subtitleColor: AppColors.success,
              cardWidth: cardWidth,
              isRevenue: true,
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required String subtitle,
    required Color subtitleColor,
    required double cardWidth,
    bool isRevenue = false,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Container(
      width: cardWidth,
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          // Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.lightBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: isTablet ? 28 : 24,
            ),
          ),
          const SizedBox(height: 12),
          // Title
          AppText(
            title,
            style: TextStyle(
              fontSize: isTablet ? 14 : 12,
              color: AppColors.textGrey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          // Value
          AppText(
            value,
            style: TextStyle(
              fontSize: isTablet ? 32 : 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          // Subtitle
          if (subtitle.isNotEmpty)
            AppText(
              subtitle,
              style: TextStyle(
                fontSize: isTablet ? 13 : 11,
                color: subtitleColor,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    } else {
      return number.toString();
    }
  }

  // ---------- Recent Activity Section ----------
  Widget _buildRecentActivitySection(
    BuildContext context,
    AdminDashboardViewModel vm,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AppText(
              'Recent Activity',
              style: TextStyle(
                fontSize: MediaQuery.of(context).size.width > 600 ? 22 : 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            TextButton(
              onPressed: () {
                // TODO: Navigate to all activities screen
              },
              child: AppText(
                'SEE ALL',
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width > 600 ? 14 : 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (vm.recentActivity.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: AppText(
                'No recent activity',
                style: TextStyle(
                  color: AppColors.textGrey,
                  fontSize: 14,
                ),
              ),
            ),
          )
        else
          ...vm.recentActivity.take(3).map((activity) => 
            _buildActivityItem(context, activity),
          ),
      ],
    );
  }

  Widget _buildActivityItem(BuildContext context, ActivityModel activity) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(isTablet ? 16 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: isTablet ? 48 : 40,
            height: isTablet ? 48 : 40,
            decoration: BoxDecoration(
              color: activity.iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              activity.icon,
              color: activity.iconColor,
              size: isTablet ? 24 : 20,
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  activity.title,
                  style: TextStyle(
                    fontSize: isTablet ? 15 : 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                AppText(
                  activity.description,
                  style: TextStyle(
                    fontSize: isTablet ? 13 : 12,
                    color: AppColors.textGrey,
                  ),
                ),
              ],
            ),
          ),
          // Time
          AppText(
            activity.timeAgo,
            style: TextStyle(
              fontSize: isTablet ? 13 : 12,
              color: AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Pending Approvals Section ----------
  Widget _buildPendingApprovalsSection(
    BuildContext context,
    AdminDashboardViewModel vm,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          'Pending Approvals',
          style: TextStyle(
            fontSize: MediaQuery.of(context).size.width > 600 ? 22 : 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 16),
        if (vm.pendingApprovals.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: AppText(
                'No pending approvals',
                style: TextStyle(
                  color: AppColors.textGrey,
                  fontSize: 14,
                ),
              ),
            ),
          )
        else
          ...vm.pendingApprovals.map((approval) => 
            _buildPendingApprovalCard(context, approval, vm),
          ),
      ],
    );
  }

  Widget _buildPendingApprovalCard(
    BuildContext context,
    PendingApprovalModel approval,
    AdminDashboardViewModel vm,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          Row(
            children: [
              // Avatar
              Container(
                width: isTablet ? 56 : 48,
                height: isTablet ? 56 : 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [approval.avatarColor1, approval.avatarColor2],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  image: approval.imageUrl != null && approval.imageUrl!.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(approval.imageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: approval.imageUrl == null || approval.imageUrl!.isEmpty
                    ? Center(
                        child: AppText(
                          approval.name.substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isTablet ? 24 : 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              // Name and details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: AppText(
                            approval.name,
                            style: TextStyle(
                              fontSize: isTablet ? 18 : 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                        // View icon
                        InkWell(
                          onTap: () {
                            // TODO: Navigate to tutor profile/view screen
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.visibility,
                              color: AppColors.primary,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    AppText(
                      '${approval.subjectsDisplay} • ${approval.experienceDisplay}',
                      style: TextStyle(
                        fontSize: isTablet ? 14 : 12,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: vm.isLoading
                      ? null
                      : () async {
                          final success = await vm.rejectTutor(approval.tutorId);
                          if (success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Tutor rejected successfully'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          } else if (!success && context.mounted && vm.errorMessage != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(vm.errorMessage!),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        },
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: isTablet ? 14 : 12),
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: AppText(
                    'Reject',
                    style: TextStyle(
                      fontSize: isTablet ? 15 : 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
              ),
              SizedBox(width: isTablet ? 12 : 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: vm.isLoading
                      ? null
                      : () async {
                          final success = await vm.approveTutor(approval.tutorId);
                          if (success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Tutor approved successfully'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          } else if (!success && context.mounted && vm.errorMessage != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(vm.errorMessage!),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: EdgeInsets.symmetric(vertical: isTablet ? 14 : 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: AppText(
                    'Approve',
                    style: TextStyle(
                      fontSize: isTablet ? 15 : 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
