// lib/data/services/chat_service.dart
import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/message_model.dart';
import '../models/chat_model.dart';

class ChatService {
  final DatabaseReference _database;
  final FirebaseAuth _auth;

  ChatService({
    DatabaseReference? database,
    FirebaseAuth? auth,
  })  : _database = database ?? 
        FirebaseDatabase.instanceFor(
          app: FirebaseDatabase.instance.app,
          databaseURL: 'https://tutor-finder-0468-default-rtdb.asia-southeast1.firebasedatabase.app',
        ).ref(),
        _auth = auth ?? FirebaseAuth.instance;

  // Get current user ID
  String? get _currentUserId => _auth.currentUser?.uid;

  // Generate consistent chat ID from two user IDs
  String _generateChatId(String userId1, String userId2) {
    List<String> ids = [userId1, userId2];
    ids.sort(); // Always same order for same two users
    return '${ids[0]}_${ids[1]}';
  }

  // ---------- MESSAGES ----------

  /// Send a message
  Future<void> sendMessage({
    required String receiverId,
    required String text,
    MessageType type = MessageType.text,
    String? imageUrl,
    String? fileName,
  }) async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    final chatId = _generateChatId(_currentUserId!, receiverId);
    final messagesRef = _database.child('chats/$chatId/messages');
    final messageRef = messagesRef.push();

    final timestamp = DateTime.now().millisecondsSinceEpoch;

    final messageData = {
      'senderId': _currentUserId,
      'receiverId': receiverId,
      'text': text,
      'timestamp': timestamp,
      'isRead': false,
      'type': MessageModel.typeToString(type),
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (fileName != null) 'fileName': fileName,
    };

    await messageRef.set(messageData);

    // Update chat metadata
    await _updateChatMetadata(
      chatId: chatId,
      participant1Id: chatId.split('_')[0],
      participant2Id: chatId.split('_')[1],
      lastMessage: text,
      lastMessageTime: timestamp,
    );

    // Update unread count for receiver
    await _database
        .child('chats/$chatId/unreadCount/$receiverId')
        .set(ServerValue.increment(1));

