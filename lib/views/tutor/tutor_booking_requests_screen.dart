import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_text.dart';
import '../../tutor_viewmodels/tutor_booking_requests_vm.dart';
import 'tutor_booking_request_detail_screen.dart';

class TutorBookingRequestsScreen extends StatelessWidget {
  const TutorBookingRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final vm = TutorBookingRequestsViewModel();
        vm.initialize();
        return vm;
      },
      child: Scaffold(
        backgroundColor: AppColors.lightBackground,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const AppText(
            'Booking Requests',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: AppColors.lightBackground,
        ),
        body: Consumer<TutorBookingRequestsViewModel>(
          builder: (context, vm, _) {
            if (vm.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (vm.errorMessage != null) {
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

            if (vm.pendingBookings.isEmpty) {
              return _buildEmptyState();
            }

            return RefreshIndicator(
              onRefresh: () => vm.initialize(),
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: vm.pendingBookings.length,
                itemBuilder: (context, index) {
                  final bookingDisplay = vm.pendingBookings[index];
                  return GestureDetector(
                    onTap: () {
                      Get.to(() => TutorBookingRequestDetailScreen(
                            bookingId: bookingDisplay.booking.bookingId,
                          ));
                    },
                    child: _buildBookingCard(context, vm, bookingDisplay),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

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
              Icons.inbox_outlined,
              size: 60,
              color: AppColors.iconGrey,
            ),
          ),
          const SizedBox(height: 24),
          const AppText(
            'No Pending Requests',
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
              'You don\'t have any pending booking requests at the moment.',
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

  Widget _buildBookingCard(
    BuildContext context,
    TutorBookingRequestsViewModel vm,
    BookingRequestDisplay bookingDisplay,
  ) {
    final booking = bookingDisplay.booking;
    final parent = bookingDisplay.parent;

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
          // Header: Parent Profile + Name
          Row(
            children: [
              // Profile Picture
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.lightBackground,
                  image: bookingDisplay.parentImageUrl.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(bookingDisplay.parentImageUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: bookingDisplay.parentImageUrl.isEmpty
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
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const AppText(
                  'PENDING',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Booking Details
          _buildDetailRow(
            Icons.calendar_today,
            _formatDate(booking.bookingDate),
          ),
          const SizedBox(height: 8),
          _buildDetailRow(
            Icons.access_time,
            booking.bookingTime,
          ),
          if (booking.notes != null && booking.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildDetailRow(
              Icons.note,
              booking.notes!,
            ),
          ],
          const SizedBox(height: 16),
          // Action Buttons
          Row(
            children: [
              // Reject Button
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _handleReject(context, vm, booking.bookingId),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.error, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const AppText(
                    'Reject',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Accept Button
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _handleAccept(context, vm, booking.bookingId),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const AppText(
                    'Accept',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
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

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.iconGrey),
        const SizedBox(width: 8),
        Expanded(
          child: AppText(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textDark,
            ),
          ),
        ),
      ],
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

  Future<void> _handleAccept(
    BuildContext context,
    TutorBookingRequestsViewModel vm,
    String bookingId,
  ) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const AppText(
          'Accept Booking',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        content: const AppText(
          'Are you sure you want to accept this booking request?',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textGrey,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const AppText(
              'Cancel',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textGrey,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const AppText(
              'Accept',
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
      final success = await vm.acceptBooking(bookingId);
      if (success) {
        Get.snackbar(
          'Success',
          'Booking request accepted',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      } else {
        Get.snackbar(
          'Error',
          vm.errorMessage ?? 'Failed to accept booking',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      }
    }
  }

  Future<void> _handleReject(
    BuildContext context,
    TutorBookingRequestsViewModel vm,
    String bookingId,
  ) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const AppText(
          'Reject Booking',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        content: const AppText(
          'Are you sure you want to reject this booking request?',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textGrey,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const AppText(
              'Cancel',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textGrey,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const AppText(
              'Reject',
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
      final success = await vm.rejectBooking(bookingId);
      if (success) {
        Get.snackbar(
          'Success',
          'Booking request rejected',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      } else {
        Get.snackbar(
          'Error',
          vm.errorMessage ?? 'Failed to reject booking',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      }
    }
  }
}

