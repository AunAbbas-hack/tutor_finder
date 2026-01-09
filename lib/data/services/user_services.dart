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
}
