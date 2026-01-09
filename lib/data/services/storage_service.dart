// lib/data/services/storage_service.dart
// This service is used for chat images and files
// Now uses Cloudinary instead of Firebase Storage
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../core/services/cloudinary_service.dart';

class StorageService {
  final CloudinaryService _cloudinaryService = CloudinaryService();

  /// Upload image file to Cloudinary (for chat)
  Future<String?> uploadImage(File imageFile, String chatId) async {
    try {
      // Check if file exists
      if (!await imageFile.exists()) {
        debugPrint('StorageService: Image file does not exist');
        throw Exception('Image file does not exist');
      }

      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';
      final folderPath = 'chat_images';

      debugPrint('StorageService: Uploading image to Cloudinary: $folderPath/$chatId');
      
      final downloadUrl = await _cloudinaryService.uploadImageFile(
        imageFile: imageFile,
        folderPath: '$folderPath/$chatId',
        fileName: fileName,
      );

      if (downloadUrl != null) {
        debugPrint('StorageService: Image uploaded successfully: $downloadUrl');
        return downloadUrl;
      } else {
        throw Exception('Failed to upload image to Cloudinary');
      }
    } catch (e) {
      debugPrint('StorageService: Error uploading image: $e');
      throw Exception('Failed to upload image: ${e.toString()}');
    }
  }

  /// Upload file (PDF, DOC, etc.) to Cloudinary (for chat)
  Future<String?> uploadFile(File file, String chatId, String fileName) async {
    try {
      // Check if file exists
      if (!await file.exists()) {
        debugPrint('StorageService: File does not exist');
        throw Exception('File does not exist');
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storageFileName = '${timestamp}_$fileName';
      final folderPath = 'chat_files';

      debugPrint('StorageService: Uploading file to Cloudinary: $folderPath/$chatId');
      
      final downloadUrl = await _cloudinaryService.uploadFile(
        file: file,
        folderPath: '$folderPath/$chatId',
        fileName: storageFileName,
      );

      if (downloadUrl != null) {
        debugPrint('StorageService: File uploaded successfully: $downloadUrl');
        return downloadUrl;
      } else {
        throw Exception('Failed to upload file to Cloudinary');
      }
    } catch (e) {
      debugPrint('StorageService: Error uploading file: $e');
      throw Exception('Failed to upload file: ${e.toString()}');
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

