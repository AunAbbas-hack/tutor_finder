import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'package:tutor_finder/views/parent/tutor_search_screen.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_text.dart';
import '../../data/models/booking_model.dart';
import '../../parent_viewmodels/bookings_navbar_vm.dart';
import 'booking_view_detail_screen.dart';
import 'payment_history_screen.dart';

class BookingsScreenNavbar extends StatelessWidget {
  const BookingsScreenNavbar({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final vm = BookingsNavbarViewModel();
        vm.initialize();
        return vm;
      },
      child: Scaffold(
        backgroundColor: AppColors.lightBackground,
        appBar: AppBar(
          title: const AppText(
            'My Bookings',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: AppColors.lightBackground,
          actions: [
            IconButton(
              icon: const Icon(
                Icons.receipt_long,
                color: AppColors.textDark,
              ),
              onPressed: () {
                Get.to(() => const PaymentHistoryScreen());
              },
              tooltip: 'Payment History',
            ),
          ],
        ),
        body: Consumer<BookingsNavbarViewModel>(
          builder: (context, vm, _) {
            return Column(
              children: [
                // Tab Bar
                _buildTabBar(context, vm),
                // Bookings List
                Expanded(
                  child: vm.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : vm.displayedBookings.isEmpty
                          ? _buildEmptyState()
                          : _buildBookingsList(context, vm),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ---------- Tab Bar ----------
  Widget _buildTabBar(BuildContext context, BookingsNavbarViewModel vm) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          _buildTab(
            context,
            'All',
            vm.showAll,
            onTap: () => vm.selectTab(null),
          ),
          const SizedBox(width: 8),
          _buildTab(
            context,
            'Pending',
            !vm.showAll && vm.selectedTab == BookingStatus.pending,
            onTap: () => vm.selectTab(BookingStatus.pending),
          ),
          const SizedBox(width: 8),
          _buildTab(
            context,
            'Approved',
            !vm.showAll && vm.selectedTab == BookingStatus.approved,
            onTap: () => vm.selectTab(BookingStatus.approved),
          ),
          const SizedBox(width: 8),
          _buildTab(
            context,
            'Rejected',
            !vm.showAll && vm.selectedTab == BookingStatus.rejected,
            onTap: () => vm.selectTab(BookingStatus.rejected),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(
    BuildContext context,
    String label,
    bool isSelected,
    {required VoidCallback onTap}
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: AppText(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textGrey,
          ),
        ),
      ),
    );
  }

  // ---------- Bookings List ----------
  Widget _buildBookingsList(
      // BookingDisplayModel bookingDisplay,

      BuildContext context, BookingsNavbarViewModel vm) {
    // final booking =bookingDisplay.booking;
    return RefreshIndicator(
      onRefresh: () => vm.initialize(),
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: vm.displayedBookings.length,
        itemBuilder: (context, index) {
          final bookingDisplay = vm.displayedBookings[index];
          return GestureDetector(
            onTap: () {
              Get.to(() => BookingViewDetailScreen(
                    bookingId: bookingDisplay.booking.bookingId,
                  ));
            },
            child: _buildBookingCard(context, vm, bookingDisplay),
          );
        },
      ),
    );
  }

  // ---------- Booking Card ----------
  Widget _buildBookingCard(
    BuildContext context,
    BookingsNavbarViewModel vm,
    BookingDisplayModel bookingDisplay,
  ) {
    final booking = bookingDisplay.booking;
    final tutor = bookingDisplay.tutor;
    final status = booking.status;

    // Check if booking is pending cancellation
    final isPendingCancel = vm.isPendingCancellation(booking.bookingId);

    // Status color and text
    Color statusColor;
    String statusText;
    if (isPendingCancel) {
      // Show "Cancelling..." if timer is active
      statusColor = AppColors.warning;
      statusText = 'CANCELLING...';
    } else {
    switch (status) {
      case BookingStatus.approved:
        statusColor = AppColors.success;
        statusText = 'APPROVED';
        break;
      case BookingStatus.pending:
        statusColor = AppColors.warning;
        statusText = 'PENDING';
        break;
      case BookingStatus.rejected:
        statusColor = AppColors.error;
        statusText = 'REJECTED';
        break;
        case BookingStatus.cancelled:
          statusColor = AppColors.textGrey;
          statusText = 'CANCELLED';
          break;
      default:
        statusColor = AppColors.textGrey;
        statusText = status.toString().toUpperCase();
      }
    }

    // Action button based on status
    Widget actionButton;
    switch (status) {
      case BookingStatus.approved:
        actionButton = _buildActionButton(
          'Make Payment',
          AppColors.primary,
          () {
            Get.to(() => BookingViewDetailScreen(
                  bookingId: booking.bookingId,
                ));
          },
        );
        break;
      case BookingStatus.pending:
        actionButton = _buildActionButton(
          'Cancel Request',
          AppColors.textGrey,
          () async {
            final confirmed = await Get.dialog<bool>(
              AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: const AppText(
                  'Cancel Booking',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                content: const AppText(
                  'Are you sure you want to cancel this booking request?',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textGrey,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Get.back(result: false),
                    child: const AppText(
                      'No',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Get.back(result: true),
                    child: const AppText(
                      'Yes, Cancel',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              barrierDismissible: false,
            );

            if (confirmed == true) {
              // Start timer for cancellation (5 seconds)
              await vm.cancelBookingWithTimer(booking.bookingId);
              Get.snackbar(
                'Cancelling...',
                'Booking will be cancelled in 5 seconds. Click to restore.',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: AppColors.warning,
                colorText: Colors.white,
                borderRadius: 12,
                margin: const EdgeInsets.all(16),
                duration: const Duration(seconds: 5),
                icon: const Icon(Icons.timer, color: Colors.white),
                mainButton: TextButton(
                  onPressed: () {
                    Get.closeCurrentSnackbar();
                    vm.restoreBookingToPending(booking.bookingId);
                  },
                  child: const Text(
                    'RESTORE',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              );
            }
          },
        );
        break;
      case BookingStatus.rejected:
        actionButton = _buildActionButton(
          'Find Another Tutor',
          AppColors.primary,
          () {
           Get.to(TutorSearchScreen());
            
          },
        );
        break;
      case BookingStatus.cancelled:
        // Show "Restore to Pending" button for cancelled bookings
        actionButton = _buildActionButton(
          'Restore to Pending',
          AppColors.primary,
          () async {
            final confirmed = await Get.dialog<bool>(
              AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: const AppText(
                  'Restore Booking',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                content: const AppText(
                  'Do you want to restore this booking to pending status?',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textGrey,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Get.back(result: false),
                    child: const AppText(
                      'No',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Get.back(result: true),
                    child: const AppText(
                      'Yes, Restore',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              barrierDismissible: false,
            );

            if (confirmed == true) {
              await vm.restoreBookingToPending(booking.bookingId);
              Get.snackbar(
                'Success',
                'Booking restored to pending',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: AppColors.success,
                colorText: Colors.white,
                borderRadius: 12,
                margin: const EdgeInsets.all(16),
                duration: const Duration(seconds: 2),
                icon: const Icon(Icons.check_circle, color: Colors.white),
              );
            }
          },
        );
        break;
      default:
        actionButton = _buildActionButton(
          'View Details',
          AppColors.primary,
          () {},
        );
    }

    // Format date
    final dateStr = _formatDate(booking.bookingDate);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
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
          // Header: Profile + Name + Status
          Row(
            children: [
              // Profile Picture
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.lightBackground,
                  image: bookingDisplay.tutorImageUrl.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(bookingDisplay.tutorImageUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: bookingDisplay.tutorImageUrl.isEmpty
                    ? const Icon(
                        Icons.person,
                        size: 32,
                        color: AppColors.iconGrey,
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
                      tutor.name,
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
                        color: AppColors.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: AppText(
                  statusText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Date and Time
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
                  fontSize: 14,
                  color: AppColors.textGrey,
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
                  fontSize: 14,
                  color: AppColors.textGrey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Action Button
          SizedBox(
            width: double.infinity,
            child: actionButton,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color == AppColors.primary
            ? AppColors.primary
            : AppColors.lightBackground,
        foregroundColor: color == AppColors.primary ? Colors.white : color,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
      ),
      child: AppText(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: color == AppColors.primary ? Colors.white : color,
        ),
      ),
    );
  }

  // ---------- Empty State ----------
  Widget _buildEmptyState() {
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
            child: const Icon(
              Icons.event_busy,
              size: 60,
              color: AppColors.iconGrey,
            ),
          ),
          const SizedBox(height: 24),
          const AppText(
            'No Bookings Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: AppText(
              'Your booking requests will appear here once you\'ve made them.',
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

  // ---------- Helper ----------
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
}

