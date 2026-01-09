// lib/viewmodels/individual_chat_vm.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/models/message_model.dart';
import '../data/models/user_model.dart';
import '../data/services/chat_service.dart';
import '../data/services/user_services.dart';
import '../data/services/storage_service.dart';

/// Message with date grouping info
class MessageWithDate {
  final MessageModel message;
  final bool showDateSeparator;
  final String? dateLabel;

  MessageWithDate({
    required this.message,
    this.showDateSeparator = false,
    this.dateLabel,
  });
}

class IndividualChatViewModel extends ChangeNotifier {
  final ChatService _chatService;
  final UserService _userService;
  final StorageService _storageService;
  final FirebaseAuth _auth;

  final String otherUserId;
  final String otherUserName;
  final String? otherUserImageUrl;

  IndividualChatViewModel({
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserImageUrl,
    ChatService? chatService,
    UserService? userService,
    StorageService? storageService,
    FirebaseAuth? auth,
  })  : _chatService = chatService ?? ChatService(),
        _userService = userService ?? UserService(),
        _storageService = storageService ?? StorageService(),
        _auth = auth ?? FirebaseAuth.instance;

  // Stream subscriptions
  StreamSubscription? _messagesSubscription;
  StreamSubscription? _typingSubscription;

  // Current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Messages list
  List<MessageModel> _messages = [];
  List<MessageModel> get messages => _messages;

  // Messages with date separators
  List<MessageWithDate> get messagesWithDates {
    if (_messages.isEmpty) return [];

    List<MessageWithDate> result = [];
    DateTime? lastDate;

    for (var message in _messages) {
      final messageDate = DateTime.fromMillisecondsSinceEpoch(message.timestamp);
      final messageDateOnly = DateTime(
        messageDate.year,
        messageDate.month,
        messageDate.day,
      );

      bool showDateSeparator = false;
      String? dateLabel;

      if (lastDate == null || !_isSameDay(lastDate, messageDateOnly)) {
        showDateSeparator = true;
        dateLabel = _formatDateLabel(messageDateOnly);
        lastDate = messageDateOnly;
      }

      result.add(MessageWithDate(
        message: message,
        showDateSeparator: showDateSeparator,
        dateLabel: dateLabel,
      ));
    }

    return result;
  }

  // Typing indicator
  bool _isOtherUserTyping = false;
  bool get isOtherUserTyping => _isOtherUserTyping;

  // Loading state
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Error message
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Other user info (for online status, student relation, etc.)
  UserModel? _otherUser;
  UserModel? get otherUser => _otherUser;

  // Online status (placeholder - will implement with presence system)
  bool get isOtherUserOnline {
    // TODO: Implement with Firebase Realtime Database presence
    return false;
  }

  // Initialize and load data
  Future<void> initialize() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      // Load other user info
      _otherUser = await _userService.getUserById(otherUserId);

      // Mark messages as read
      await _chatService.markMessagesAsRead(otherUserId);

      // Start listening to messages
      _messagesSubscription?.cancel();
      _messagesSubscription = _chatService
          .getMessagesStream(otherUserId)
          .listen(
            (messages) {
              _messages = messages;
              _setLoading(false);
              notifyListeners();
            },
            onError: (error) {
              _errorMessage = 'Failed to load messages: ${error.toString()}';
              _setLoading(false);
              notifyListeners();
            },
          );

      // Start listening to typing indicator
      _typingSubscription?.cancel();
      _typingSubscription = _chatService
          .getTypingStream(otherUserId)
          .listen(
            (isTyping) {
              _isOtherUserTyping = isTyping;
              notifyListeners();
            },
          );

