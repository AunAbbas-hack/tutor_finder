// lib/data/models/student_model.dart

class StudentModel {
  final String studentId; // FK -> UserModel.userId
  final String? schoolCollege;
  final String? grade;

  const StudentModel({
    required this.studentId,
    this.schoolCollege,
    this.grade,
  });

  StudentModel copyWith({
    String? studentId,
    String? schoolCollege,
    String? grade,
  }) {
    return StudentModel(
      studentId: studentId ?? this.studentId,
      schoolCollege: schoolCollege ?? this.schoolCollege,
      grade: grade ?? this.grade,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'schoolCollege': schoolCollege,
      'grade': grade,
    };
  }

  factory StudentModel.fromMap(Map<String, dynamic> map) {
    return StudentModel(
      studentId: map['studentId'] as String,
      schoolCollege: map['schoolCollege'] as String?,
      grade: map['grade'] as String?,
    );
  }
}
