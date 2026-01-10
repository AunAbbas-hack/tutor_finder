// lib/data/models/tutor_model.dart

/// Education entry model
class EducationEntry {
  final String degree;
  final String institution;
  final String period; // e.g., "2015 - 2019"

  EducationEntry({
    required this.degree,
    required this.institution,
    required this.period,
  });

  Map<String, dynamic> toMap() {
    return {
      'degree': degree,
      'institution': institution,
      'period': period,
    };
  }

  factory EducationEntry.fromMap(Map<String, dynamic> map) {
    return EducationEntry(
      degree: map['degree'] as String? ?? '',
      institution: map['institution'] as String? ?? '',
      period: map['period'] as String? ?? '',
    );
  }
}

/// Certification entry model
class CertificationEntry {
  final String title;
  final String issuer;
  final String year;

  CertificationEntry({
    required this.title,
    required this.issuer,
    required this.year,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'issuer': issuer,
      'year': year,
    };
  }

  factory CertificationEntry.fromMap(Map<String, dynamic> map) {
    return CertificationEntry(
      title: map['title'] as String? ?? '',
      issuer: map['issuer'] as String? ?? '',
      year: map['year'] as String? ?? '',
    );
  }
}

/// Portfolio document model
class PortfolioDocument {
  final String fileName;
  final String fileUrl; // Firebase Storage URL
  final String fileSize; // e.g., "128 KB", "2.4 MB"
  final String fileType; // e.g., "pdf", "doc"

  PortfolioDocument({
    required this.fileName,
    required this.fileUrl,
    required this.fileSize,
    required this.fileType,
  });

  Map<String, dynamic> toMap() {
    return {
      'fileName': fileName,
      'fileUrl': fileUrl,
      'fileSize': fileSize,
      'fileType': fileType,
    };
  }

  factory PortfolioDocument.fromMap(Map<String, dynamic> map) {
    return PortfolioDocument(
      fileName: map['fileName'] as String? ?? '',
      fileUrl: map['fileUrl'] as String? ?? '',
      fileSize: map['fileSize'] as String? ?? '',
      fileType: map['fileType'] as String? ?? 'pdf',
    );
  }
}

class TutorModel {
  final String tutorId; // FK -> UserModel.userId
  final List<String> subjects; // one or multiple subjects
  final String? qualification;
  final int? experience; // in years
  final String? bio;
  final List<EducationEntry> education; // Education history
  final List<CertificationEntry> certifications; // Certifications
  final List<PortfolioDocument> portfolioDocuments; // Portfolio files
  final double? hourlyFee; // Hourly tuition fee
  final double? monthlyFee; // Monthly tuition fee
  final String? cnicFrontUrl; // CNIC front side image URL
  final String? cnicBackUrl; // CNIC back side image URL

  const TutorModel({
    required this.tutorId,
    this.subjects = const [],
    this.qualification,
    this.experience,
    this.bio,
    this.education = const [],
    this.certifications = const [],
    this.portfolioDocuments = const [],
    this.hourlyFee,
    this.monthlyFee,
    this.cnicFrontUrl,
    this.cnicBackUrl,
  });

  TutorModel copyWith({
    String? tutorId,
    List<String>? subjects,
    String? qualification,
    int? experience,
    String? bio,
    List<EducationEntry>? education,
    List<CertificationEntry>? certifications,
    List<PortfolioDocument>? portfolioDocuments,
    double? hourlyFee,
    double? monthlyFee,
    String? cnicFrontUrl,
    String? cnicBackUrl,
  }) {
    return TutorModel(
      tutorId: tutorId ?? this.tutorId,
      subjects: subjects ?? this.subjects,
      qualification: qualification ?? this.qualification,
      experience: experience ?? this.experience,
      bio: bio ?? this.bio,
      education: education ?? this.education,
      certifications: certifications ?? this.certifications,
      portfolioDocuments: portfolioDocuments ?? this.portfolioDocuments,
      hourlyFee: hourlyFee ?? this.hourlyFee,
      monthlyFee: monthlyFee ?? this.monthlyFee,
      cnicFrontUrl: cnicFrontUrl ?? this.cnicFrontUrl,
      cnicBackUrl: cnicBackUrl ?? this.cnicBackUrl,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tutorId': tutorId,
      'subjects': subjects,
      'qualification': qualification,
      'experience': experience,
      'bio': bio,
      'education': education.map((e) => e.toMap()).toList(),
      'certifications': certifications.map((c) => c.toMap()).toList(),
      'portfolioDocuments': portfolioDocuments.map((p) => p.toMap()).toList(),
      'hourlyFee': hourlyFee,
      'monthlyFee': monthlyFee,
      'cnicFrontUrl': cnicFrontUrl,
      'cnicBackUrl': cnicBackUrl,
    };
  }

  factory TutorModel.fromMap(Map<String, dynamic> map) {
    return TutorModel(
      tutorId: map['tutorId'] as String,
      subjects: (map['subjects'] as List?)?.cast<String>() ?? <String>[],
      qualification: map['qualification'] as String?,
      experience: (map['experience'] as num?)?.toInt(),
      bio: map['bio'] as String?,
      education: (map['education'] as List?)
              ?.map((e) => EducationEntry.fromMap(e as Map<String, dynamic>))
              .toList() ??
          <EducationEntry>[],
      certifications: (map['certifications'] as List?)
              ?.map((c) =>
                  CertificationEntry.fromMap(c as Map<String, dynamic>))
              .toList() ??
          <CertificationEntry>[],
      portfolioDocuments: (map['portfolioDocuments'] as List?)
              ?.map((p) =>
                  PortfolioDocument.fromMap(p as Map<String, dynamic>))
              .toList() ??
          <PortfolioDocument>[],
      hourlyFee: (map['hourlyFee'] as num?)?.toDouble(),
      monthlyFee: (map['monthlyFee'] as num?)?.toDouble(),
      cnicFrontUrl: map['cnicFrontUrl'] as String?,
      cnicBackUrl: map['cnicBackUrl'] as String?,
    );
  }
}
