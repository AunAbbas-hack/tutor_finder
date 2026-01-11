// lib/data/models/pending_approval_model.dart
import 'package:flutter/material.dart';
import 'tutor_model.dart';
import 'user_model.dart';

/// Model for pending tutor approval in admin dashboard
class PendingApprovalModel {
  final String tutorId;
  final String name;
  final List<String> subjects;
  final String? qualification;
  final int? experience; // in years
  final String? imageUrl;
  final DateTime submittedAt;
  
  // Avatar gradient colors (for UI display)
  final Color avatarColor1;
  final Color avatarColor2;

  const PendingApprovalModel({
    required this.tutorId,
    required this.name,
    required this.subjects,
    this.qualification,
    this.experience,
    this.imageUrl,
    required this.submittedAt,
    required this.avatarColor1,
    required this.avatarColor2,
  });

  PendingApprovalModel copyWith({
    String? tutorId,
    String? name,
    List<String>? subjects,
    String? qualification,
    int? experience,
    String? imageUrl,
    DateTime? submittedAt,
    Color? avatarColor1,
    Color? avatarColor2,
  }) {
    return PendingApprovalModel(
      tutorId: tutorId ?? this.tutorId,
      name: name ?? this.name,
      subjects: subjects ?? this.subjects,
      qualification: qualification ?? this.qualification,
      experience: experience ?? this.experience,
      imageUrl: imageUrl ?? this.imageUrl,
      submittedAt: submittedAt ?? this.submittedAt,
      avatarColor1: avatarColor1 ?? this.avatarColor1,
      avatarColor2: avatarColor2 ?? this.avatarColor2,
    );
  }

  /// Create from UserModel and TutorModel
  factory PendingApprovalModel.fromTutorAndUser({
    required TutorModel tutor,
    required UserModel user,
    Color? avatarColor1,
    Color? avatarColor2,
  }) {
    // Generate avatar colors if not provided
    final colors = _generateAvatarColors(user.userId);
    
    return PendingApprovalModel(
      tutorId: tutor.tutorId,
      name: user.name,
      subjects: tutor.subjects,
      qualification: tutor.qualification,
      experience: tutor.experience,
      imageUrl: user.imageUrl,
      submittedAt: DateTime.now(), // TODO: Get actual submission date from Firestore
      avatarColor1: avatarColor1 ?? colors[0],
      avatarColor2: avatarColor2 ?? colors[1],
    );
  }

  /// Get subjects display string (e.g., "English, History")
  String get subjectsDisplay {
    if (subjects.isEmpty) return 'No subjects';
    return subjects.join(', ');
  }

  /// Get experience display string (e.g., "5 yrs exp.", "PhD Holder")
  String get experienceDisplay {
    if (qualification?.toLowerCase().contains('phd') ?? false) {
      return 'PhD Holder';
    } else if (experience != null && experience! > 0) {
      return '$experience yrs exp.';
    } else if (qualification != null && qualification!.isNotEmpty) {
      return qualification!;
    }
    return 'New tutor';
  }

  /// Generate consistent avatar colors based on user ID
  static List<Color> _generateAvatarColors(String userId) {
    // Use userId hash to generate consistent colors
    final hash = userId.hashCode;
    final colorPairs = <List<Color>>[
      [const Color(0xFFFF6B6B), const Color(0xFFFF8E8E)], // Red
      [const Color(0xFF4ECDC4), const Color(0xFF7EDED8)], // Teal
      [const Color(0xFFFFA07A), const Color(0xFFFFB89A)], // Orange
      [const Color(0xFF95E1D3), const Color(0xFFB4EDE0)], // Mint
      [const Color(0xFFF38181), const Color(0xFFF9A8A8)], // Pink
      [const Color(0xFFAA96DA), const Color(0xFFC4B5E8)], // Purple
    ];
    return colorPairs[hash.abs() % colorPairs.length];
  }
}