      _setLoading(false);
    } catch (e) {
      _errorMessage = 'Failed to initialize chat: ${e.toString()}';
      _setLoading(false);
      notifyListeners();
    }
  }

  // Send message
  Future<bool> sendMessage(String text) async {
    if (text.trim().isEmpty) return false;

    try {
      await _chatService.sendMessage(
        receiverId: otherUserId,
        text: text.trim(),
      );
      return true;
    } catch (e) {
      _errorMessage = 'Failed to send message: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Send image message
  Future<bool> sendImageMessage(File imageFile, String? caption) async {
    try {
      _setLoading(true);
      _errorMessage = null;
      
      if (_auth.currentUser == null) {
        _errorMessage = 'User not authenticated';
        _setLoading(false);
        notifyListeners();
        return false;
      }
      
      final chatId = _chatService.getChatId(_auth.currentUser!.uid, otherUserId);
      
      // Upload image to Firebase Storage
      final imageUrl = await _storageService.uploadImage(imageFile, chatId);
      if (imageUrl == null) {
        _errorMessage = 'Failed to upload image. Please check Firebase Storage configuration.';
        _setLoading(false);
        notifyListeners();
        return false;
      }

      // Send message with image
      await _chatService.sendMessage(
        receiverId: otherUserId,
        text: caption ?? 'Image',
        type: MessageType.image,
        imageUrl: imageUrl,
      );

      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString().contains('Storage is not configured')
          ? 'Firebase Storage is not enabled. Please enable it in Firebase Console.'
          : 'Failed to send image: ${e.toString()}';
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Send file message
  Future<bool> sendFileMessage(File file, String fileName) async {
    try {
      _setLoading(true);
      _errorMessage = null;
      
      if (_auth.currentUser == null) {
        _errorMessage = 'User not authenticated';
        _setLoading(false);
        notifyListeners();
        return false;
      }
      
      final chatId = _chatService.getChatId(_auth.currentUser!.uid, otherUserId);
      
      // Upload file to Firebase Storage
      final fileUrl = await _storageService.uploadFile(file, chatId, fileName);
      if (fileUrl == null) {
        _errorMessage = 'Failed to upload file. Please check Firebase Storage configuration.';
        _setLoading(false);
        notifyListeners();
        return false;
      }

      // Send message with file
      // Note: For file messages, we'll store the file URL in imageUrl field
      // since MessageModel doesn't have a separate fileUrl field
      await _chatService.sendMessage(
        receiverId: otherUserId,
        text: 'File: $fileName',
        type: MessageType.file,
        fileName: fileName,
        imageUrl: fileUrl, // Storing file download URL in imageUrl
      );

      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString().contains('Storage is not configured')
          ? 'Firebase Storage is not enabled. Please enable it in Firebase Console.'
          : 'Failed to send file: ${e.toString()}';
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Set typing status
  Future<void> setTyping(bool isTyping) async {
    try {
      await _chatService.setTyping(otherUserId, isTyping);
    } catch (e) {
      // Silently fail for typing indicator
    }
  }

  // Format timestamp for message
  String formatMessageTime(MessageModel message) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(message.timestamp);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      // Today - show time only
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      // Yesterday
      return 'Yesterday';
    } else {
      // Other date - show date
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  // Format time for message bubble (HH:MM format)
  String formatBubbleTime(MessageModel message) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(message.timestamp);
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  // Helper: Check if two dates are the same day
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  // Helper: Format date label
  String _formatDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else {
      // Format: "Monday, Oct 23" or similar
      final weekdays = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday'
      ];
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

      return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
    }
  }

  // Download file
  Future<bool> downloadFile({
    required String fileUrl,
    required String fileName,
  }) async {
    try {
      _errorMessage = null;
      _setLoading(true);
      notifyListeners();

      final filePath = await _storageService.downloadFile(
        fileUrl: fileUrl,
        fileName: fileName,
      );

      _setLoading(false);
      
      if (filePath != null) {
        if (kDebugMode) {
          print('File downloaded successfully: $filePath');
        }
        return true;
      } else {
        _errorMessage = 'Failed to download file';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _setLoading(false);
      _errorMessage = 'Failed to download file: ${e.toString()}';
      notifyListeners();
      if (kDebugMode) {
        print('Error downloading file: $e');
      }
      return false;
    }
  }

  // Open file (downloads if not exists, then opens)
  Future<bool> openFile({
    required String fileUrl,
    required String fileName,
  }) async {
    try {
      _errorMessage = null;
      _setLoading(true);
      notifyListeners();

      final success = await _storageService.downloadAndOpenFile(
        fileUrl: fileUrl,
        fileName: fileName,
      );

      _setLoading(false);
      
      if (!success) {
        _errorMessage = 'Failed to open file. Please check if you have an app installed to open this file type.';
        notifyListeners();
      }
      
      return success;
    } catch (e) {
      _setLoading(false);
      _errorMessage = 'Failed to open file: ${e.toString()}';
      notifyListeners();
      if (kDebugMode) {
        print('Error opening file: $e');
      }
      return false;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _messagesSubscription?.cancel();
    _typingSubscription?.cancel();
    // Stop typing when leaving
    setTyping(false);
    super.dispose();
  }
}

