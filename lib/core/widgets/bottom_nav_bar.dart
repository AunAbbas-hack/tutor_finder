import 'package:flutter/material.dart';
import 'package:badges/badges.dart' as badges_package;
import '../theme/app_colors.dart';

/// Reusable bottom navigation bar
class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final int? unreadMessageCount; // Total unread messages count

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.unreadMessageCount,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.iconGrey,
      selectedLabelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      items: [
        const BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today),
          label: 'Bookings',
        ),
        BottomNavigationBarItem(
          icon: _buildMessagesIcon(),
          label: 'Messages',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: 'Profile',
        ),
      ],
    );
  }

  Widget _buildMessagesIcon() {
    final icon = currentIndex == 2
        ? const Icon(Icons.chat_bubble)
        : const Icon(Icons.chat_bubble_outline);
    
    final unreadCount = unreadMessageCount ?? 0;
    
    if (unreadCount > 0) {
      return badges_package.Badge(
        badgeContent: Text(
          unreadCount > 99 ? '99+' : unreadCount.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        badgeColor: AppColors.error,
        child: icon,
      );
    }
    
    return icon;
  }
}

