// lib/core/services/file_picker_service.dart
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

class FilePickerService {
  /// Pick a single file
  Future<PlatformFile?> pickFile({
    List<String>? allowedExtensions,
    String? type,
  }) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: type == null
            ? FileType.any
            : type == 'pdf'
                ? FileType.custom
                : FileType.any,
        allowedExtensions: allowedExtensions,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        return result.files.single;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Pick PDF file
  Future<PlatformFile?> pickPDF() async {
    return pickFile(
      allowedExtensions: ['pdf'],
      type: 'pdf',
    );
  }

  /// Pick document files (PDF, DOC, DOCX, etc.)
  Future<PlatformFile?> pickDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'xls', 'xlsx', 'ppt', 'pptx'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        return result.files.single;
      }
      return null;
    } catch (e) {
      debugPrint('Error picking document: $e');
      return null;
    }
  }

  /// Pick multiple files
  Future<List<PlatformFile>> pickMultipleFiles({
    List<String>? allowedExtensions,
  }) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: allowedExtensions != null
            ? FileType.custom
            : FileType.any,
        allowedExtensions: allowedExtensions,
        allowMultiple: true,
      );

      if (result != null) {
        return result.files.where((file) => file.path != null).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Get file size in readable format
  String getFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}
