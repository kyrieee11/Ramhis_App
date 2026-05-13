class ChatMessageModel {
  final String id;
  final String threadId;
  final String senderId;
  final String message;
  final DateTime? createdAt;

  const ChatMessageModel({
    required this.id,
    required this.threadId,
    required this.senderId,
    required this.message,
    required this.createdAt,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: (json['_id'] ?? '').toString(),
      threadId: (json['thread_id'] ?? '').toString(),
      senderId: (json['sender_id'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }
}