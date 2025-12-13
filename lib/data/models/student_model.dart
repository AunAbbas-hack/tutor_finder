// lib/data/models/student_model.dart

class StudentModel {
  final String studentId; // FK -> UserModel.userId
  final String parentId; // FK -> UserModel.userId (parent's userId)
  final String? schoolCollege;
  final String? grade;
  final String? subjects; // Subjects or focus areas (e.g., "Mathematics Focus", "Science & English")

  const StudentModel({
    required this.studentId,
    required this.parentId,
    this.schoolCollege,
    this.grade,
    this.subjects,
  });

  StudentModel copyWith({
    String? studentId,
    String? parentId,
    String? schoolCollege,
    String? grade,
    String? subjects,
  }) {
    return StudentModel(
      studentId: studentId ?? this.studentId,
      parentId: parentId ?? this.parentId,
      schoolCollege: schoolCollege ?? this.schoolCollege,
      grade: grade ?? this.grade,
      subjects: subjects ?? this.subjects,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'parentId': parentId,
      'schoolCollege': schoolCollege,
      'grade': grade,
      'subjects': subjects,
    };
  }

  factory StudentModel.fromMap(Map<String, dynamic> map) {
    return StudentModel(
      studentId: map['studentId'] as String,
      parentId: map['parentId'] as String? ?? '',
      schoolCollege: map['schoolCollege'] as String?,
      grade: map['grade'] as String?,
      subjects: map['subjects'] as String?,
    );
  }
}
