// lib/core/utils/seed_admin.dart
/// Utility script to seed admin accounts
/// 
/// Usage:
/// 1. Run this script once to create admin accounts
/// 2. Or call from main.dart during development
/// 
/// IMPORTANT: Change credentials in AdminSeedService before running!

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../../firebase_options.dart';
import '../../data/services/admin_seed_service.dart';

/// Run admin seeding script
/// 
/// This should be called after Firebase initialization
/// Set ENABLE_ADMIN_SEEDING = true in main.dart to enable
Future<void> runAdminSeeding() async {
  if (kDebugMode) {
    print('\n' + '=' * 60);
    print('🌱 ADMIN ACCOUNTS SEEDING SCRIPT');
    print('=' * 60);
  }

  try {
    // Ensure Firebase is initialized
    if (Firebase.apps.isEmpty) {
      if (kDebugMode) {
        print('⚠️ Firebase not initialized. Initializing now...');
      }
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    // Create seed service and run
    final seedService = AdminSeedService();
    
    // First verify existing accounts
    if (kDebugMode) {
      print('\n📋 Step 1: Verifying existing admin accounts...');
    }
    await seedService.verifyAdminAccounts();

    // Seed admin accounts
    if (kDebugMode) {
      print('\n📋 Step 2: Creating/updating admin accounts...');
    }
    final createdIds = await seedService.seedAdminAccounts();

    // Verify again after seeding
    if (kDebugMode) {
      print('\n📋 Step 3: Verifying after seeding...');
    }
    await seedService.verifyAdminAccounts();

    if (kDebugMode) {
      print('\n' + '=' * 60);
      print('✅ SEEDING COMPLETED');
      print('📊 Created/Updated: ${createdIds.length} admin accounts');
      print('=' * 60);
      print('\n📝 Admin Credentials:');
      for (final cred in AdminSeedService.adminCredentials) {
        print('   Email: ${cred['email']}');
        print('   Password: ${cred['password']}');
        print('   Name: ${cred['name']}');
        print('');
      }
      print('⚠️ IMPORTANT: Change these credentials in production!');
      print('=' * 60 + '\n');
    }
  } catch (e, stackTrace) {
    if (kDebugMode) {
      print('\n❌ ERROR during admin seeding: $e');
      print('StackTrace: $stackTrace');
      print('=' * 60 + '\n');
    }
    rethrow;
  }
}
