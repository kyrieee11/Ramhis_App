class ChatThreadModel {
  final String id;
  final String name;
  final String lastMessage;
  final int unread;
  final DateTime? updatedAt;

  final String type;
  final String eventId;
  final String eventTitle;
  final int memberCount;
  final List<dynamic> participants;

  const ChatThreadModel({
    required this.id,
    required this.name,
    required this.lastMessage,
    required this.unread,
    required this.updatedAt,
    required this.type,
    required this.eventId,
    required this.eventTitle,
    required this.memberCount,
    required this.participants,
  });

  bool get isGroup => type.toLowerCase() == 'group';

  String get displayName {
    if (isGroup) {
      if (name.trim().isNotEmpty) return name;
      if (eventTitle.trim().isNotEmpty) return eventTitle;
      return 'Group Chat';
    }

    return name.trim().isNotEmpty ? name : 'User Chat';
  }

  factory ChatThreadModel.fromJson(Map<String, dynamic> json) {
    final rawParticipants =
        json['participants'] ??
        json['members'] ??
        const [];

    final participants = rawParticipants is List
        ? List<dynamic>.from(rawParticipants)
        : <dynamic>[];

    final type = (json['type'] ?? 'direct').toString();

    final name = (
      json['name'] ??
          json['threadName'] ??
          json['eventTitle'] ??
          'User Chat'
    ).toString();

    return ChatThreadModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: name,
      lastMessage: (
        json['lastMessage'] ??
            json['last_message'] ??
            'No messages yet'
      ).toString(),
      unread: json['unread'] is int
          ? json['unread'] as int
          : int.tryParse((json['unread'] ?? '0').toString()) ?? 0,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : json['updated_at'] != null
              ? DateTime.tryParse(json['updated_at'].toString())
              : null,
      type: type,
      eventId: (
        json['eventId'] ??
            json['event_id'] ??
            ''
      ).toString(),
      eventTitle: (
        json['eventTitle'] ??
            json['event_title'] ??
            name
      ).toString(),
      memberCount: json['memberCount'] is int
          ? json['memberCount'] as int
          : int.tryParse(
                (json['memberCount'] ?? '').toString(),
              ) ??
              participants.length,
      participants: participants,
    );
  }
}