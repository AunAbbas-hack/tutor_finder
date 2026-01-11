// lib/views/admin/admin_main_screen.dart
import 'package:flutter/material.dart';
import '../../core/widgets/app_text.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/admin_bottom_nav_bar.dart';
import 'admin_dashboard_screen.dart';
import 'user_management.dart';
import 'finance_screen.dart';
// import 'settings_screen.dart';

/// Main admin screen with bottom navigation
class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _currentNavIndex = 0;
  final List<int> _tabHistory = []; // Tab navigation history

  // List of screens for each tab
  List<Widget> get _screens => [
    const AdminDashboardScreen(), // Home tab
    const UserManagementScreen(), // Users tab
    const FinanceScreen(), // Finance tab
    _buildComingSoonScreen('Settings'), // Settings tab (placeholder)
  ];

  // Handle tab navigation with history
  void _handleTabChange(int newIndex) {
    if (_currentNavIndex != newIndex) {
      setState(() {
        // Add previous tab to history (if not already last)
        if (_tabHistory.isEmpty || _tabHistory.last != _currentNavIndex) {
          _tabHistory.add(_currentNavIndex);
        }
        _currentNavIndex = newIndex;
      });
    }
  }

  // Handle back button press
  Future<bool> _handleWillPop() async {
    // If history is not empty, navigate to previous tab
    if (_tabHistory.isNotEmpty) {
      setState(() {
        _currentNavIndex = _tabHistory.removeLast();
      });
      return false; // Don't pop the route
    }

    // If history is empty (on Dashboard), show exit dialog
    final shouldExit = await _showExitDialog();
    return shouldExit;
  }

  // Show exit confirmation dialog
  Future<bool> _showExitDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const AppText(
                'Exit App',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              content: const AppText(
                'Are you sure you want to exit the app?',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textGrey,
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const AppText(
                    'No',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textGrey,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const AppText(
                    'Yes',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _handleWillPop,
      child: Scaffold(
        body: _screens[_currentNavIndex],
        bottomNavigationBar: AdminBottomNavBar(
          currentIndex: _currentNavIndex,
          onTap: _handleTabChange,
        ),
      ),
    );
  }

  // Placeholder screen for coming soon features
  Widget _buildComingSoonScreen(String featureName) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.construction_outlined,
                  size: 64,
                  color: AppColors.iconGrey,
                ),
                const SizedBox(height: 24),
                AppText(
                  '$featureName\nComing Soon',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                AppText(
                  'This feature will be available soon.',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textGrey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
