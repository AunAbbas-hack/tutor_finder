import 'package:cloud_firestore/cloud_firestore.dart';

class ParentModel {
  final String parentId; // same as userId
  final String address;

  const ParentModel({
    required this.parentId,
    required this.address,
  });

  ParentModel copyWith({
    String? parentId,
    String? address,
  }) {
    return ParentModel(
      parentId: parentId ?? this.parentId,
      address: address ?? this.address,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'parentId': parentId,
      'address': address,
    };
  }

  factory ParentModel.fromMap(Map<String, dynamic> map) {
    return ParentModel(
      parentId: map['parentId'] as String? ?? '',
      address: map['address'] as String? ?? '',
    );
  }

  factory ParentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ParentModel(
      parentId: data['parentId'] as String? ?? doc.id,
      address: data['address'] as String? ?? '',
    );
  }
}
