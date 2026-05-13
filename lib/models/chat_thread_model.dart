class ChatThreadModel {
  final String id;
  final String name;
  final String lastMessage;
  final int unread;
  final DateTime? updatedAt;

  const ChatThreadModel({
    required this.id,
    required this.name,
    required this.lastMessage,
    required this.unread,
    required this.updatedAt,
  });

  factory ChatThreadModel.fromJson(Map<String, dynamic> json) {
    return ChatThreadModel(
      id: (json['_id'] ?? '').toString(),
      name: (json['name'] ?? 'User Chat').toString(),
      lastMessage: (json['last_message'] ?? 'No messages yet').toString(),
      unread: json['unread'] is int
          ? json['unread'] as int
          : int.tryParse((json['unread'] ?? '0').toString()) ?? 0,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }
}