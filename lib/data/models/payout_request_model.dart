// lib/data/models/payout_request_model.dart
import 'package:flutter/material.dart';

enum PayoutMethod { bankTransfer, easyPaisa, jazzCash }

enum PayoutStatus { pending, approved, rejected }

/// Model to represent a tutor withdrawal / payout request
class PayoutRequestModel {
  final String id;
  final String tutorName;
  final double amount;
  final String currencySymbol;
  final PayoutMethod method;
  final String accountTitle;
  final String accountNumber;
  final String? phoneNumber;
  final DateTime requestedAt;
  final List<Color> avatarColors;
  final PayoutStatus status;

  const PayoutRequestModel({
    required this.id,
    required this.tutorName,
    required this.amount,
    this.currencySymbol = '\$',
    required this.method,
    required this.accountTitle,
    required this.accountNumber,
    this.phoneNumber,
    required this.requestedAt,
    this.avatarColors = const [Color(0xFF4FACFE), Color(0xFF00F2FE)],
    this.status = PayoutStatus.pending,
  });

  PayoutRequestModel copyWith({
    String? id,
    String? tutorName,
    double? amount,
    String? currencySymbol,
    PayoutMethod? method,
    String? accountTitle,
    String? accountNumber,
    String? phoneNumber,
    DateTime? requestedAt,
    List<Color>? avatarColors,
    PayoutStatus? status,
  }) {
    return PayoutRequestModel(
      id: id ?? this.id,
      tutorName: tutorName ?? this.tutorName,
      amount: amount ?? this.amount,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      method: method ?? this.method,
      accountTitle: accountTitle ?? this.accountTitle,
      accountNumber: accountNumber ?? this.accountNumber,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      requestedAt: requestedAt ?? this.requestedAt,
      avatarColors: avatarColors ?? this.avatarColors,
      status: status ?? this.status,
    );
  }

  String get formattedAmount {
    // Keep whole numbers tidy while allowing cents when needed
    final isWhole = amount == amount.roundToDouble();
    final amountString = isWhole ? amount.toStringAsFixed(0) : amount.toStringAsFixed(2);
    return '$currencySymbol$amountString';
  }

  String get methodLabel {
    switch (method) {
      case PayoutMethod.bankTransfer:
        return 'Bank Transfer';
      case PayoutMethod.easyPaisa:
        return 'EasyPaisa';
      case PayoutMethod.jazzCash:
        return 'JazzCash';
    }
  }

  IconData get methodIcon {
    switch (method) {
      case PayoutMethod.bankTransfer:
        return Icons.account_balance;
      case PayoutMethod.easyPaisa:
        return Icons.wallet;
      case PayoutMethod.jazzCash:
        return Icons.payments_outlined;
    }
  }

  String get maskedAccountNumber {
    if (accountNumber.length <= 4) return accountNumber;
    final lastFour = accountNumber.substring(accountNumber.length - 4);
    return '•••• $lastFour';
  }
}
