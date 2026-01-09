// lib/views/parent/notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_text.dart';
import '../../data/models/notification_model.dart';
import '../../parent_viewmodels/notification_vm.dart';
import '../../data/services/user_services.dart';
import 'booking_view_detail_screen.dart';
import 'bookings_screen_navbar.dart';
import '../chat/individual_chat_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final vm = NotificationViewModel();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          vm.initialize();
        });
        return vm;
      },
      child: Scaffold(
        backgroundColor: AppColors.lightBackground,
        body: SafeArea(
          child: Consumer<NotificationViewModel>(
            builder: (context, vm, _) {
              return Column(
                children: [
                  // Header
                  _buildHeader(context, vm),
                  // Content
                  Expanded(
                    child: _buildContent(context, vm),
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
  Widget _buildHeader(BuildContext context, NotificationViewModel vm) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(
            color: AppColors.border,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Back Button
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 8),
          // Title
          const Expanded(
            child: AppText(
              'Notifications',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ),
          // Mark All as Read Button
          if (vm.hasUnread)
            TextButton(
              onPressed: vm.isLoading ? null : () => vm.markAllAsRead(),
              child: const AppText(
                'Mark all read',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ---------- Content ----------
  Widget _buildContent(BuildContext context, NotificationViewModel vm) {
    if (vm.isLoading && vm.notifications.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
        ),
      );
    }

    if (vm.errorMessage != null && vm.notifications.isEmpty) {
      return Center(
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
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => vm.refresh(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const AppText('Retry'),
            ),
          ],
        ),
      );
    }

    if (vm.notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.notifications_none,
              size: 64,
              color: AppColors.iconGrey,
            ),
            const SizedBox(height: 16),
            const AppText(
              'No notifications yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textGrey,
              ),
            ),
            const SizedBox(height: 8),
            const AppText(
              'You\'ll see notifications here when you receive them',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => vm.refresh(),
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: vm.notifications.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final notification = vm.notifications[index];
          return _buildNotificationItem(context, vm, notification);
        },
      ),
    );
  }

  // ---------- Notification Item ----------
  Widget _buildNotificationItem(
    BuildContext context,
    NotificationViewModel vm,
    NotificationModel notification,
  ) {
    final isUnread = notification.status == NotificationStatus.unread;
    
    return Dismissible(
      key: Key(notification.notificationId),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      onDismissed: (direction) {
        vm.deleteNotification(notification.notificationId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: AppText('Notification deleted'),
            duration: Duration(seconds: 2),
          ),
        );
      },
      child: InkWell(
        onTap: () {
          // Mark as read if unread
          if (isUnread) {
            vm.markAsRead(notification.notificationId);
          }
          // Navigate based on notification type
          _handleNotificationTap(context, notification);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isUnread ? AppColors.primary : AppColors.border,
              width: isUnread ? 1.5 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isUnread
                      ? AppColors.primary.withOpacity(0.1)
                      : AppColors.lightBackground,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  _getNotificationIcon(notification.message),
                  color: isUnread ? AppColors.primary : AppColors.iconGrey,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Message
                    AppText(
                      notification.message,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isUnread ? FontWeight.w600 : FontWeight.w500,
                        color: AppColors.textDark,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Time
                    AppText(
                      _formatDateTime(notification.dateTime),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),
              // Unread indicator
              if (isUnread)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- Navigation ----------
  Future<void> _handleNotificationTap(
    BuildContext context,
    NotificationModel notification,
  ) async {
    final type = notification.type;
    final relatedId = notification.relatedId;
    final actionData = notification.actionData;

    if (type == null) {
      // No type, just mark as read (already done above)
      return;
    }

    switch (type) {
      case 'booking_approved':
      case 'booking_rejected':
      case 'booking_cancelled':
      case 'booking_reminder':
      case 'session_completed':
        // Navigate to booking detail screen if bookingId is available
        if (relatedId != null && relatedId.isNotEmpty) {
          Navigator.pop(context); // Close notifications screen
          Get.to(() => BookingViewDetailScreen(bookingId: relatedId));
        } else {
          // Navigate to bookings list
          Navigator.pop(context); // Close notifications screen
          Get.to(() => const BookingsScreenNavbar());
        }
        break;

      case 'message':
        // Navigate to chat screen with sender
        final senderId = relatedId ?? actionData?['senderId'] as String?;
        if (senderId != null && senderId.isNotEmpty) {
          final userService = UserService();
          final sender = await userService.getUserById(senderId);
          if (sender != null && mounted) {
            Navigator.pop(context); // Close notifications screen
            Get.to(() => IndividualChatScreen(
              otherUserId: sender.userId,
              otherUserName: sender.name,
              otherUserImageUrl: sender.imageUrl,
            ));
          }
        } else {
          // Navigate to messages list
          Navigator.pop(context); // Close notifications screen
          // Navigate to messages tab in main screen (index 2)
          // This would require accessing ParentMainScreen, which is complex
          // For now, just close notifications screen
        }
        break;

      case 'booking_request':
        // This notification is for tutors, not parents
        // But if parent sees it, navigate to bookings list
        Navigator.pop(context);
        Get.to(() => const BookingsScreenNavbar());
        break;

      case 'welcome':
      case 'profile_verified':
      case 'profile_under_review':
      default:
        // For other notification types, just mark as read
        // No navigation needed
        break;
    }
  }

  // ---------- Helpers ----------
  IconData _getNotificationIcon(String message) {
    final msgLower = message.toLowerCase();
    if (msgLower.contains('booking')) {
      return Icons.calendar_today;
    } else if (msgLower.contains('message')) {
      return Icons.message;
    } else if (msgLower.contains('approved') ||
        msgLower.contains('verified')) {
      return Icons.check_circle;
    } else if (msgLower.contains('rejected') ||
        msgLower.contains('cancelled')) {
      return Icons.cancel;
    } else if (msgLower.contains('welcome')) {
      return Icons.celebration;
    }
    return Icons.notifications;
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

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
      return DateFormat('MMM d, y').format(dateTime);
    }
  }
}
