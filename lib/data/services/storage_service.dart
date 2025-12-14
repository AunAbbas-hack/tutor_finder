// lib/data/services/storage_service.dart
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Upload image file to Firebase Storage
  Future<String?> uploadImage(File imageFile, String chatId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        debugPrint('StorageService: User not authenticated');
        throw Exception('User not authenticated');
      }

      // Check if file exists
      if (!await imageFile.exists()) {
        debugPrint('StorageService: Image file does not exist');
        throw Exception('Image file does not exist');
      }

      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(imageFile.path)}';
      final storagePath = 'chat_images/$chatId/$fileName';

      debugPrint('StorageService: Uploading image to $storagePath');
      final ref = _storage.ref().child(storagePath);
      final uploadTask = ref.putFile(imageFile);

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      debugPrint('StorageService: Image uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('StorageService: Error uploading image: $e');
      // Check if it's a storage permission/configuration error
      if (e.toString().contains('permission') || 
          e.toString().contains('unauthorized') ||
          e.toString().contains('storage')) {
        throw Exception('Firebase Storage is not configured. Please enable Storage in Firebase Console.');
      }
      throw Exception('Failed to upload image: ${e.toString()}');
    }
  }

  /// Upload file (PDF, DOC, etc.) to Firebase Storage
  Future<String?> uploadFile(File file, String chatId, String fileName) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        debugPrint('StorageService: User not authenticated');
        throw Exception('User not authenticated');
      }

      // Check if file exists
      if (!await file.exists()) {
        debugPrint('StorageService: File does not exist');
        throw Exception('File does not exist');
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileExtension = path.extension(fileName);
      final storageFileName = '${timestamp}_$fileName';
      final storagePath = 'chat_files/$chatId/$storageFileName';

      debugPrint('StorageService: Uploading file to $storagePath');
      final ref = _storage.ref().child(storagePath);
      final uploadTask = ref.putFile(file);

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      debugPrint('StorageService: File uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('StorageService: Error uploading file: $e');
      // Check if it's a storage permission/configuration error
      if (e.toString().contains('permission') || 
          e.toString().contains('unauthorized') ||
          e.toString().contains('storage')) {
        throw Exception('Firebase Storage is not configured. Please enable Storage in Firebase Console.');
      }
      throw Exception('Failed to upload file: ${e.toString()}');
    }
  }

  /// Delete file from Firebase Storage
  Future<bool> deleteFile(String fileUrl) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      await ref.delete();
      return true;
    } catch (e) {
      return false;
    }
  }
}

