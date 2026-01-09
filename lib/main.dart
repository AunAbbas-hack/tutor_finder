import 'package:firebase_core/firebase_core.dart';
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
  const maxRetries = 3;
  
  while (!firebaseInitialized && retryCount < maxRetries) {
    try {
      // Check if Firebase is already initialized
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        debugPrint('✅ Firebase initialized successfully');
      } else {
        debugPrint('✅ Firebase already initialized');
      }
      firebaseInitialized = true;
    } catch (e, stackTrace) {
      retryCount++;
      debugPrint('❌ Firebase initialization error (attempt $retryCount/$maxRetries): $e');
      
      if (retryCount >= maxRetries) {
        debugPrint('❌ Failed to initialize Firebase after $maxRetries attempts');
        debugPrint('Stack trace: $stackTrace');
        // For development, we'll continue anyway but show an error
        // In production, you might want to show an error screen
        debugPrint('⚠️ Continuing without Firebase - some features may not work');
      } else {
        // Wait a bit before retrying
        await Future.delayed(Duration(milliseconds: 500 * retryCount));
        debugPrint('🔄 Retrying Firebase initialization...');
      }
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


