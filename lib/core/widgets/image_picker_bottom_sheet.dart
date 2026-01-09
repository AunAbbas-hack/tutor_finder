// lib/core/widgets/image_picker_bottom_sheet.dart
import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'app_text.dart';
import '../../core/services/image_picker_service.dart';

class ImagePickerBottomSheet extends StatelessWidget {
  final VoidCallback onGalleryTap;
  final VoidCallback onCameraTap;
  final VoidCallback? onCancel;

  const ImagePickerBottomSheet({
    super.key,
    required this.onGalleryTap,
    required this.onCameraTap,
    this.onCancel,
  });

  /// Show the image picker bottom sheet
  static void show({
    required BuildContext context,
    required VoidCallback onGalleryTap,
    required VoidCallback onCameraTap,
    VoidCallback? onCancel,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ImagePickerBottomSheet(
        onGalleryTap: onGalleryTap,
        onCameraTap: onCameraTap,
        onCancel: onCancel,
      ),
    );
  }

  /// Show the image picker bottom sheet with callbacks that handle image selection
  /// This is a convenience method that handles the image picker service internally
  static void showWithImagePicker({
    required BuildContext context,
    required Function(File?) onImageSelected,
  }) {
    final imagePicker = ImagePickerService();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ImagePickerBottomSheet(
        onGalleryTap: () {
          Navigator.pop(context);
          imagePicker.pickImageFromGallery().then((imageFile) {
            if (imageFile != null && context.mounted) {
              onImageSelected(imageFile);
            }
          });
        },
        onCameraTap: () {
          Navigator.pop(context);
          imagePicker.pickImageFromCamera().then((imageFile) {
            if (imageFile != null && context.mounted) {
              onImageSelected(imageFile);
            }
          });
        },
        onCancel: () => Navigator.pop(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: AppText(
              'SELECT PHOTO SOURCE',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
          ),
          const Divider(height: 1),
          // Take Photo Option
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.camera_alt,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            title: const AppText(
              'Take Photo',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              onCameraTap();
            },
          ),
          // Choose from Gallery Option
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.photo_library,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            title: const AppText(
              'Choose from Gallery',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              onGalleryTap();
            },
          ),
          const SizedBox(height: 8),
          // Cancel Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  onCancel?.call();
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const AppText(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
