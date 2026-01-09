import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'package:tutor_finder/views/parent/tutor_detail_screen.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_text.dart';
import '../../core/widgets/search_bar_widget.dart';
import '../../core/widgets/tutor_card.dart' show TutorCard, DistanceBadge;
import '../../core/widgets/recommended_tutor_card.dart';
import '../../core/widgets/subject_button.dart';
import '../../core/widgets/bottom_nav_bar.dart';

import '../../parent_viewmodels/auth_vm.dart';
import '../../parent_viewmodels/parent_dashboard_vm.dart';
import 'parent_profile_screen.dart';
import 'tutor_search_screen.dart';

class ParentDashboardHome extends StatefulWidget {
  const ParentDashboardHome({super.key});

  @override
  State<ParentDashboardHome> createState() => _ParentDashboardHomeState();
}

class _ParentDashboardHomeState extends State<ParentDashboardHome> {
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
        final vm = ParentDashboardViewModel();
        // Initialize dashboard data after first frame
        WidgetsBinding.instance.addPostFrameCallback((_) {
          vm.initialize();
        });
        return vm;
      },
      child: _DashboardContent(
        searchController: _searchController,
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  final TextEditingController searchController;

  const _DashboardContent({
    required this.searchController,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: SafeArea(
        child: Consumer<ParentDashboardViewModel>(
          builder: (context, vm, _) {
              return RefreshIndicator(
                onRefresh: () => vm.initialize(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      // Top Header Section
                      _buildHeader(context, vm),
                      const SizedBox(height: 24),
                      // Search and Filter Section
                      GestureDetector(
                        onTap: () {
                          // Navigate to Tutor Search Screen when search bar is tapped
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const TutorSearchScreen(),
                            ),
                          );
                        },
                        child: AbsorbPointer(
                          absorbing: true, // Make it non-interactive to TextField
                          child: SearchBarWidget(
                            controller: searchController,
                            hintText: 'Search for subjects, tutors...',
                            onFilterTap: () {
                              // Navigate to Tutor Search Screen
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const TutorSearchScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Nearby Tutors Section
                      _DashboardContent._buildNearbyTutorsSection(vm),
                      const SizedBox(height: 32),
                      // Explore by Subject Section
                      _DashboardContent._buildExploreBySubjectSection(),
                      const SizedBox(height: 32),
                      // Recommended for You Section
                      _DashboardContent._buildRecommendedSection(vm),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        // Bottom navigation removed - handled by ParentMainScreen

    );
  }

  // ---------- Header with Profile & Greeting ----------
  Widget _buildHeader(BuildContext context, ParentDashboardViewModel vm) {
    return Row(
      children: [
        // Profile Picture (Clickable)
        InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ParentProfileScreen(),
              ),
            );
          },
          borderRadius: BorderRadius.circular(28),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.lightBackground,
              border: Border.all(color: AppColors.border, width: 2),
              image: vm.userImageUrl.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(vm.userImageUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: vm.userImageUrl.isEmpty
                ? const Icon(
                    Icons.person,
                    size: 32,
                    color: AppColors.iconGrey,
                  )
                : null,
          ),
        ),
        const SizedBox(width: 16),
        // Greeting
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                '${vm.getGreeting()}, ${vm.userName.isNotEmpty ? vm.userName : "User"}!',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
        // Notification Bell & Logout
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.notifications_outlined,
                    color: AppColors.textDark,
                    size: 28,
                  ),
                  onPressed: () {
                    // TODO: Navigate to notifications
                  },
                ),
            if (vm.notificationCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: AppText(
                      vm.notificationCount > 9 ? '9+' : '${vm.notificationCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ),
              ),
            ),
            // Logout Button
            Builder(
              builder: (builderContext) => PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert,
                  color: AppColors.textDark,
                  size: 28,
                ),
                onSelected: (value) async {
                  if (value == 'logout') {
                    final authVm = Provider.of<AuthViewModel>(builderContext, listen: false);
                    final confirmed = await Get.dialog<bool>(
                      AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: const AppText(
                          'Logout',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                        content: const AppText(
                          'Are you sure you want to logout?',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textGrey,
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Get.back(result: false),
                            child: const AppText(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.textGrey,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Get.back(result: true),
                            child: const AppText(
                              'Logout',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      barrierDismissible: false,
                    );

                    if (confirmed == true && builderContext.mounted) {
                      await authVm.logout();
                      // AuthWrapper automatically redirects to login
                    }
                  }
                },
                itemBuilder: (menuContext) => [
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, color: AppColors.error),
                        SizedBox(width: 8),
                        AppText(
                          'Logout',
                          style: TextStyle(color: AppColors.error),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    )
  ]);
  }

  // ---------- Nearby Tutors Section ----------
  static Widget _buildNearbyTutorsSection(ParentDashboardViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          'Nearby Tutors',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: vm.nearbyTutors.isEmpty
              ? const Center(
                  child: AppText(
                    'No nearby tutors found',
                    style: TextStyle(color: AppColors.textGrey),
                  ),
                )
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: vm.nearbyTutors.length,
                  itemBuilder: (context, index) {
                    final tutor = vm.nearbyTutors[index];
                    return Column(
                      children: [
                        TutorCard(
                          name: tutor.name,
                          subject: tutor.subject,
                          distance: tutor.distance,
                          imageUrl: tutor.imageUrl,
                          onTap: () {
                            Get.to(() => TutorDetailScreen(tutorId: tutor.tutorId));
                          },
                        ),
                        DistanceBadge(distance: tutor.distance),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ---------- Explore by Subject Section ----------
  static Widget _buildExploreBySubjectSection() {
    final subjects = [
      {'name': 'Math', 'icon': Icons.calculate},
      {'name': 'Science', 'icon': Icons.science},
      {'name': 'History', 'icon': Icons.menu_book},
      {'name': 'English', 'icon': Icons.language},
      {'name': 'Physics', 'icon': Icons.bolt},
      {'name': 'Chemistry', 'icon': Icons.eco},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          'Explore by Subject',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: subjects.length,
            itemBuilder: (context, index) {
              final subject = subjects[index];
              return SubjectButton(
                subject: subject['name'] as String,
                icon: subject['icon'] as IconData,
                isSelected: index == 0, // First one selected by default
                onTap: () {
                  // TODO: Filter tutors by subject
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // ---------- Recommended Section ----------
  static Widget _buildRecommendedSection(ParentDashboardViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          'Recommended for You',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 16),
        vm.recommendedTutors.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: AppText(
                    'No recommendations yet',
                    style: TextStyle(color: AppColors.textGrey),
                  ),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: vm.recommendedTutors.length,
                itemBuilder: (context, index) {
                  final tutor = vm.recommendedTutors[index];
                  return RecommendedTutorCard(
                    name: tutor.name,
                    rating: tutor.rating,
                    reviewCount: tutor.reviewCount,
                    specialization: tutor.specialization,
                    imageUrl: tutor.imageUrl,
                    isSaved: tutor.isSaved,
                    onTap: () {
                      Get.to(() => TutorDetailScreen(tutorId: tutor.tutorId));
                    },
                    onSaveTap: () {
                      vm.toggleSaveTutor(tutor.tutorId);
                    },
                  );
                },
              ),
      ],
    );
  }
}

