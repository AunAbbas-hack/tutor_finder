import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/widgets/tutor_bottom_nav_bar.dart';
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
            
            return TutorBottomNavBar(
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

