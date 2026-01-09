import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:tutor_finder/core/theme/app_theme.dart';
import 'package:tutor_finder/core/widgets/auth_wrapper.dart';
import 'package:tutor_finder/parent_viewmodels/auth_vm.dart';

import 'firebase_options.dart';

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

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthViewModel()),
      ],
      child: const MyApp(),
    ),
  );
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


