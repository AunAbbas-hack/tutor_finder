import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/parent_model.dart';

class ParentService {
  final FirebaseFirestore _firestore;

  ParentService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _parentsCol =>
      _firestore.collection('parents');

  Future<void> createParent(ParentModel parent) async {
    await _parentsCol.doc(parent.parentId).set(parent.toMap());
  }

  Future<ParentModel?> getParentById(String parentId) async {
    final doc = await _parentsCol.doc(parentId).get();
    if (!doc.exists) return null;
    return ParentModel.fromFirestore(doc);
  }

  Future<void> updateParent(ParentModel parent) async {
    await _parentsCol.doc(parent.parentId).update(parent.toMap());
  }

  Future<void> deleteParent(String parentId) async {
    await _parentsCol.doc(parentId).delete();
  }
}
