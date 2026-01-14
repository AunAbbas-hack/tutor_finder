// lib/views/admin/admin_parent_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../admin_viewmodels/admin_parent_detail_vm.dart';
import '../../core/widgets/app_text.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/user_model.dart';
import '../../data/models/booking_model.dart';
import '../../data/models/student_model.dart';

class AdminParentDetailScreen extends StatefulWidget {
  final String parentId;

  const AdminParentDetailScreen({
    super.key,
    required this.parentId,
  });

  @override
  State<AdminParentDetailScreen> createState() => _AdminParentDetailScreenState();
}

class _AdminParentDetailScreenState extends State<AdminParentDetailScreen> {
  final TextEditingController _notificationController = TextEditingController();

  @override
  void dispose() {
    _notificationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final vm = AdminParentDetailViewModel();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          vm.loadParentData(widget.parentId);
        });
        return vm;
      },
      child: Scaffold(
        backgroundColor: AppColors.lightBackground,
        body: SafeArea(
          child: Consumer<AdminParentDetailViewModel>(
            builder: (context, vm, _) {
              if (vm.isLoading && vm.user == null) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                );
              }

              if (vm.errorMessage != null && vm.user == null) {
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
                        onPressed: () => vm.loadParentData(widget.parentId),
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

              if (vm.user == null) {
                return const Center(
                  child: AppText(
                    'Parent data not found',
                    style: TextStyle(color: AppColors.error),
                  ),
                );
              }

              return Column(
                children: [
                  // Header
                  _buildHeader(context),
                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Parent Profile Section
                          Align(
                              alignment: Alignment.center,
                              child: _buildParentProfile(context, vm)),
                          const SizedBox(height: 24),
                          // Stats Cards
                          _buildStatsCards(context, vm),
                          const SizedBox(height: 24),
                          // Children Profiles Section
                          _buildChildrenSection(context, vm),
                          const SizedBox(height: 24),
                          // Booking History Section
                          _buildBookingHistory(context, vm),
                          const SizedBox(height: 24),
                          // Manage Account Section
                          _buildManageAccount(context, vm),
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
        color: Colors.white,
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
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const Expanded(
            child: AppText(
              'Parent Details',
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

  // ---------- Parent Profile ----------
  Widget _buildParentProfile(BuildContext context, AdminParentDetailViewModel vm) {
    final user = vm.user!;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    final status = user.status;
    final statusText = status == UserStatus.active
        ? 'ACTIVE ACCOUNT'
        : status == UserStatus.suspended
            ? 'SUSPENDED'
            : status == UserStatus.pending
                ? 'PENDING'
                : 'INACTIVE';

    final statusColor = status == UserStatus.active
        ? const Color(0xFFE8F5E9)
        : status == UserStatus.suspended
            ? const Color(0xFFFFEBEE)
            : status == UserStatus.pending
                ? const Color(0xFFE3F2FD)
                : const Color(0xFFF3F4F6);

    final statusTextColor = status == UserStatus.active
        ? AppColors.success
        : status == UserStatus.suspended
            ? AppColors.error
            : status == UserStatus.pending
                ? AppColors.primary
                : AppColors.textGrey;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
          // Profile Picture
          Stack(
            children: [
              Container(
                width: isTablet ? 100 : 80,
                height: isTablet ? 100 : 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withOpacity(0.1),
                  image: user.imageUrl != null && user.imageUrl!.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(user.imageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: user.imageUrl == null || user.imageUrl!.isEmpty
                    ? Center(
                        child: AppText(
                          user.name.substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: isTablet ? 40 : 32,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    : null,
              ),
              if (status == UserStatus.active)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle,
                      color: AppColors.success,
                      size: isTablet ? 24 : 20,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Name
          AppText(
            user.name,
            style: TextStyle(
              fontSize: isTablet ? 24 : 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          // Email
          AppText(
            user.email,
            style: TextStyle(
              fontSize: isTablet ? 16 : 14,
              color: AppColors.textGrey,
            ),
          ),
          const SizedBox(height: 12),
          // Status Badge
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 16 : 12,
              vertical: isTablet ? 8 : 6,
            ),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: AppText(
              statusText,
              style: TextStyle(
                fontSize: isTablet ? 14 : 12,
                fontWeight: FontWeight.w600,
                color: statusTextColor,
              ),
            ),
          ),
        ],
    );
  }

  // ---------- Stats Cards ----------
  Widget _buildStatsCards(BuildContext context, AdminParentDetailViewModel vm) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    final spentText = vm.totalSpent >= 1000
        ? '\$${(vm.totalSpent / 1000).toStringAsFixed(1)}k'
        : '\$${vm.totalSpent.toStringAsFixed(0)}';

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            label: 'BOOKINGS',
            value: '${vm.bookingsCount}',
            icon: Icons.calendar_today,
            color: AppColors.primary,
            isTablet: isTablet,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            label: 'SPENT',
            value: spentText,
            icon: Icons.payment,
            color: AppColors.textDark,
            isTablet: isTablet,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            label: 'CHILDREN',
            value: '${vm.childrenCount}',
            icon: Icons.people,
            color: AppColors.textDark,
            isTablet: isTablet,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required bool isTablet,
  }) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 20 : 16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            label,
            style: TextStyle(
              fontSize: isTablet ? 12 : 10,
              color: AppColors.textGrey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              AppText(
                value,
                style: TextStyle(
                  fontSize: isTablet ? 20 : 18,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------- Children Section ----------
  Widget _buildChildrenSection(BuildContext context, AdminParentDetailViewModel vm) {
    if (vm.children.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.people_outline, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            const AppText(
              'Children Profiles',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...vm.children.map((child) => _buildChildCard(context, child)),
      ],
    );
  }

  Widget _buildChildCard(BuildContext context, StudentModel child) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    final initials = child.studentId.length >= 2
        ? child.studentId.substring(0, 2).toUpperCase()
        : 'CH';

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
          // Avatar
          Container(
            width: isTablet ? 48 : 40,
            height: isTablet ? 48 : 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withOpacity(0.1),
            ),
            child: Center(
              child: AppText(
                initials,
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: isTablet ? 16 : 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Child Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  'Child ${child.studentId.substring(0, 4)}',
                  style: TextStyle(
                    fontSize: isTablet ? 16 : 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                if (child.grade != null || child.subjects != null) ...[
                  const SizedBox(height: 4),
                  AppText(
                    '${child.grade ?? ''}${child.grade != null && child.subjects != null ? ' • ' : ''}${child.subjects ?? ''}',
                    style: TextStyle(
                      fontSize: isTablet ? 14 : 12,
                      color: AppColors.textGrey,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: isTablet ? 16 : 14,
            color: AppColors.iconGrey,
          ),
        ],
      ),
    );
  }

  // ---------- Booking History ----------
  Widget _buildBookingHistory(BuildContext context, AdminParentDetailViewModel vm) {
    final recentBookings = vm.recentBookings;
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.history, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                const AppText(
                  'Booking History',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
            if (vm.bookings.length > 3)
              TextButton(
                onPressed: () {
                  // TODO: Navigate to full booking history
                },
                child: const AppText(
                  'View All',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (recentBookings.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: AppText(
                'No bookings yet',
                style: TextStyle(
                  color: AppColors.textGrey,
                  fontSize: 14,
                ),
              ),
            ),
          )
        else
          ...recentBookings.map((booking) => _buildBookingCard(
                context,
                booking,
                vm.getTutorName(booking.tutorId),
                dateFormat,
              )),
      ],
    );
  }

  Widget _buildBookingCard(
    BuildContext context,
    BookingModel booking,
    String tutorName,
    DateFormat dateFormat,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    String statusText;
    Color statusColor;
    Color statusBgColor;

    switch (booking.status) {
      case BookingStatus.completed:
        statusText = 'COMPLETED';
        statusColor = AppColors.success;
        statusBgColor = const Color(0xFFE8F5E9);
        break;
      case BookingStatus.approved:
        statusText = 'UPCOMING';
        statusColor = AppColors.primary;
        statusBgColor = const Color(0xFFE3F2FD);
        break;
      case BookingStatus.cancelled:
        statusText = 'CANCELLED';
        statusColor = AppColors.error;
        statusBgColor = const Color(0xFFFFEBEE);
        break;
      case BookingStatus.pending:
        statusText = 'PENDING';
        statusColor = AppColors.warning;
        statusBgColor = const Color(0xFFFFF3E0);
        break;
      default:
        statusText = 'REJECTED';
        statusColor = AppColors.error;
        statusBgColor = const Color(0xFFFFEBEE);
    }

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      booking.subjects.isNotEmpty
                          ? booking.subjects.first
                          : booking.subject,
                      style: TextStyle(
                        fontSize: isTablet ? 16 : 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    AppText(
                      'with $tutorName',
                      style: TextStyle(
                        fontSize: isTablet ? 14 : 12,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 10 : 8,
                  vertical: isTablet ? 6 : 4,
                ),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: AppText(
                  statusText,
                  style: TextStyle(
                    fontSize: isTablet ? 12 : 10,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 14, color: AppColors.iconGrey),
              const SizedBox(width: 4),
              AppText(
                '${dateFormat.format(booking.bookingDate)} • ${booking.bookingTime}',
                style: TextStyle(
                  fontSize: isTablet ? 13 : 12,
                  color: AppColors.textGrey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------- Manage Account ----------
  Widget _buildManageAccount(BuildContext context, AdminParentDetailViewModel vm) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppText(
          'Manage Account',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 12),
        // Send Notification Button
        ElevatedButton.icon(
          onPressed: () => _showNotificationDialog(context, vm),
          icon: const Icon(Icons.notifications, color: Colors.white),
          label: const AppText(
            'Send Notification',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: EdgeInsets.symmetric(
              vertical: isTablet ? 16 : 14,
              horizontal: 16,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            minimumSize: const Size(double.infinity, 0),
          ),
        ),
        const SizedBox(height: 12),
        // Suspend Account Button
        OutlinedButton.icon(
          onPressed: vm.user?.status == UserStatus.suspended
              ? null
              : () => _showSuspendDialog(context, vm),
          icon: const Icon(Icons.block, color: AppColors.error),
          label: const AppText(
            'Suspend Account',
            style: TextStyle(
              color: AppColors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.error,
            side: const BorderSide(color: AppColors.error),
            padding: EdgeInsets.symmetric(
              vertical: isTablet ? 16 : 14,
              horizontal: 16,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            minimumSize: const Size(double.infinity, 0),
          ),
        ),
      ],
    );
  }

  void _showNotificationDialog(BuildContext context, AdminParentDetailViewModel vm) {
    _notificationController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const AppText('Send Notification'),
        content: TextField(
          controller: _notificationController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Enter notification message...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const AppText('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_notificationController.text.isNotEmpty) {
                final success = await vm.sendNotification(_notificationController.text);
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success
                          ? 'Notification sent successfully'
                          : 'Failed to send notification'),
                      backgroundColor: success ? AppColors.success : AppColors.error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const AppText(
              'Send',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuspendDialog(BuildContext context, AdminParentDetailViewModel vm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const AppText('Suspend Account'),
        content: const AppText(
          'Are you sure you want to suspend this parent account?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const AppText('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await vm.suspendAccount();
              if (context.mounted) {
                Navigator.of(context).pop();
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Account suspended successfully'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(vm.errorMessage ?? 'Failed to suspend account'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const AppText(
              'Suspend',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
