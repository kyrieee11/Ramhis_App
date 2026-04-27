class ChatMessageModel {
  final String id;
  final String threadId;
  final String senderId;
  final String message;
  final String createdAt;

  const ChatMessageModel({
    required this.id,
    required this.threadId,
    required this.senderId,
    required this.message,
    required this.createdAt,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    final rawMessage = (json['message'] ?? '').toString().trim();

    return ChatMessageModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      threadId: (json['thread_id'] ?? json['threadId'] ?? '').toString(),
      senderId: (json['sender_id'] ?? json['senderId'] ?? '').toString(),
      message: rawMessage,
      createdAt: (json['created_at'] ?? json['createdAt'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'thread_id': threadId,
      'sender_id': senderId,
      'message': message,
      'created_at': createdAt,
    };
  }

  ChatMessageModel copyWith({
    String? id,
    String? threadId,
    String? senderId,
    String? message,
    String? createdAt,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      threadId: threadId ?? this.threadId,
      senderId: senderId ?? this.senderId,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}