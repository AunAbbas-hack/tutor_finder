import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_text.dart';
import '../../tutor_viewmodels/tutor_session_vm.dart';
import '../chat/individual_chat_screen.dart';

class TutorSessionScreen extends StatefulWidget {
  const TutorSessionScreen({super.key});

  @override
  State<TutorSessionScreen> createState() => _TutorSessionScreenState();
}

class _TutorSessionScreenState extends State<TutorSessionScreen> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final vm = TutorSessionViewModel();
        // Initialize sessions data after first frame
        WidgetsBinding.instance.addPostFrameCallback((_) {
          vm.initialize();
        });
        return vm;
      },
      child: Container(
        color: AppColors.lightBackground,
        child: SafeArea(
          child: Consumer<TutorSessionViewModel>(
            builder: (context, vm, _) {
              if (vm.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              return Column(
                children: [
                  // Header
                  _buildHeader(context, vm),
                  // Tabs
                  _buildTabs(vm),
                  // Sessions List
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () => vm.initialize(),
                      child: vm.sessionsGroupedByDate.isEmpty
                          ? _buildEmptyState(vm)
                          : _buildSessionsList(vm),
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

  // ---------- Header Section ----------
  Widget _buildHeader(BuildContext context, TutorSessionViewModel vm) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
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
          // Title
          const Expanded(
            child: AppText(
              'My Sessions',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ),
          // Filter Icon (only show when viewing past bookings)
          if (vm.selectedTabIndex == 2)
            IconButton(
              icon: Icon(
                Icons.tune,
                color: vm.pastBookingFilter != PastBookingFilter.all
                    ? AppColors.primary
                    : AppColors.textDark,
                size: 28,
              ),
              onPressed: () {
                _showFilterDialog(context, vm);
              },
            ),
        ],
      ),
    );
  }

  // ---------- Tabs Section ----------
  Widget _buildTabs(TutorSessionViewModel vm) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: _buildTab(
              'Upcoming',
              vm.selectedTabIndex == 0,
              onTap: () => vm.selectTab(0),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildTab(
              'Approved',
              vm.selectedTabIndex == 1,
              onTap: () => vm.selectTab(1),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildTab(
              'Past',
              vm.selectedTabIndex == 2,
              onTap: () => vm.selectTab(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String label, bool isSelected, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: AppText(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : AppColors.textGrey,
            ),
          ),
        ),
      ),
    );
  }

  // ---------- Sessions List ----------
  Widget _buildSessionsList(TutorSessionViewModel vm) {
    final groupedSessions = vm.sessionsGroupedByDate;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: groupedSessions.length,
      itemBuilder: (context, index) {
        final dateGroup = groupedSessions[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Label
            Padding(
              padding: EdgeInsets.only(bottom: 12, top: index > 0 ? 24 : 0),
              child: AppText(
                dateGroup.dateLabel,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textGrey,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            // Sessions for this date
            ...dateGroup.sessions.map((session) => _buildSessionCard(session, vm.selectedTabIndex == 0)),
          ],
        );
      },
    );
  }

  // ---------- Session Card ----------
  Widget _buildSessionCard(SessionDisplayModel session, bool isUpcoming) {
    final booking = session.booking;
    final parent = session.parent;
    final isPast = !isUpcoming;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.selectionBg, // Light blue background
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left vertical blue bar
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
            // Main card content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  // Header: Profile + Name + Subject + Time
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Picture
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(
                            color: AppColors.border,
                            width: 1,
                          ),
                          image: session.parentImageUrl.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(session.parentImageUrl),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: session.parentImageUrl.isEmpty
                            ? Center(
                                child: AppText(
                                  parent.name.isNotEmpty
                                      ? parent.name[0].toUpperCase()
                                      : 'P',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      // Name and Subject
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText(
                              parent.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            AppText(
                              booking.subject,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.primary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Time Pill (light blue with white text)
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: AppText(
                            booking.bookingTime,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Separator line
                  const SizedBox(height: 16),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.border,
                  ),
                  const SizedBox(height: 12),
                  // Location
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: AppText(
                          session.location,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Duration
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      AppText(
                        '${session.duration.toStringAsFixed(session.duration.truncateToDouble() == session.duration ? 0 : 1)} ${session.duration == 1.0 ? 'hr' : 'hrs'} duration',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Action Buttons
                  Row(
                    children: [
                      // Details Button (large, blue, left)
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // TODO: Navigate to session details
                            Get.snackbar(
                              'Coming Soon',
                              'Session details will be available soon',
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: AppColors.primary,
                              colorText: Colors.white,
                              borderRadius: 12,
                              margin: const EdgeInsets.all(16),
                              duration: const Duration(seconds: 2),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const AppText(
                            'Details',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Message Button (square, rounded)
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.border,
                            width: 1,
                          ),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.message,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          onPressed: () {
                            // Navigate to chat with parent
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => IndividualChatScreen(
                                  otherUserId: parent.userId,
                                  otherUserName: parent.name,
                                  otherUserImageUrl: session.parentImageUrl.isNotEmpty
                                      ? session.parentImageUrl
                                      : null,
                                ),
                              ),
                            );
                          },
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            )],
        ),
      ),
    );
  }

  // ---------- Empty State ----------
  Widget _buildEmptyState(TutorSessionViewModel vm) {
    String title;
    String message;
    IconData icon;

    if (vm.selectedTabIndex == 0) {
      // Upcoming tab
      title = 'No Upcoming Sessions';
      message = 'Your upcoming sessions (with payment done) will appear here.';
      icon = Icons.event_busy;
    } else if (vm.selectedTabIndex == 1) {
      // Approved tab
      title = 'No Approved Sessions';
      message = 'Approved bookings awaiting payment will appear here.';
      icon = Icons.pending_actions;
    } else {
      // Past tab
      switch (vm.pastBookingFilter) {
        case PastBookingFilter.completed:
          title = 'No Completed Sessions';
          message = 'Completed sessions (with payment) will appear here.';
          icon = Icons.check_circle_outline;
          break;
        case PastBookingFilter.pastIncomplete:
          title = 'No Past Incomplete Sessions';
          message = 'Past sessions awaiting payment will appear here.';
          icon = Icons.pending_outlined;
          break;
        case PastBookingFilter.all:
        default:
          title = 'No Past Sessions';
          message = 'Your completed sessions will appear here.';
          icon = Icons.history;
          break;
      }
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.lightBackground,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 60,
              color: AppColors.iconGrey,
            ),
          ),
          const SizedBox(height: 24),
          AppText(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: AppText(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textGrey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Filter Dialog ----------
  void _showFilterDialog(BuildContext context, TutorSessionViewModel vm) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    const AppText(
                      'Filter Past Bookings',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textGrey),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Filter Options
              _buildFilterOption(
                context,
                'All Past Bookings',
                PastBookingFilter.all,
                vm.pastBookingFilter,
                () {
                  vm.setPastBookingFilter(PastBookingFilter.all);
                  Navigator.pop(context);
                },
              ),
              _buildFilterOption(
                context,
                'Completed (Paid)',
                PastBookingFilter.completed,
                vm.pastBookingFilter,
                () {
                  vm.setPastBookingFilter(PastBookingFilter.completed);
                  Navigator.pop(context);
                },
              ),
              _buildFilterOption(
                context,
                'Past Incomplete (Unpaid)',
                PastBookingFilter.pastIncomplete,
                vm.pastBookingFilter,
                () {
                  vm.setPastBookingFilter(PastBookingFilter.pastIncomplete);
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterOption(
    BuildContext context,
    String title,
    PastBookingFilter filter,
    PastBookingFilter selectedFilter,
    VoidCallback onTap,
  ) {
    final isSelected = filter == selectedFilter;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: AppText(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? AppColors.primary : AppColors.textDark,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: 24,
              )
            else
              const Icon(
                Icons.radio_button_unchecked,
                color: AppColors.iconGrey,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
