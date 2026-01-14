// lib/parent_viewmodels/payment_history_vm.dart
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../data/models/payment_model.dart';
import '../data/models/user_model.dart';
import '../data/services/payment_service.dart';
import '../data/services/user_services.dart';
import '../core/theme/app_colors.dart';

/// Model for displaying payment with tutor info
class PaymentDisplayModel {
  final PaymentModel payment;
  final UserModel tutor;
  final String tutorName;
  final String tutorImageUrl;

  PaymentDisplayModel({
    required this.payment,
    required this.tutor,
    required this.tutorName,
    this.tutorImageUrl = '',
  });
}

enum PaymentFilter {
  all,
  completed,
  pending,
  failed,
}

class PaymentHistoryViewModel extends ChangeNotifier {
  final PaymentService _paymentService;
  final UserService _userService;
  final FirebaseAuth _auth;

  PaymentHistoryViewModel({
    PaymentService? paymentService,
    UserService? userService,
    FirebaseAuth? auth,
  })  : _paymentService = paymentService ?? PaymentService(),
        _userService = userService ?? UserService(),
        _auth = auth ?? FirebaseAuth.instance;

  // ---------- State ----------
  bool _isDisposed = false;
  bool _isLoading = false;
  String? _errorMessage;
  List<PaymentDisplayModel> _allPayments = [];
  List<PaymentDisplayModel> _filteredPayments = [];
  PaymentFilter _selectedFilter = PaymentFilter.all;
  String _searchQuery = '';

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<PaymentDisplayModel> get payments => _filteredPayments;
  PaymentFilter get selectedFilter => _selectedFilter;
  String get searchQuery => _searchQuery;
  int get totalPayments => _allPayments.length;
  double get totalAmount => _allPayments
      .where((p) => p.payment.status == PaymentStatus.completed)
      .fold(0.0, (sum, p) => sum + p.payment.amount);

  // ---------- Initialize ----------
  Future<void> initialize() async {
    if (_isDisposed) return;

    _setLoading(true);
    _errorMessage = null;

    try {
      final user = _auth.currentUser;
      if (user == null) {
        _errorMessage = 'User not authenticated';
        _setLoading(false);
        notifyListeners();
        return;
      }

      await loadPayments(user.uid);
    } catch (e) {
      if (!_isDisposed) {
        _errorMessage = 'Failed to load payment history: ${e.toString()}';
        if (kDebugMode) {
          print('Error loading payment history: $e');
        }
      }
    } finally {
      if (!_isDisposed) {
        _setLoading(false);
        notifyListeners();
      }
    }
  }

  // ---------- Load Payments ----------
  Future<void> loadPayments(String parentId) async {
    try {
      final payments = await _paymentService.getPaymentsByParentId(parentId);

      // Load tutor info for each payment
      final List<PaymentDisplayModel> paymentDisplays = [];
      for (final payment in payments) {
        try {
          final tutor = await _userService.getUserById(payment.tutorId);
          if (tutor != null) {
            paymentDisplays.add(
              PaymentDisplayModel(
                payment: payment,
                tutor: tutor,
                tutorName: tutor.name,
                tutorImageUrl: tutor.imageUrl ?? '',
              ),
            );
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error loading tutor for payment ${payment.paymentId}: $e');
          }
          // Continue with other payments even if one fails
        }
      }

      _allPayments = paymentDisplays;
      _applyFilters();
    } catch (e) {
      if (!_isDisposed) {
        _errorMessage = 'Failed to load payments: ${e.toString()}';
      }
    }
  }

  // ---------- Filter Methods ----------
  void setFilter(PaymentFilter filter) {
    _selectedFilter = filter;
    _applyFilters();
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query.trim().toLowerCase();
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    List<PaymentDisplayModel> filtered = List.from(_allPayments);

    // Apply status filter
    if (_selectedFilter != PaymentFilter.all) {
      PaymentStatus? status;
      switch (_selectedFilter) {
        case PaymentFilter.completed:
          status = PaymentStatus.completed;
          break;
        case PaymentFilter.pending:
          status = PaymentStatus.pending;
          break;
        case PaymentFilter.failed:
          status = PaymentStatus.failed;
          break;
        default:
          break;
      }

      if (status != null) {
        filtered = filtered.where((p) => p.payment.status == status).toList();
      }
    }

    // Apply search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((p) {
        final tutorName = p.tutorName.toLowerCase();
        final bookingId = p.payment.bookingId.toLowerCase();
        final paymentId = p.payment.paymentId.toLowerCase();
        final amount = p.payment.amount.toString();

        return tutorName.contains(_searchQuery) ||
            bookingId.contains(_searchQuery) ||
            paymentId.contains(_searchQuery) ||
            amount.contains(_searchQuery);
      }).toList();
    }

    _filteredPayments = filtered;
  }

  // ---------- Refresh ----------
  Future<void> refresh() async {
    final user = _auth.currentUser;
    if (user != null) {
      await loadPayments(user.uid);
    }
  }

  // ---------- Helper Methods ----------
  void _setLoading(bool value) {
    if (!_isDisposed) {
      _isLoading = value;
    }
  }

  String formatAmount(double amount, {String symbol = 'Rs '}) {
    return '$symbol${amount.toStringAsFixed(2)}';
  }

  String formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    }
  }

  Color getStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.completed:
        return AppColors.success;
      case PaymentStatus.pending:
        return AppColors.warning;
      case PaymentStatus.failed:
        return AppColors.error;
      case PaymentStatus.processing:
        return AppColors.primary;
      default:
        return AppColors.textGrey;
    }
  }

  String getStatusText(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.completed:
        return 'Completed';
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.failed:
        return 'Failed';
      case PaymentStatus.processing:
        return 'Processing';
      case PaymentStatus.refunded:
        return 'Refunded';
      case PaymentStatus.cancelled:
        return 'Cancelled';
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
