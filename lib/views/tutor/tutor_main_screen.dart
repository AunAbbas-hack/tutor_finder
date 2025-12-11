import 'package:flutter/material.dart';
import '../../core/widgets/tutor_bottom_nav_bar.dart';
import 'tutor_dashboard_screen.dart';
import 'tutor_session_screen.dart';
import '../chat/chat_screen.dart';
import 'tutor_profile_screen.dart';

/// Main tutor screen with bottom navigation
class TutorMainScreen extends StatefulWidget {
  const TutorMainScreen({super.key});

  @override
  State<TutorMainScreen> createState() => _TutorMainScreenState();
}

class _TutorMainScreenState extends State<TutorMainScreen> {
  int _currentNavIndex = 0;

  // List of screens for each tab
  final List<Widget> _screens = [
    const TutorDashboardScreen(),
    const TutorSessionScreen(),
    const ChatScreen(), // Messages screen (shared with parent)
    const TutorProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentNavIndex],
      bottomNavigationBar: TutorBottomNavBar(
        currentIndex: _currentNavIndex,
        onTap: (index) {
          setState(() {
            _currentNavIndex = index;
          });
        },
      ),
    );
  }
}

