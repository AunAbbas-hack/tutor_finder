import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/student_model.dart';

class StudentService {
  final FirebaseFirestore _firestore;

  StudentService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _studentsCol =>
      _firestore.collection('students');

  Future<void> createStudent(StudentModel student) async {
    await _studentsCol.doc(student.studentId).set(student.toMap());
  }

  Future<StudentModel?> getStudentById(String studentId) async {
    final doc = await _studentsCol.doc(studentId).get();
    if (!doc.exists) return null;
    return StudentModel.fromMap(doc.data()!);
  }

  Future<void> updateStudent(StudentModel student) async {
    await _studentsCol.doc(student.studentId).update(student.toMap());
  }

  Future<void> deleteStudent(String studentId) async {
    await _studentsCol.doc(studentId).delete();
  }

  /// Get all students for a specific parent
  Future<List<StudentModel>> getStudentsByParentId(String parentId) async {
    try {
      final snapshot = await _studentsCol
          .where('parentId', isEqualTo: parentId)
          .get();

      return snapshot.docs
          .map((doc) {
            final data = doc.data();
            return StudentModel.fromMap({
              ...data,
              'studentId': data['studentId'] ?? doc.id,
            });
          })
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Stream of students for a specific parent (real-time updates)
  Stream<List<StudentModel>> getStudentsByParentIdStream(String parentId) {
    return _studentsCol
        .where('parentId', isEqualTo: parentId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              final data = doc.data();
              return StudentModel.fromMap({
                ...data,
                'studentId': data['studentId'] ?? doc.id,
              });
            })
            .toList());
  }
}

