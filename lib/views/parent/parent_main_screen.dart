import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/widgets/bottom_nav_bar.dart';
import '../../viewmodels/parent_dashboard_vm.dart';
import 'parent_dashboard_home.dart';
import 'bookings_screen_navbar.dart';

/// Main parent screen with bottom navigation
class ParentMainScreen extends StatefulWidget {
  const ParentMainScreen({super.key});

  @override
  State<ParentMainScreen> createState() => _ParentMainScreenState();
}

class _ParentMainScreenState extends State<ParentMainScreen> {
  int _currentNavIndex = 0;

  // List of screens for each tab
  final List<Widget> _screens = [
    const ParentDashboardHome(),
    const BookingsScreenNavbar(),
    // TODO: Add Messages screen
    const Scaffold(
      body: Center(
        child: Text('Messages - Coming Soon'),
      ),
    ),
    // TODO: Add Saved screen
    const Scaffold(
      body: Center(
        child: Text('Saved - Coming Soon'),
      ),
    ),
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

