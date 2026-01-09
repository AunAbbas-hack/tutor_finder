import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/user_model.dart';
import '../../data/services/user_services.dart';
import '../../views/auth/login_screen.dart';
import '../../views/parent/parent_main_screen.dart';
import '../../views/tutor/tutor_main_screen.dart';
// TODO: Import admin dashboard when created
// import '../../views/admin/admin_dashboard_home.dart';

/// AuthWrapper checks if user is logged in and navigates to appropriate screen
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  FirebaseAuth? _auth;
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    // Ensure Firebase is initialized before accessing FirebaseAuth
    if (Firebase.apps.isNotEmpty) {
      _auth = FirebaseAuth.instance;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if Firebase is initialized
    if (Firebase.apps.isEmpty || _auth == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return StreamBuilder<User?>(
      stream: _auth!.authStateChanges(),
      builder: (context, snapshot) {
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Not logged in - show login screen
        if (!snapshot.hasData || snapshot.data == null) {
          return const LoginScreen();
        }

        // Logged in - get user role and show appropriate dashboard
        final userId = snapshot.data!.uid;
        return FutureBuilder<UserModel?>(
          future: _userService.getUserById(userId),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final userModel = userSnapshot.data;
            
            // Debug logging
            if (userSnapshot.hasError) {
              debugPrint('❌ AuthWrapper: Error fetching user data');
              debugPrint('   Error: ${userSnapshot.error}');
              debugPrint('   StackTrace: ${userSnapshot.stackTrace}');
            }

            // If user data not found, show error message
            if (userModel == null) {
              // Debug: Print error for developers
              debugPrint('❌ AuthWrapper Error: User data not found for userId: $userId');
              debugPrint('   Please check Firestore "users" collection for this userId');
              debugPrint('   HasError: ${userSnapshot.hasError}');
              debugPrint('   Error: ${userSnapshot.error}');
              
              return Scaffold(
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'User Data Not Found',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Your account exists but user data is missing in database.\n\nPlease contact support or try signing up again.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'User ID: ${userId.substring(0, 8)}...',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () async {
                            await _auth!.signOut();
                            // Will automatically show login screen
                          },
                          child: const Text('Logout & Try Again'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            // Debug: Log user info
            debugPrint('✅ AuthWrapper: User data loaded successfully');
            debugPrint('   UserId: ${userModel.userId}');
            debugPrint('   Name: ${userModel.name}');
            debugPrint('   Email: ${userModel.email}');
            debugPrint('   Role: ${userModel.role}');
            debugPrint('   Status: ${userModel.status}');
            
            // Navigate based on role
            switch (userModel.role) {
              case UserRole.parent:
                debugPrint('✅ AuthWrapper: Navigating to ParentMainScreen');
                return const ParentMainScreen();
              case UserRole.tutor:
                debugPrint('✅ AuthWrapper: Navigating to TutorMainScreen');
                return const TutorMainScreen();
              case UserRole.admin:
                // TODO: Return AdminDashboardHome when created
                return Scaffold(
                  body: Center(
                    child: Text('Admin Dashboard - Coming Soon\n${userModel.name}'),
                  ),
                );
              case UserRole.student:
                // TODO: Return StudentDashboardHome when created
                return Scaffold(
                  body: Center(
                    child: Text('Student Dashboard - Coming Soon\n${userModel.name}'),
                  ),
                );
            }
          },
        );
      },
    );
  }
}

