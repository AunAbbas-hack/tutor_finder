// lib/admin_viewmodels/finance_vm.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../data/models/payout_request_model.dart';

enum PayoutSort { dateDesc, amountDesc, nameAsc }

class FinanceViewModel extends ChangeNotifier {
  bool _isDisposed = false;
  bool _isLoading = false;
  String? _errorMessage;
  List<PayoutRequestModel> _requests = [];
  PayoutSort _sortBy = PayoutSort.dateDesc;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  PayoutSort get sortBy => _sortBy;

  List<PayoutRequestModel> get pendingRequests {
    final pending = _requests.where((r) => r.status == PayoutStatus.pending).toList();
    return _sorted(pending);
  }

  double get totalPendingAmount {
    return _requests
        .where((r) => r.status == PayoutStatus.pending)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  int get pendingCount => pendingRequests.length;

  Future<void> initialize() async {
    if (_isDisposed) return;
    _setLoading(true);
    _errorMessage = null;

    try {
      // Simulate initial load; replace with real service call later
      await Future<void>.delayed(const Duration(milliseconds: 200));
      _requests = _seedData();
    } catch (e) {
      if (!_isDisposed) {
        _errorMessage = 'Failed to load payouts: ${e.toString()}';
      }
    } finally {
      if (!_isDisposed) {
        _setLoading(false);
      }
    }
  }

  void updateSort(PayoutSort sort) {
    if (_sortBy == sort) return;
    _sortBy = sort;
    _safeNotifyListeners();
  }

  Future<void> approve(String id) async {
    _updateStatus(id, PayoutStatus.approved);
  }

  Future<void> reject(String id) async {
    _updateStatus(id, PayoutStatus.rejected);
  }

  String formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final month = months[date.month - 1];
    final day = date.day.toString().padLeft(2, '0');
    return '$month $day, ${date.year}';
  }

  String formatAmount(double amount, {String symbol = '\$'}) {
    final isWhole = amount == amount.roundToDouble();
    final text = isWhole ? amount.toStringAsFixed(0) : amount.toStringAsFixed(2);
    return '$symbol$text';
  }

  List<PayoutRequestModel> _sorted(List<PayoutRequestModel> list) {
    final sorted = List<PayoutRequestModel>.from(list);
    switch (_sortBy) {
      case PayoutSort.dateDesc:
        sorted.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
        break;
      case PayoutSort.amountDesc:
        sorted.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case PayoutSort.nameAsc:
        sorted.sort((a, b) => a.tutorName.toLowerCase().compareTo(b.tutorName.toLowerCase()));
        break;
    }
    return sorted;
  }

  void _updateStatus(String id, PayoutStatus status) {
    final index = _requests.indexWhere((r) => r.id == id);
    if (index == -1) return;

    _requests[index] = _requests[index].copyWith(status: status);
    _safeNotifyListeners();
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

  List<PayoutRequestModel> _seedData() {
    // Sample data; replace with backend data when available
    return [
      PayoutRequestModel(
        id: 'req_theresa',
        tutorName: 'Theresa Webb',
        amount: 450.0,
        method: PayoutMethod.bankTransfer,
        accountTitle: 'Theresa Webb',
        accountNumber: 'PK70 UNIL 0000 1234 5678',
        requestedAt: DateTime.now().subtract(const Duration(days: 1)),
        avatarColors: const [Color(0xFFFFC39A), Color(0xFFFF8C7F)],
      ),
      PayoutRequestModel(
        id: 'req_jerome',
        tutorName: 'Jerome Bell',
        amount: 1200.0,
        method: PayoutMethod.easyPaisa,
        accountTitle: 'Jerome Bell',
        accountNumber: '920 300 1234567',
        phoneNumber: '+92 300 1234567',
        requestedAt: DateTime.now().subtract(const Duration(days: 2)),
        avatarColors: const [Color(0xFF6DD5ED), Color(0xFF2193B0)],
      ),
      PayoutRequestModel(
        id: 'req_eleanor',
        tutorName: 'Eleanor Pena',
        amount: 280.0,
        method: PayoutMethod.jazzCash,
        accountTitle: 'Eleanor Pena',
        accountNumber: '312 9876543',
        phoneNumber: '+92 312 9876543',
        requestedAt: DateTime.now().subtract(const Duration(days: 3)),
        avatarColors: const [Color(0xFFFFE29F), Color(0xFFffa99f)],
      ),
      PayoutRequestModel(
        id: 'req_arham',
        tutorName: 'Arham Khan',
        amount: 820.0,
        method: PayoutMethod.bankTransfer,
        accountTitle: 'Arham Khan',
        accountNumber: 'PK09 HBL 0000 9876 5432',
        requestedAt: DateTime.now().subtract(const Duration(days: 4, hours: 3)),
        avatarColors: const [Color(0xFFa18cd1), Color(0xFFfbc2eb)],
      ),
    ];
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
