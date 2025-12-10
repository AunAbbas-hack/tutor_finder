import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore;

  UserService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _usersCol =>
      _firestore.collection('users');

  Future<void> createUser(UserModel user) async {
    await _usersCol.doc(user.userId).set(user.toMap());
  }

  Future<UserModel?> getUserById(String userId) async {
    final doc = await _usersCol.doc(userId).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }
}
