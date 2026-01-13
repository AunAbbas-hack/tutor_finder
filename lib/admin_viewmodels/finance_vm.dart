// lib/admin_viewmodels/finance_vm.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../data/models/payment_model.dart';
import '../data/models/user_model.dart';
import '../data/services/payment_services.dart';
import '../data/services/user_services.dart';

enum PaymentSort { dateDesc, amountDesc, nameAsc }

class PaymentDisplayModel {
  final PaymentModel payment;
  final String tutorName;
  final String parentName;
  final Color avatarColor1;
  final Color avatarColor2;

  PaymentDisplayModel({
    required this.payment,
    required this.tutorName,
    required this.parentName,
    required this.avatarColor1,
    required this.avatarColor2,
  });
}

class FinanceViewModel extends ChangeNotifier {
  final PaymentService _paymentService;
  final UserService _userService;
  bool _isDisposed = false;
  bool _isLoading = false;
  String? _errorMessage;
  List<PaymentDisplayModel> _payments = [];
  PaymentSort _sortBy = PaymentSort.dateDesc;

  FinanceViewModel({
    PaymentService? paymentService,
    UserService? userService,
  })  : _paymentService = paymentService ?? PaymentService(),
        _userService = userService ?? UserService();

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  PaymentSort get sortBy => _sortBy;

  List<PaymentDisplayModel> get pendingPayments {
    final pending = _payments.where((p) => 
      p.payment.status == PaymentStatus.completed && !p.payment.tutorPaid
    ).toList();
    return _sorted(pending);
  }

  double get totalPendingAmount {
    return pendingPayments.fold(0.0, (sum, item) => sum + item.payment.amount);
  }

  int get pendingCount => pendingPayments.length;

  Future<void> initialize() async {
    if (_isDisposed) return;
    _setLoading(true);
    _errorMessage = null;

    try {
      // Load all completed payments
      final payments = await _paymentService.getPaymentsByStatus(PaymentStatus.completed);
      
      // Load user names for each payment
      final displayPayments = <PaymentDisplayModel>[];
      for (final payment in payments) {
        final tutor = await _userService.getUserById(payment.tutorId);
        final parent = await _userService.getUserById(payment.parentId);
        
        if (tutor != null && parent != null) {
          final colors = _getAvatarColors(tutor.name);
          displayPayments.add(PaymentDisplayModel(
            payment: payment,
            tutorName: tutor.name,
            parentName: parent.name,
            avatarColor1: colors[0],
            avatarColor2: colors[1],
          ));
        }
      }
      
      _payments = displayPayments;
    } catch (e) {
      if (!_isDisposed) {
        _errorMessage = 'Failed to load payments: ${e.toString()}';
      }
    } finally {
      if (!_isDisposed) {
        _setLoading(false);
      }
    }
  }

  void updateSort(PaymentSort sort) {
    if (_sortBy == sort) return;
    _sortBy = sort;
    _safeNotifyListeners();
  }

  Future<void> markAsPaidToTutor(String paymentId) async {
    try {
      await _paymentService.markAsPaidToTutor(paymentId);
      // Reload payments
      await initialize();
    } catch (e) {
      _errorMessage = 'Failed to mark payment as paid: ${e.toString()}';
      _safeNotifyListeners();
    }
  }

  String formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final month = months[date.month - 1];
    final day = date.day.toString().padLeft(2, '0');
    return '$month $day, ${date.year}';
  }

  String formatAmount(double amount, {String symbol = 'Rs '}) {
    final isWhole = amount == amount.roundToDouble();
    final text = isWhole ? amount.toStringAsFixed(0) : amount.toStringAsFixed(2);
    return '$symbol$text';
  }

  List<PaymentDisplayModel> _sorted(List<PaymentDisplayModel> list) {
    final sorted = List<PaymentDisplayModel>.from(list);
    switch (_sortBy) {
      case PaymentSort.dateDesc:
        sorted.sort((a, b) => b.payment.createdAt.compareTo(a.payment.createdAt));
        break;
      case PaymentSort.amountDesc:
        sorted.sort((a, b) => b.payment.amount.compareTo(a.payment.amount));
        break;
      case PaymentSort.nameAsc:
        sorted.sort((a, b) => a.tutorName.toLowerCase().compareTo(b.tutorName.toLowerCase()));
        break;
    }
    return sorted;
  }

  List<Color> _getAvatarColors(String name) {
    // Generate consistent colors based on name
    final hash = name.hashCode;
    final colors = [
      [Color(0xFFFFC39A), Color(0xFFFF8C7F)],
      [Color(0xFF6DD5ED), Color(0xFF2193B0)],
      [Color(0xFFFFE29F), Color(0xFFffa99f)],
      [Color(0xFFa18cd1), Color(0xFFfbc2eb)],
      [Color(0xFFfad0c4), Color(0xFFffd1ff)],
      [Color(0xFFa8edea), Color(0xFFfed6e3)],
    ];
    return colors[hash.abs() % colors.length];
  }

  void _setLoading(bool value) {
    _isLoading = value;
    _safeNotifyListeners();
  }

  void _safeNotifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }


  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
