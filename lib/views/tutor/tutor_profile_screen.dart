// lib/views/tutor/tutor_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_text.dart';
import '../../data/models/tutor_model.dart';
import '../../tutor_viewmodels/tutor_profile_vm.dart';
import 'tutor_profile_screen_edit.dart';
import 'availability_screen.dart';

class TutorProfileScreen extends StatelessWidget {
  const TutorProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final vm = TutorProfileViewModel();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          vm.initialize();
        });
        return vm;
      },
      child: Builder(
        builder: (context) => Container(
          color: AppColors.lightBackground,
          child: Column(
            children: [
              // App Bar
              _buildAppBar(context),
              // Body Content
              Expanded(
                child: Consumer<TutorProfileViewModel>(
                  builder: (context, vm, _) {
                    if (vm.isLoading) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      );
                    }

                    if (vm.errorMessage != null) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AppText(
                              vm.errorMessage!,
                              style: const TextStyle(
                                color: AppColors.error,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => vm.refresh(),
                              child: const AppText('Retry'),
                            ),
                          ],
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () => vm.refresh(),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          // crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Profile Summary
                            _buildProfileSummary(vm),
                            const SizedBox(height: 32),

                            // About Me Section
                            _buildAboutMeSection(vm),
                            const SizedBox(height: 24),

                            // Location Section
                            if (vm.hasLocation) ...[
                              _buildLocationSection(vm),
                              const SizedBox(height: 24),
                            ],

                            // Areas of Expertise Section
                            Align(
                                alignment: Alignment.topLeft
                               , child: _buildAreasOfExpertiseSection(vm)),
                            const SizedBox(height: 24),

                            // Fee Structure Section - Always show
                            Align(
                              alignment: Alignment.topLeft,
                              child: _buildTuitionFeesSection(vm),
                            ),
                            const SizedBox(height: 24),

                            // Education Section
                            Align(
                                alignment: Alignment.topLeft,
                                child: _buildEducationSection(vm)),
                            const SizedBox(height: 24),

                            // Certifications Section
                            Align(
                                alignment: Alignment.topLeft,
                                child: _buildCertificationsSection(vm)),
                            const SizedBox(height: 24),

                            // Portfolio & Documents Section
                            Align(
                                alignment: Alignment.topLeft,
                                child: _buildPortfolioSection(vm)),
                            const SizedBox(height: 24),

                            // Availability Management Section
                            Align(
                              alignment: Alignment.topLeft,
                              child: _buildAvailabilitySection(),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        left: 16,
        right: 16,
        bottom: 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(
            color: AppColors.border,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          const Expanded(
            child: AppText(
              'My Profile',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.edit,
              color: AppColors.primary,
            ),
            onPressed: () async {
              final result = await Get.to(() => const TutorProfileScreenEdit());
              // Refresh profile if save was successful
              if (result == true) {
                final vm = Provider.of<TutorProfileViewModel>(context, listen: false);
                vm.refresh();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSummary(TutorProfileViewModel vm) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Profile Picture
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.lightBackground,
            border: Border.all(
              color: AppColors.border,
              width: 3,
            ),
            image: vm.imageUrl.isNotEmpty
                ? DecorationImage(
                    image: NetworkImage(vm.imageUrl),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: vm.imageUrl.isEmpty
              ? const Icon(
                  Icons.person,
                  size: 60,
                  color: AppColors.iconGrey,
                )
              : null,
        ),
        const SizedBox(height: 16),
        // Name
        AppText(
          vm.name.isNotEmpty ? vm.name : 'Tutor',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 4),
        // Professional Headline
        if (vm.professionalHeadline.isNotEmpty)
          AppText(
            vm.professionalHeadline,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textGrey,
            ),
          ),
      ],
    );
  }

  Widget _buildAboutMeSection(TutorProfileViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppText(
          'About Me',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: AppText(
            vm.aboutMe.isNotEmpty
                ? vm.aboutMe
                : 'No information available.',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textDark,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationSection(TutorProfileViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppText(
          'Location',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                Icons.location_on,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      vm.locationAddress ?? 
                      (vm.latitude != null && vm.longitude != null
                          ? '${vm.latitude!.toStringAsFixed(6)}, ${vm.longitude!.toStringAsFixed(6)}'
                          : 'Location not set'),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const AppText(
                      'Primary Teaching Area',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTuitionFeesSection(TutorProfileViewModel vm) {
    final hourlyFee = vm.hourlyFee;
    final monthlyFee = vm.monthlyFee;
    final savingsPercentage = vm.monthlySavingsPercentage;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.lightBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with "Fee Structure" and "per hour"
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const AppText(
                'Tution Fees',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              if (hourlyFee != null)
                const AppText(
                  'per hour',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textGrey,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Hourly and Monthly Rates in a row
          if (hourlyFee != null || monthlyFee != null) ...[
            Row(
              children: [
                // Hourly Rate
                if (hourlyFee != null && hourlyFee > 0) ...[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AppText(
                          'Hourly Rate',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        AppText(
                          '${hourlyFee.toStringAsFixed(0)}Rs. /hr',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                // Divider if both rates exist
                if (hourlyFee != null && monthlyFee != null) ...[
                  Container(
                    width: 1,
                    height: 50,
                    color: AppColors.border,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ],
                
               // Monthly Rate
               //  if (monthlyFee != null && monthlyFee > 0) ...[
               //    Expanded(
               //      child: Column(
               //        crossAxisAlignment: CrossAxisAlignment.start,
               //        children: [
               //          const AppText(
               //            'Monthly Rate',
               //            style: TextStyle(
               //              fontSize: 14,
               //              fontWeight: FontWeight.w500,
               //              color: AppColors.textDark,
               //            ),
               //          ),
               //          const SizedBox(height: 8),
               //          AppText(
               //            '₹${monthlyFee.toStringAsFixed(0)} /mo',
               //            style: const TextStyle(
               //              fontSize: 24,
               //              fontWeight: FontWeight.w700,
               //              color: AppColors.primary,
               //            ),
               //          ),
               //        ],
               //      ),
               //    ),
               //  ],
              ],
            ),
          ] else ...[
            const AppText(
              'Fee structure not available',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textGrey,
              ),
            ),
          ],
          
          // Savings Note
          // if (savingsPercentage != null && savingsPercentage > 0) ...[
          //   const SizedBox(height: 12),
          //   Container(
          //     padding: const EdgeInsets.all(12),
          //     decoration: BoxDecoration(
          //       color: AppColors.primary.withOpacity(0.1),
          //       borderRadius: BorderRadius.circular(8),
          //     ),
          //     child: Row(
          //       children: [
          //         Icon(
          //           Icons.info_outline,
          //           size: 16,
          //           color: AppColors.primary,
          //         ),
          //         const SizedBox(width: 8),
          //         Expanded(
          //           child: AppText(
          //             'Save over ${savingsPercentage.toStringAsFixed(0)}% with monthly plans. Package deals available for 10+ hours.',
          //             style: TextStyle(
          //               fontSize: 12,
          //               color: AppColors.primary,
          //               fontWeight: FontWeight.w500,
          //             ),
          //           ),
          //         ),
          //       ],
          //     ),
          //   ),
          // ]
          // else if (hourlyFee != null || monthlyFee != null) ...[
          //   const SizedBox(height: 12),
          //   const AppText(
          //     'Package deals available for 10+ hours.',
          //     style: TextStyle(
          //       fontSize: 12,
          //       color: AppColors.textGrey,
          //     ),
          //   ),
          // ],
        ],
      ),
    );
  }

  Widget _buildAreasOfExpertiseSection(TutorProfileViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: vm.toggleExpertise,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const AppText(
                'Areas of Expertise',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              Icon(
                vm.isExpertiseExpanded
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                color: AppColors.iconGrey,
              ),
            ],
          ),
        ),
        if (vm.isExpertiseExpanded) ...[
          const SizedBox(height: 12),
          if (vm.areasOfExpertise.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.lightBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: AppText(
                'No areas of expertise added.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textGrey,
                ),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: vm.areasOfExpertise.map((subject) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: AppText(
                    subject,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ],
    );
  }

  Widget _buildEducationSection(TutorProfileViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: vm.toggleEducation,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const AppText(
                'Education',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              Icon(
                vm.isEducationExpanded
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                color: AppColors.iconGrey,
              ),
            ],
          ),
        ),
        if (vm.isEducationExpanded) ...[
          const SizedBox(height: 12),
          if (vm.education.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.lightBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: AppText(
                'No education information added.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textGrey,
                ),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: vm.education.asMap().entries.map((entry) {
                  final index = entry.key;
                  final education = entry.value;
                  return Column(
                    children: [
                      _buildEducationItem(education),
                      if (index < vm.education.length - 1)
                        Divider(
                          height: 1,
                          color: AppColors.border,
                          indent: 16,
                          endIndent: 16,
                        ),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildEducationItem(EducationEntry education) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.school,
            color: AppColors.iconGrey,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  education.degree,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                AppText(
                  education.institution,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                AppText(
                  education.period,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textGrey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCertificationsSection(TutorProfileViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: vm.toggleCertifications,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const AppText(
                'Certifications',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              Icon(
                vm.isCertificationsExpanded
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                color: AppColors.iconGrey,
              ),
            ],
          ),
        ),
        if (vm.isCertificationsExpanded) ...[
          const SizedBox(height: 12),
          if (vm.certifications.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.lightBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: AppText(
                'No certifications added.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textGrey,
                ),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: vm.certifications.asMap().entries.map((entry) {
                  final index = entry.key;
                  final certification = entry.value;
                  return Column(
                    children: [
                      _buildCertificationItem(certification),
                      if (index < vm.certifications.length - 1)
                        Divider(
                          height: 1,
                          color: AppColors.border,
                          indent: 16,
                          endIndent: 16,
                        ),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildCertificationItem(CertificationEntry certification) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.success,
            ),
            child: const Icon(
              Icons.check,
              size: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  certification.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                AppText(
                  '${certification.issuer}, ${certification.year}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortfolioSection(TutorProfileViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: vm.togglePortfolio,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const AppText(
                'Portfolio & Documents',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              Icon(
                vm.isPortfolioExpanded
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                color: AppColors.iconGrey,
              ),
            ],
          ),
        ),
        if (vm.isPortfolioExpanded) ...[
          const SizedBox(height: 12),
          if (vm.portfolioDocuments.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.lightBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: AppText(
                'No portfolio documents added.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textGrey,
                ),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: vm.portfolioDocuments.asMap().entries.map((entry) {
                  final index = entry.key;
                  final document = entry.value;
                  return Column(
                    children: [
                      _buildPortfolioItem(document),
                      if (index < vm.portfolioDocuments.length - 1)
                        Divider(
                          height: 1,
                          color: AppColors.border,
                          indent: 16,
                          endIndent: 16,
                        ),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildPortfolioItem(PortfolioDocument document) {
    IconData iconData;
    Color iconColor;
    if (document.fileType.toLowerCase() == 'pdf') {
      iconData = Icons.picture_as_pdf;
      iconColor = Colors.red;
    } else {
      iconData = Icons.insert_drive_file;
      iconColor = AppColors.primary;
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            iconData,
            color: iconColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  document.fileName,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                AppText(
                  document.fileSize,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textGrey,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.download,
              color: AppColors.iconGrey,
            ),
            onPressed: () {
              // TODO: Implement download functionality
              Get.snackbar(
                'Download',
                'Downloading ${document.fileName}',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: AppColors.primary,
                colorText: Colors.white,
                borderRadius: 12,
                margin: const EdgeInsets.all(16),
                duration: const Duration(seconds: 2),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppText(
          'Availability',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () {
            Get.to(() => const AvailabilityScreen());
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.calendar_today,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        'Manage Availability',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      SizedBox(height: 4),
                      AppText(
                        'Set your weekly schedule and available time slots',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppColors.iconGrey,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

