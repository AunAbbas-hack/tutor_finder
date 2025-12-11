// lib/data/models/message_model.dart

enum MessageType {
  text,
  image,
  file,
}

class MessageModel {
  final String messageId;
  final String senderId;
  final String receiverId;
  final String text;
  final int timestamp;
  final bool isRead;
  final MessageType type;
  final String? imageUrl; // For image messages
  final String? fileName; // For file messages

  const MessageModel({
    required this.messageId,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.timestamp,
    this.isRead = false,
    this.type = MessageType.text,
    this.imageUrl,
    this.fileName,
  });

  MessageModel copyWith({
    String? messageId,
    String? senderId,
    String? receiverId,
    String? text,
    int? timestamp,
    bool? isRead,
    MessageType? type,
    String? imageUrl,
    String? fileName,
  }) {
    return MessageModel(
      messageId: messageId ?? this.messageId,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
      imageUrl: imageUrl ?? this.imageUrl,
      fileName: fileName ?? this.fileName,
    );
  }

  // ---------- Realtime Database mapping ----------

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'timestamp': timestamp,
      'isRead': isRead,
      'type': _typeToString(type),
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (fileName != null) 'fileName': fileName,
    };
  }

  factory MessageModel.fromMap(String messageId, Map<dynamic, dynamic> map) {
    return MessageModel(
      messageId: messageId,
      senderId: map['senderId'] as String? ?? '',
      receiverId: map['receiverId'] as String? ?? '',
      text: map['text'] as String? ?? '',
      timestamp: (map['timestamp'] as num?)?.toInt() ?? 0,
      isRead: map['isRead'] as bool? ?? false,
      type: _typeFromString(map['type'] as String?),
      imageUrl: map['imageUrl'] as String?,
      fileName: map['fileName'] as String?,
    );
  }

  // ---------- Helpers ----------

  static String typeToString(MessageType type) {
    switch (type) {
      case MessageType.text:
        return 'text';
      case MessageType.image:
        return 'image';
      case MessageType.file:
        return 'file';
    }
  }

  static String _typeToString(MessageType type) => typeToString(type);

  static MessageType _typeFromString(String? value) {
    switch (value) {
      case 'image':
        return MessageType.image;
      case 'file':
        return MessageType.file;
      default:
        return MessageType.text;
    }
  }

  // Check if message is sent by current user
  bool isSentBy(String userId) {
    return senderId == userId;
  }

  // Get formatted timestamp
  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch(timestamp);
}

