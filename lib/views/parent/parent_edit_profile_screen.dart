// lib/views/parent/parent_edit_profile_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_text.dart';
import '../../core/widgets/app_textfield.dart';
import '../../parent_viewmodels/parent_edit_profile_vm.dart';
import '../../core/services/image_picker_service.dart';

class ParentEditProfileScreen extends StatefulWidget {
  const ParentEditProfileScreen({super.key});

  @override
  State<ParentEditProfileScreen> createState() => _ParentEditProfileScreenState();
}

class _ParentEditProfileScreenState extends State<ParentEditProfileScreen> {
  late TextEditingController _fullNameController;
  late TextEditingController _locationController;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController();
    _locationController = TextEditingController();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final vm = ParentEditProfileViewModel();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          vm.initialize().then((_) {
            // Set initial values in controllers
            _fullNameController.text = vm.fullName;
            _locationController.text = vm.location;
          });
        });
        return vm;
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildAppBar(context),
        body: Consumer<ParentEditProfileViewModel>(
          builder: (context, vm, _) {
            if (vm.isLoading && vm.fullName.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              );
            }

            // Update controllers when data loads
            if (vm.fullName.isNotEmpty && _fullNameController.text != vm.fullName) {
              _fullNameController.text = vm.fullName;
            }
            if (vm.location.isNotEmpty && _locationController.text != vm.location) {
              _locationController.text = vm.location;
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  // Profile Picture
                  _buildProfilePicture(context, vm),
                  const SizedBox(height: 32),
                  // Full Name Field
                  _buildFullNameField(context, vm),
                  const SizedBox(height: 24),
                  // Email Address Field (Read-only)
                  _buildEmailField(context, vm),
                  const SizedBox(height: 24),
                  // Location Field
                  _buildLocationField(context, vm),
                  const SizedBox(height: 32),
                  // Error Message
                  if (vm.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: AppText(
                        vm.errorMessage!,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 14,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ---------- App Bar ----------
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back,
          color: AppColors.textDark,
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: const AppText(
        'Edit Profile',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.textDark,
        ),
      ),
      centerTitle: true,
      actions: [
        Consumer<ParentEditProfileViewModel>(
          builder: (context, vm, _) {
            return TextButton(
              onPressed: vm.isLoading || !vm.hasChanges
                  ? null
                  : () async {
                      final success = await vm.saveProfile();
                      if (success && context.mounted) {
                        Get.snackbar(
                          'Success',
                          'Profile updated successfully',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: AppColors.success,
                          colorText: Colors.white,
                          borderRadius: 12,
                          margin: const EdgeInsets.all(16),
                          duration: const Duration(seconds: 2),
                          icon: const Icon(Icons.check_circle, color: Colors.white),
                        );
                        Navigator.of(context).pop(true); // Return true to indicate success
                      } else if (vm.errorMessage != null) {
                        Get.snackbar(
                          'Error',
                          vm.errorMessage!,
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: AppColors.error,
                          colorText: Colors.white,
                          borderRadius: 12,
                          margin: const EdgeInsets.all(16),
                          duration: const Duration(seconds: 3),
                          icon: const Icon(Icons.error, color: Colors.white),
                        );
                      }
                    },
              child: AppText(
                'Save',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: vm.isLoading || !vm.hasChanges
                      ? AppColors.textGrey
                      : AppColors.primary,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ---------- Profile Picture ----------
  Widget _buildProfilePicture(BuildContext context, ParentEditProfileViewModel vm) {
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
                width: 3,
              ),
              image: _getProfileImage(vm) != null
                  ? DecorationImage(
                      image: _getProfileImage(vm)!,
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: _getProfileImage(vm) == null
                ? const Icon(
                    Icons.person,
                    size: 60,
                    color: AppColors.iconGrey,
                  )
                : null,
          ),
          // Camera Icon Overlay
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: () => _showImagePickerOptions(context, vm),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.background,
                    width: 3,
                  ),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  ImageProvider? _getProfileImage(ParentEditProfileViewModel vm) {
    if (vm.selectedImageFile != null) {
      return FileImage(vm.selectedImageFile!);
    } else if (vm.imageUrl != null && vm.imageUrl!.isNotEmpty) {
      return NetworkImage(vm.imageUrl!);
    }
    return null;
  }

  // ---------- Full Name Field ----------
  Widget _buildFullNameField(BuildContext context, ParentEditProfileViewModel vm) {
    return AppTextField(
      label: 'Full Name',
      hintText: 'Enter your full name',
      controller: _fullNameController,
      onChanged: (value) => vm.updateFullName(value),
      textInputAction: TextInputAction.next,
      suffixIcon: const Icon(
        Icons.edit,
        color: AppColors.iconGrey,
        size: 20,
      ),
    );
  }

  // ---------- Email Field (Read-only) ----------
  Widget _buildEmailField(BuildContext context, ParentEditProfileViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppText(
          'Email Address',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.lightBackground,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Expanded(
                child: AppText(
                  vm.email,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              const Icon(
                Icons.email_outlined,
                color: AppColors.iconGrey,
                size: 20,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------- Location Field ----------
  Widget _buildLocationField(BuildContext context, ParentEditProfileViewModel vm) {
    return AppTextField(
      label: 'Location',
      hintText: 'Enter your location',
      controller: _locationController,
      onChanged: (value) => vm.updateLocation(value),
      textInputAction: TextInputAction.done,
      suffixIcon: const Icon(
        Icons.location_on,
        color: AppColors.iconGrey,
        size: 20,
      ),
    );
  }

  // ---------- Image Picker Options ----------
  void _showImagePickerOptions(BuildContext context, ParentEditProfileViewModel vm) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.primary),
              title: const AppText(
                'Choose from Gallery',
                style: TextStyle(fontSize: 16),
              ),
              onTap: () {
                Navigator.pop(context);
                vm.pickImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: const AppText(
                'Take Photo',
                style: TextStyle(fontSize: 16),
              ),
              onTap: () async {
                Navigator.pop(context);
                // Pick from camera
                final imagePicker = ImagePickerService();
                final imageFile = await imagePicker.pickImageFromCamera();
                if (imageFile != null && context.mounted) {
                  vm.updateSelectedImage(imageFile);
                }
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.cancel, color: AppColors.error),
              title: const AppText(
                'Cancel',
                style: TextStyle(fontSize: 16, color: AppColors.error),
              ),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

