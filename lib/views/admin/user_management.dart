// lib/views/admin/user_management.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../admin_viewmodels/user_management_vm.dart';
import '../../core/widgets/app_text.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/user_model.dart';
import '../../data/models/tutor_model.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final vm = UserManagementViewModel();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          vm.initialize();
        });
        return vm;
      },
      child: Scaffold(
        backgroundColor: AppColors.lightBackground,
        body: SafeArea(
          child: Consumer<UserManagementViewModel>(
            builder: (context, vm, _) {
              if (vm.isLoading && vm.displayUsers.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                );
              }

              if (vm.errorMessage != null && vm.displayUsers.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AppText(
                          vm.errorMessage!,
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => vm.initialize(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                          ),
                          child: const AppText(
                            'Retry',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: [
                  // Header
                  _buildHeader(context, vm),
                  const SizedBox(height: 16),
                  // Search Bar
                  _buildSearchBar(context, vm),
                  const SizedBox(height: 16),
                  // Filter Tabs
                  _buildFilterTabs(context, vm),
                  const SizedBox(height: 16),
                  // User List
                  Expanded(
                    child: _buildUserList(context, vm),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ---------- Header ----------
  Widget _buildHeader(BuildContext context, UserManagementViewModel vm) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 24 : 20,
        vertical: 12,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AppText(
            'Tutor Management',
            style: TextStyle(
              fontSize: isTablet ? 28 : 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          // Add User Icon
          InkWell(
            onTap: () {
              // TODO: Navigate to add user/tutor screen
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_add,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Search Bar ----------
  Widget _buildSearchBar(BuildContext context, UserManagementViewModel vm) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isTablet ? 24 : 20),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 16 : 12,
          vertical: isTablet ? 14 : 12,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.search,
              color: AppColors.iconGrey,
              size: isTablet ? 24 : 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by name or subject',
                  hintStyle: TextStyle(
                    fontSize: isTablet ? 15 : 14,
                    color: AppColors.textLight,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                ),
                style: TextStyle(
                  fontSize: isTablet ? 15 : 14,
                  color: AppColors.textDark,
                ),
                onChanged: (value) {
                  vm.setSearchQuery(value);
                },
              ),
            ),
            if (_searchController.text.isNotEmpty)
              InkWell(
                onTap: () {
                  setState(() {
                    _searchController.clear();
                  });
                  vm.setSearchQuery('');
                },
                child: Icon(
                  Icons.clear,
                  color: AppColors.iconGrey,
                  size: isTablet ? 20 : 18,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ---------- Filter Tabs ----------
  Widget _buildFilterTabs(BuildContext context, UserManagementViewModel vm) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isTablet ? 24 : 20),
      child: Row(
        children: [
          _buildTab(
            context,
            label: 'All',
            isSelected: vm.selectedTab == UserFilterTab.all,
            onTap: () => vm.setSelectedTab(UserFilterTab.all),
            isTablet: isTablet,
          ),
          const SizedBox(width: 8),
          _buildTab(
            context,
            label: 'Tutors',
            isSelected: vm.selectedTab == UserFilterTab.tutors,
            onTap: () => vm.setSelectedTab(UserFilterTab.tutors),
            isTablet: isTablet,
          ),
          const SizedBox(width: 8),
          _buildTab(
            context,
            label: 'Parents',
            isSelected: vm.selectedTab == UserFilterTab.parents,
            onTap: () => vm.setSelectedTab(UserFilterTab.parents),
            isTablet: isTablet,
          ),
        ],
      ),
    );
  }

  Widget _buildTab(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isTablet,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 20 : 16,
            vertical: isTablet ? 12 : 10,
          ),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.selectionBg : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.transparent,
              width: 1,
            ),
          ),
          child: Center(
            child: AppText(
              label,
              style: TextStyle(
                fontSize: isTablet ? 15 : 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textGrey,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------- User List ----------
  Widget _buildUserList(BuildContext context, UserManagementViewModel vm) {
    if (vm.displayUsers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.people_outline,
                size: 64,
                color: AppColors.iconGrey,
              ),
              const SizedBox(height: 16),
              AppText(
                vm.searchQuery.isNotEmpty
                    ? 'No users found matching your search'
                    : 'No users found',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textGrey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => vm.refresh(),
      child: ListView.builder(
        padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width > 600 ? 24 : 20,
          vertical: 8,
        ),
        itemCount: vm.displayUsers.length,
        itemBuilder: (context, index) {
          final userDisplay = vm.displayUsers[index];
          return _buildUserCard(context, userDisplay);
        },
      ),
    );
  }

  // ---------- User Card ----------
  Widget _buildUserCard(BuildContext context, UserDisplayModel userDisplay) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          // TODO: Navigate to user detail screen
        },
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            // Avatar
            Container(
              width: isTablet ? 56 : 48,
              height: isTablet ? 56 : 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.lightBackground,
                image: userDisplay.user.imageUrl != null &&
                        userDisplay.user.imageUrl!.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(userDisplay.user.imageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: userDisplay.user.imageUrl == null ||
                      userDisplay.user.imageUrl!.isEmpty
                  ? Icon(
                      Icons.person,
                      size: isTablet ? 28 : 24,
                      color: AppColors.iconGrey,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  AppText(
                    userDisplay.user.name,
                    style: TextStyle(
                      fontSize: isTablet ? 18 : 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Email
                  AppText(
                    userDisplay.user.email,
                    style: TextStyle(
                      fontSize: isTablet ? 14 : 12,
                      color: AppColors.textGrey,
                    ),
                  ),
                  if (userDisplay.subjects.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    // Subjects
                    Row(
                      children: [
                        Icon(
                          Icons.school_outlined,
                          size: isTablet ? 16 : 14,
                          color: AppColors.iconGrey,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: AppText(
                            userDisplay.subjects.join(', '),
                            style: TextStyle(
                              fontSize: isTablet ? 13 : 12,
                              color: AppColors.textGrey,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // Status Badge and Arrow
            Column(
              children: [
                // Status Badge
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 10 : 8,
                    vertical: isTablet ? 6 : 4,
                  ),
                  decoration: BoxDecoration(
                    color: userDisplay.statusBgColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: AppText(
                    userDisplay.statusDisplay,
                    style: TextStyle(
                      fontSize: isTablet ? 12 : 10,
                      fontWeight: FontWeight.w600,
                      color: userDisplay.statusColor,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Arrow Icon
                Icon(
                  Icons.arrow_forward_ios,
                  size: isTablet ? 16 : 14,
                  color: AppColors.iconGrey,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
