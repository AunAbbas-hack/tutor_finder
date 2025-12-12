// lib/data/services/storage_service.dart
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path/path.dart' as path;

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Upload image file to Firebase Storage
  Future<String?> uploadImage(File imageFile, String chatId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(imageFile.path)}';
      final storagePath = 'chat_images/$chatId/$fileName';

      final ref = _storage.ref().child(storagePath);
      final uploadTask = ref.putFile(imageFile);

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      return null;
    }
  }

  /// Upload file (PDF, DOC, etc.) to Firebase Storage
  Future<String?> uploadFile(File file, String chatId, String fileName) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileExtension = path.extension(fileName);
      final storageFileName = '${timestamp}_$fileName';
      final storagePath = 'chat_files/$chatId/$storageFileName';

      final ref = _storage.ref().child(storagePath);
      final uploadTask = ref.putFile(file);

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      return null;
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

