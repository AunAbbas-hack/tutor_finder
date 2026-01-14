// lib/views/parent/tutor_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_text.dart';
import '../../data/models/review_model.dart';
import '../../viewmodels/tutor_detail_vm.dart';
import '../chat/individual_chat_screen.dart';
import '../../core/utils/debug_logger.dart';
import 'request_booking_screen.dart';

class TutorDetailScreen extends StatelessWidget {
  final String tutorId;

  const TutorDetailScreen({
    super.key,
    required this.tutorId,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final vm = TutorDetailViewModel(tutorId: tutorId);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          vm.initialize();
        });
        return vm;
      },
      child: Scaffold(
        backgroundColor: AppColors.lightBackground,
        body: Consumer<TutorDetailViewModel>(
          builder: (context, vm, child) {
            if (vm.isLoading && vm.tutor == null) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            if (vm.errorMessage != null && vm.tutor == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AppText(
                      vm.errorMessage!,
                      style: const TextStyle(color: AppColors.error),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => vm.initialize(),
                      child: const AppText('Retry'),
                    ),
                  ],
                ),
              );
            }

            return CustomScrollView(
              slivers: [
                // App Bar
                SliverAppBar(
                  backgroundColor: AppColors.lightBackground,
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
                    onPressed: () => Get.back(),
                  ),
                  title: const AppText(
                    'Tutor Profile',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  centerTitle: true,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.share, color: AppColors.textDark),
                      onPressed: () {
                        // TODO: Implement share functionality
                      },
                    ),
                  ],
                  pinned: true,
                ),
                // Content
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tutor Overview
                        _buildTutorOverview(vm),
                        const SizedBox(height: 24),
                        // Navigation Tabs
                        _buildTabs(vm),
                        const SizedBox(height: 24),
                        // Tab Content
                        _buildTabContent(vm, context),
                        const SizedBox(height: 24),
                        // Footer Buttons
                        _buildFooterButtons(vm, context),
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
    );
  }

  Widget _buildTutorOverview(TutorDetailViewModel vm) {
    final tutorUser = vm.tutorUser;
    final tutor = vm.tutor;

    if (tutorUser == null || tutor == null) return const SizedBox();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Profile Picture
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.lightBackground,
            border: Border.all(
              color: AppColors.border,
              width: 2,
            ),
            image: tutorUser.imageUrl != null && tutorUser.imageUrl!.isNotEmpty
                ? DecorationImage(
              image: NetworkImage(tutorUser.imageUrl!),
              fit: BoxFit.cover,
            )
                : null,
          ),
          child: tutorUser.imageUrl == null || tutorUser.imageUrl!.isEmpty
              ? const Icon(
            Icons.person,
            size: 40,
            color: AppColors.iconGrey,
          )
              : null,
        ),
        const SizedBox(width: 16),
        // Name and Details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: AppText(
                      tutorUser.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  // Verified Badge
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Subjects
              AppText(
                tutor.subjects.join(', '),
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textGrey,
                ),
              ),
              const SizedBox(height: 8),
              // Rating
              Row(
                children: [
                  const Icon(
                    Icons.star,
                    color: Colors.amber,
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  AppText(
                    '${vm.rating} (${vm.reviewCount} reviews)',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textGrey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabs(TutorDetailViewModel vm) {
    return Row(
      children: [
        _buildTabButton('About', 0, vm),
        const SizedBox(width: 24),
        _buildTabButton('Schedule', 1, vm),
        const SizedBox(width: 24),
        _buildTabButton('Reviews', 2, vm),
      ],
    );
  }

  Widget _buildTabButton(String label, int index, TutorDetailViewModel vm) {
    final isSelected = vm.selectedTab == index;
    return GestureDetector(
      onTap: () => vm.selectTab(index),
      child: Column(
        children: [
          AppText(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppColors.primary : AppColors.textGrey,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 3,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(TutorDetailViewModel vm, BuildContext context) {
    switch (vm.selectedTab) {
      case 0:
        return _buildAboutTab(vm);
      case 1:
        return _buildScheduleTab(vm, context);
      case 2:
        return _buildReviewsTab(vm);
      default:
        return _buildAboutTab(vm);
    }
  }

  Widget _buildAboutTab(TutorDetailViewModel vm) {
    final tutor = vm.tutor;
    if (tutor == null) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // About Me
        const AppText(
          'About Me',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 12),
        AppText(
          tutor.bio ?? 'No bio available',
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textGrey,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        // Experience
        _buildInfoRow(
          icon: Icons.school,
          label: 'Experience',
          value: '${tutor.experience ?? 0}+ Years',
        ),
        const SizedBox(height: 16),
        // Languages
        _buildInfoRow(
          icon: Icons.language,
          label: 'Languages',
          value: vm.languages.join(', '),
        ),
        const SizedBox(height: 16),
        // Location
        _buildInfoRow(
          icon: Icons.location_on,
          label: 'Location',
          value: vm.fullAddress,
        ),
        const SizedBox(height: 24),
        // Fee Structure
        _buildFeeStructure(vm),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textGrey,
                ),
              ),
              const SizedBox(height: 2),
              AppText(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeeStructure(TutorDetailViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.lightBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const AppText(
                'Fee Structure',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const AppText(
                'per hour',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textGrey,
                ),
              ),
              if (vm.hourlyFee == 0.0)
                const AppText(
                  ' (Not set)',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textGrey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          AppText(
            '${vm.hourlyFee.toStringAsFixed(0)} Rs.',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          // const AppText(
          //   'Package deals available for 10+ hours',
          //   style: TextStyle(
          //     fontSize: 12,
          //     color: AppColors.textGrey,
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildScheduleTab(TutorDetailViewModel vm, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const AppText(
              'Availability',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            GestureDetector(
              onTap: () => _showFullCalendar(context, vm),
              child: const AppText(
                'View Full Calendar',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Days Row
        _buildDaysRow(vm),
        const SizedBox(height: 16),
        // Time Slots
        _buildTimeSlots(vm),
      ],
    );
  }

  Widget _buildDaysRow(TutorDetailViewModel vm) {
    final days = vm.getNextFiveDays();
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: days.map((date) {
        final isSelected = _isSameDay(date, vm.selectedDate);
        final dayName = weekdays[date.weekday - 1];
        final dayNumber = date.day;

        return GestureDetector(
          onTap: () => vm.selectDate(date),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    AppText(
                      dayName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isSelected ? Colors.white : AppColors.textGrey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    AppText(
                      dayNumber.toString(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTimeSlots(TutorDetailViewModel vm) {
    return FutureBuilder<List<String>>(
      future: vm.getAvailableTimeSlots(vm.selectedDate),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2,
              ),
            ),
          );
        }

        final timeSlots = snapshot.data ?? [];

        if (timeSlots.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.lightBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.event_busy,
                  size: 48,
                  color: AppColors.iconGrey,
                ),
                SizedBox(height: 12),
                AppText(
                  'No available slots for this day',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textGrey,
                  ),
                ),
              ],
            ),
          );
        }

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: timeSlots.map((timeSlot) {
            final isSelected = vm.selectedTimeSlot == timeSlot;
            return GestureDetector(
              onTap: () => vm.selectTimeSlot(timeSlot),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                    width: 1,
                  ),
                ),
                child: AppText(
                  timeSlot,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.textDark,
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildReviewsTab(TutorDetailViewModel vm)
    {
      if (vm.reviewCount == 0) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.star_border,
                size: 64,
                color: AppColors.iconGrey,
              ),
              const SizedBox(height: 16),
              const AppText(
                'No reviews yet',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              const AppText(
                'Be the first to review this tutor',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textGrey,
                ),
              ),
            ],
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rating Summary
          Container(
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
            child: Row(
              children: [
                // Average Rating
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        AppText(
                          vm.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 28,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    AppText(
                      '${vm.reviewCount} ${vm.reviewCount == 1
                          ? 'review'
                          : 'reviews'}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Reviews List
          SizedBox(
            height: 400, // Fixed height for reviews list
            child: ListView.builder(
              itemCount: vm.reviews.length,
              itemBuilder: (context, index) {
                final review = vm.reviews[index];
                return _buildReviewCard(review);
              },
            ),
          ),
        ],
      );
    }
  
  Widget _buildReviewCard(ReviewModel review) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rating Stars
          Row(
            children: List.generate(5, (index) {
              return Icon(
                index < review.rating ? Icons.star : Icons.star_border,
                size: 18,
                color: index < review.rating ? Colors.amber : AppColors.iconGrey,
              );
            }),
          ),
          const SizedBox(height: 8),
          // Comment
          if (review.hasComment) ...[
            AppText(
              review.comment!,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textDark,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
          ],
          // Date
          AppText(
            _formatDate(review.createdAt),
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textLight,
            ),
          ),
          // Tutor Reply (if exists)
          if (review.hasReply) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.lightBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppText(
                    'Tutor\'s Reply',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  AppText(
                    review.reply!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textGrey,
                      height: 1.4,
                    ),
                  ),
                  if (review.repliedAt != null) ...[
                    const SizedBox(height: 4),
                    AppText(
                      _formatDate(review.repliedAt!),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
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
  }
  
  Widget _buildFooterButtons(TutorDetailViewModel vm, BuildContext context) {
    return Row(
      children: [
        // Chat Button
        Expanded(
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.lightBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.border,
                width: 1,
              ),
            ),
            child: TextButton.icon(
              onPressed: () {
                if (vm.tutorUser != null) {
                  Get.to(() => IndividualChatScreen(
                    otherUserId: vm.tutorUser!.userId,
                    otherUserName: vm.tutorUser!.name,
                    otherUserImageUrl: vm.tutorUser!.imageUrl,
                  ));
                }
              },
              icon: const Icon(
                Icons.chat_bubble_outline,
                color: AppColors.textDark,
              ),
              label: const AppText(
                'Chat',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Request Booking Button
        Expanded(
          flex: 2,
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: TextButton(
              onPressed: () => _showBookingDialog(context, vm),
              style: TextButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const AppText(
                'Request Booking',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showFullCalendar(BuildContext context, TutorDetailViewModel vm) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppText(
                'Select Date',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 20),
              TableCalendar(
                firstDay: DateTime.now(),
                lastDay: DateTime.now().add(const Duration(days: 365)),
                focusedDay: vm.selectedDate,
                selectedDayPredicate: (day) => _isSameDay(day, vm.selectedDate),
                onDaySelected: (selectedDay, focusedDay) {
                  vm.selectDate(selectedDay);
                  Get.back();
                },
                calendarStyle: const CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Get.back(),
                child: const AppText('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBookingDialog(BuildContext context, TutorDetailViewModel vm) {
    // #region agent log
    DebugLogger.log(location: 'tutor_detail_screen.dart:710', message: 'Booking dialog called', data: {'tutorId': vm.tutorId, 'selectedDate': vm.selectedDate.toString(), 'selectedTime': vm.selectedTimeSlot}, hypothesisId: 'BOOKING-UI-1').catchError((_) {});
    // #endregion
    
    // Navigate to Request Booking Screen
    if (vm.tutor != null && vm.tutorUser != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => RequestBookingScreen(
            tutorId: vm.tutorId,
            tutorName: vm.tutorUser!.name,
            tutorImageUrl: vm.tutorUser!.imageUrl,
            tutorSubjects: vm.tutor!.subjects.isNotEmpty 
                ? vm.tutor!.subjects 
                : ['General'], // Fallback if no subjects
          ),
        ),
      );
    } else {
      if (kDebugMode) {
        print('Tutor or TutorUser is null. Tutor: ${vm.tutor != null}, TutorUser: ${vm.tutorUser != null}');
      }
    Get.snackbar(
        'Error',
        'Tutor information not loaded. Please wait...',
      snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
      colorText: Colors.white,
        duration: const Duration(seconds: 3),
    );
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}

