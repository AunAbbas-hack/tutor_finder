// lib/views/tutor/tutor_profile_screen_edit.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_text.dart';
import '../../core/widgets/app_textfield.dart';
import '../../core/widgets/image_picker_bottom_sheet.dart';
import '../../tutor_viewmodels/tutor_profile_edit_vm.dart';
import '../../core/services/image_picker_service.dart';
import '../auth/location_selection_screen.dart';

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
  late TextEditingController _educationDegreeController;
  late TextEditingController _educationInstitutionController;
  late TextEditingController _educationPeriodController;
  late TextEditingController _expertiseController;
  late TextEditingController _languageController;
  late TextEditingController _certificationTitleController;
  late TextEditingController _certificationIssuerController;
  late TextEditingController _certificationYearController;
  late TextEditingController _hourlyFeeController;
  late TextEditingController _monthlyFeeController;
  late TextEditingController _accountTitleController;
  late TextEditingController _bankNameController;
  late TextEditingController _accountNumberController;

  late FocusNode _fullNameFocusNode;
  late FocusNode _headlineFocusNode;
  late FocusNode _aboutMeFocusNode;
  late FocusNode _educationDegreeFocusNode;
  late FocusNode _educationInstitutionFocusNode;
  late FocusNode _educationPeriodFocusNode;
  late FocusNode _expertiseFocusNode;
  late FocusNode _languageFocusNode;
  late FocusNode _certificationTitleFocusNode;
  late FocusNode _certificationIssuerFocusNode;
  late FocusNode _certificationYearFocusNode;
  late FocusNode _hourlyFeeFocusNode;
  late FocusNode _monthlyFeeFocusNode;
  late FocusNode _accountTitleFocusNode;
  late FocusNode _bankNameFocusNode;
  late FocusNode _accountNumberFocusNode;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController();
    _headlineController = TextEditingController();
    _aboutMeController = TextEditingController();
    _educationDegreeController = TextEditingController();
    _educationInstitutionController = TextEditingController();
    _educationPeriodController = TextEditingController();
    _expertiseController = TextEditingController();
    _languageController = TextEditingController();
    _certificationTitleController = TextEditingController();
    _certificationIssuerController = TextEditingController();
    _certificationYearController = TextEditingController();
    _hourlyFeeController = TextEditingController();
    _monthlyFeeController = TextEditingController();
    _accountTitleController = TextEditingController();
    _bankNameController = TextEditingController();
    _accountNumberController = TextEditingController();

    _fullNameFocusNode = FocusNode();
    _headlineFocusNode = FocusNode();
    _aboutMeFocusNode = FocusNode();
    _educationDegreeFocusNode = FocusNode();
    _educationInstitutionFocusNode = FocusNode();
    _educationPeriodFocusNode = FocusNode();
    _expertiseFocusNode = FocusNode();
    _languageFocusNode = FocusNode();
    _certificationTitleFocusNode = FocusNode();
    _certificationIssuerFocusNode = FocusNode();
    _certificationYearFocusNode = FocusNode();
    _hourlyFeeFocusNode = FocusNode();
    _monthlyFeeFocusNode = FocusNode();
    _accountTitleFocusNode = FocusNode();
    _bankNameFocusNode = FocusNode();
    _accountNumberFocusNode = FocusNode();
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
      // Update fee controllers
      final hourlyFeeText = vm.hourlyFee != null ? vm.hourlyFee!.toStringAsFixed(0) : '';
      if (_hourlyFeeController.text != hourlyFeeText) {
        _hourlyFeeController.text = hourlyFeeText;
      }
      final monthlyFeeText = vm.monthlyFee != null ? vm.monthlyFee!.toStringAsFixed(0) : '';
      if (_monthlyFeeController.text != monthlyFeeText) {
        _monthlyFeeController.text = monthlyFeeText;
      }
      // Update bank account controllers
      if (_accountTitleController.text != vm.accountTitle) {
        _accountTitleController.text = vm.accountTitle;
      }
      if (_bankNameController.text != vm.bankName) {
        _bankNameController.text = vm.bankName;
      }
      if (_accountNumberController.text != vm.accountNumber) {
        _accountNumberController.text = vm.accountNumber;
      }
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _headlineController.dispose();
    _aboutMeController.dispose();
    _educationDegreeController.dispose();
    _educationInstitutionController.dispose();
    _educationPeriodController.dispose();
    _expertiseController.dispose();
    _languageController.dispose();
    _certificationTitleController.dispose();
    _certificationIssuerController.dispose();
    _certificationYearController.dispose();
    _hourlyFeeController.dispose();
    _monthlyFeeController.dispose();
    _accountTitleController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();

    _fullNameFocusNode.dispose();
    _headlineFocusNode.dispose();
    _aboutMeFocusNode.dispose();
    _educationDegreeFocusNode.dispose();
    _educationInstitutionFocusNode.dispose();
    _educationPeriodFocusNode.dispose();
    _expertiseFocusNode.dispose();
    _languageFocusNode.dispose();
    _certificationTitleFocusNode.dispose();
    _certificationIssuerFocusNode.dispose();
    _certificationYearFocusNode.dispose();
    _hourlyFeeFocusNode.dispose();
    _monthlyFeeFocusNode.dispose();
    _accountTitleFocusNode.dispose();
    _bankNameFocusNode.dispose();
    _accountNumberFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: AppColors.lightBackground,
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

                  // Location
                  _buildLocationSection(vm, context),
                  const SizedBox(height: 24),

                  // Areas of Expertise
                  _buildExpertiseSection(vm),
                  const SizedBox(height: 24),

                  // Languages
                  _buildLanguagesSection(vm),
                  const SizedBox(height: 24),

                  // Tuition Fees
                  _buildTuitionFeesSection(vm),
                  const SizedBox(height: 24),

                  // Education
                  _buildEducationSection(vm),
                  const SizedBox(height: 24),

                  // Certifications
                  _buildCertificationsSection(vm),
                  const SizedBox(height: 24),

                  // Portfolio / Documents
                  _buildPortfolioSection(vm),
                  const SizedBox(height: 24),

                  // Identity Verification (CNIC)
                  _buildIdentityVerificationSection(vm),
                  const SizedBox(height: 24),

                  // Payout Account Details
                  _buildPayoutAccountSection(vm),
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
    final selectedImage = vm.selectedImageFile;
    
    // Determine which image to show
    ImageProvider? imageProvider;
    if (selectedImage != null) {
      imageProvider = FileImage(selectedImage);
    } else if (imageUrl.isNotEmpty) {
      imageProvider = NetworkImage(imageUrl);
    }
    
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
              image: imageProvider != null
                  ? DecorationImage(
                      image: imageProvider,
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: imageProvider == null
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
            child: GestureDetector(
              onTap: () => _showImagePickerOptions(context, vm),
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
                  Icons.camera_alt_outlined,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Image Picker Options Bottom Sheet ----------
  void _showImagePickerOptions(BuildContext context, TutorProfileViewModel vm) {
    ImagePickerBottomSheet.show(
      context: context,
      onGalleryTap: () {
        vm.pickImage();
      },
      onCameraTap: () async {
        final imagePicker = ImagePickerService();
        final imageFile = await imagePicker.pickImageFromCamera();
        if (imageFile != null && context.mounted) {
          vm.updateSelectedImage(imageFile);
        }
      },
    );
  }

  Widget _buildLocationSection(TutorProfileViewModel vm, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          'Location',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            // Navigate to location selection screen with current location
            final result = await Navigator.of(context).push<Map<String, dynamic>>(
              MaterialPageRoute(
                builder: (context) => LocationSelectionScreen(
                  showStepIndicator: false,
                  buttonLabel: 'Update Location',
                  returnLocation: true,
                  initialLatitude: vm.latitude,
                  initialLongitude: vm.longitude,
                  initialAddress: vm.selectedAddress,
                ),
              ),
            );

            // If location was selected, update the viewmodel
            if (result != null) {
              final lat = result['latitude'] as double?;
              final lng = result['longitude'] as double?;
              final address = result['address'] as String?;
              
              if (lat != null && lng != null) {
                vm.updateLocation(lat, lng, address);
              }
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.lightBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
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
                        vm.selectedAddress ?? 
                        (vm.latitude != null && vm.longitude != null
                            ? 'Location set (${vm.latitude!.toStringAsFixed(4)}, ${vm.longitude!.toStringAsFixed(4)})'
                            : 'Tap to select location'),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      if (vm.selectedAddress == null && vm.latitude != null && vm.longitude != null)
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
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppColors.iconGrey,
                ),
              ],
            ),
          ),
        ),
        if (vm.latitude != null && vm.longitude != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: AppText(
                  'Lat: ${vm.latitude!.toStringAsFixed(6)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textGrey,
                  ),
                ),
              ),
              Expanded(
                child: AppText(
                  'Lng: ${vm.longitude!.toStringAsFixed(6)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textGrey,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
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
              borderSide: BorderSide(
                color: Colors.grey,
                width: 2
              ),
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

  Widget _buildTuitionFeesSection(TutorProfileViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: vm.toggleFees,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText(
                'Tution Fees',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
              ),
              Icon(
                vm.isFeesExpanded
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                color: AppColors.iconGrey,
              ),
            ],
          ),
        ),
        if (vm.isFeesExpanded) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      'Hourly Fee',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _hourlyFeeController,
                      focusNode: _hourlyFeeFocusNode,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      textInputAction: TextInputAction.next,
                      onChanged: (value) {
                        vm.updateHourlyFee(value);
                      },
                      decoration: InputDecoration(
                        hintText: '0',
                        suffixText: "Rs.",
                        prefixStyle: const TextStyle(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w600,
                        ),
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
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      'Monthly Fee',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _monthlyFeeController,
                      focusNode: _monthlyFeeFocusNode,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      textInputAction: TextInputAction.done,
                      onChanged: (value) {
                        vm.updateMonthlyFee(value);
                      },
                      decoration: InputDecoration(
                        hintText: '0',suffixText: 'Rs.',
                        prefixStyle: const TextStyle(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w600,
                        ),
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
                ),
              ),
            ],
          ),
        ],
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

  Widget _buildLanguagesSection(TutorProfileViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: vm.toggleLanguages,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText(
                'Languages',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
              ),
              Icon(
                vm.isLanguagesExpanded
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                color: AppColors.iconGrey,
              ),
            ],
          ),
        ),
        if (vm.isLanguagesExpanded) ...[
          const SizedBox(height: 12),
          // Existing language tags
          if (vm.languages.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: vm.languages.map((language) {
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
                        language,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => vm.removeLanguage(language),
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
          // Add new language
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _languageController,
                  focusNode: _languageFocusNode,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    hintText: 'Add language (e.g., English, Urdu)',
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
                    if (_languageController.text.trim().isNotEmpty) {
                      vm.addLanguage(_languageController.text.trim());
                      _languageController.clear();
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
          // Existing education entries
          if (vm.education.isNotEmpty)
            Column(
              children: vm.education.map((education) {
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
                              education.degree,
                              style: const TextStyle(
                                color: AppColors.textDark,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            if (education.institution.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              AppText(
                                education.institution,
                                style: const TextStyle(
                                  color: AppColors.textDark,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                            if (education.period.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              AppText(
                                education.period,
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
                        onPressed: () => vm.removeEducation(education),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 12),
          // Education input fields
          AppTextField(
            label: 'Degree',
            hintText: 'e.g., BSCS, PhD',
            controller: _educationDegreeController,
            focusNode: _educationDegreeFocusNode,
            onChanged: vm.updateEducationDegree,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 8),
          AppTextField(
            label: 'Institution',
            hintText: 'e.g., MIT, Stanford University',
            controller: _educationInstitutionController,
            focusNode: _educationInstitutionFocusNode,
            onChanged: vm.updateEducationInstitution,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  label: 'Period',
                  hintText: 'e.g., 2015 - 2019',
                  controller: _educationPeriodController,
                  focusNode: _educationPeriodFocusNode,
                  onChanged: vm.updateEducationPeriod,
                  textInputAction: TextInputAction.done,
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
                    if (_educationDegreeController.text.trim().isNotEmpty &&
                        _educationInstitutionController.text.trim().isNotEmpty) {
                      vm.addEducation();
                      _educationDegreeController.clear();
                      _educationInstitutionController.clear();
                      _educationPeriodController.clear();
                      _educationDegreeFocusNode.unfocus();
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

  Widget _buildIdentityVerificationSection(TutorProfileViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: vm.toggleIdentityVerification,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText(
                'Identity Verification (CNIC)',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
              ),
              Icon(
                vm.isIdentityVerificationExpanded
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                color: AppColors.iconGrey,
              ),
            ],
          ),
        ),
        if (vm.isIdentityVerificationExpanded) ...[
          const SizedBox(height: 12),
          AppText(
            'Please upload clear photos of both sides of your original CNIC for account verification.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textGrey,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildCnicUploadArea(
                  label: 'Front of CNIC',
                  imageFile: vm.selectedCnicFrontFile,
                  imageUrl: vm.cnicFrontUrl,
                  onTap: () => _showCnicImagePickerOptions(context, vm, isFront: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCnicUploadArea(
                  label: 'Back of CNIC',
                  imageFile: vm.selectedCnicBackFile,
                  imageUrl: vm.cnicBackUrl,
                  onTap: () => _showCnicImagePickerOptions(context, vm, isFront: false),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildCnicUploadArea({
    required String label,
    File? imageFile,
    String? imageUrl,
    required VoidCallback onTap,
  }) {
    ImageProvider? imageProvider;
    if (imageFile != null) {
      imageProvider = FileImage(imageFile);
    } else if (imageUrl != null && imageUrl.isNotEmpty) {
      imageProvider = NetworkImage(imageUrl);
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: AppColors.lightBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: imageProvider != null ? AppColors.primary : AppColors.border,
            width: imageProvider != null ? 2 : 1.5,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (imageProvider != null)
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                  child: Image(
                    image: imageProvider,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
              )
            else
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      label.contains('Front') ? Icons.camera_alt_outlined : Icons.upload,
                      size: 32,
                      color: AppColors.iconGrey,
                    ),
                    const SizedBox(height: 8),
                    AppText(
                      label.contains('Front') ? 'Upload Front' : 'Upload Back',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textGrey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: imageProvider != null ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(11)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppText(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      color: imageProvider != null ? AppColors.primary : AppColors.textGrey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (imageProvider != null) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.check_circle,
                      size: 14,
                      color: AppColors.primary,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCnicImagePickerOptions(BuildContext context, TutorProfileViewModel vm, {required bool isFront}) {
    ImagePickerBottomSheet.show(
      context: context,
      onGalleryTap: () {
        if (isFront) {
          vm.pickCnicFrontImage();
        } else {
          vm.pickCnicBackImage();
        }
      },
      onCameraTap: () async {
        final imagePicker = ImagePickerService();
        final imageFile = await imagePicker.pickImageFromCamera();
        if (imageFile != null && context.mounted) {
          if (isFront) {
            vm.updateSelectedCnicFrontImage(imageFile);
          } else {
            vm.updateSelectedCnicBackImage(imageFile);
          }
        }
      },
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
          // Portfolio upload button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: vm.isLoading
                  ? null
                  : () async {
                      // Upload file
                      final success = await vm.uploadPortfolioDocument();
                      if (success) {
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
              icon: const Icon(Icons.add, color: Colors.white),
              label: const AppText(
                'Add Document',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPayoutAccountSection(TutorProfileViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: vm.togglePayoutAccount,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.account_balance,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        'Payout Account Details',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                      ),
                      const SizedBox(height: 2),
                      AppText(
                        'Receive your earnings',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textGrey,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
              Icon(
                vm.isPayoutAccountExpanded
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                color: AppColors.iconGrey,
              ),
            ],
          ),
        ),
        if (vm.isPayoutAccountExpanded) ...[
          const SizedBox(height: 16),
          AppTextField(
            label: 'ACCOUNT TITLE',
            hintText: 'Enter account holder name',
            controller: _accountTitleController,
            focusNode: _accountTitleFocusNode,
            onChanged: (value) {
              vm.updateAccountTitle(value);
            },
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: 'BANK NAME',
            hintText: 'Enter bank name',
            controller: _bankNameController,
            focusNode: _bankNameFocusNode,
            onChanged: (value) {
              vm.updateBankName(value);
            },
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: 'IBAN / ACCOUNT NUMBER',
            hintText: 'Enter IBAN or account number',
            controller: _accountNumberController,
            focusNode: _accountNumberFocusNode,
            onChanged: (value) {
              vm.updateAccountNumber(value);
            },
            textInputAction: TextInputAction.done,
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
