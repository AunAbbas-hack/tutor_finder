// lib/views/tutor/tutor_booking_request_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_text.dart';
import '../../tutor_viewmodels/tutor_booking_request_detail_vm.dart';
import '../../data/models/booking_model.dart';

class TutorBookingRequestDetailScreen extends StatelessWidget {
  final String bookingId;

  const TutorBookingRequestDetailScreen({
    super.key,
    required this.bookingId,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final vm = TutorBookingRequestDetailViewModel();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          vm.initialize(bookingId);
        });
        return vm;
      },
      child: Scaffold(
        backgroundColor: AppColors.lightBackground,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
            onPressed: () => Get.back(),
          ),
          title: const AppText(
            'Request Details',
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
        body: Consumer<TutorBookingRequestDetailViewModel>(
          builder: (context, vm, _) {
            if (vm.isLoading && vm.booking == null) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            if (vm.errorMessage != null && vm.booking == null) {
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
                      onPressed: () => vm.initialize(bookingId),
                      child: const AppText('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (vm.booking == null || vm.parent == null) {
              return const Center(
                child: AppText('Booking not found'),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Parent Profile Section
                  _buildParentProfileSection(vm),
                  const SizedBox(height: 24),

                  // Booking Details Card
                  _buildBookingDetailsCard(vm),
                  const SizedBox(height: 24),

                  // Parent Location Section
                  if (vm.hasParentLocation) ...[
                    _buildLocationSection(context, vm),
                    const SizedBox(height: 24),
                  ],

                  // Message Section
                  if (vm.booking!.notes != null && vm.booking!.notes!.isNotEmpty) ...[
                    _buildMessageSection(vm),
                    const SizedBox(height: 24),
                  ],

                  // Action Buttons
                  _buildActionButtons(context, vm),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ---------- Parent Profile Section ----------
  Widget _buildParentProfileSection(TutorBookingRequestDetailViewModel vm) {
    final parent = vm.parent!;
    
    // Get student name and grade
    String studentInfo = '';
    if (vm.students.isNotEmpty) {
      final student = vm.students.first;
      final studentUser = vm.studentUsers[student.studentId];
      final studentName = studentUser?.name ?? 'Student';
      final grade = student.grade ?? 'N/A';
      final relationship = vm.students.length == 1 ? 'son' : 'child';
      studentInfo = 'for $relationship, $studentName (Grade $grade)';
    } else {
      studentInfo = 'for child';
    }

    final initial = parent.name.isNotEmpty ? parent.name[0].toUpperCase() : '?';
    final avatarColor = _getAvatarColor(initial);

    return Center(
      child: Column(
        children: [
          // Profile Picture with Verified Badge
          Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: avatarColor.withValues(alpha: 0.2),
                  image: vm.parentImageUrl.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(vm.parentImageUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                  border: Border.all(
                    color: AppColors.border,
                    width: 2,
                  ),
                ),
                child: vm.parentImageUrl.isEmpty
                    ? Center(
                        child: AppText(
                          initial,
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w700,
                            color: avatarColor,
                          ),
                        ),
                      )
                    : null,
              ),
              // Verified Badge
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.fromBorderSide(
                      BorderSide(color: Colors.white, width: 3),
                    ),
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Parent Name
          AppText(
            parent.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          // Student Info
          AppText(
            studentInfo,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textGrey,
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Booking Details Card ----------
  Widget _buildBookingDetailsCard(TutorBookingRequestDetailViewModel vm) {
    final booking = vm.booking!;
    
    // Get subject
    final subject = booking.subjects.isNotEmpty 
        ? booking.subjects.first 
        : booking.subject;
    
    // Get booking plan
    final bookingPlan = booking.bookingType == BookingType.monthlyBooking
        ? 'Monthly Subscription'
        : 'Single Session';
    
    // Get schedule
    String schedule = booking.bookingTime;
    if (booking.bookingType == BookingType.monthlyBooking &&
        booking.recurringDays != null &&
        booking.recurringDays!.isNotEmpty) {
      final days = _formatRecurringDays(booking.recurringDays!);
      schedule = '$days • ${booking.bookingTime}';
    }
    
    // Get fee
    String fee = '';
    if (booking.monthlyBudget != null) {
      if (booking.bookingType == BookingType.monthlyBooking) {
        fee = '₹${booking.monthlyBudget!.toStringAsFixed(0)}/month';
      } else {
        // Single session - show as hourly rate
        fee = '₹${booking.monthlyBudget!.toStringAsFixed(0)}/hr';
      }
    } else {
      // Fallback if budget not available
      fee = 'Fee details in message';
    }

    return Container(
      width: double.infinity,
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
        children: [
          _buildDetailRow(
            Icons.menu_book,
            'SUBJECT',
            subject,
            AppColors.primary,
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            Icons.calendar_month,
            'BOOKING PLAN',
            bookingPlan,
            const Color(0xFF9C27B0), // Purple
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            Icons.calendar_view_week,
            'SCHEDULE',
            schedule,
            const Color(0xFF03A9F4), // Light Blue
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            Icons.attach_money,
            'OFFERED FEE',
            fee,
            AppColors.success, // Green
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, Color iconColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textGrey,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              AppText(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------- Location Section ----------
  Widget _buildLocationSection(
    BuildContext context,
    TutorBookingRequestDetailViewModel vm,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const AppText(
              'Parent Location',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            if (vm.distanceText != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.near_me,
                      color: AppColors.primary,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    AppText(
                      vm.distanceText!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        // Map
        Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: GoogleMap(
              key: ValueKey('parent_map_${vm.parentLatitude}_${vm.parentLongitude}'),
              initialCameraPosition: CameraPosition(
                target: LatLng(
                  vm.parentLatitude!,
                  vm.parentLongitude!,
                ),
                zoom: 14.0,
              ),
              onMapCreated: (GoogleMapController controller) {
                // Map controller initialized
                // Can be used for future map operations if needed
              },
              myLocationButtonEnabled: false,
              zoomControlsEnabled: true,
              zoomGesturesEnabled: true,
              mapToolbarEnabled: false,
              mapType: MapType.normal,
              compassEnabled: false,
              rotateGesturesEnabled: true,
              scrollGesturesEnabled: true,
              tiltGesturesEnabled: false,
              markers: {
                Marker(
                  markerId: const MarkerId('parent_location'),
                  position: LatLng(
                    vm.parentLatitude!,
                    vm.parentLongitude!,
                  ),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueRed,
                  ),
                  infoWindow: InfoWindow(
                    title: 'Parent Location',
                    snippet: vm.parentLocationAddress ?? 'Booking Location',
                  ),
                ),
              },
              gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Address
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.home,
                color: AppColors.iconGrey,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppText(
                  vm.parentLocationAddress ?? 'Address not available',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------- Message Section ----------
  Widget _buildMessageSection(TutorBookingRequestDetailViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppText(
          'Message',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.format_quote,
                color: AppColors.iconGrey,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppText(
                  vm.booking!.notes!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textDark,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------- Action Buttons ----------
  Widget _buildActionButtons(
    BuildContext context,
    TutorBookingRequestDetailViewModel vm,
  ) {
    return Row(
      children: [
        // Reject Button
        Expanded(
          child: OutlinedButton(
            onPressed: vm.isLoading
                ? null
                : () => _handleReject(context, vm),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.error, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const AppText(
              'Reject',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.error,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Accept Button
        Expanded(
          child: ElevatedButton(
            onPressed: vm.isLoading
                ? null
                : () => _handleAccept(context, vm),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: vm.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const AppText(
                    'Accept',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  // ---------- Handlers ----------
  Future<void> _handleAccept(
    BuildContext context,
    TutorBookingRequestDetailViewModel vm,
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
      final success = await vm.acceptBooking();
      if (success) {
        Get.snackbar(
          'Success',
          'Booking request accepted',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
        Get.back();
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
    TutorBookingRequestDetailViewModel vm,
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
      final success = await vm.rejectBooking();
      if (success) {
        Get.snackbar(
          'Success',
          'Booking request rejected',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
        Get.back();
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

  // ---------- Helpers ----------
  Color _getAvatarColor(String initial) {
    final colors = [
      const Color(0xFFE91E63), // Pink
      const Color(0xFF9C27B0), // Purple
      const Color(0xFF673AB7), // Deep Purple
      const Color(0xFF3F51B5), // Indigo
      const Color(0xFF2196F3), // Blue
      const Color(0xFF00BCD4), // Cyan
      const Color(0xFF4CAF50), // Green
      const Color(0xFF8BC34A), // Light Green
      const Color(0xFFFFC107), // Amber
      const Color(0xFFFF9800), // Orange
    ];
    final index = initial.codeUnitAt(0) % colors.length;
    return colors[index];
  }

  String _formatRecurringDays(List<int> days) {
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final dayStrings = days.map((day) => dayNames[day - 1]).toList();
    return dayStrings.join(', ');
  }
}
