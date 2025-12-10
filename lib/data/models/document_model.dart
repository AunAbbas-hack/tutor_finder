// lib/data/models/document_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum DocumentStatus {
  pending,
  approved,
  rejected,
}

class DocumentModel {
  final String documentId;
  final String userId; // FK -> UserModel.userId
  final String filePath; // Storage path or URL
  final String type; // e.g. 'id_card', 'certificate'
  final DocumentStatus status;

  const DocumentModel({
    required this.documentId,
    required this.userId,
    required this.filePath,
    required this.type,
    required this.status,
  });

  DocumentModel copyWith({
    String? documentId,
    String? userId,
    String? filePath,
    String? type,
    DocumentStatus? status,
  }) {
    return DocumentModel(
      documentId: documentId ?? this.documentId,
      userId: userId ?? this.userId,
      filePath: filePath ?? this.filePath,
      type: type ?? this.type,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'documentId': documentId,
      'userId': userId,
      'filePath': filePath,
      'type': type,
      'status': _statusToString(status),
    };
  }

  factory DocumentModel.fromMap(Map<String, dynamic> map) {
    return DocumentModel(
      documentId: map['documentId'] as String,
      userId: map['userId'] as String,
      filePath: map['filePath'] as String,
      type: map['type'] as String,
      status: _statusFromString(map['status'] as String?),
    );
  }

  factory DocumentModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc,
      ) {
    final data = doc.data() ?? {};
    return DocumentModel.fromMap({
      ...data,
      'documentId': data['documentId'] ?? doc.id,
    });
  }

  static String _statusToString(DocumentStatus status) {
    switch (status) {
      case DocumentStatus.pending:
        return 'pending';
      case DocumentStatus.approved:
        return 'approved';
      case DocumentStatus.rejected:
        return 'rejected';
    }
  }

  static DocumentStatus _statusFromString(String? value) {
    switch (value) {
      case 'approved':
        return DocumentStatus.approved;
      case 'rejected':
        return DocumentStatus.rejected;
      case 'pending':
      default:
        return DocumentStatus.pending;
    }
  }
}