    // Update userChats for both users (quick lookup)
    await _database.child('userChats/$_currentUserId/$chatId').set(true);
    await _database.child('userChats/$receiverId/$chatId').set(true);
  }

  /// Get messages stream (real-time updates)
  Stream<List<MessageModel>> getMessagesStream(String otherUserId) {
    if (_currentUserId == null) {
      return Stream.value([]);
    }

    final chatId = _generateChatId(_currentUserId!, otherUserId);
    final messagesRef = _database.child('chats/$chatId/messages');

    return messagesRef.orderByChild('timestamp').onValue.map((event) {
      if (event.snapshot.value == null) return <MessageModel>[];

      final Map<dynamic, dynamic> messagesMap =
          event.snapshot.value as Map<dynamic, dynamic>;

      return messagesMap.entries.map((entry) {
        return MessageModel.fromMap(
          entry.key.toString(),
          entry.value as Map<dynamic, dynamic>,
        );
      }).toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    });
  }

  /// Mark messages as read
  Future<void> markMessagesAsRead(String otherUserId) async {
    if (_currentUserId == null) return;

    final chatId = _generateChatId(_currentUserId!, otherUserId);
    final messagesRef = _database.child('chats/$chatId/messages');

    // Get all unread messages for current user
    final snapshot = await messagesRef
        .orderByChild('receiverId')
        .equalTo(_currentUserId)
        .once();

    if (snapshot.snapshot.value != null) {
      final Map<dynamic, dynamic> messages =
          snapshot.snapshot.value as Map<dynamic, dynamic>;

      // Update each unread message
      for (var entry in messages.entries) {
        final messageData = entry.value as Map<dynamic, dynamic>;
        if (messageData['isRead'] == false) {
          await messagesRef.child('${entry.key}/isRead').set(true);
        }
      }
    }

    // Reset unread count for current user
    await _database
        .child('chats/$chatId/unreadCount/$_currentUserId')
        .set(0);
  }

  /// Delete a message
  Future<void> deleteMessage(String otherUserId, String messageId) async {
    if (_currentUserId == null) return;

    final chatId = _generateChatId(_currentUserId!, otherUserId);
    await _database.child('chats/$chatId/messages/$messageId').remove();
  }

  // ---------- CONVERSATIONS ----------

  /// Get conversations list stream (real-time updates)
  Stream<List<ChatModel>> getConversationsStream() {
    if (_currentUserId == null) {
      return Stream.value([]);
    }

    final userChatsRef = _database.child('userChats/$_currentUserId');
    final controller = StreamController<List<ChatModel>>();
    StreamSubscription? userChatsSubscription;
    final Map<String, StreamSubscription> chatSubscriptions = {};

    // Function to fetch and return all conversations
    Future<List<ChatModel>> fetchConversations(Map<dynamic, dynamic> chatIds) async {
      List<ChatModel> conversations = [];

      for (var chatIdKey in chatIds.keys) {
        try {
          final chatId = chatIdKey.toString();
          final chatRef = _database.child('chats/$chatId');
          final snapshot = await chatRef.once();

          if (snapshot.snapshot.value != null) {
            final chatData =
                snapshot.snapshot.value as Map<dynamic, dynamic>;
            conversations.add(ChatModel.fromMap(chatId, chatData));
          }
        } catch (e) {
          continue;
        }
      }

      // Sort by last message time (newest first)
      conversations.sort((a, b) {
        final timeA = a.lastMessageTime ?? 0;
        final timeB = b.lastMessageTime ?? 0;
        return timeB.compareTo(timeA);
      });

      return conversations;
    }

    // Function to emit conversations and setup listeners
    Future<void> emitAndSetupListeners(Object? chatIdsData) async {
      if (chatIdsData == null || chatIdsData is! Map || (chatIdsData as Map).isEmpty) {
        controller.add(<ChatModel>[]);
        return;
      }

      final chatIds = chatIdsData as Map<dynamic, dynamic>;
      
      // Cancel old chat subscriptions
      for (var sub in chatSubscriptions.values) {
        await sub.cancel();
      }
      chatSubscriptions.clear();

      // Fetch and emit conversations
      final conversations = await fetchConversations(chatIds);
      controller.add(conversations);

      // Setup listeners for each chat's metadata changes
      for (var chatIdKey in chatIds.keys) {
        final chatId = chatIdKey.toString();
        final chatMetadataRef = _database.child('chats/$chatId');
        
        // Listen to lastMessageTime changes (triggers on new messages)
        final subscription = chatMetadataRef
            .child('lastMessageTime')
            .onValue
            .listen((_) async {
          // Re-fetch all conversations when any chat updates
          final currentChatIds = await userChatsRef.once();
          if (currentChatIds.snapshot.value != null) {
            final currentIds = currentChatIds.snapshot.value as Map<dynamic, dynamic>;
            final updated = await fetchConversations(currentIds);
            if (!controller.isClosed) {
              controller.add(updated);
            }
          }
        });
        
        chatSubscriptions[chatId] = subscription;
      }
    }

    // Listen to userChats changes (new conversations)
    userChatsSubscription = userChatsRef.onValue.listen((event) async {
      final chatIdsData = event.snapshot.value;
      await emitAndSetupListeners(chatIdsData);
    });

    // Cleanup on close
    controller.onCancel = () {
      userChatsSubscription?.cancel();
      for (var sub in chatSubscriptions.values) {
        sub.cancel();
      }
      chatSubscriptions.clear();
    };

    return controller.stream;
  }

  /// Get or create chat with another user
  Future<String> getOrCreateChatId(String otherUserId) async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    final chatId = _generateChatId(_currentUserId!, otherUserId);

    // Check if chat exists
    final chatRef = _database.child('chats/$chatId');
    final snapshot = await chatRef.once();

    if (snapshot.snapshot.value == null) {
      // Create new chat
      await _updateChatMetadata(
        chatId: chatId,
        participant1Id: chatId.split('_')[0],
        participant2Id: chatId.split('_')[1],
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

      // Add to userChats
      await _database.child('userChats/$_currentUserId/$chatId').set(true);
      await _database.child('userChats/$otherUserId/$chatId').set(true);
    }

    return chatId;
  }

  // ---------- TYPING INDICATORS ----------

  /// Set typing status
  Future<void> setTyping(String otherUserId, bool isTyping) async {
    if (_currentUserId == null) return;

    final chatId = _generateChatId(_currentUserId!, otherUserId);
    final typingRef =
        _database.child('chats/$chatId/typing/$_currentUserId');

    if (isTyping) {
      await typingRef.set(ServerValue.timestamp);
    } else {
      await typingRef.remove();
    }
  }

  /// Get typing status stream
  Stream<bool> getTypingStream(String otherUserId) {
    if (_currentUserId == null) {
      return Stream.value(false);
    }

    final chatId = _generateChatId(_currentUserId!, otherUserId);
    return _database
        .child('chats/$chatId/typing/$otherUserId')
        .onValue
        .map((event) => event.snapshot.value != null);
  }

  // ---------- HELPER METHODS ----------

  /// Update chat metadata
  Future<void> _updateChatMetadata({
    required String chatId,
    required String participant1Id,
    required String participant2Id,
    String? lastMessage,
    int? lastMessageTime,
    int? createdAt,
  }) async {
    final updates = <String, dynamic>{
      'participant1Id': participant1Id,
      'participant2Id': participant2Id,
      if (lastMessage != null) 'lastMessage': lastMessage,
      if (lastMessageTime != null) 'lastMessageTime': lastMessageTime,
      if (createdAt != null) 'createdAt': createdAt,
    };

    await _database.child('chats/$chatId').update(updates);
  }

  /// Get chat by ID
  Future<ChatModel?> getChatById(String chatId) async {
    final chatRef = _database.child('chats/$chatId');
    final snapshot = await chatRef.once();

    if (snapshot.snapshot.value == null) return null;

    final chatData = snapshot.snapshot.value as Map<dynamic, dynamic>;
    return ChatModel.fromMap(chatId, chatData);
  }

  /// Get chat ID from two user IDs
  String getChatId(String userId1, String userId2) {
    return _generateChatId(userId1, userId2);
  }
}

