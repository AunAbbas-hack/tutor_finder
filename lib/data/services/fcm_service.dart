// lib/data/services/fcm_service.dart
// FCM Token Management Service
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FCMService {
  final FirebaseMessaging _messaging;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FCMService({
    FirebaseMessaging? messaging,
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _messaging = messaging ?? FirebaseMessaging.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// Get current user ID
  String? get _currentUserId => _auth.currentUser?.uid;

  /// Get FCM token for current user
  Future<String?> getToken() async {
    try {
      final token = await _messaging.getToken();
      if (kDebugMode) {
        print('📱 FCM Token retrieved: ${token?.substring(0, 20)}...');
      }
      return token;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting FCM token: $e');
      }
      return null;
    }
  }

  /// Save FCM token to Firestore (user document)
  Future<bool> saveTokenToFirestore(String? token) async {
    if (token == null || _currentUserId == null) {
      if (kDebugMode) {
        print('⚠️ Cannot save token: token or userId is null');
      }
      return false;
    }

    try {
      await _firestore.collection('users').doc(_currentUserId).update({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        print('✅ FCM token saved to Firestore for user: $_currentUserId');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error saving FCM token to Firestore: $e');
      }
      return false;
    }
  }

  /// Get FCM token from Firestore for a specific user
  Future<String?> getTokenFromFirestore(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) {
        if (kDebugMode) {
          print('❌ User document not found: $userId');
        }
        return null;
      }

      final data = doc.data();
      final token = data?['fcmToken'] as String?;
      
      if (kDebugMode && token != null) {
        print('✅ FCM token retrieved from Firestore for user: $userId');
      }
      
      return token;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting FCM token from Firestore: $e');
      }
      return null;
    }
  }

  /// Initialize FCM token management
  /// Call this after user login
  Future<void> initializeToken() async {
    try {
      // Get current token
      final token = await getToken();
      
      if (token != null && _currentUserId != null) {
        // Save to Firestore
        await saveTokenToFirestore(token);
        
        // Listen for token refresh
        _messaging.onTokenRefresh.listen((newToken) async {
          if (kDebugMode) {
            print('📱 FCM token refreshed: ${newToken.substring(0, 20)}...');
          }
          await saveTokenToFirestore(newToken);
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initializing FCM token: $e');
      }
    }
  }

  /// Delete FCM token from Firestore (on logout)
  Future<void> deleteToken() async {
    if (_currentUserId == null) return;

    try {
      await _firestore.collection('users').doc(_currentUserId).update({
        'fcmToken': FieldValue.delete(),
        'fcmTokenUpdatedAt': FieldValue.delete(),
      });

      if (kDebugMode) {
        print('✅ FCM token deleted from Firestore');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error deleting FCM token: $e');
      }
    }
  }

  /// Request notification permissions
  Future<bool> requestPermission() async {
    try {
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      final isAuthorized = settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;

      if (kDebugMode) {
        print('📱 Notification permission status: ${settings.authorizationStatus}');
        print('   Authorized: $isAuthorized');
      }

      return isAuthorized;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error requesting notification permission: $e');
      }
      return false;
    }
  }

  /// Check if notifications are enabled
  Future<bool> isNotificationEnabled() async {
    try {
      final settings = await _messaging.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error checking notification status: $e');
      }
      return false;
    }
  }
}
