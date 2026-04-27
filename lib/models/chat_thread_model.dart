class ChatThreadModel {
  final String id;
  final String name;
  final String lastMessage;
  final int unread;
  final String updatedAt;

  const ChatThreadModel({
    required this.id,
    required this.name,
    required this.lastMessage,
    required this.unread,
    required this.updatedAt,
  });

  factory ChatThreadModel.fromJson(Map<String, dynamic> json) {
    final rawName = (json['name'] ?? '').toString().trim();
    final rawLastMessage = (json['last_message'] ?? '').toString().trim();

    return ChatThreadModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: rawName.isEmpty ? 'User Chat' : rawName,
      lastMessage: rawLastMessage.isEmpty ? 'No messages yet' : rawLastMessage,
      unread: _toInt(json['unread']),
      updatedAt: (json['updated_at'] ?? json['created_at'] ?? '').toString(),
    );
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'last_message': lastMessage,
      'unread': unread,
      'updated_at': updatedAt,
    };
  }

  ChatThreadModel copyWith({
    String? id,
    String? name,
    String? lastMessage,
    int? unread,
    String? updatedAt,
  }) {
    return ChatThreadModel(
      id: id ?? this.id,
      name: name ?? this.name,
      lastMessage: lastMessage ?? this.lastMessage,
      unread: unread ?? this.unread,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}