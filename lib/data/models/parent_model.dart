import 'package:cloud_firestore/cloud_firestore.dart';

/// Payment method model
class PaymentMethod {
  final String methodId;
  final String type; // e.g., "credit_card", "debit_card", "paypal", "bank_transfer"
  final String? cardNumber; // Last 4 digits for cards
  final String? cardHolderName;
  final String? expiryDate; // MM/YY format
  final bool isDefault;
  final String? bankName; // For bank transfers
  final String? accountNumber; // Last 4 digits for bank accounts

  PaymentMethod({
    required this.methodId,
    required this.type,
    this.cardNumber,
    this.cardHolderName,
    this.expiryDate,
    this.isDefault = false,
    this.bankName,
    this.accountNumber,
  });

  Map<String, dynamic> toMap() {
    return {
      'methodId': methodId,
      'type': type,
      'cardNumber': cardNumber,
      'cardHolderName': cardHolderName,
      'expiryDate': expiryDate,
      'isDefault': isDefault,
      'bankName': bankName,
      'accountNumber': accountNumber,
    };
  }

  factory PaymentMethod.fromMap(Map<String, dynamic> map) {
    return PaymentMethod(
      methodId: map['methodId'] as String? ?? '',
      type: map['type'] as String? ?? '',
      cardNumber: map['cardNumber'] as String?,
      cardHolderName: map['cardHolderName'] as String?,
      expiryDate: map['expiryDate'] as String?,
      isDefault: map['isDefault'] as bool? ?? false,
      bankName: map['bankName'] as String?,
      accountNumber: map['accountNumber'] as String?,
    );
  }
}

class ParentModel {
  final String parentId; // same as userId
  final String address;
  final List<String> preferredSubjects; // Preferred subjects for finding tutors
  final List<PaymentMethod> paymentMethods; // Payment methods
  final List<String> childrenIds; // List of student IDs (children)
  final String? emergencyContact; // Emergency contact number
  final String? emergencyContactName; // Emergency contact name

  const ParentModel({
    required this.parentId,
    required this.address,
    this.preferredSubjects = const [],
    this.paymentMethods = const [],
    this.childrenIds = const [],
    this.emergencyContact,
    this.emergencyContactName,
  });

  ParentModel copyWith({
    String? parentId,
    String? address,
    List<String>? preferredSubjects,
    List<PaymentMethod>? paymentMethods,
    List<String>? childrenIds,
    String? emergencyContact,
    String? emergencyContactName,
  }) {
    return ParentModel(
      parentId: parentId ?? this.parentId,
      address: address ?? this.address,
      preferredSubjects: preferredSubjects ?? this.preferredSubjects,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      childrenIds: childrenIds ?? this.childrenIds,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'parentId': parentId,
      'address': address,
      'preferredSubjects': preferredSubjects,
      'paymentMethods': paymentMethods.map((p) => p.toMap()).toList(),
      'childrenIds': childrenIds,
      'emergencyContact': emergencyContact,
      'emergencyContactName': emergencyContactName,
    };
  }

  factory ParentModel.fromMap(Map<String, dynamic> map) {
    return ParentModel(
      parentId: map['parentId'] as String? ?? '',
      address: map['address'] as String? ?? '',
      preferredSubjects:
          (map['preferredSubjects'] as List?)?.cast<String>() ?? <String>[],
      paymentMethods: (map['paymentMethods'] as List?)
              ?.map((p) => PaymentMethod.fromMap(p as Map<String, dynamic>))
              .toList() ??
          <PaymentMethod>[],
      childrenIds: (map['childrenIds'] as List?)?.cast<String>() ?? <String>[],
      emergencyContact: map['emergencyContact'] as String?,
      emergencyContactName: map['emergencyContactName'] as String?,
    );
  }

  factory ParentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ParentModel.fromMap({
      ...data,
      'parentId': data['parentId'] ?? doc.id,
    });
  }
}
