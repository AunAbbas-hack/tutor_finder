// lib/data/models/tutor_model.dart

class TutorModel {
  final String tutorId; // FK -> UserModel.userId
  final List<String> subjects; // one or multiple subjects
  final String? qualification;
  final int? experience; // in years
  final String? bio;

  const TutorModel({
    required this.tutorId,
    this.subjects = const [],
    this.qualification,
    this.experience,
    this.bio,
  });

  TutorModel copyWith({
    String? tutorId,
    List<String>? subjects,
    String? qualification,
    int? experience,
    String? bio,
  }) {
    return TutorModel(
      tutorId: tutorId ?? this.tutorId,
      subjects: subjects ?? this.subjects,
      qualification: qualification ?? this.qualification,
      experience: experience ?? this.experience,
      bio: bio ?? this.bio,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tutorId': tutorId,
      'subjects': subjects,
      'qualification': qualification,
      'experience': experience,
      'bio': bio,
    };
  }

  factory TutorModel.fromMap(Map<String, dynamic> map) {
    return TutorModel(
      tutorId: map['tutorId'] as String,
      subjects: (map['subjects'] as List?)?.cast<String>() ?? <String>[],
      qualification: map['qualification'] as String?,
      experience: (map['experience'] as num?)?.toInt(),
      bio: map['bio'] as String?,
    );
  }
}
