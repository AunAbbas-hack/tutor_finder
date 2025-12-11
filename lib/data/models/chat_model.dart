// lib/data/models/chat_model.dart

class ChatModel {
  final String chatId;
  final String participant1Id;
  final String participant2Id;
  final String? lastMessage;
  final int? lastMessageTime;
  final Map<String, int> unreadCount; // {userId: count}
  final int? createdAt;

  const ChatModel({
    required this.chatId,
    required this.participant1Id,
    required this.participant2Id,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = const {},
    this.createdAt,
  });

  ChatModel copyWith({
    String? chatId,
    String? participant1Id,
    String? participant2Id,
    String? lastMessage,
    int? lastMessageTime,
    Map<String, int>? unreadCount,
    int? createdAt,
  }) {
    return ChatModel(
      chatId: chatId ?? this.chatId,
      participant1Id: participant1Id ?? this.participant1Id,
      participant2Id: participant2Id ?? this.participant2Id,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // ---------- Realtime Database mapping ----------

  Map<String, dynamic> toMap() {
    return {
      'participant1Id': participant1Id,
      'participant2Id': participant2Id,
      if (lastMessage != null) 'lastMessage': lastMessage,
      if (lastMessageTime != null) 'lastMessageTime': lastMessageTime,
      'unreadCount': unreadCount,
      if (createdAt != null) 'createdAt': createdAt,
    };
  }

  factory ChatModel.fromMap(String chatId, Map<dynamic, dynamic> map) {
    // Handle unreadCount - can be Map or null
    Map<String, int> unreadCountMap = {};
    if (map['unreadCount'] != null) {
      final unreadData = map['unreadCount'] as Map<dynamic, dynamic>?;
      if (unreadData != null) {
        unreadData.forEach((key, value) {
          unreadCountMap[key.toString()] = (value as num?)?.toInt() ?? 0;
        });
      }
    }

    return ChatModel(
      chatId: chatId,
      participant1Id: map['participant1Id'] as String? ?? '',
      participant2Id: map['participant2Id'] as String? ?? '',
      lastMessage: map['lastMessage'] as String?,
      lastMessageTime: (map['lastMessageTime'] as num?)?.toInt(),
      unreadCount: unreadCountMap,
      createdAt: (map['createdAt'] as num?)?.toInt(),
    );
  }

  // Get the other participant's ID
  String getOtherParticipantId(String currentUserId) {
    if (participant1Id == currentUserId) {
      return participant2Id;
    }
    return participant1Id;
  }

  // Get unread count for current user
  int getUnreadCountForUser(String userId) {
    return unreadCount[userId] ?? 0;
  }

  // Get formatted last message time
  DateTime? get lastMessageDateTime {
    if (lastMessageTime == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(lastMessageTime!);
  }
}

