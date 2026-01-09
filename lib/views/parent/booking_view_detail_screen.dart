import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_text.dart';
import '../../parent_viewmodels/booking_view_detail_vm.dart';
import '../../data/models/booking_model.dart';
import '../../data/models/user_model.dart';
import '../../data/services/user_services.dart';
import '../../core/utils/distance_calculator.dart';
import '../chat/individual_chat_screen.dart';

class BookingViewDetailScreen extends StatelessWidget {
  final String bookingId;

  const BookingViewDetailScreen({
    super.key,
    required this.bookingId,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final vm = BookingViewDetailViewModel();
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
            'Booking Details',
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
              icon: const Icon(Icons.more_vert, color: AppColors.textDark),
              onPressed: () {
                // TODO: Show options menu
              },
            ),
          ],
        ),
        body: Consumer<BookingViewDetailViewModel>(
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

            if (vm.booking == null) {
              return const Center(
                child: AppText('Booking not found'),
              );
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final isSmallScreen = constraints.maxWidth < 400;
                final horizontalPadding = isSmallScreen ? 16.0 : 20.0;
                
                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Section
                      _buildStatusSection(context, vm),
                      const SizedBox(height: 20),

                      // Tutor Section
                      _buildTutorSection(context, vm),
                      const SizedBox(height: 20),

                      // Session Details Section
                      _buildSessionDetailsSection(context, vm),
                      const SizedBox(height: 20),

                      // Location Section
                      if (vm.hasTutorLocation) ...[
                        _buildLocationSection(context, vm),
                        const SizedBox(height: 20),
                      ],

                      // Special Requests Section
                      if (vm.booking!.notes != null &&
                          vm.booking!.notes!.isNotEmpty) ...[
                        _buildSpecialRequestsSection(context, vm),
                        const SizedBox(height: 20),
                      ],

                      // Action Buttons
                      _buildActionButtons(context, vm),
                      const SizedBox(height: 20),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  // ---------- Status Section ----------
  Widget _buildStatusSection(
      BuildContext context, BookingViewDetailViewModel vm) {
    final status = vm.booking!.status;
    Color statusColor;
    IconData statusIcon;
    String statusText;
    String statusMessage;

    switch (status) {
      case BookingStatus.approved:
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle;
        statusText = 'APPROVED';
        statusMessage = 'Your request has been confirmed.';
        break;
      case BookingStatus.pending:
        statusColor = AppColors.warning;
        statusIcon = Icons.pending;
        statusText = 'PENDING';
        statusMessage = 'Your request is being reviewed.';
        break;
      case BookingStatus.rejected:
        statusColor = AppColors.error;
        statusIcon = Icons.cancel;
        statusText = 'REJECTED';
        statusMessage = 'Your request has been rejected.';
        break;
      case BookingStatus.cancelled:
        statusColor = AppColors.textGrey;
        statusIcon = Icons.cancel;
        statusText = 'CANCELLED';
        statusMessage = 'This booking has been cancelled.';
        break;
      case BookingStatus.completed:
        statusColor = AppColors.primary;
        statusIcon = Icons.check_circle;
        statusText = 'COMPLETED';
        statusMessage = 'This session has been completed.';
        break;
    }

    return Container(
      width: double.infinity,
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
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              statusIcon,
              color: statusColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  statusText,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: 4),
                AppText(
                  statusMessage,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textGrey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Tutor Section ----------
  Widget _buildTutorSection(
      BuildContext context, BookingViewDetailViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppText(
          'TUTOR',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textGrey,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
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
          child: Row(
            children: [
              // Profile Picture
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.lightBackground,
                  image: (vm.tutorImageUrl != null && vm.tutorImageUrl!.isNotEmpty)
                      ? DecorationImage(
                          image: NetworkImage(vm.tutorImageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: (vm.tutorImageUrl == null || vm.tutorImageUrl!.isEmpty)
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
                      vm.tutor?.name ?? 'Unknown Tutor',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    AppText(
                      vm.booking!.subjects.isNotEmpty
                          ? vm.booking!.subjects.first
                          : vm.booking!.subject,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
              // Graduation Cap Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.school,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------- Session Details Section ----------
  Widget _buildSessionDetailsSection(
      BuildContext context, BookingViewDetailViewModel vm) {
    final booking = vm.booking!;
    final dateStr = _formatDate(booking.bookingDate);
    final timeStr = booking.bookingTime;

    // Get student info
    String studentName = 'N/A';
    String studentGrade = '';
    if (vm.students.isNotEmpty) {
      final student = vm.students.first;
      final studentUser = vm.studentUsers[student.studentId];
      studentName = studentUser?.name ?? 'Unknown Student';
      studentGrade = student.grade ?? '';
    }

    // Get parent name
    final parentName = vm.parent?.name ?? 'N/A';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppText(
          'SESSION DETAILS',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textGrey,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
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
            children: [
              _buildDetailRow(
                icon: Icons.calendar_today,
                iconColor: AppColors.primary,
                label: 'Date',
                value: dateStr,
              ),
              const SizedBox(height: 16),
              _buildDetailRow(
                icon: Icons.access_time,
                iconColor: const Color(0xFFFFA000),
                label: 'Time',
                value: timeStr,
              ),
              const SizedBox(height: 16),
              _buildDetailRow(
                icon: Icons.person,
                iconColor: const Color(0xFF9C27B0),
                label: 'Student',
                value: studentGrade.isNotEmpty
                    ? '$studentName - $studentGrade'
                    : studentName,
              ),
              const SizedBox(height: 16),
              _buildDetailRow(
                icon: Icons.people,
                iconColor: AppColors.textGrey,
                label: 'Parent',
                value: parentName,
              ),
              const SizedBox(height: 16),
              _buildDetailRow(
                icon: Icons.attach_money,
                iconColor: AppColors.success,
                label: 'Offered Amount',
                value: booking.monthlyBudget != null
                    ? '\$${booking.monthlyBudget!.toStringAsFixed(2)}'
                    : 'N/A',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
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
                  fontSize: 12,
                  color: AppColors.textGrey,
                ),
              ),
              const SizedBox(height: 2),
              AppText(
                value,
                style: const TextStyle(
                  fontSize: 16,
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

  // ---------- Location Section ----------
  Widget _buildLocationSection(
      BuildContext context, BookingViewDetailViewModel vm) {
    return FutureBuilder<UserModel?>(
      future: _getCurrentUser(),
      builder: (context, snapshot) {
        String distanceText = '';
        if (snapshot.hasData && snapshot.data != null) {
          final parent = snapshot.data!;
          if (parent.latitude != null &&
              parent.longitude != null &&
              vm.tutorLatitude != null &&
              vm.tutorLongitude != null) {
            final distanceInKm = DistanceCalculator.calculateDistanceInKm(
              parent.latitude!,
              parent.longitude!,
              vm.tutorLatitude!,
              vm.tutorLongitude!,
            );
            distanceText = 'Booking from ${distanceInKm.toStringAsFixed(1)} km away.';
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppText(
              'LOCATION',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textGrey,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
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
                  // Address Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: AppColors.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText(
                              vm.tutorLocationAddress ?? 'Location not available',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
                              ),
                            ),
                            if (distanceText.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              AppText(
                                distanceText,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textGrey,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Map
                  if (vm.tutorLatitude != null && vm.tutorLongitude != null)
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final mapHeight = constraints.maxWidth < 400 ? 180.0 : 200.0;
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            height: mapHeight,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.border,
                                width: 1,
                              ),
                            ),
                            child: Stack(
                              children: [
                                GoogleMap(
                                  initialCameraPosition: CameraPosition(
                                    target: LatLng(
                                      vm.tutorLatitude!,
                                      vm.tutorLongitude!,
                                    ),
                                    zoom: 14.0,
                                  ),
                                  myLocationButtonEnabled: false,
                                  zoomControlsEnabled: false,
                                  mapToolbarEnabled: false,
                                  markers: {
                                    Marker(
                                      markerId: const MarkerId('tutor_location'),
                                      position: LatLng(
                                        vm.tutorLatitude!,
                                        vm.tutorLongitude!,
                                      ),
                                      icon: BitmapDescriptor.defaultMarkerWithHue(
                                        BitmapDescriptor.hueBlue,
                                      ),
                                    ),
                                  },
                                ),
                                // Map expand button
                                Positioned(
                                  bottom: 8,
                                  right: 8,
                                  child: GestureDetector(
                                    onTap: () {
                                      // TODO: Open full screen map
                                    },
                                    child: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.1),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                      ),
                                      child: const Icon(
                                        Icons.map,
                                        color: AppColors.primary,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
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
      },
    );
  }

  // ---------- Special Requests Section ----------
  Widget _buildSpecialRequestsSection(
      BuildContext context, BookingViewDetailViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppText(
          'SPECIAL REQUESTS',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textGrey,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.note,
                color: AppColors.textGrey,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppText(
                  '"${vm.booking!.notes!}"',
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
      BuildContext context, BookingViewDetailViewModel vm) {
    final status = vm.booking!.status;

    return Row(
      children: [
        // Cancel Button
        if (status == BookingStatus.approved ||
            status == BookingStatus.pending)
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                // TODO: Implement cancel booking
                Get.snackbar(
                  'Cancel Booking',
                  'Cancel functionality will be implemented',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const AppText(
                'Cancel',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.error,
                ),
              ),
            ),
          ),
        if (status == BookingStatus.approved ||
            status == BookingStatus.pending)
          const SizedBox(width: 12),
        // Chat Button
        Expanded(
          flex: status == BookingStatus.approved ||
                  status == BookingStatus.pending
              ? 1
              : 2,
          child: ElevatedButton(
            onPressed: vm.tutor != null
                ? () {
                    Get.to(() => IndividualChatScreen(
                          otherUserId: vm.tutor!.userId,
                          otherUserName: vm.tutor!.name,
                          otherUserImageUrl: vm.tutor!.imageUrl,
                        ));
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.chat_bubble_outline, size: 20),
                SizedBox(width: 8),
                AppText(
                  'Chat with Tutor',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---------- Helpers ----------
  Future<UserModel?> _getCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return await UserService().getUserById(user.uid);
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
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }
}
