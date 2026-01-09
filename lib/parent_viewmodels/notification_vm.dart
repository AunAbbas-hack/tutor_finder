// lib/parent_viewmodels/notification_vm.dart
// Parent Notification ViewModel
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/notification_model.dart';
import '../../data/services/notification_service.dart';

class NotificationViewModel extends ChangeNotifier {
  final NotificationService _notificationService;
  final FirebaseAuth _auth;

  NotificationViewModel({
    NotificationService? notificationService,
    FirebaseAuth? auth,
  })  : _notificationService = notificationService ?? NotificationService(),
        _auth = auth ?? FirebaseAuth.instance;

  // ---------- State ----------
  bool _isDisposed = false;
  bool _isLoading = false;
  String? _errorMessage;
  
  List<NotificationModel> _notifications = [];
  StreamSubscription<List<NotificationModel>>? _notificationsSubscription;
  int _unreadCount = 0;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get hasUnread => _unreadCount > 0;

  // Get current user ID
  String? get _currentUserId => _auth.currentUser?.uid;

  // ---------- Initialize ----------
  Future<void> initialize() async {
    if (_isDisposed || _currentUserId == null) return;

    _setLoading(true);
    _errorMessage = null;

    try {
      // Load notifications
      await loadNotifications();

      // Start listening to real-time updates
      _startNotificationsStream();

      // Load unread count
      await loadUnreadCount();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initializing notifications: $e');
      }
      _errorMessage = 'Failed to load notifications: ${e.toString()}';
    } finally {
      if (!_isDisposed) {
        _setLoading(false);
      }
    }
  }

  // ---------- Load Notifications ----------
  Future<void> loadNotifications() async {
    if (_currentUserId == null) return;

    try {
      final notifications = await _notificationService.getNotifications(_currentUserId!);
      
      if (!_isDisposed) {
        _notifications = notifications;
        _updateUnreadCount();
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading notifications: $e');
      }
      if (!_isDisposed) {
        _errorMessage = 'Failed to load notifications';
        notifyListeners();
      }
    }
  }

  // ---------- Real-time Stream ----------
  void _startNotificationsStream() {
    if (_currentUserId == null) return;

    // Cancel existing subscription
    _notificationsSubscription?.cancel();

    // Start new stream
    _notificationsSubscription = _notificationService
        .getNotificationsStream(_currentUserId!)
        .listen(
      (notifications) {
        if (!_isDisposed) {
          _notifications = notifications;
          _updateUnreadCount();
          notifyListeners();
        }
      },
      onError: (error) {
        if (kDebugMode) {
          print('❌ Error in notifications stream: $error');
        }
        if (!_isDisposed) {
          _errorMessage = 'Error receiving notifications';
          notifyListeners();
        }
      },
    );
  }

  // ---------- Unread Count ----------
  Future<void> loadUnreadCount() async {
    if (_currentUserId == null) return;

    try {
      final count = await _notificationService.getUnreadCount(_currentUserId!);
      
      if (!_isDisposed) {
        _unreadCount = count;
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading unread count: $e');
      }
    }
  }

  void _updateUnreadCount() {
    _unreadCount = _notifications.where((n) => n.status == NotificationStatus.unread).length;
  }

  // ---------- Mark as Read ----------
  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationService.markAsRead(notificationId);
      
      // Update local state
      final index = _notifications.indexWhere((n) => n.notificationId == notificationId);
      if (index != -1 && !_isDisposed) {
        _notifications[index] = _notifications[index].copyWith(
          status: NotificationStatus.read,
        );
        _updateUnreadCount();
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error marking notification as read: $e');
      }
      if (!_isDisposed) {
        _errorMessage = 'Failed to mark notification as read';
        notifyListeners();
      }
    }
  }

  // ---------- Mark All as Read ----------
  Future<void> markAllAsRead() async {
    if (_currentUserId == null) return;

    try {
      await _notificationService.markAllAsRead(_currentUserId!);
      
      // Update local state
      if (!_isDisposed) {
        _notifications = _notifications.map((n) => n.copyWith(
          status: NotificationStatus.read,
        )).toList();
        _updateUnreadCount();
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error marking all as read: $e');
      }
      if (!_isDisposed) {
        _errorMessage = 'Failed to mark all as read';
        notifyListeners();
      }
    }
  }

  // ---------- Delete Notification ----------
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationService.deleteNotification(notificationId);
      
      // Update local state
      if (!_isDisposed) {
        _notifications.removeWhere((n) => n.notificationId == notificationId);
        _updateUnreadCount();
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error deleting notification: $e');
      }
      if (!_isDisposed) {
        _errorMessage = 'Failed to delete notification';
        notifyListeners();
      }
    }
  }

  // ---------- Refresh ----------
  Future<void> refresh() async {
    await loadNotifications();
    await loadUnreadCount();
  }

  // ---------- Helpers ----------
  void _setLoading(bool value) {
    if (_isDisposed) return;
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    if (_isDisposed) return;
    _errorMessage = null;
    notifyListeners();
  }

  // ---------- Dispose ----------
  @override
  void dispose() {
    _isDisposed = true;
    _notificationsSubscription?.cancel();
    super.dispose();
  }
}
