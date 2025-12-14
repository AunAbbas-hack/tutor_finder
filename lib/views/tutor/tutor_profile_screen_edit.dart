// lib/views/tutor/tutor_profile_screen_edit.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_text.dart';
import '../../core/widgets/app_textfield.dart';
import '../../tutor_viewmodels/tutor_profile_edit_vm.dart';

class TutorProfileScreenEdit extends StatelessWidget {
  const TutorProfileScreenEdit({super.key});

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
      child: const _TutorProfileView(),
    );
  }
}

class _TutorProfileView extends StatefulWidget {
  const _TutorProfileView();

  @override
  State<_TutorProfileView> createState() => _TutorProfileScreenState();
}

class _TutorProfileScreenState extends State<_TutorProfileView> {
  late TextEditingController _fullNameController;
  late TextEditingController _headlineController;
  late TextEditingController _aboutMeController;
  late TextEditingController _educationController;
  late TextEditingController _expertiseController;
  late TextEditingController _certificationTitleController;
  late TextEditingController _certificationIssuerController;
  late TextEditingController _certificationYearController;
  late TextEditingController _portfolioFileNameController;

  late FocusNode _fullNameFocusNode;
  late FocusNode _headlineFocusNode;
  late FocusNode _aboutMeFocusNode;
  late FocusNode _educationFocusNode;
  late FocusNode _expertiseFocusNode;
  late FocusNode _certificationTitleFocusNode;
  late FocusNode _certificationIssuerFocusNode;
  late FocusNode _certificationYearFocusNode;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController();
    _headlineController = TextEditingController();
    _aboutMeController = TextEditingController();
    _educationController = TextEditingController();
    _expertiseController = TextEditingController();
    _certificationTitleController = TextEditingController();
    _certificationIssuerController = TextEditingController();
    _certificationYearController = TextEditingController();
    _portfolioFileNameController = TextEditingController();

