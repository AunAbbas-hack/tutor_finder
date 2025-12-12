// lib/core/services/image_picker_service.dart
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ImagePickerService {
  final ImagePicker _picker = ImagePicker();

  /// Pick image from gallery
  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85, // Compress image to 85% quality
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Pick image from camera
  Future<File?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Show options to pick image (gallery or camera)
  Future<File?> pickImage({bool allowCamera = true}) async {
    // This will be handled by UI showing a bottom sheet
    // For now, default to gallery
    return pickImageFromGallery();
  }
}
