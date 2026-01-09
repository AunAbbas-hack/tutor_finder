import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tutor_finder/views/parent/parent_profile_screen.dart';
import '../../core/widgets/bottom_nav_bar.dart';
import '../../parent_viewmodels/chat_vm.dart';
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
  late ChatViewModel _chatViewModel;

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
  List<Widget> get _screens => [
    const ParentDashboardHome(),
    const BookingsScreenNavbar(),
    const ChatScreen(), // Messages screen (has its own ChatViewModel)
    const ParentProfileScreen(showBackButton: false), // Hide back button when from bottom nav
  ];

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _chatViewModel,
      child: Scaffold(
        body: _screens[_currentNavIndex],
        bottomNavigationBar: Consumer<ChatViewModel>(
          builder: (context, chatVm, _) {
            // Get unread count from ChatViewModel
            final unreadCount = chatVm.totalUnreadCount;
            
            return AppBottomNavBar(
              currentIndex: _currentNavIndex,
              onTap: (index) {
                setState(() {
                  _currentNavIndex = index;
                });
              },
              unreadMessageCount: unreadCount > 0 ? unreadCount : null,
            );
          },
        ),
      ),
    );
  }
}

