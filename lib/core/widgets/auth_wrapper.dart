import 'package:firebase_auth/firebase_auth.dart';
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
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _auth.authStateChanges(),
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
        return FutureBuilder<UserModel?>(
          future: _userService.getUserById(snapshot.data!.uid),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final userModel = userSnapshot.data;

            // If user data not found, show login
            if (userModel == null) {
              return const LoginScreen();
            }

            // Navigate based on role
            switch (userModel.role) {
              case UserRole.parent:
                return const ParentMainScreen();
              case UserRole.tutor:
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

