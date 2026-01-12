// lib/data/services/notification_service.dart
// Notification Service for Firestore operations and Push Notifications
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;
import '../models/notification_model.dart';
import '../models/booking_model.dart';
import 'fcm_service.dart';
import 'oauth_token_service.dart';
import 'user_services.dart';

class NotificationService {
  final FirebaseFirestore _firestore;
  final FCMService _fcmService;
  final OAuthTokenService _oauthService;
  final UserService _userService;

  NotificationService({
    FirebaseFirestore? firestore,
    FCMService? fcmService,
    OAuthTokenService? oauthService,
    UserService? userService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _fcmService = fcmService ?? FCMService(),
        _oauthService = oauthService ?? OAuthTokenService.instance,
        _userService = userService ?? UserService();

  CollectionReference<Map<String, dynamic>> get _notificationsCol =>
      _firestore.collection('notifications');

  // ---------- FIRESTORE OPERATIONS ----------

  /// Create a notification in Firestore
  Future<String> createNotification({
    required String userId,
    required String message,
    DateTime? dateTime,
    String? type,
    String? relatedId,
    Map<String, dynamic>? actionData,
  }) async {
    try {
      final notificationId = _notificationsCol.doc().id;
      final notification = NotificationModel(
        notificationId: notificationId,
        userId: userId,
        message: message,
        dateTime: dateTime ?? DateTime.now(),
        status: NotificationStatus.unread,
        type: type,
        relatedId: relatedId,
        actionData: actionData,
      );

      await _notificationsCol.doc(notificationId).set(notification.toMap());

      if (kDebugMode) {
        print('✅ Notification created: $notificationId for user: $userId (type: $type)');
      }

      return notificationId;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error creating notification: $e');
      }
      rethrow;
    }
  }

  /// Get notifications for a user (real-time stream)
  Stream<List<NotificationModel>> getNotificationsStream(String userId) {
    return _notificationsCol
        .where('userId', isEqualTo: userId)
        .orderBy('dateTime', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => NotificationModel.fromMap(doc.data()))
          .toList();
    });
  }

  /// Get notifications for a user (one-time fetch)
  Future<List<NotificationModel>> getNotifications(String userId) async {
    try {
      final snapshot = await _notificationsCol
          .where('userId', isEqualTo: userId)
          .orderBy('dateTime', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => NotificationModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting notifications: $e');
      }
      return [];
    }
  }

  /// Get unread notifications count
  Future<int> getUnreadCount(String userId) async {
    try {
      final snapshot = await _notificationsCol
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'unread')
          .get();

      return snapshot.docs.length;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting unread count: $e');
      }
      return 0;
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationsCol.doc(notificationId).update({
        'status': 'read',
      });

      if (kDebugMode) {
        print('✅ Notification marked as read: $notificationId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error marking notification as read: $e');
      }
      rethrow;
    }
  }

  /// Mark all notifications as read for a user
  Future<void> markAllAsRead(String userId) async {
    try {
      final snapshot = await _notificationsCol
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'unread')
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'status': 'read'});
      }

      await batch.commit();

      if (kDebugMode) {
        print('✅ All notifications marked as read for user: $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error marking all as read: $e');
      }
      rethrow;
    }
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationsCol.doc(notificationId).delete();

      if (kDebugMode) {
        print('✅ Notification deleted: $notificationId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error deleting notification: $e');
      }
      rethrow;
    }
  }

  /// Delete old notifications (older than 30 days)
  Future<void> deleteOldNotifications(String userId) async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final snapshot = await _notificationsCol
          .where('userId', isEqualTo: userId)
          .where('dateTime', isLessThan: Timestamp.fromDate(thirtyDaysAgo))
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      if (kDebugMode) {
        print('✅ Old notifications deleted for user: $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error deleting old notifications: $e');
      }
    }
  }

  // ---------- PUSH NOTIFICATION OPERATIONS ----------

  /// Send push notification using FCM V1 API with OAuth 2.0
  Future<bool> sendPushNotification({
    required String userId,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    try {
      if (kDebugMode) {
        print('🔔 sendPushNotification called for userId: $userId');
        print('   Title: $title');
      }
      
      // Get FCM token for the user
      final fcmToken = await _fcmService.getTokenFromFirestore(userId);
      
      if (fcmToken == null) {
        if (kDebugMode) {
          print('⚠️ FCM token not found in Firestore for user: $userId');
          print('   Notification will be saved to Firestore but push will not be sent');
        }
        return false;
      }
      
      if (kDebugMode) {
        print('✅ FCM token found: ${fcmToken.substring(0, 30)}...');
      }

      // Get authenticated HTTP client with OAuth 2.0 token
      final authenticatedClient = await _oauthService.getAuthenticatedClient();
      if (authenticatedClient == null) {
        if (kDebugMode) {
          print('❌ Failed to get OAuth authenticated client');
        }
        return false;
      }

      // Prepare notification payload (V1 API format)
      final projectId = _oauthService.projectId;
      final payload = {
        'message': {
          'token': fcmToken,
          'notification': {
            'title': title,
            'body': message,
          },
          if (data != null && data.isNotEmpty)
            'data': data.map((key, value) => MapEntry(key.toString(), value.toString())),
          'android': {
            'priority': 'high',
            'notification': {
              'sound': 'default',
            },
          },
          'apns': {
            'headers': {
              'apns-priority': '10',
            },
            'payload': {
              'aps': {
                'sound': 'default',
              },
            },
          },
        },
      };

      // Send notification via FCM V1 API
      final url = 'https://fcm.googleapis.com/v1/projects/$projectId/messages:send';
      
      if (kDebugMode) {
        print('📤 Sending FCM V1 API request to: $url');
        print('   Token: ${fcmToken.substring(0, 20)}...');
      }

      final response = await authenticatedClient.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('✅ Push notification sent successfully to user: $userId');
          final responseData = jsonDecode(response.body);
          print('   Message ID: ${responseData['name']}');
        }
        return true;
      } else {
        if (kDebugMode) {
          print('❌ Failed to send push notification: ${response.statusCode}');
          print('   Response: ${response.body}');
          
          // Handle common errors
          if (response.statusCode == 401) {
            print('   Error: Unauthorized - Token may be invalid. Clearing cache...');
            _oauthService.clearCache();
          } else if (response.statusCode == 403) {
            print('   Error: Forbidden - Check Service Account permissions');
          } else if (response.statusCode == 404) {
            print('   Error: Not Found - Check project ID and FCM token');
          }
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error sending push notification: $e');
      }
      return false;
    }
  }

  // ---------- COMBINED OPERATIONS (Firestore + Push) ----------

  /// Create notification in Firestore AND send push notification
  Future<String?> createAndSendNotification({
    required String userId,
    required String title,
    required String message,
    Map<String, dynamic>? data,
    DateTime? dateTime,
    bool sendPush = true,
  }) async {
    try {
      // Extract type and relatedId from data for navigation
      final type = data?['type'] as String?;
      // Priority: bookingId > senderId (for messages) > tutorId/parentId
      final relatedId = data?['bookingId'] as String? ??
          data?['senderId'] as String? ??
          data?['tutorId'] as String? ??
          data?['parentId'] as String? ??
          data?['chatId'] as String?;

      // Create notification in Firestore with type and relatedId
      final notificationId = await createNotification(
        userId: userId,
        message: message,
        dateTime: dateTime,
        type: type,
        relatedId: relatedId,
        actionData: data,
      );

      // Send push notification if requested
      if (sendPush) {
        await sendPushNotification(
          userId: userId,
          title: title,
          message: message,
          data: data,
        );
      }

      return notificationId;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error creating and sending notification: $e');
      }
      return null;
    }
  }

  // ---------- SPECIFIC NOTIFICATION HELPERS ----------

  /// Send booking notification to tutor
  Future<void> sendBookingNotificationToTutor({
    required String tutorId,
    required String parentName,
    required String subject,
    String? bookingId,
  }) async {
    await createAndSendNotification(
      userId: tutorId,
      title: 'New Booking Request',
      message: 'New booking request from $parentName for $subject',
      data: {
        'type': 'booking_request',
        'parentName': parentName,
        'subject': subject,
        if (bookingId != null) 'bookingId': bookingId,
      },
    );
  }

  /// Send booking approval notification to parent
  Future<void> sendBookingApprovalToParent({
    required String parentId,
    required String tutorName,
    String? bookingId,
  }) async {
    await createAndSendNotification(
      userId: parentId,
      title: 'Booking Approved',
      message: 'Your booking has been approved by $tutorName. Now make payment to confirm your booking',
      data: {
        'type': 'booking_approved',
        'tutorName': tutorName,
        if (bookingId != null) 'bookingId': bookingId,
      },
    );
  }

  /// Send booking rejection notification to parent
  Future<void> sendBookingRejectionToParent({
    required String parentId,
    required String tutorName,
    String? bookingId,
  }) async {
    await createAndSendNotification(
      userId: parentId,
      title: 'Booking Rejected',
      message: 'Your booking request has been rejected by $tutorName',
      data: {
        'type': 'booking_rejected',
        'tutorName': tutorName,
        if (bookingId != null) 'bookingId': bookingId,
      },
    );
  }

  /// Send message notification
  Future<void> sendMessageNotification({
    required String receiverId,
    required String senderName,
    required String messagePreview,
    String? senderId,
  }) async {
    await createAndSendNotification(
      userId: receiverId,
      title: senderName,
      message: messagePreview,
      data: {
        'type': 'message',
        'senderName': senderName,
        if (senderId != null) 'senderId': senderId,
      },
    );
  }

  /// Send booking cancellation notification to parent
  Future<void> sendBookingCancellationToParent({
    required String parentId,
    required String tutorName,
    String? bookingId,
  }) async {
    await createAndSendNotification(
      userId: parentId,
      title: 'Booking Cancelled',
      message: '$tutorName has cancelled your booking',
      data: {
        'type': 'booking_cancelled',
        'tutorName': tutorName,
        if (bookingId != null) 'bookingId': bookingId,
      },
    );
  }

  /// Send booking cancellation notification to tutor
  Future<void> sendBookingCancellationToTutor({
    required String tutorId,
    required String parentName,
    String? bookingId,
  }) async {
    await createAndSendNotification(
      userId: tutorId,
      title: 'Booking Cancelled',
      message: '$parentName has cancelled the booking',
      data: {
        'type': 'booking_cancelled',
        'parentName': parentName,
        if (bookingId != null) 'bookingId': bookingId,
      },
    );
  }

  /// Send session completed notification to parent
  Future<void> sendSessionCompletedToParent({
    required String parentId,
    required String tutorName,
    String? bookingId,
  }) async {
    await createAndSendNotification(
      userId: parentId,
      title: 'Session Completed',
      message: 'Session with $tutorName has been marked as completed',
      data: {
        'type': 'session_completed',
        'tutorName': tutorName,
        if (bookingId != null) 'bookingId': bookingId,
      },
    );
  }

  /// Send session completed notification to tutor
  Future<void> sendSessionCompletedToTutor({
    required String tutorId,
    required String parentName,
    String? bookingId,
  }) async {
    await createAndSendNotification(
      userId: tutorId,
      title: 'Session Completed',
      message: 'Session with $parentName has been marked as completed',
      data: {
        'type': 'session_completed',
        'parentName': parentName,
        if (bookingId != null) 'bookingId': bookingId,
      },
    );
  }

  /// Send profile under review notification to tutor
  Future<void> sendProfileUnderReviewToTutor({
    required String tutorId,
  }) async {
    if (kDebugMode) {
      print('📨 sendProfileUnderReviewToTutor called for tutorId: $tutorId');
    }
    
    final notificationId = await createAndSendNotification(
      userId: tutorId,
      title: 'Profile Under Review',
      message: 'Your profile is under review by admin. Please make sure you completed your profile.',
      data: {
        'type': 'profile_under_review',
      },
    );
    
    if (kDebugMode) {
      if (notificationId != null) {
        print('✅ Profile under review notification created with ID: $notificationId');
      } else {
        print('❌ Failed to create profile under review notification');
      }
    }
  }

  /// Send welcome notification to parent
  Future<void> sendWelcomeNotificationToParent({
    required String parentId,
  }) async {
    await createAndSendNotification(
      userId: parentId,
      title: 'Welcome to Tutor Finder!',
      message: 'Welcome to Tutor Finder! Find the best tutors for your children.',
      data: {
        'type': 'welcome',
      },
    );
  }

  // ---------- PROFILE/ACCOUNT NOTIFICATIONS (Low Priority) ----------

  /// Send profile verified notification to parent
  Future<void> sendProfileVerifiedToParent({
    required String parentId,
  }) async {
    await createAndSendNotification(
      userId: parentId,
      title: 'Profile Verified',
      message: 'Your profile has been verified successfully',
      data: {
        'type': 'profile_verified',
      },
    );
  }

  /// Send profile approved notification to tutor
  Future<void> sendProfileApprovedToTutor({
    required String tutorId,
  }) async {
    await createAndSendNotification(
      userId: tutorId,
      title: 'Profile Approved',
      message: 'Congratulations! Your tutor profile has been approved',
      data: {
        'type': 'profile_approved',
      },
    );
  }

  /// Send profile rejected notification to tutor
  Future<void> sendProfileRejectedToTutor({
    required String tutorId,
    String? reason,
  }) async {
    final message = reason != null && reason.isNotEmpty
        ? 'Your tutor profile has been rejected. Reason: $reason. Please update your information.'
        : 'Your tutor profile has been rejected. Please update your information.';
    
    await createAndSendNotification(
      userId: tutorId,
      title: 'Profile Rejected',
      message: message,
      data: {
        'type': 'profile_rejected',
        if (reason != null) 'reason': reason,
      },
    );
  }

  // ---------- BOOKING SELF-CONFIRMATION NOTIFICATIONS (Tutor) ----------

  /// Send booking accepted confirmation to tutor (self-confirmation)
  Future<void> sendBookingAcceptedConfirmationToTutor({
    required String tutorId,
    required String parentName,
  }) async {
    await createAndSendNotification(
      userId: tutorId,
      title: 'Booking Accepted',
      message: 'You have accepted booking request from $parentName',
      data: {
        'type': 'booking_accepted_confirmation',
        'parentName': parentName,
      },
    );
  }

  /// Send booking rejected confirmation to tutor (self-confirmation)
  Future<void> sendBookingRejectedConfirmationToTutor({
    required String tutorId,
    required String parentName,
  }) async {
    await createAndSendNotification(
      userId: tutorId,
      title: 'Booking Rejected',
      message: 'You have rejected booking request from $parentName',
      data: {
        'type': 'booking_rejected_confirmation',
        'parentName': parentName,
      },
    );
  }

  // ---------- REMINDER NOTIFICATIONS (Medium Priority) ----------

  /// Send booking reminder to parent (1 day before session)
  Future<void> sendBookingReminderToParent({
    required String parentId,
    required String tutorName,
    required DateTime sessionDate,
    required String sessionTime,
    String? bookingId,
  }) async {
    final formattedDate = _formatDate(sessionDate);
    await createAndSendNotification(
      userId: parentId,
      title: 'Session Reminder',
      message: 'Reminder: Your session with $tutorName is tomorrow at $sessionTime',
      data: {
        'type': 'booking_reminder',
        'tutorName': tutorName,
        'sessionDate': sessionDate.toIso8601String(),
        'sessionTime': sessionTime,
        if (bookingId != null) 'bookingId': bookingId,
      },
    );
  }

  /// Send session reminder to tutor (2 hours before session)
  Future<void> sendSessionReminderToTutor({
    required String tutorId,
    required String parentName,
    required DateTime sessionDate,
    required String sessionTime,
    String? bookingId,
  }) async {
    await createAndSendNotification(
      userId: tutorId,
      title: 'Upcoming Session',
      message: 'Reminder: You have a session with $parentName in 2 hours at $sessionTime',
      data: {
        'type': 'session_reminder',
        'parentName': parentName,
        'sessionDate': sessionDate.toIso8601String(),
        'sessionTime': sessionTime,
        if (bookingId != null) 'bookingId': bookingId,
      },
    );
  }

  /// Check and send reminders for upcoming sessions
  /// This should be called periodically (e.g., when app opens, or in dashboard)
  Future<void> checkAndSendReminders() async {
    try {
      final now = DateTime.now();
      
      // Get all approved bookings with future dates
      final bookingsSnapshot = await _firestore
          .collection('bookings')
          .where('status', isEqualTo: 'approved')
          .get();

      final bookings = bookingsSnapshot.docs
          .map((doc) => BookingModel.fromFirestore(doc))
          .where((booking) => booking.bookingDate.isAfter(now))
          .toList();

      for (final booking in bookings) {
        final sessionDateTime = _combineDateAndTime(booking.bookingDate, booking.bookingTime);
        if (sessionDateTime == null) continue;

        final timeUntilSession = sessionDateTime.difference(now);

        // Parent reminder: 24 hours before (between 23-25 hours)
        if (timeUntilSession.inHours >= 23 && timeUntilSession.inHours <= 25) {
          // Check if reminder already sent (to avoid duplicates)
          final reminderKey = 'reminder_parent_${booking.bookingId}_24h';
          final reminderSent = await _checkReminderSent(reminderKey);
          
          if (!reminderSent) {
            final tutor = await _userService.getUserById(booking.tutorId);
            if (tutor != null) {
              await sendBookingReminderToParent(
                parentId: booking.parentId,
                tutorName: tutor.name,
                sessionDate: booking.bookingDate,
                sessionTime: booking.bookingTime,
                bookingId: booking.bookingId,
              );
              await _markReminderSent(reminderKey);
            }
          }
        }

        // Tutor reminder: 2 hours before (between 1.5-2.5 hours)
        if (timeUntilSession.inHours >= 1 && timeUntilSession.inHours <= 3) {
          // Check if reminder already sent
          final reminderKey = 'reminder_tutor_${booking.bookingId}_2h';
          final reminderSent = await _checkReminderSent(reminderKey);
          
          if (!reminderSent) {
            final parent = await _userService.getUserById(booking.parentId);
            if (parent != null) {
              await sendSessionReminderToTutor(
                tutorId: booking.tutorId,
                parentName: parent.name,
                sessionDate: booking.bookingDate,
                sessionTime: booking.bookingTime,
                bookingId: booking.bookingId,
              );
              await _markReminderSent(reminderKey);
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error checking reminders: $e');
      }
    }
  }

  /// Combine booking date and time string into DateTime
  DateTime? _combineDateAndTime(DateTime date, String timeString) {
    try {
      // Parse time string (e.g., "4:00 PM" or "16:00")
      int hour = 0;
      int minute = 0;
      
      if (timeString.toLowerCase().contains('pm') || timeString.toLowerCase().contains('am')) {
        // 12-hour format
        final parts = timeString.replaceAll(RegExp(r'[APM\s]', caseSensitive: false), '').split(':');
        if (parts.length >= 2) {
          hour = int.parse(parts[0]);
          minute = int.parse(parts[1]);
          
          if (timeString.toLowerCase().contains('pm') && hour != 12) {
            hour += 12;
          } else if (timeString.toLowerCase().contains('am') && hour == 12) {
            hour = 0;
          }
        }
      } else {
        // 24-hour format
        final parts = timeString.split(':');
        if (parts.length >= 2) {
          hour = int.parse(parts[0]);
          minute = int.parse(parts[1]);
        }
      }
      
      return DateTime(date.year, date.month, date.day, hour, minute);
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Error parsing time: $timeString - $e');
      }
      // Default to 4 PM if parsing fails
      return DateTime(date.year, date.month, date.day, 16, 0);
    }
  }

  /// Format date for display
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Check if reminder already sent (to avoid duplicates)
  Future<bool> _checkReminderSent(String reminderKey) async {
    try {
      final doc = await _firestore.collection('reminder_sent').doc(reminderKey).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  /// Mark reminder as sent
  Future<void> _markReminderSent(String reminderKey) async {
    try {
      await _firestore.collection('reminder_sent').doc(reminderKey).set({
        'sentAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Error marking reminder as sent: $e');
      }
    }
  }
}
