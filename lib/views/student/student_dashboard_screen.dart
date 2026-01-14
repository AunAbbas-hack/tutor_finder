// lib/views/student/student_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_text.dart';
import '../../student_viewmodels/student_dashboard_vm.dart';
import '../../data/models/booking_model.dart';
import '../../data/models/user_model.dart';
import '../parent/booking_view_detail_screen.dart';

class StudentDashboardScreen extends StatelessWidget {
  const StudentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final vm = StudentDashboardViewModel();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          vm.initialize();
        });
        return vm;
      },
      child: Scaffold(
        backgroundColor: AppColors.lightBackground,
        body: Consumer<StudentDashboardViewModel>(
          builder: (context, vm, _) {
            if (vm.isLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              );
            }

            if (vm.errorMessage != null && vm.studentUser == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: 16),
                      AppText(
                        vm.errorMessage!,
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.textGrey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => vm.initialize(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: const AppText('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () => vm.refresh(),
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Header
                    _buildWelcomeHeader(vm),
                    const SizedBox(height: 24),

                    // Statistics Cards
                    _buildStatisticsCards(vm),
                    const SizedBox(height: 24),

                    // Assigned Tutors Section
                    if (vm.tutors.isNotEmpty) ...[
                      _buildSectionHeader('My Tutors'),
                      const SizedBox(height: 12),
                      _buildTutorsList(vm),
                      const SizedBox(height: 24),
                    ],

                    // Upcoming Sessions
                    if (vm.upcomingBookings.isNotEmpty) ...[
                      _buildSectionHeader('Upcoming Sessions'),
                      const SizedBox(height: 12),
                      _buildBookingsList(vm, vm.upcomingBookings),
                      const SizedBox(height: 24),
                    ],

                    // Completed Sessions
                    if (vm.completedBookings.isNotEmpty) ...[
                      _buildSectionHeader('Completed Sessions'),
                      const SizedBox(height: 12),
                      _buildBookingsList(vm, vm.completedBookings),
                      const SizedBox(height: 24),
                    ],

                    // Pending Sessions
                    if (vm.pendingBookings.isNotEmpty) ...[
                      _buildSectionHeader('Pending Sessions'),
                      const SizedBox(height: 12),
                      _buildBookingsList(vm, vm.pendingBookings),
                      const SizedBox(height: 24),
                    ],

                    // Empty State
                    if (vm.allBookings.isEmpty)
                      _buildEmptyState(),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader(StudentDashboardViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Profile Avatar
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.2),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: vm.studentUser?.imageUrl != null &&
                    vm.studentUser!.imageUrl!.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      vm.studentUser!.imageUrl!,
                      fit: BoxFit.cover,
                    ),
                  )
                : const Icon(
                    Icons.person,
                    size: 32,
                    color: Colors.white,
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  'Welcome, ${vm.studentName}!',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                if (vm.studentGrade != 'N/A')
                  AppText(
                    'Grade ${vm.studentGrade}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCards(StudentDashboardViewModel vm) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.calendar_today,
            label: 'Total Sessions',
            value: vm.totalSessions.toString(),
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.check_circle,
            label: 'Completed',
            value: vm.completedSessions.toString(),
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.upcoming,
            label: 'Upcoming',
            value: vm.upcomingSessions.toString(),
            color: const Color(0xFFFFA000),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
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
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          AppText(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          AppText(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textGrey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return AppText(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.textDark,
      ),
    );
  }

  Widget _buildTutorsList(StudentDashboardViewModel vm) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: vm.tutors.length,
        itemBuilder: (context, index) {
          final tutor = vm.tutors[index];
          return _buildTutorCard(tutor);
        },
      ),
    );
  }

  Widget _buildTutorCard(UserModel tutor) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.lightBackground,
              image: tutor.imageUrl != null && tutor.imageUrl!.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(tutor.imageUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: tutor.imageUrl == null || tutor.imageUrl!.isEmpty
                ? const Icon(
                    Icons.person,
                    color: AppColors.iconGrey,
                    size: 30,
                  )
                : null,
          ),
          const SizedBox(height: 8),
          AppText(
            tutor.name,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildBookingsList(
    StudentDashboardViewModel vm,
    List<BookingModel> bookings,
  ) {
    return Column(
      children: bookings.map((booking) {
        return _buildBookingCard(vm, booking);
      }).toList(),
    );
  }

  Widget _buildBookingCard(
    StudentDashboardViewModel vm,
    BookingModel booking,
  ) {
    final tutor = vm.getTutorForBooking(booking.tutorId);
    final dateStr = _formatDate(booking.bookingDate);
    final statusColor = _getStatusColor(booking.status);
    final statusText = _getStatusText(booking.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: InkWell(
        onTap: () {
          Get.to(() => BookingViewDetailScreen(bookingId: booking.bookingId));
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                // Tutor Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.lightBackground,
                    image: tutor?.imageUrl != null &&
                            tutor!.imageUrl!.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(tutor.imageUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: tutor?.imageUrl == null || tutor!.imageUrl!.isEmpty
                      ? const Icon(
                          Icons.person,
                          color: AppColors.iconGrey,
                          size: 24,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        tutor?.name ?? 'Tutor',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      AppText(
                        booking.subjects.isNotEmpty
                            ? booking.subjects.first
                            : booking.subject,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor, width: 1),
                  ),
                  child: AppText(
                    statusText,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Date & Time
            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: AppColors.iconGrey,
                ),
                const SizedBox(width: 8),
                AppText(
                  dateStr,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(
                  Icons.access_time,
                  size: 16,
                  color: AppColors.iconGrey,
                ),
                const SizedBox(width: 8),
                AppText(
                  booking.bookingTime,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.event_busy,
            size: 64,
            color: AppColors.iconGrey,
          ),
          const SizedBox(height: 16),
          const AppText(
            'No Sessions Yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          const AppText(
            'Your parent will book sessions for you.\nYou\'ll see them here once booked.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textGrey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return const Color(0xFFFFA000);
      case BookingStatus.approved:
        return AppColors.primary;
      case BookingStatus.completed:
        return AppColors.success;
      case BookingStatus.rejected:
        return AppColors.error;
      case BookingStatus.cancelled:
        return AppColors.textGrey;
    }
  }

  String _getStatusText(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return 'Pending';
      case BookingStatus.approved:
        return 'Approved';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.rejected:
        return 'Rejected';
      case BookingStatus.cancelled:
        return 'Cancelled';
    }
  }
}
