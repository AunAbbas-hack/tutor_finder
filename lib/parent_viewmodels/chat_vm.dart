// lib/parent_viewmodels/chat_vm.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/models/chat_model.dart';
import '../data/models/message_model.dart';
import '../data/models/user_model.dart';
import '../data/services/chat_service.dart';
import '../data/services/user_services.dart';

/// UI Model for conversation list item
class ConversationItem {
  final ChatModel chat;
  final UserModel? otherUser; // The other participant
  final int unreadCount;
  final String? lastMessagePreview;
  final DateTime? lastMessageTime;

  ConversationItem({
    required this.chat,
    this.otherUser,
    required this.unreadCount,
    this.lastMessagePreview,
    this.lastMessageTime,
  });
}

class ChatViewModel extends ChangeNotifier {
  final ChatService _chatService;
  final UserService _userService;
  final FirebaseAuth _auth;

  ChatViewModel({
    ChatService? chatService,
    UserService? userService,
    FirebaseAuth? auth,
  })  : _chatService = chatService ?? ChatService(),
        _userService = userService ?? UserService(),
        _auth = auth ?? FirebaseAuth.instance;

  // Stream subscription
  StreamSubscription? _conversationsSubscription;
  Timer? _timeoutTimer;

  // Current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Conversations list
  List<ConversationItem> _conversations = [];
  List<ConversationItem> get conversations => _conversations;

  // Total unread messages count
  int get totalUnreadCount {
    if (currentUserId == null) return 0;
    return _conversations.fold<int>(
      0,
      (sum, conv) => sum + conv.unreadCount,
    );
  }

  // Loading state
  bool _isLoading = false;
  bool _hasInitialized = false; // Track if we've received first data
  bool get isLoading => _isLoading;

  // Error message
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Search query
  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  // Filtered conversations based on search
  List<ConversationItem> get filteredConversations {
    if (_searchQuery.isEmpty) return _conversations;

    final query = _searchQuery.toLowerCase();
    return _conversations.where((conv) {
      final userName = conv.otherUser?.name.toLowerCase() ?? '';
      final lastMessage = conv.lastMessagePreview?.toLowerCase() ?? '';
      return userName.contains(query) || lastMessage.contains(query);
    }).toList();
  }

  // Initialize conversations
  Future<void> initialize() async {
    // Cancel existing subscription and timer if any
    await _conversationsSubscription?.cancel();
    _conversationsSubscription = null;
    _timeoutTimer?.cancel();
    _timeoutTimer = null;

    if (currentUserId == null) {
      _errorMessage = 'User not authenticated';
      _conversations = [];
      _setLoading(false);
      _hasInitialized = true;
      notifyListeners();
      return;
    }

    _setLoading(true);
    _errorMessage = null;
    _hasInitialized = false;

    try {
      // Set a timeout - if stream doesn't emit within 1.5 seconds, show empty state
      _timeoutTimer = Timer(const Duration(milliseconds: 1500), () {
        if (!_hasInitialized && _conversations.isEmpty) {
          _conversations = [];
          _setLoading(false);
          _hasInitialized = true;
          notifyListeners();
        }
      });

      // Listen to conversations stream
      _conversationsSubscription = _chatService.getConversationsStream().listen(
        (chats) async {
          // Cancel timeout timer as we received data
          _timeoutTimer?.cancel();
          _timeoutTimer = null;
          await _loadConversationsWithUserData(chats);
        },
        onError: (error) {
          _timeoutTimer?.cancel();
          _timeoutTimer = null;
          _errorMessage = 'Failed to load conversations: $error';
          _setLoading(false);
          _hasInitialized = true;
          notifyListeners();
        },
        cancelOnError: false,
      );
    } catch (e) {
      _timeoutTimer?.cancel();
      _timeoutTimer = null;
      _errorMessage = 'Failed to initialize: $e';
      _setLoading(false);
      _hasInitialized = true;
      notifyListeners();
    }
  }

  // Load conversations with user data
  Future<void> _loadConversationsWithUserData(List<ChatModel> chats) async {
    if (currentUserId == null) {
      _conversations = [];
      _setLoading(false);
      _hasInitialized = true;
      notifyListeners();
      return;
    }

    List<ConversationItem> items = [];

    // If chats list is empty, still set loading to false
    if (chats.isEmpty) {
      _conversations = items;
      _setLoading(false);
      _hasInitialized = true;
      notifyListeners();
      return;
    }

    for (var chat in chats) {
      try {
        // Get other participant's ID
        final otherUserId = chat.getOtherParticipantId(currentUserId!);

        // Fetch user data from Firestore
        final otherUser = await _userService.getUserById(otherUserId);

        // Get unread count
        final unreadCount = chat.getUnreadCountForUser(currentUserId!);

        items.add(ConversationItem(
          chat: chat,
          otherUser: otherUser,
          unreadCount: unreadCount,
          lastMessagePreview: chat.lastMessage,
          lastMessageTime: chat.lastMessageDateTime,
        ));
      } catch (e) {
        if (kDebugMode) {
          print('Error loading conversation data: $e');
        }
      }
    }

    _conversations = items;
    _setLoading(false);
    _hasInitialized = true;
    notifyListeners();
  }

  // Update search query
  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // Clear search
  void clearSearch() {
    _searchQuery = '';
    notifyListeners();
  }

  // Get or create chat with user
  Future<String?> getOrCreateChatId(String otherUserId) async {
    try {
      return await _chatService.getOrCreateChatId(otherUserId);
    } catch (e) {
      _errorMessage = 'Failed to create chat: $e';
      notifyListeners();
      return null;
    }
  }

  // Mark messages as read
  Future<void> markAsRead(String otherUserId) async {
    try {
      await _chatService.markMessagesAsRead(otherUserId);
    } catch (e) {
      if (kDebugMode) {
        print('Error marking messages as read: $e');
      }
    }
  }

  // Delete conversation (optional)
  Future<void> deleteConversation(String chatId) async {
    // Note: This would require additional service method
    // For now, just remove from local list
    _conversations.removeWhere((item) => item.chat.chatId == chatId);
    notifyListeners();
  }

  // Helper: Format timestamp
  String formatTimestamp(DateTime? dateTime) {
    if (dateTime == null) return '';

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      // Today - show time
      final hour = dateTime.hour;
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$displayHour:$minute $period';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      // This week - show day name
      final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[dateTime.weekday - 1];
    } else {
      // Older - show date
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
      return '${months[dateTime.month - 1]} ${dateTime.day}';
    }
  }

  // Helper: Check if user is online (placeholder - implement with presence system)
  bool isUserOnline(String userId) {
    // TODO: Implement with Firebase Realtime Database presence
    return false;
  }

  // Set loading state
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    // Cancel stream subscription and timer
    _conversationsSubscription?.cancel();
    _timeoutTimer?.cancel();
    super.dispose();
  }
}

