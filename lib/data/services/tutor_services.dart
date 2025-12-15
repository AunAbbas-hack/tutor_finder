import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/tutor_model.dart';

class TutorService {
  final FirebaseFirestore _firestore;

  TutorService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _tutorsCol =>
      _firestore.collection('tutors');

  Future<void> createTutor(TutorModel tutor) async {
    await _tutorsCol.doc(tutor.tutorId).set(tutor.toMap());
  }

  Future<TutorModel?> getTutorById(String tutorId) async {
    final doc = await _tutorsCol.doc(tutorId).get();
    if (!doc.exists) return null;
    return TutorModel.fromMap({
      ...doc.data()!,
      'tutorId': doc.id,
    });
  }

  Future<void> updateTutor(TutorModel tutor) async {
    final data = tutor.toMap();
    
    // For arrays, we need to explicitly set them using update() to ensure they replace existing arrays
    // First, update all non-array fields using set with merge
    final nonArrayData = Map<String, dynamic>.from(data);
    nonArrayData.remove('education');
    nonArrayData.remove('certifications');
    nonArrayData.remove('portfolioDocuments');
    
    if (nonArrayData.isNotEmpty) {
      await _tutorsCol.doc(tutor.tutorId).set(nonArrayData, SetOptions(merge: true));
    }
    
    // Then explicitly update array fields to ensure they replace existing arrays
    await _tutorsCol.doc(tutor.tutorId).update({
      'education': tutor.education.map((e) => e.toMap()).toList(),
      'certifications': tutor.certifications.map((c) => c.toMap()).toList(),
      'portfolioDocuments': tutor.portfolioDocuments.map((p) => p.toMap()).toList(),
    });
  }

  /// Get all tutors from Firestore
  Future<List<TutorModel>> getAllTutors() async {
    try {
      final snapshot = await _tutorsCol.get();
      return snapshot.docs.map((doc) {
        return TutorModel.fromMap({
          ...doc.data(),
          'tutorId': doc.id,
        });
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get tutors by subject
  Future<List<TutorModel>> getTutorsBySubject(String subject) async {
    try {
      final snapshot = await _tutorsCol
          .where('subjects', arrayContains: subject)
          .get();
      return snapshot.docs.map((doc) {
        return TutorModel.fromMap({
          ...doc.data(),
          'tutorId': doc.id,
        });
      }).toList();
    } catch (e) {
      return [];
    }
  }
}
