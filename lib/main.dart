import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:tutor_finder/core/theme/app_theme.dart';
import 'package:tutor_finder/core/widgets/auth_wrapper.dart';
import 'package:tutor_finder/parent_viewmodels/auth_vm.dart';
import 'package:tutor_finder/core/services/firebase_messaging_handler.dart';

import 'firebase_options.dart';
import 'core/utils/seed_admin.dart';

/// Enable/disable admin seeding on app start
/// ⚠️ Set to false in production!
const bool ENABLE_ADMIN_SEEDING = false; // Change to true to seed admin accounts

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables from .env file
  try {
    await dotenv.load(fileName: ".env");
    debugPrint('✅ Environment variables loaded successfully');
  } catch (e) {
    debugPrint('⚠️ Warning: Could not load .env file: $e');
    debugPrint('⚠️ Cloudinary features may not work without .env file');
  }
  
  // Initialize Firebase with retry logic
  bool firebaseInitialized = false;
  int retryCount = 0;
  const maxRetries = 5; // Increased retries
  
  while (!firebaseInitialized && retryCount < maxRetries) {
    try {
      // Check if Firebase is already initialized
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        debugPrint('✅ Firebase initialized successfully');
        
        // Verify initialization by checking if we can access Firebase services
        try {
          final test = FirebaseFirestore.instance;
          debugPrint('✅ Firebase Firestore verified');
        } catch (e) {
          debugPrint('⚠️ Firebase initialized but Firestore not accessible: $e');
          throw Exception('Firestore not accessible after initialization');
        }
      } else {
        debugPrint('✅ Firebase already initialized');
        // Verify it's working
        try {
          final test = FirebaseFirestore.instance;
          debugPrint('✅ Firebase Firestore verified');
        } catch (e) {
          debugPrint('⚠️ Firebase apps exist but Firestore not accessible: $e');
          // Clear and reinitialize
          await Firebase.app().delete();
          continue;
        }
      }
      firebaseInitialized = true;
    } catch (e, stackTrace) {
      retryCount++;
      debugPrint('❌ Firebase initialization error (attempt $retryCount/$maxRetries): $e');
      
      if (retryCount >= maxRetries) {
        debugPrint('❌ Failed to initialize Firebase after $maxRetries attempts');
        debugPrint('Stack trace: $stackTrace');
        // Don't continue without Firebase - throw error
        throw Exception('Failed to initialize Firebase: $e');
      } else {
        // Wait a bit before retrying (exponential backoff)
        await Future.delayed(Duration(milliseconds: 500 * retryCount));
        debugPrint('🔄 Retrying Firebase initialization...');
      }
    }
  }
  
  // Final check - ensure Firebase is initialized before proceeding
  if (!firebaseInitialized || Firebase.apps.isEmpty) {
    throw Exception('Firebase initialization failed - cannot proceed');
  }

  // Initialize Firebase Cloud Messaging (FCM)
  await _initializeFCM();

  // Seed admin accounts (only if enabled and in debug mode)
  if (ENABLE_ADMIN_SEEDING && kDebugMode) {
    try {
      if (kDebugMode) {
        debugPrint('\n🌱 Admin seeding is enabled. Running seed script...');
      }
      await runAdminSeeding();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Admin seeding failed: $e');
        debugPrint('⚠️ You may need to run seed script manually');
      }
      // Don't block app startup if seeding fails
    }
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthViewModel()),
      ],
      child: const MyApp(),
    ),
  );
}

/// Initialize Firebase Cloud Messaging
Future<void> _initializeFCM() async {
  try {
    final messaging = FirebaseMessaging.instance;

    // Request notification permissions
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (kDebugMode) {
      print('📱 FCM Permission status: ${settings.authorizationStatus}');
    }

    // Register background message handler
    // This must be called before runApp()
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('📱 Foreground message received:');
        print('   Title: ${message.notification?.title}');
        print('   Body: ${message.notification?.body}');
        print('   Data: ${message.data}');
      }
      // You can show local notification here if needed
      // For now, system will handle it automatically
    });

    // Handle notification taps (when app is opened from notification)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('📱 Notification tapped - App opened from notification');
        print('   Data: ${message.data}');
      }
      // Navigate to specific screen based on notification data
      // This will be handled in AuthWrapper or specific screens
    });

    // Check if app was opened from a notification (when app was terminated)
    RemoteMessage? initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      if (kDebugMode) {
        print('📱 App opened from terminated state via notification');
        print('   Data: ${initialMessage.data}');
      }
      // Handle navigation here if needed
    }

    // Get FCM token
    String? token = await messaging.getToken();
    if (token != null) {
      if (kDebugMode) {
        print('📱 FCM Token: $token');
      }
      // Token will be saved to Firestore in FCM Service (Phase 2)
    }

    // Listen for token refresh
    messaging.onTokenRefresh.listen((newToken) {
      if (kDebugMode) {
        print('📱 FCM Token refreshed: $newToken');
      }
      // Update token in Firestore (will be handled in FCM Service)
    });

    if (kDebugMode) {
      print('✅ FCM initialized successfully');
    }
  } catch (e) {
    if (kDebugMode) {
      print('❌ FCM initialization error: $e');
    }
    // Don't throw error - app should still work without FCM
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Tutor Finder',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light, // Force light mode - ignore system theme
      // AuthWrapper automatically shows login or dashboard based on auth state
      home: const AuthWrapper(),
    );
  }
}


