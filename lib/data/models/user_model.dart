// lib/data/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

enum UserRole {
  parent,
  student,
  tutor,
  admin,
}

enum UserStatus {
  active,
  inactive,
  suspended,
  pending,
}

class UserModel {
  final String userId; // Firestore doc id / Auth uid
  final String name;
  final String email;
  final String? password; // ⚠️ Usually NOT stored in Firestore
  final String? phone;
  final UserRole role;
  final UserStatus status;
  final double? latitude;
  final double? longitude;
  final String? imageUrl; // Profile picture URL

  const UserModel({
    required this.userId,
    required this.name,
    required this.email,
    this.password,
    this.phone,
    required this.role,
    required this.status,
    this.latitude,
    this.longitude,
    this.imageUrl,
  });
  UserModel copyWith({
    String? userId,
    String? name,
    String? email,
    String? password,
    String? phone,
    UserRole? role,
    UserStatus? status,
    double? latitude,
    double? longitude,
    String? imageUrl,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      status: status ?? this.status,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }


  // ---------- JSON / Firestore mapping ----------

  Map<String, dynamic> toMap({bool includePassword = false}) {
    final map = <String, dynamic>{
      'userId': userId,
      'name': name,
      'email': email,
      if (includePassword) 'password': password,
      'phone': phone,
      'role': _roleToString(role),
      'status': _statusToString(status),
      'latitude': latitude,
      'longitude': longitude,
      'imageUrl': imageUrl,
    };
    
    if (kDebugMode) {
      print('📍 UserModel.toMap:');
      print('   Latitude: $latitude');
      print('   Longitude: $longitude');
      print('   Map: $map');
    }
    
    return map;
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    try {
      final roleString = map['role'] as String?;
      final statusString = map['status'] as String?;
      
      if (kDebugMode) {
        print('📋 UserModel.fromMap:');
        print('   Raw role from map: $roleString');
        print('   Raw status from map: $statusString');
      }
      
      final parsedRole = _roleFromString(roleString);
      final parsedStatus = _statusFromString(statusString);
      
      if (kDebugMode) {
        print('   Parsed role: $parsedRole');
        print('   Parsed status: $parsedStatus');
      }
      
      return UserModel(
        userId: map['userId'] as String? ?? '',
        name: map['name'] as String? ?? '',
        email: map['email'] as String? ?? '',
        password: map['password'] as String?,
        phone: map['phone'] as String?,
        role: parsedRole,
        status: parsedStatus,
        latitude: (map['latitude'] as num?)?.toDouble(),
        longitude: (map['longitude'] as num?)?.toDouble(),
        imageUrl: map['imageUrl'] as String?,
      );
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ UserModel.fromMap Error: $e');
        print('   Map data: $map');
        print('   StackTrace: $stackTrace');
      }
      rethrow;
    }
  }

  factory UserModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc,
      ) {
    final data = doc.data() ?? {};
    return UserModel.fromMap({
      ...data,
      'userId': data['userId'] ?? doc.id,
    });
  }

  // ---------- Helpers ----------

  static String _roleToString(UserRole role) {
    switch (role) {
      case UserRole.parent:
        return 'parent';
      case UserRole.student:
        return 'student';
      case UserRole.tutor:
        return 'tutor';
      case UserRole.admin:
        return 'admin';
    }
  }

  static UserRole _roleFromString(String? value) {
    switch (value) {
      case 'parent':
        return UserRole.parent;
      case 'student':
        return UserRole.student;
      case 'tutor':
        return UserRole.tutor;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.parent; // default fallback
    }
  }

  static String _statusToString(UserStatus status) {
    switch (status) {
      case UserStatus.active:
        return 'active';
      case UserStatus.inactive:
        return 'inactive';
      case UserStatus.suspended:
        return 'suspended';
      case UserStatus.pending:
        return 'pending';
    }
  }

  static UserStatus _statusFromString(String? value) {
    switch (value) {
      case 'active':
        return UserStatus.active;
      case 'inactive':
        return UserStatus.inactive;
      case 'suspended':
        return UserStatus.suspended;
      case 'pending':
        return UserStatus.pending;
      default:
        return UserStatus.pending;
    }
  }
}
