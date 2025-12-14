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
        color: AppColors.background,
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
          // Filter Icon
          IconButton(
            icon: const Icon(
              Icons.tune,
              color: AppColors.textDark,
              size: 28,
            ),
            onPressed: () {
              // TODO: Open filter dialog
              Get.snackbar(
                'Coming Soon',
                'Filter feature will be available soon',
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
              vm.showUpcoming,
              onTap: () => vm.selectTab(true),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildTab(
              'Past',
              !vm.showUpcoming,
              onTap: () => vm.selectTab(false),
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
            ...dateGroup.sessions.map((session) => _buildSessionCard(session, vm.showUpcoming)),
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
          // Header: Profile + Name + Subject + Time
          Row(
            children: [
              // Profile Picture
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.lightBackground,
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
                          style: TextStyle(
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
                    ),
                    const SizedBox(height: 4),
                    AppText(
                      booking.subject,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              // Time Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isPast
                      ? AppColors.lightBackground
                      : AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: AppText(
                  booking.bookingTime,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isPast ? AppColors.textGrey : AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Location
          Row(
            children: [
              Icon(
                Icons.location_on,
                size: 16,
                color: isPast ? AppColors.iconGrey : AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AppText(
                  session.location,
                  style: TextStyle(
                    fontSize: 14,
                    color: isPast ? AppColors.textGrey : AppColors.textDark,
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
                color: isPast ? AppColors.iconGrey : AppColors.primary,
              ),
              const SizedBox(width: 8),
              AppText(
                '${session.duration.toStringAsFixed(session.duration.truncateToDouble() == session.duration ? 0 : 1)} ${session.duration == 1.0 ? 'hr' : 'hrs'} duration',
                style: TextStyle(
                  fontSize: 14,
                  color: isPast ? AppColors.textGrey : AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Action Buttons
          Row(
            children: [
              // Details Button
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
                    backgroundColor: isPast ? Colors.white : AppColors.primary,
                    foregroundColor: isPast ? AppColors.textDark : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isPast ? AppColors.border : Colors.transparent,
                        width: 1,
                      ),
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
              // Message Button
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
                  icon: Icon(
                    Icons.message,
                    color: isPast ? AppColors.iconGrey : AppColors.primary,
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
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------- Empty State ----------
  Widget _buildEmptyState(TutorSessionViewModel vm) {
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
              vm.showUpcoming ? Icons.event_busy : Icons.history,
              size: 60,
              color: AppColors.iconGrey,
            ),
          ),
          const SizedBox(height: 24),
          AppText(
            vm.showUpcoming ? 'No Upcoming Sessions' : 'No Past Sessions',
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
              vm.showUpcoming
                  ? 'Your upcoming sessions will appear here once bookings are confirmed.'
                  : 'Your completed sessions will appear here.',
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
}