    _fullNameFocusNode = FocusNode();
    _headlineFocusNode = FocusNode();
    _aboutMeFocusNode = FocusNode();
    _educationFocusNode = FocusNode();
    _expertiseFocusNode = FocusNode();
    _certificationTitleFocusNode = FocusNode();
    _certificationIssuerFocusNode = FocusNode();
    _certificationYearFocusNode = FocusNode();
  }

  void _updateControllersFromViewModel(TutorProfileViewModel vm) {
    if (vm.user != null && vm.tutor != null) {
      if (_fullNameController.text != vm.fullName) {
        _fullNameController.text = vm.fullName;
      }
      if (_headlineController.text != vm.professionalHeadline) {
        _headlineController.text = vm.professionalHeadline;
      }
      if (_aboutMeController.text != vm.aboutMe) {
        _aboutMeController.text = vm.aboutMe;
      }
      if (_educationController.text != vm.education) {
        _educationController.text = vm.education;
      }
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _headlineController.dispose();
    _aboutMeController.dispose();
    _educationController.dispose();
    _expertiseController.dispose();
    _certificationTitleController.dispose();
    _certificationIssuerController.dispose();
    _certificationYearController.dispose();
    _portfolioFileNameController.dispose();

    _fullNameFocusNode.dispose();
    _headlineFocusNode.dispose();
    _aboutMeFocusNode.dispose();
    _educationFocusNode.dispose();
    _expertiseFocusNode.dispose();
    _certificationTitleFocusNode.dispose();
    _certificationIssuerFocusNode.dispose();
    _certificationYearFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Get.back(),
        ),
        title: AppText(
          'Edit Profile',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<TutorProfileViewModel>(
        builder: (context, vm, child) {
          // Update controllers when data is loaded
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _updateControllersFromViewModel(vm);
          });

          if (vm.isLoading && vm.user == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (vm.errorMessage != null && vm.user == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppText(
                    vm.errorMessage!,
                    style: const TextStyle(color: AppColors.error),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => vm.initialize(),
                    child: const AppText('Retry'),
                  ),
                ],
              ),
            );
          }

          return GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus();
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Profile Picture
                  _buildProfilePicture(vm),
                  const SizedBox(height: 32),

                  // Full Name
                  AppTextField(
                    label: 'Full Name',
                    hintText: 'Enter your full name',
                    controller: _fullNameController,
                    focusNode: _fullNameFocusNode,
                    onChanged: (value) {
                      vm.updateFullName(value);
                    },
                  ),
                  const SizedBox(height: 24),

                  // Professional Headline
                  AppTextField(
                    label: 'Professional Headline',
                    hintText: 'e.g., PhD in Physics & STEM Enthusiast',
                    controller: _headlineController,
                    focusNode: _headlineFocusNode,
                    onChanged: (value) {
                      vm.updateProfessionalHeadline(value);
                    },
                  ),
                  const SizedBox(height: 24),

                  // About Me
                  _buildAboutMeField(vm),
                  const SizedBox(height: 24),

                  // Areas of Expertise
                  _buildExpertiseSection(vm),
                  const SizedBox(height: 24),

                  // Education
                  _buildEducationSection(vm),
                  const SizedBox(height: 24),

                  // Certifications
                  _buildCertificationsSection(vm),
                  const SizedBox(height: 24),

                  // Portfolio / Documents
                  _buildPortfolioSection(vm),
                  const SizedBox(height: 32),

                  // Save Profile Button
                  _buildSaveButton(vm),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfilePicture(TutorProfileViewModel vm) {
    final imageUrl = vm.user?.imageUrl ?? '';
    return Center(
      child: Stack(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.lightBackground,
              border: Border.all(
                color: AppColors.border,
                width: 2,
              ),
              image: imageUrl.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(imageUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: imageUrl.isEmpty
                ? const Icon(
                    Icons.person,
                    size: 60,
                    color: AppColors.iconGrey,
                  )
                : null,
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary,
                border: Border.all(
                  color: AppColors.background,
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.edit,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutMeField(TutorProfileViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          'About Me',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _aboutMeController,
          focusNode: _aboutMeFocusNode,
          maxLines: 5,
          onChanged: (value) {
            vm.updateAboutMe(value);
          },
          decoration: InputDecoration(
            hintText: 'Tell us about yourself...',
            hintStyle: TextStyle(color: Colors.grey[600]),
            filled: true,
            fillColor: const Color(0xFFF5F6FA),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpertiseSection(TutorProfileViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: vm.toggleExpertise,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText(
                'Areas of Expertise',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
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
          // Existing expertise tags
          if (vm.areasOfExpertise.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: vm.areasOfExpertise.map((expertise) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.selectionBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppText(
                        expertise,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => vm.removeExpertise(expertise),
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 12),
          // Add new expertise
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _expertiseController,
                  focusNode: _expertiseFocusNode,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    hintText: 'Add expertise',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    filled: true,
                    fillColor: const Color(0xFFF5F6FA),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.border,
                    width: 1,
                  ),
                ),
                child: IconButton(
                  icon: const Icon(Icons.add, color: AppColors.primary),
                  onPressed: () {
                    if (_expertiseController.text.trim().isNotEmpty) {
                      vm.addExpertise(_expertiseController.text.trim());
                      _expertiseController.clear();
                    }
                  },
                ),
              ),
            ],
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
              AppText(
                'Education',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
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
          AppTextField(
            label: '',
            hintText: 'Enter your education details',
            controller: _educationController,
            focusNode: _educationFocusNode,
            onChanged: (value) {
              vm.updateEducation(value);
            },
          ),
        ],
      ],
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
              AppText(
                'Certifications',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
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
          if (vm.certifications.isNotEmpty)
            Column(
              children: vm.certifications.map((cert) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.lightBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText(
                              cert.title,
                              style: const TextStyle(
                                color: AppColors.textDark,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            if (cert.issuer.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              AppText(
                                '${cert.issuer}${cert.year.isNotEmpty ? ', ${cert.year}' : ''}',
                                style: const TextStyle(
                                  color: AppColors.textGrey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          size: 20,
                          color: AppColors.error,
                        ),
                        onPressed: () => vm.removeCertification(cert),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 12),
          // Certification input fields
          TextField(
            controller: _certificationTitleController,
            focusNode: _certificationTitleFocusNode,
            textInputAction: TextInputAction.next,
            onChanged: vm.updateCertificationTitle,
            decoration: InputDecoration(
              hintText: 'Add certification',
              hintStyle: TextStyle(color: Colors.grey[600]),
              filled: true,
              fillColor: const Color(0xFFF5F6FA),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _certificationIssuerController,
                  focusNode: _certificationIssuerFocusNode,
                  textInputAction: TextInputAction.next,
                  onChanged: vm.updateCertificationIssuer,
                  decoration: InputDecoration(
                    hintText: 'Issuer (optional)',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    filled: true,
                    fillColor: const Color(0xFFF5F6FA),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _certificationYearController,
                  focusNode: _certificationYearFocusNode,
                  textInputAction: TextInputAction.done,
                  onChanged: vm.updateCertificationYear,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Year (optional)',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    filled: true,
                    fillColor: const Color(0xFFF5F6FA),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.border,
                    width: 1,
                  ),
                ),
                child: IconButton(
                  icon: const Icon(Icons.add, color: AppColors.primary),
                  onPressed: () {
                    vm.addCertification();
                    _certificationTitleController.clear();
                    _certificationIssuerController.clear();
                    _certificationYearController.clear();
                    _certificationTitleFocusNode.unfocus();
                  },
                ),
              ),
            ],
          ),
        ],
      ],
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
              AppText(
                'Portfolio / Documents',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
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
          if (vm.portfolioDocuments.isNotEmpty)
            Column(
              children: vm.portfolioDocuments.map((doc) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.lightBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        doc.fileType.toLowerCase() == 'pdf'
                            ? Icons.picture_as_pdf
                            : Icons.insert_drive_file,
                        color: doc.fileType.toLowerCase() == 'pdf'
                            ? Colors.red
                            : AppColors.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText(
                              doc.fileName,
                              style: const TextStyle(
                                color: AppColors.textDark,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            AppText(
                              doc.fileSize,
                              style: const TextStyle(
                                color: AppColors.textGrey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          size: 20,
                          color: AppColors.error,
                        ),
                        onPressed: () => vm.removePortfolioDocument(doc),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 12),
          // Portfolio input field and upload button
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _portfolioFileNameController,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    hintText: 'Add document',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    filled: true,
                    fillColor: const Color(0xFFF5F6FA),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.border,
                    width: 1,
                  ),
                ),
                child: IconButton(
                  icon: const Icon(Icons.add, color: AppColors.primary),
                  onPressed: vm.isLoading
                      ? null
                      : () async {
                          // Upload file
                          final success = await vm.uploadPortfolioDocument();
                          if (success) {
                            _portfolioFileNameController.clear();
                            Get.snackbar(
                              'Success',
                              'Document uploaded successfully',
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: AppColors.success,
                              colorText: Colors.white,
                              duration: const Duration(seconds: 2),
                            );
                          } else if (vm.errorMessage != null) {
                            Get.snackbar(
                              'Error',
                              vm.errorMessage!,
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: AppColors.error,
                              colorText: Colors.white,
                              duration: const Duration(seconds: 3),
                            );
                          }
                        },
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildSaveButton(TutorProfileViewModel vm) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: vm.isLoading
            ? null
            : () async {
                FocusScope.of(context).unfocus();
                final success = await vm.saveProfile();
                if (success) {
                  Get.snackbar(
                    'Success',
                    'Profile updated successfully',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: AppColors.success,
                    colorText: Colors.white,
                    duration: const Duration(seconds: 2),
                  );
                  // Refresh profile screen before going back
                  Get.back(result: true);
                } else {
                  Get.snackbar(
                    'Error',
                    vm.errorMessage ?? 'Failed to save profile',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: AppColors.error,
                    colorText: Colors.white,
                    duration: const Duration(seconds: 3),
                  );
                }
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: vm.isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const AppText(
                'Save Profile',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
