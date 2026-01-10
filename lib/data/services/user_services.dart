import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore;

  UserService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _usersCol =>
      _firestore.collection('users');

  Future<void> createUser(UserModel user) async {
    if (kDebugMode) {
      print('📍 UserService.createUser:');
      print('   UserId: ${user.userId}');
      print('   Latitude: ${user.latitude}');
      print('   Longitude: ${user.longitude}');
    }
    final map = user.toMap();
    if (kDebugMode) {
      print('   Map to save: $map');
      print('   Map latitude: ${map['latitude']}');
      print('   Map longitude: ${map['longitude']}');
    }
    await _usersCol.doc(user.userId).set(map);
    if (kDebugMode) {
      print('✅ User saved to Firestore successfully');
    }
  }

  Future<UserModel?> getUserById(String userId) async {
    try {
      final doc = await _usersCol.doc(userId).get();
      if (!doc.exists) {
        debugPrint('❌ UserService: Document not found for userId: $userId');
        return null;
      }
      
      final data = doc.data();
      debugPrint('✅ UserService: Document found for userId: $userId');
      debugPrint('   Data: $data');
      debugPrint('   Role in Firestore: ${data?['role']}');
      
      final userModel = UserModel.fromFirestore(doc);
      debugPrint('✅ UserService: UserModel created successfully');
      debugPrint('   Parsed Role: ${userModel.role}');
      debugPrint('   Parsed Status: ${userModel.status}');
      
      return userModel;
    } catch (e, stackTrace) {
      debugPrint('❌ UserService Error: Failed to get user by id: $userId');
      debugPrint('   Error: $e');
      debugPrint('   StackTrace: $stackTrace');
      return null;
    }
  }

  Future<void> updateUser(UserModel user) async {
    await _usersCol.doc(user.userId).update(user.toMap());
  }

  /// Get all users (for admin dashboard)
  /// Note: Fetches all users - use with caution for large datasets
  Future<List<UserModel>> getAllUsers() async {
    try {
      final snapshot = await _usersCol.get();
      return snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting all users: $e');
      }
      return [];
    }
  }

  /// Get users by role
  Future<List<UserModel>> getUsersByRole(UserRole role) async {
    try {
      // Convert role to string manually since _roleToString is private
      String roleString;
      switch (role) {
        case UserRole.parent:
          roleString = 'parent';
          break;
        case UserRole.student:
          roleString = 'student';
          break;
        case UserRole.tutor:
          roleString = 'tutor';
          break;
        case UserRole.admin:
          roleString = 'admin';
          break;
      }
      
      final snapshot = await _usersCol
          .where('role', isEqualTo: roleString)
          .get();
      return snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting users by role: $e');
      }
      return [];
    }
  }

  /// Get users by status
  Future<List<UserModel>> getUsersByStatus(UserStatus status) async {
    try {
      // Convert status to string manually since _statusToString is private
      String statusString;
      switch (status) {
        case UserStatus.active:
          statusString = 'active';
          break;
        case UserStatus.inactive:
          statusString = 'inactive';
          break;
        case UserStatus.suspended:
          statusString = 'suspended';
          break;
        case UserStatus.pending:
          statusString = 'pending';
          break;
      }
      
      final snapshot = await _usersCol
          .where('status', isEqualTo: statusString)
          .get();
      return snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting users by status: $e');
      }
      return [];
    }
  }
}
