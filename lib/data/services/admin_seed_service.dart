// lib/data/services/admin_seed_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
// Import admin credentials from config file (gitignored)
// If file doesn't exist, will use default credentials
import '../config/admin_credentials.dart' as admin_config;

/// Service to seed admin accounts in Firebase
class AdminSeedService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AdminSeedService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  /// Admin credentials list
  /// ⚠️ Credentials are imported from admin_credentials.dart (gitignored)
  /// ⚠️ File location: lib/data/config/admin_credentials.dart
  /// ⚠️ Make sure file exists - copy from admin_credentials.dart.example if needed
  static List<Map<String, String>> get adminCredentials {
    return admin_config.adminCredentials;
  }

  /// Seed admin accounts in Firebase Auth and Firestore
  /// Returns list of created admin user IDs
  Future<List<String>> seedAdminAccounts() async {
    if (kDebugMode) {
      print('🌱 Starting admin accounts seeding...');
      print('📋 Total admin accounts to create: ${adminCredentials.length}');
    }

    final createdUserIds = <String>[];

    for (int i = 0; i < adminCredentials.length; i++) {
      final cred = adminCredentials[i];
      final email = cred['email']!;
      final password = cred['password']!;
      final name = cred['name']!;

      try {
        if (kDebugMode) {
          print('\n📝 Processing admin ${i + 1}/${adminCredentials.length}: $email');
        }

        // Check if user already exists in Firebase Auth
        UserCredential? userCredential;
        
        // First, try to create user (if doesn't exist)
        try {
          if (kDebugMode) {
            print('   🔨 Creating new user in Firebase Auth...');
            print('   📧 Email: $email');
            print('   🔑 Password length: ${password.length} characters');
          }
          
          // Validate email format first
          if (!email.contains('@') || !email.contains('.')) {
            throw FirebaseAuthException(
              code: 'invalid-email',
              message: 'Invalid email format: $email',
            );
          }
          
          // Validate password length (Firebase requires min 6 chars)
          if (password.length < 6) {
            throw FirebaseAuthException(
              code: 'weak-password',
              message: 'Password must be at least 6 characters',
            );
          }
          
          userCredential = await _auth.createUserWithEmailAndPassword(
            email: email.trim(),
            password: password,
          );
          if (kDebugMode) {
            print('   ✅ User created in Firebase Auth');
          }
        } catch (e) {
          // User already exists - try to sign in
          if (e is FirebaseAuthException && e.code == 'email-already-in-use') {
            if (kDebugMode) {
              print('   ℹ️ User already exists. Trying to sign in...');
            }
            
            // Try to sign in with credentials
            try {
              userCredential = await _auth.signInWithEmailAndPassword(
                email: email.trim(),
                password: password,
              );
              if (kDebugMode) {
                print('   ✅ Signed in successfully with existing user');
              }
            } catch (signInError) {
              if (signInError is FirebaseAuthException) {
                if (signInError.code == 'wrong-password' || 
                    signInError.code == 'invalid-credential' ||
                    signInError.code == 'user-not-found') {
                  if (kDebugMode) {
                    print('   ⚠️ Error: ${signInError.code}');
                    print('   ⚠️ User exists but password is incorrect or user not properly configured.');
                    print('   ⚠️ Cannot update password automatically.');
                    print('   ⚠️ Solutions:');
                    print('      1. Manually reset password from Firebase Console');
                    print('      2. Delete user from Firebase Console and run seed again');
                    print('      3. Or use Firebase Admin SDK to update password');
                  }
                  continue;
                } else {
                  if (kDebugMode) {
                    print('   ❌ Sign-in error: ${signInError.code} - ${signInError.message}');
                  }
                  rethrow;
                }
              } else {
                rethrow;
              }
            }
          } else if (e is FirebaseAuthException) {
            // Handle other Firebase Auth exceptions
            if (e.code == 'weak-password') {
              if (kDebugMode) {
                print('   ❌ Password is too weak. Minimum 6 characters required.');
                print('   ❌ Current password length: ${password.length}');
              }
              continue;
            } else if (e.code == 'invalid-email') {
              if (kDebugMode) {
                print('   ❌ Invalid email format: $email');
              }
              continue;
            } else if (e.code == 'invalid-credential') {
              if (kDebugMode) {
                print('   ❌ Invalid credential during creation (unusual).');
                print('   ❌ This might be a Firebase Auth configuration issue.');
                print('   ❌ Check Firebase Console → Authentication → Settings');
              }
              continue;
            } else {
              // Some other Firebase Auth error
              if (kDebugMode) {
                print('   ❌ Firebase Auth error: ${e.code}');
                print('   ❌ Message: ${e.message}');
                print('   ❌ StackTrace: ${e.stackTrace}');
              }
              continue; // Skip this user and continue with next
            }
          } else {
            // Non-Firebase exception
            if (kDebugMode) {
              print('   ❌ Unexpected error: ${e.toString()}');
            }
            continue; // Skip this user and continue with next
          }
        }

        final user = userCredential.user;
        if (user == null) {
          if (kDebugMode) {
            print('   ❌ Failed to get user after creation/login');
          }
          continue;
        }

        // Create/Update user document in Firestore
        final userDocRef = _firestore.collection('users').doc(user.uid);
        final userDoc = await userDocRef.get();

        final userModel = UserModel(
          userId: user.uid,
          name: name,
          email: email,
          role: UserRole.admin,
          status: UserStatus.active,
        );

        if (userDoc.exists) {
          // Update existing document
          if (kDebugMode) {
            print('   🔄 Updating existing user document in Firestore...');
          }
          await userDocRef.update(userModel.toMap());
          if (kDebugMode) {
            print('   ✅ User document updated in Firestore');
          }
        } else {
          // Create new document
          if (kDebugMode) {
            print('   📄 Creating new user document in Firestore...');
          }
          await userDocRef.set(userModel.toMap());
          if (kDebugMode) {
            print('   ✅ User document created in Firestore');
          }
        }

        createdUserIds.add(user.uid);

        if (kDebugMode) {
          print('   ✅ Admin account setup complete: $email (UID: ${user.uid})');
        }
      } catch (e, stackTrace) {
        if (kDebugMode) {
          print('   ❌ Error creating admin account $email: $e');
          print('   StackTrace: $stackTrace');
        }
        // Continue with next admin account
      }
    }

    // Sign out after seeding (important!)
    if (_auth.currentUser != null) {
      await _auth.signOut();
      if (kDebugMode) {
        print('\n🔒 Signed out after seeding');
      }
    }

    if (kDebugMode) {
      print('\n✅ Admin seeding completed!');
      print('📊 Successfully created/updated: ${createdUserIds.length}/${adminCredentials.length} admin accounts');
      if (createdUserIds.length < adminCredentials.length) {
        print('⚠️ Some accounts failed to create. Check logs above for details.');
      }
    }

    return createdUserIds;
  }

  /// Verify admin accounts exist
  /// Returns map of email -> exists (bool)
  Future<Map<String, bool>> verifyAdminAccounts() async {
    if (kDebugMode) {
      print('🔍 Verifying admin accounts...');
    }

    final verificationResults = <String, bool>{};

    for (final cred in adminCredentials) {
      final email = cred['email']!;
      try {
        // Check Firestore for admin role
        final usersSnapshot = await _firestore
            .collection('users')
            .where('email', isEqualTo: email)
            .where('role', isEqualTo: 'admin')
            .limit(1)
            .get();

        final exists = usersSnapshot.docs.isNotEmpty;
        verificationResults[email] = exists;

        if (kDebugMode) {
          if (exists) {
            print('   ✅ $email - Admin account exists');
          } else {
            print('   ❌ $email - Admin account NOT found');
          }
        }
      } catch (e) {
        verificationResults[email] = false;
        if (kDebugMode) {
          print('   ❌ $email - Error checking: $e');
        }
      }
    }

    if (kDebugMode) {
      final existingCount = verificationResults.values.where((v) => v).length;
      print('\n📊 Verification Summary: $existingCount/${adminCredentials.length} admin accounts exist');
    }

    return verificationResults;
  }

  /// Delete all admin accounts (USE WITH CAUTION!)
  /// ⚠️ This will permanently delete admin accounts from Firebase Auth and Firestore
  Future<void> deleteAllAdminAccounts() async {
    if (kDebugMode) {
      print('⚠️ WARNING: Deleting all admin accounts...');
    }

    for (final cred in adminCredentials) {
      final email = cred['email']!;
      try {
        // Find user in Firestore
        final usersSnapshot = await _firestore
            .collection('users')
            .where('email', isEqualTo: email)
            .where('role', isEqualTo: 'admin')
            .limit(1)
            .get();

        if (usersSnapshot.docs.isNotEmpty) {
          final userDoc = usersSnapshot.docs.first;
          final userId = userDoc.id;

          // Delete from Firestore
          await userDoc.reference.delete();
          if (kDebugMode) {
            print('   ✅ Deleted $email from Firestore');
          }

          // Note: Cannot delete from Firebase Auth without admin SDK
          // User will need to delete manually from Firebase Console
          if (kDebugMode) {
            print('   ⚠️ Firebase Auth user still exists. Delete manually from Firebase Console: $email');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('   ❌ Error deleting $email: $e');
        }
      }
    }

    if (kDebugMode) {
      print('✅ Admin accounts deletion completed');
    }
  }
}
