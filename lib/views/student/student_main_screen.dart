// lib/views/student/student_main_screen.dart
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'student_dashboard_screen.dart';

/// Main student screen
class StudentMainScreen extends StatelessWidget {
  const StudentMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: const StudentDashboardScreen(),
    );
  }
}
