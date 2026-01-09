import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/widgets/tutor_bottom_nav_bar.dart';
import '../../core/widgets/app_text.dart';
import '../../core/theme/app_colors.dart';
import '../../parent_viewmodels/chat_vm.dart';
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
  late ChatViewModel _chatViewModel;
  final List<int> _tabHistory = []; // Tab navigation history

  @override
  void initState() {
    super.initState();
    // Create ChatViewModel at main screen level for badge access
    _chatViewModel = ChatViewModel();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _chatViewModel.initialize();
    });
  }

  @override
  void dispose() {
    _chatViewModel.dispose();
    super.dispose();
  }

  // List of screens for each tab
  final List<Widget> _screens = [
    const TutorDashboardScreen(),
    const TutorSessionScreen(),
    const ChatScreen(), // Messages screen (has its own ChatViewModel)
    const TutorProfileScreen(),
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
      child: ChangeNotifierProvider.value(
        value: _chatViewModel,
        child: Scaffold(
          body: _screens[_currentNavIndex],
          bottomNavigationBar: Consumer<ChatViewModel>(
            builder: (context, chatVm, _) {
              // Get unread count from ChatViewModel
              final unreadCount = chatVm.totalUnreadCount;
              
              return TutorBottomNavBar(
                currentIndex: _currentNavIndex,
                onTap: _handleTabChange,
                unreadMessageCount: unreadCount > 0 ? unreadCount : null,
              );
            },
          ),
        ),
      ),
    );
  }
}

