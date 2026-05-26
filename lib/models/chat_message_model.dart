class ChatMessageModel {
  final String id;
  final String threadId;
  final String senderId;
  final String message;
  final DateTime? createdAt;

  final String messageType;
  final String fileUrl;
  final String fileName;
  final String fileType;
  final int fileSize;

  const ChatMessageModel({
    required this.id,
    required this.threadId,
    required this.senderId,
    required this.message,
    required this.createdAt,
    required this.messageType,
    required this.fileUrl,
    required this.fileName,
    required this.fileType,
    required this.fileSize,
  });

  bool get isFile {
    return messageType == 'file' || messageType == 'image';
  }

 bool get isImage {
  final lowerName = fileName.toLowerCase();
  final lowerUrl = fileUrl.toLowerCase();
  final lowerType = fileType.toLowerCase();

  return messageType.toLowerCase() == 'image' ||
      lowerType.startsWith('image/') ||
      lowerName.endsWith('.jpg') ||
      lowerName.endsWith('.jpeg') ||
      lowerName.endsWith('.png') ||
      lowerName.endsWith('.gif') ||
      lowerName.endsWith('.webp') ||
      lowerUrl.endsWith('.jpg') ||
      lowerUrl.endsWith('.jpeg') ||
      lowerUrl.endsWith('.png') ||
      lowerUrl.endsWith('.gif') ||
      lowerUrl.endsWith('.webp');
}

  static String _readId(dynamic value) {
    if (value == null) return '';

    if (value is Map) {
      return (
        value['_id'] ??
            value['id'] ??
            value[r'$oid'] ??
            ''
      ).toString().trim();
    }

    return value.toString().trim();
  }

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    final rawSender =
        json['senderId'] ??
            json['sender_id'] ??
            json['sender'] ??
            json['userId'] ??
            json['user_id'] ??
            '';

    final rawThread =
        json['threadId'] ??
            json['thread_id'] ??
            json['thread'] ??
            '';

    final rawDate =
        json['createdAt'] ??
            json['created_at'] ??
            json['updatedAt'] ??
            json['updated_at'];

    return ChatMessageModel(
      id: _readId(
        json['_id'] ??
            json['id'] ??
            '',
      ),
      threadId: _readId(rawThread),
      senderId: _readId(rawSender),
      message: (
        json['message'] ??
            json['text'] ??
            ''
      ).toString(),
      createdAt: rawDate != null
          ? DateTime.tryParse(rawDate.toString())
          : null,
      messageType: (
        json['messageType'] ??
            json['message_type'] ??
            'text'
      ).toString(),
      fileUrl: (
        json['fileUrl'] ??
            json['file_url'] ??
            ''
      ).toString(),
      fileName: (
        json['fileName'] ??
            json['file_name'] ??
            ''
      ).toString(),
      fileType: (
        json['fileType'] ??
            json['file_type'] ??
            ''
      ).toString(),
      fileSize: json['fileSize'] is int
          ? json['fileSize'] as int
          : int.tryParse(
                (
                  json['fileSize'] ??
                      json['file_size'] ??
                      '0'
                ).toString(),
              ) ??
              0,
    );
  }
}