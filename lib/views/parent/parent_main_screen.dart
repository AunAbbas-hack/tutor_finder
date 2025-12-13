import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tutor_finder/views/parent/parent_profile_screen.dart';
import '../../core/widgets/bottom_nav_bar.dart';
import 'parent_dashboard_home.dart';
import 'bookings_screen_navbar.dart';
import '../chat/chat_screen.dart';

/// Main parent screen with bottom navigation
class ParentMainScreen extends StatefulWidget {
  const ParentMainScreen({super.key});

  @override
  State<ParentMainScreen> createState() => _ParentMainScreenState();
}

class _ParentMainScreenState extends State<ParentMainScreen> {
  int _currentNavIndex = 0;

  // List of screens for each tab
  List<Widget> get _screens => [
    const ParentDashboardHome(),
    const BookingsScreenNavbar(),
    const ChatScreen(), // Messages screen
    const ParentProfileScreen(showBackButton: false), // Hide back button when from bottom nav
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentNavIndex],
      bottomNavigationBar: AppBottomNavBar(
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

