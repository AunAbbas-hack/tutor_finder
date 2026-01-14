// lib/data/services/report_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/report_model.dart';

class ReportService {
  final FirebaseFirestore _firestore;

  ReportService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _reportsCol =>
      _firestore.collection('reports');

  // ---------- CREATE ----------

  /// Create a new report
  Future<String> createReport({
    required String createdByUser,
    required ReportType type,
    required String description,
    String? againstUser,
    String? bookingId,
    List<String>? imageUrls,
  }) async {
    try {
      final reportId = _reportsCol.doc().id;
      final now = DateTime.now();

      final report = ReportModel(
        reportId: reportId,
        createdByUser: createdByUser,
        againstUser: againstUser,
        bookingId: bookingId,
        type: type,
        description: description,
        status: ReportStatus.pending,
        createdAt: now,
        updatedAt: now,
        imageUrls: imageUrls,
      );

      await _reportsCol.doc(reportId).set(report.toMap());

      if (kDebugMode) {
        print('✅ Report created: $reportId');
      }

      return reportId;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error creating report: $e');
      }
      rethrow;
    }
  }

  // ---------- READ ----------

  /// Get report by ID
  Future<ReportModel?> getReportById(String reportId) async {
    try {
      final doc = await _reportsCol.doc(reportId).get();
      if (!doc.exists) return null;
      return ReportModel.fromFirestore(doc);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching report: $e');
      }
      return null;
    }
  }

  /// Get all reports created by a user
  Future<List<ReportModel>> getReportsByUserId(String userId) async {
    try {
      final snapshot = await _reportsCol
          .where('createdByUser', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ReportModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching reports by user: $e');
      }
      return [];
    }
  }

  /// Get all reports (for admin)
  Future<List<ReportModel>> getAllReports() async {
    try {
      final snapshot = await _reportsCol
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ReportModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching all reports: $e');
      }
      return [];
    }
  }

  /// Get reports by status (for admin)
  Future<List<ReportModel>> getReportsByStatus(ReportStatus status) async {
    try {
      final snapshot = await _reportsCol
          .where('status', isEqualTo: ReportModel.statusToString(status))
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ReportModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching reports by status: $e');
      }
      return [];
    }
  }

  /// Get reports by type
  Future<List<ReportModel>> getReportsByType(ReportType type) async {
    try {
      final snapshot = await _reportsCol
          .where('type', isEqualTo: ReportModel.typeToString(type))
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ReportModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching reports by type: $e');
      }
      return [];
    }
  }

  /// Get reports against a specific user
  Future<List<ReportModel>> getReportsAgainstUser(String userId) async {
    try {
      final snapshot = await _reportsCol
          .where('againstUser', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ReportModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching reports against user: $e');
      }
      return [];
    }
  }

  /// Get reports for a specific booking
  Future<List<ReportModel>> getReportsByBookingId(String bookingId) async {
    try {
      final snapshot = await _reportsCol
          .where('bookingId', isEqualTo: bookingId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ReportModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching reports by booking: $e');
      }
      return [];
    }
  }

  /// Get pending reports count (for admin dashboard)
  Future<int> getPendingReportsCount() async {
    try {
      final snapshot = await _reportsCol
          .where('status', isEqualTo: ReportModel.statusToString(ReportStatus.pending))
          .get();

      return snapshot.docs.length;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting pending reports count: $e');
      }
      return 0;
    }
  }

  // ---------- UPDATE ----------

  /// Update report status
  Future<void> updateReportStatus({
    required String reportId,
    required ReportStatus status,
    String? handledBy,
    String? adminNotes,
  }) async {
    try {
      final updates = <String, dynamic>{
        'status': ReportModel.statusToString(status),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      if (handledBy != null) {
        updates['handledBy'] = handledBy;
      }

      if (adminNotes != null) {
        updates['adminNotes'] = adminNotes;
      }

      await _reportsCol.doc(reportId).update(updates);

      if (kDebugMode) {
        print('✅ Report status updated: $reportId -> ${ReportModel.statusToString(status)}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating report status: $e');
      }
      rethrow;
    }
  }

  /// Add admin notes to report
  Future<void> addAdminNotes({
    required String reportId,
    required String adminNotes,
    String? handledBy,
  }) async {
    try {
      final updates = <String, dynamic>{
        'adminNotes': adminNotes,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      if (handledBy != null) {
        updates['handledBy'] = handledBy;
      }

      await _reportsCol.doc(reportId).update(updates);

      if (kDebugMode) {
        print('✅ Admin notes added to report: $reportId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error adding admin notes: $e');
      }
      rethrow;
    }
  }

  /// Assign report to admin
  Future<void> assignReportToAdmin({
    required String reportId,
    required String adminId,
  }) async {
    try {
      await _reportsCol.doc(reportId).update({
        'adminId': adminId,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      if (kDebugMode) {
        print('✅ Report assigned to admin: $reportId -> $adminId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error assigning report to admin: $e');
      }
      rethrow;
    }
  }

  // ---------- DELETE ----------

  /// Delete a report (soft delete - set status to rejected)
  Future<void> deleteReport(String reportId) async {
    try {
      await updateReportStatus(
        reportId: reportId,
        status: ReportStatus.rejected,
      );

      if (kDebugMode) {
        print('✅ Report deleted (rejected): $reportId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error deleting report: $e');
      }
      rethrow;
    }
  }

  /// Permanently delete a report (admin only)
  Future<void> permanentlyDeleteReport(String reportId) async {
    try {
      await _reportsCol.doc(reportId).delete();

      if (kDebugMode) {
        print('✅ Report permanently deleted: $reportId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error permanently deleting report: $e');
      }
      rethrow;
    }
  }

  // ---------- STREAMS (Real-time) ----------

  /// Stream of all reports (for admin - real-time updates)
  Stream<List<ReportModel>> getAllReportsStream() {
    return _reportsCol
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReportModel.fromFirestore(doc))
            .toList());
  }

  /// Stream of reports by status (for admin)
  Stream<List<ReportModel>> getReportsByStatusStream(ReportStatus status) {
    return _reportsCol
        .where('status', isEqualTo: ReportModel.statusToString(status))
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReportModel.fromFirestore(doc))
            .toList());
  }

  /// Stream of reports by user (real-time updates)
  Stream<List<ReportModel>> getReportsByUserIdStream(String userId) {
    return _reportsCol
        .where('createdByUser', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReportModel.fromFirestore(doc))
            .toList());
  }
}
