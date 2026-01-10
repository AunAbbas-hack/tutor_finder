// lib/data/services/storage_service_cloudinary.dart
// This service is used for chat images and files
// Now uses Cloudinary instead of Firebase Storage
import 'dart:io' show File, Directory, Platform;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as path;
import 'package:open_filex/open_filex.dart';
import '../../core/services/cloudinary_service.dart';
import 'storage_mobile_helper.dart'
    if (dart.library.html) 'storage_web_helper.dart' as web;

class StorageService {
  final CloudinaryService _cloudinaryService = CloudinaryService();

  /// Upload image file to Cloudinary (for chat)
  Future<String?> uploadImage(dynamic imageFile, String chatId) async {
    try {
      // Check if file exists (only for mobile)
      if (!kIsWeb) {
        if (!await (imageFile as File).exists()) {
          debugPrint('StorageService: Image file does not exist');
          throw Exception('Image file does not exist');
        }
      }

      final fileName = kIsWeb
          ? '${DateTime.now().millisecondsSinceEpoch}_${imageFile.name}'
          : '${DateTime.now().millisecondsSinceEpoch}_${(imageFile as File).path.split('/').last}';
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
  Future<String?> uploadFile(dynamic file, String chatId, String fileName) async {
    try {
      // Check if file exists (only for mobile)
      if (!kIsWeb) {
        if (!await (file as File).exists()) {
          debugPrint('StorageService: File does not exist');
          throw Exception('File does not exist');
        }
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

  /// Download file from URL and save to device storage
  /// Returns the saved file path, or null if download failed
  Future<String?> downloadFile({
    required String fileUrl,
    required String fileName,
  }) async {
    try {
      debugPrint('StorageService: Starting download: $fileName from $fileUrl');

      // Handle web platform differently
      if (kIsWeb) {
        // For web, trigger browser download via helper
        final response = await http.get(Uri.parse(fileUrl));
        if (response.statusCode == 200) {
          web.triggerBrowserDownload(response.bodyBytes, fileName);
          debugPrint('StorageService: File download triggered in browser: $fileName');
          // Return a placeholder path for web (file is saved by browser)
          return 'web_download:$fileName';
        } else {
          throw Exception('Failed to download file: HTTP ${response.statusCode}');
        }
      }

      // Mobile platform code
      bool isAndroid = false;
      bool isIOS = false;
      try {
        isAndroid = Platform.isAndroid;
        isIOS = Platform.isIOS;
      } catch (e) {
        debugPrint('StorageService: Platform check failed: $e');
        throw Exception('Platform detection failed. This method is only available on mobile platforms.');
      }

      // For Android 10+, we use app-specific directory which doesn't require permissions
      // For Android 6-9, we try to request permission but still use app directory as fallback
      if (isAndroid) {
        try {
          final status = await Permission.storage.status;
          if (!status.isGranted) {
            await Permission.storage.request();
            // Even if permission is denied, we can use app-specific directory (Android 10+)
            debugPrint('StorageService: Using app-specific directory for download');
          }
        } catch (e) {
          // Permission request failed, but we can still use app directory
          debugPrint('StorageService: Permission request failed, using app directory: $e');
        }
      }

      // Get download directory
      Directory? downloadDir;
      if (isAndroid) {
        // For Android 10+, use app-specific directory
        // This doesn't require permissions
        downloadDir = await getExternalStorageDirectory();
        if (downloadDir != null) {
          // Navigate to Downloads folder within app directory
          downloadDir = Directory('${downloadDir.path}/Downloads');
          if (!await downloadDir.exists()) {
            await downloadDir.create(recursive: true);
          }
        }
      } else if (isIOS) {
        // For iOS, use application documents directory
        downloadDir = await getApplicationDocumentsDirectory();
      }

      if (downloadDir == null) {
        throw Exception('Could not access download directory');
      }

      // Clean filename (remove invalid characters)
      String cleanFileName = fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
      
      // Check if file already exists and create unique filename if needed
      String finalFileName = cleanFileName;
      File file = File(path.join(downloadDir.path, finalFileName));
      
      if (await file.exists()) {
        // If file exists, add timestamp to filename
        final nameWithoutExt = path.basenameWithoutExtension(cleanFileName);
        final extension = path.extension(cleanFileName);
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        finalFileName = '${nameWithoutExt}_$timestamp$extension';
        file = File(path.join(downloadDir.path, finalFileName));
        debugPrint('StorageService: File exists, saving as: $finalFileName');
      }
      
      // Create full file path
      final filePath = path.join(downloadDir.path, finalFileName);

      // Download file
      final response = await http.get(Uri.parse(fileUrl));
      
      if (response.statusCode == 200) {
        // Save file
        await file.writeAsBytes(response.bodyBytes);
        debugPrint('StorageService: File downloaded successfully: $filePath');
        return filePath;
      } else {
        throw Exception('Failed to download file: HTTP ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('StorageService: Error downloading file: $e');
      throw Exception('Failed to download file: ${e.toString()}');
    }
  }

  /// Get file size in human readable format
  String getFileSizeString(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  /// Check if file is already downloaded
  /// Returns the file path if exists, null otherwise
  Future<String?> getDownloadedFilePath(String fileName) async {
    try {
      // On web, we can't check for downloaded files
      if (kIsWeb) {
        return null;
      }

      bool isAndroid = false;
      bool isIOS = false;
      try {
        isAndroid = Platform.isAndroid;
        isIOS = Platform.isIOS;
      } catch (e) {
        debugPrint('StorageService: Platform check failed: $e');
        return null;
      }

      Directory? downloadDir;
      if (isAndroid) {
        downloadDir = await getExternalStorageDirectory();
        if (downloadDir != null) {
          downloadDir = Directory('${downloadDir.path}/Downloads');
        }
      } else if (isIOS) {
        downloadDir = await getApplicationDocumentsDirectory();
      }

      if (downloadDir == null || !await downloadDir.exists()) {
        return null;
      }

      // Clean filename
      String cleanFileName = fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
      
      // Check for exact match first
      File file = File(path.join(downloadDir.path, cleanFileName));
      if (await file.exists()) {
        return file.path;
      }

      // Check for files with similar name (might have timestamp)
      final nameWithoutExt = path.basenameWithoutExtension(cleanFileName);
      final extension = path.extension(cleanFileName);
      final pattern = RegExp('^${RegExp.escape(nameWithoutExt)}(_\\d+)?${RegExp.escape(extension)}\$');
      
      final files = downloadDir.listSync();
      for (var fileSystemEntity in files) {
        if (fileSystemEntity is File) {
          final fileName = path.basename(fileSystemEntity.path);
          if (pattern.hasMatch(fileName)) {
            return fileSystemEntity.path;
          }
        }
      }

      return null;
    } catch (e) {
      debugPrint('StorageService: Error checking downloaded file: $e');
      return null;
    }
  }

  /// Open file using system default app
  /// Returns a tuple: (success: bool, errorMessage: String?)
  Future<Map<String, dynamic>> openFile(String filePath) async {
    try {
      // Handle web platform differently
      if (kIsWeb) {
        // On web, if filePath starts with 'web_download:', it means file was downloaded by browser
        if (filePath.startsWith('web_download:')) {
          return {
            'success': true,
            'errorMessage': null,
          };
        }
        // Try to open file URL directly in browser
        if (filePath.startsWith('http://') || filePath.startsWith('https://')) {
          if (kIsWeb) {
            final opened = web.openInBrowser(filePath);
            return {
              'success': opened,
              'errorMessage': opened ? null : 'Failed to open file in browser',
            };
          }
          return {'success': true, 'errorMessage': null};
        }
        return {
          'success': false,
          'errorMessage': 'File opening on web is not supported for local files',
        };
      }

      // Mobile platform code
      File file;
      try {
        file = File(filePath);
      } catch (e) {
        final error = 'File class not available on this platform';
        debugPrint('StorageService: $error');
        return {'success': false, 'errorMessage': error};
      }

      if (!await file.exists()) {
        final error = 'File does not exist: $filePath';
        debugPrint('StorageService: $error');
        return {'success': false, 'errorMessage': error};
      }

      final result = await OpenFilex.open(filePath);
      
      if (result.type == ResultType.done) {
        debugPrint('StorageService: File opened successfully: $filePath');
        return {'success': true, 'errorMessage': null};
      } else if (result.type == ResultType.noAppToOpen) {
        // Check file extension to provide specific app suggestion
        final extension = path.extension(filePath).toLowerCase();
        String appSuggestion = '';
        if (extension == '.pdf') {
          appSuggestion = 'Please install a PDF viewer app like Adobe Reader or Google PDF Viewer';
        } else if (['.doc', '.docx'].contains(extension)) {
          appSuggestion = 'Please install Microsoft Word or WPS Office to open this file';
        } else if (['.xls', '.xlsx'].contains(extension)) {
          appSuggestion = 'Please install Microsoft Excel or WPS Office to open this file';
        } else if (['.ppt', '.pptx'].contains(extension)) {
          appSuggestion = 'Please install Microsoft PowerPoint or WPS Office to open this file';
        } else {
          appSuggestion = 'Please install an app to open this file type';
        }
        
        final error = 'No app found to open this file. $appSuggestion';
        debugPrint('StorageService: $error');
        return {'success': false, 'errorMessage': error};
      } else if (result.type == ResultType.error) {
        // Use the actual error message from open_filex which may contain app-specific info
        final error = result.message ?? 'Failed to open file';
        debugPrint('StorageService: Error opening file: $error');
        return {'success': false, 'errorMessage': error};
      } else {
        final error = 'File open cancelled or failed';
        debugPrint('StorageService: $error: $filePath');
        return {'success': false, 'errorMessage': error};
      }
    } catch (e) {
      final error = 'Error opening file: ${e.toString()}';
      debugPrint('StorageService: $error');
      return {'success': false, 'errorMessage': error};
    }
  }

  /// Download and open file (downloads if not exists, then opens)
  /// Returns a tuple: (success: bool, errorMessage: String?)
  Future<Map<String, dynamic>> downloadAndOpenFile({
    required String fileUrl,
    required String fileName,
  }) async {
    try {
      // For web, directly open the URL in browser
      if (kIsWeb) {
        debugPrint('StorageService: Opening file in browser (web): $fileUrl');
        final opened = web.openInBrowser(fileUrl);
        return {
          'success': opened,
          'errorMessage': opened ? null : 'Failed to open file in browser',
        };
      }

      // Mobile platform: First check if file already exists
      String? filePath = await getDownloadedFilePath(fileName);
      
      if (filePath != null) {
        // File exists, open it
        debugPrint('StorageService: File already downloaded, opening: $filePath');
        return await openFile(filePath);
      } else {
        // File doesn't exist, download first
        debugPrint('StorageService: File not found, downloading: $fileName');
        filePath = await downloadFile(
          fileUrl: fileUrl,
          fileName: fileName,
        );
        
        if (filePath != null) {
          // Download successful, now open
          return await openFile(filePath);
        } else {
          return {'success': false, 'errorMessage': 'Failed to download file'};
        }
      }
    } catch (e) {
      final error = 'Error in downloadAndOpenFile: ${e.toString()}';
      debugPrint('StorageService: $error');
      return {'success': false, 'errorMessage': error};
    }
  }
}

