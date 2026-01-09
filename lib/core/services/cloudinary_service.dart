// lib/data/services/cloudinary_service.dart
import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CloudinaryService {
  CloudinaryPublic? _cloudinary;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isInitialized = false;

  /// Initialize Cloudinary (lazy initialization)
  void _ensureInitialized() {
    if (_isInitialized && _cloudinary != null) {
      return;
    }

    try {
      // Check if dotenv is loaded
      if (!dotenv.isInitialized) {
        throw Exception('DotEnv is not initialized. Make sure dotenv.load() is called in main()');
      }

      // Initialize Cloudinary with credentials from .env file
      final cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'];
      final uploadPreset = dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? 'tutor_finder_aun';

      if (cloudName == null || cloudName.isEmpty) {
        debugPrint('⚠️ Cloudinary cloud name not found in .env file');
        throw Exception('Cloudinary credentials not configured. Please check .env file.');
      }

      // CloudinaryPublic constructor: CloudinaryPublic(cloudName, uploadPreset)
      _cloudinary = CloudinaryPublic(
        cloudName,
        uploadPreset,
      );

      _isInitialized = true;
      debugPrint('✅ Cloudinary initialized with cloud name: $cloudName, preset: $uploadPreset');
    } catch (e) {
      debugPrint('❌ Error initializing Cloudinary: $e');
      rethrow;
    }
  }

  /// Upload image file to Cloudinary
  /// Returns download URL
  Future<String?> uploadImageFile({
    required File imageFile,
    required String folderPath,
    String? fileName,
  }) async {
    try {
      // Ensure Cloudinary is initialized
      _ensureInitialized();
      
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Check file size (100MB limit for Cloudinary free tier)
      final fileSize = await imageFile.length();
      const maxFileSize = 100 * 1024 * 1024; // 100MB
      if (fileSize > maxFileSize) {
        throw Exception('File size exceeds 100MB limit. Please choose a smaller file.');
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final name = fileName ?? 'image_$timestamp.jpg';
      final publicId = '$folderPath/$userId/$name';

      debugPrint('CloudinaryService: Uploading image to $publicId');

      final response = await _cloudinary!.uploadFile(
        CloudinaryFile.fromFile(
          imageFile.path,
          resourceType: CloudinaryResourceType.Image,
          folder: folderPath,
        ),
      );

      final downloadUrl = response.secureUrl;
      debugPrint('CloudinaryService: Image uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('CloudinaryService: Error uploading image: $e');
      return null;
    }
  }

  /// Upload file (PDF, DOC, etc.) to Cloudinary
  /// Returns download URL
  Future<String?> uploadFile({
    required File file,
    required String folderPath,
    required String fileName,
  }) async {
    try {
      // Ensure Cloudinary is initialized
      _ensureInitialized();
      
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Check file size (100MB limit for Cloudinary free tier)
      final fileSize = await file.length();
      const maxFileSize = 100 * 1024 * 1024; // 100MB
      if (fileSize > maxFileSize) {
        throw Exception('File size exceeds 100MB limit. Please choose a smaller file.');
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final publicId = '$folderPath/$userId/${timestamp}_$fileName';

      debugPrint('CloudinaryService: Uploading file to $publicId');

      // Determine resource type based on file extension
      final extension = fileName.split('.').last.toLowerCase();
      CloudinaryResourceType resourceType;
      
      if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'svg'].contains(extension)) {
        resourceType = CloudinaryResourceType.Image;
      } else if (['mp4', 'mov', 'avi', 'webm'].contains(extension)) {
        resourceType = CloudinaryResourceType.Video;
      } else {
        resourceType = CloudinaryResourceType.Raw; // For PDF, DOC, etc.
      }

      final response = await _cloudinary!.uploadFile(
        CloudinaryFile.fromFile(
          file.path,
          resourceType: resourceType,
          folder: folderPath,
        ),
      );

      final downloadUrl = response.secureUrl;
      debugPrint('CloudinaryService: File uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('CloudinaryService: Error uploading file: $e');
      return null;
    }
  }

  /// Upload file from file path (for compatibility with existing code)
  Future<String?> uploadFileFromPath({
    required String filePath,
    required String folderPath,
    required String fileName,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      debugPrint('CloudinaryService: File does not exist at path: $filePath');
      return null;
    }
    return uploadFile(
      file: file,
      folderPath: folderPath,
      fileName: fileName,
    );
  }

  /// Delete file from Cloudinary
  /// Note: cloudinary_public package doesn't support delete directly
  /// For deletion, you would need to use Cloudinary Admin API
  /// This is a placeholder - implement if needed via backend
  Future<bool> deleteFile(String fileUrl) async {
    try {
      debugPrint('CloudinaryService: Delete not supported by cloudinary_public package');
      debugPrint('CloudinaryService: Use Cloudinary Admin API for file deletion');
      // TODO: Implement deletion via Cloudinary Admin API if needed
      return false;
    } catch (e) {
      debugPrint('CloudinaryService: Error deleting file: $e');
      return false;
    }
  }

  /// Generate thumbnail URL from original Cloudinary URL
  /// Useful for bandwidth optimization
  String getThumbnailUrl(String originalUrl, {int width = 300, int height = 300}) {
    try {
      // Cloudinary transformation: w_300,h_300,c_fill
      // Insert transformation before filename
      final uri = Uri.parse(originalUrl);
      final pathSegments = uri.pathSegments;
      
      final uploadIndex = pathSegments.indexOf('upload');
      if (uploadIndex == -1) {
        return originalUrl; // Return original if can't parse
      }

      // Insert transformation: w_{width},h_{height},c_fill
      final transformation = 'w_$width,h_$height,c_fill';
      pathSegments.insert(uploadIndex + 1, transformation);

      return uri.replace(pathSegments: pathSegments).toString();
    } catch (e) {
      debugPrint('CloudinaryService: Error generating thumbnail URL: $e');
      return originalUrl; // Return original URL on error
    }
  }
}
