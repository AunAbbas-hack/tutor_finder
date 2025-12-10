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
}

