// lib/core/services/firebase_messaging_handler.dart
// Top-level background message handler for FCM
// This must be a top-level function (not a class method) to work when app is killed

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Background message handler
/// This function will be called when app is in background or terminated
/// Must be a top-level function (not inside a class)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ensure Firebase is initialized
  // Note: Firebase.initializeApp() is already called in main.dart
  // But we need to ensure it's initialized here too for background handler
  
  if (kDebugMode) {
    print('📱 Background message received:');
    print('   Title: ${message.notification?.title}');
    print('   Body: ${message.notification?.body}');
    print('   Data: ${message.data}');
  }

  // Handle background notification here
  // You can save to local storage, update Firestore, etc.
  
  // Note: UI updates are not possible in background handler
  // The system will automatically show the notification
}
