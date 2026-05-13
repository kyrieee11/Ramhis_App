import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../core/app_config.dart';

class SocketService {
  io.Socket? _socket;

  io.Socket? get socket => _socket;

  bool get isConnected => _socket?.connected == true;

  // ── Connect ────────────────────────────────────────────────────────────────
  void connect() {
    if (_socket != null && _socket!.connected) return;

    _socket = io.io(
      AppConfig.baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    _socket!.connect();
  }

  // ── Disconnect ─────────────────────────────────────────────────────────────
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  // ── Chat: join_room ────────────────────────────────────────────────────────
  void joinRoom(String threadId) {
    if (threadId.isEmpty) return;

    _socket?.emit('join_room', threadId);
  }

  // ── Chat: send_message ─────────────────────────────────────────────────────
  void sendMessage({
    required String threadId,
    required String senderId,
    required String message,
  }) {
    if (threadId.isEmpty || message.trim().isEmpty) return;

    _socket?.emit('send_message', {
      'threadId': threadId,
      'senderId': senderId,
      'message': message.trim(),
    });
  }

  // ── Chat: receive_message ──────────────────────────────────────────────────
  void onReceiveMessage(void Function(Map<String, dynamic> data) callback) {
    _socket?.off('receive_message');

    _socket?.on('receive_message', (data) {
      if (data is Map) {
        callback(Map<String, dynamic>.from(data));
      }
    });
  }

  // ── Events: events_updated ─────────────────────────────────────────────────
  void onEventsUpdated(void Function(Map<String, dynamic> data) callback) {
    _socket?.off('events_updated');

    _socket?.on('events_updated', (data) {
      if (data is Map) {
        callback(Map<String, dynamic>.from(data));
      }
    });
  }

  // ── Content: content_updated ───────────────────────────────────────────────
  void onContentUpdated(void Function(Map<String, dynamic> data) callback) {
    _socket?.off('content_updated');

    _socket?.on('content_updated', (data) {
      if (data is Map) {
        callback(Map<String, dynamic>.from(data));
      }
    });
  }

  // ── Remove listeners ───────────────────────────────────────────────────────
  void removeChatListeners() {
    _socket?.off('receive_message');
  }

  void removeEventListeners() {
    _socket?.off('events_updated');
  }

  void removeContentListeners() {
    _socket?.off('content_updated');
  }

  void removeAllListeners() {
    _socket?.off('receive_message');
    _socket?.off('events_updated');
    _socket?.off('content_updated');
  }
}