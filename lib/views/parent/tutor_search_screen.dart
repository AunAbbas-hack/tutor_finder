import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_text.dart';
import '../../core/widgets/search_bar_widget.dart';
import '../../core/widgets/tutor_search_card.dart';
import '../../parent_viewmodels/tutor_search_vm.dart';
import '../parent/tutor_detail_screen.dart';

class TutorSearchScreen extends StatefulWidget {
  const TutorSearchScreen({super.key});

  @override
  State<TutorSearchScreen> createState() => _TutorSearchScreenState();
}

class _TutorSearchScreenState extends State<TutorSearchScreen> {
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
        final vm = TutorSearchViewModel();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          vm.initialize();
        });
        return vm;
      },
      child: Scaffold(
        backgroundColor: AppColors.lightBackground,
        body: SafeArea(
          child: Consumer<TutorSearchViewModel>(
            builder: (context, vm, _) {
              return Column(
                children: [
                  // Header with Back Button
                  _buildHeader(context),
                  
                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.lightBackground,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) => vm.updateSearchQuery(value),
                        decoration: InputDecoration(
                          hintText: 'Math Tutor',
                          hintStyle: const TextStyle(
                            color: AppColors.textGrey,
                            fontSize: 14,
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: AppColors.iconGrey,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Filters Section
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Subjects Filter
                          _buildSubjectsFilter(vm),
                          const SizedBox(height: 20),

                          // Price Range Filter
                          _buildPriceRangeFilter(vm),
                          const SizedBox(height: 20),

                          // Location Radius Filter
                          _buildLocationRadiusFilter(vm),
                          const SizedBox(height: 24),

                          // Results Header
                          _buildResultsHeader(vm),
                          const SizedBox(height: 16),

                          // Tutors List
                          vm.isLoading
                              ? const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(32.0),
                                    child: CircularProgressIndicator(
                                      color: AppColors.primary,
                                    ),
                                  ),
                                )
                              : vm.errorMessage != null
                                  ? Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(32.0),
                                        child: AppText(
                                          vm.errorMessage!,
                                          style: const TextStyle(
                                            color: AppColors.error,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    )
                                  : vm.filteredTutors.isEmpty
                                      ? Center(
                                          child: Padding(
                                            padding: const EdgeInsets.all(32.0),
                                            child: AppText(
                                              'No tutors found',
                                              style: const TextStyle(
                                                color: AppColors.textGrey,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                        )
                                      : ListView.builder(
                                          shrinkWrap: true,
                                          physics: const NeverScrollableScrollPhysics(),
                                          itemCount: vm.filteredTutors.length,
                                          itemBuilder: (context, index) {
                                            final tutor = vm.filteredTutors[index];
                                            return TutorSearchCard(
                                              name: tutor.name,
                                              profession: tutor.profession,
                                              rating: tutor.rating,
                                              distance: tutor.distance,
                                              hourlyRate: tutor.hourlyRate,
                                              imageUrl: tutor.imageUrl,
                                              isOnline: tutor.isOnline,
                                              isFavorite: tutor.isFavorite,
                                              onTap: () {
                                                Get.to(() => TutorDetailScreen(tutorId: tutor.tutorId));
                                              },
                                              onFavoriteTap: () {
                                                vm.toggleFavorite(tutor.tutorId);
                                              },
                                            );
                                          },
                                        ),
                        ],
                      ),
                    ),
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
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          // Back Button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back,
                color: AppColors.textDark,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Title
          const Expanded(
            child: AppText(
              'Find Tutors',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Subjects Filter ----------
  Widget _buildSubjectsFilter(TutorSearchViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppText(
          'Subjects',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 12),
        // Subjects List (scrollable horizontally)
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: vm.availableSubjects.length,
            itemBuilder: (context, index) {
              final subject = vm.availableSubjects[index];
              final isSelected = vm.selectedSubjects.contains(subject);
              
              return GestureDetector(
                onTap: () => vm.toggleSubject(subject),
                child: Container(
                  margin: EdgeInsets.only(right: index < vm.availableSubjects.length - 1 ? 12 : 0),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.lightBackground,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: AppText(
                      subject,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : AppColors.textDark,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ---------- Price Range Filter ----------
  Widget _buildPriceRangeFilter(TutorSearchViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.wallet,
                    size: 20,
                    color: AppColors.iconGrey,
                  ),
                  const SizedBox(width: 8),
                  const AppText(
                    'Price Range',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
              AppText(
                '\$${vm.minPrice.toStringAsFixed(0)} - \$${vm.maxPrice.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          RangeSlider(
            values: RangeValues(vm.minPrice, vm.maxPrice),
            min: 0.0,
            max: 100.0,
            divisions: 50,
            activeColor: AppColors.primary,
            inactiveColor: AppColors.lightBackground,
            labels: RangeLabels(
              '\$${vm.minPrice.toStringAsFixed(0)}',
              '\$${vm.maxPrice.toStringAsFixed(0)}',
            ),
            onChanged: (RangeValues values) {
              vm.setPriceRange(values.start, values.end);
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              AppText(
                '\$0',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textGrey,
                ),
              ),
              AppText(
                '\$100+',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textGrey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------- Location Radius Filter ----------
  Widget _buildLocationRadiusFilter(TutorSearchViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 20,
                    color: AppColors.iconGrey,
                  ),
                  const SizedBox(width: 8),
                  const AppText(
                    'Location Radius',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
              AppText(
                '${vm.locationRadius.toStringAsFixed(0)} km',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Slider(
            value: vm.locationRadius,
            min: 1.0,
            max: 10.0, // Maximum 10KM
            divisions: 9,
            activeColor: AppColors.primary,
            inactiveColor: AppColors.lightBackground,
            label: '${vm.locationRadius.toStringAsFixed(0)} km',
            onChanged: (double value) {
              vm.setLocationRadius(value);
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              AppText(
                '1 km',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textGrey,
                ),
              ),
              AppText(
                '10 km',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textGrey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------- Results Header ----------
  Widget _buildResultsHeader(TutorSearchViewModel vm) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppText(
          '${vm.tutorCount} Tutors found',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        // Sort Button
        PopupMenuButton<SortOption>(
          icon: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              AppText(
                'Sort',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              SizedBox(width: 4),
              Icon(
                Icons.swap_vert,
                size: 20,
                color: AppColors.iconGrey,
              ),
            ],
          ),
          onSelected: (SortOption option) {
            vm.setSortOption(option);
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: SortOption.distance,
              child: AppText('Sort by Distance'),
            ),
            const PopupMenuItem(
              value: SortOption.rating,
              child: AppText('Sort by Rating'),
            ),
            const PopupMenuItem(
              value: SortOption.priceLow,
              child: AppText('Sort by Price: Low to High'),
            ),
            const PopupMenuItem(
              value: SortOption.priceHigh,
              child: AppText('Sort by Price: High to Low'),
            ),
          ],
        ),
      ],
    );
  }
}
