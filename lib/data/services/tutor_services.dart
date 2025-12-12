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
    await _tutorsCol.doc(tutor.tutorId).update(tutor.toMap());
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
