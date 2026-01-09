// lib/core/services/storage_service.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'cloudinary_service.dart';

/// StorageService - Uses Cloudinary for file uploads
/// This service provides a unified interface for file uploads
/// All files are now uploaded to Cloudinary instead of Firebase Storage
class StorageService {
  final CloudinaryService _cloudinaryService = CloudinaryService();

  /// Upload image file to Cloudinary
  /// Returns download URL
  Future<String?> uploadImageFile({
    required File imageFile,
    required String folderPath,
    String? fileName,
  }) async {
    try {
      return await _cloudinaryService.uploadImageFile(
        imageFile: imageFile,
        folderPath: folderPath,
        fileName: fileName,
      );
    } catch (e) {
      debugPrint('StorageService: Error uploading image: $e');
      return null;
    }
  }

  /// Upload file to Cloudinary
  /// Returns download URL
  Future<String?> uploadFile({
    required String filePath,
    required String folderPath,
    required String fileName,
  }) async {
    try {
      return await _cloudinaryService.uploadFileFromPath(
        filePath: filePath,
        folderPath: folderPath,
        fileName: fileName,
      );
    } catch (e) {
      debugPrint('StorageService: Error uploading file: $e');
      return null;
    }
  }

  /// Delete file from Cloudinary
  Future<bool> deleteFile(String fileUrl) async {
    try {
      return await _cloudinaryService.deleteFile(fileUrl);
    } catch (e) {
      debugPrint('StorageService: Error deleting file: $e');
      return false;
    }
  }
}

