import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../core/app_config.dart';
import '../../core/session_manager.dart';

class SocketService {
  SocketService._internal();

  static final SocketService _instance = SocketService._internal();

  factory SocketService() => _instance;

  io.Socket? _socket;
  String _userId = '';

  io.Socket? get socket => _socket;

  bool get isConnected => _socket?.connected == true;

  // ─────────────────────────────────────────────────────────────
  // CONNECT
  // ─────────────────────────────────────────────────────────────

  void connect() {
  final currentUser = AuthSession.currentUser;

  _userId = (
    currentUser?['_id'] ??
    currentUser?['id'] ??
    currentUser?['userId'] ??
    ''
  ).toString().trim();

  if (_socket != null && _socket!.connected) {
    if (_userId.isNotEmpty) {
      _socket!.emit('user_online', _userId);
    }
    return;
  }

  _socket = io.io(
    AppConfig.socketBaseUrl,
    io.OptionBuilder()
        .setTransports(['websocket'])
        .enableReconnection()
        .setReconnectionAttempts(10)
        .setReconnectionDelay(1000)
        .disableAutoConnect()
        .build(),
  );

  _socket?.connect();

  _socket?.onConnect((_) {
    debugPrint('✅ Socket connected');

    if (_userId.isNotEmpty) {
      _socket?.emit('user_online', _userId);
      debugPrint('🟢 User online: $_userId');
    }
  });

  _socket?.onDisconnect((_) {
    debugPrint('❌ Socket disconnected');
  });

  _socket?.onConnectError((error) {
    debugPrint('❌ Socket connect error: $error');
  });

  _socket?.onError((error) {
    debugPrint('❌ Socket error: $error');
  });

  _socket?.onReconnect((_) {
    debugPrint('🔄 Socket reconnected');

    if (_userId.isNotEmpty) {
      _socket?.emit('user_online', _userId);
      debugPrint('🟢 User online after reconnect: $_userId');
    }
  });
}

  // ─────────────────────────────────────────────────────────────
  // DISCONNECT
  // ─────────────────────────────────────────────────────────────

  void disconnect() {
    removeAllListeners();

    _socket?.disconnect();
    _socket?.dispose();

    _socket = null;
  }

  // ─────────────────────────────────────────────────────────────
  // CHAT: JOIN ROOM
  // ─────────────────────────────────────────────────────────────

  void joinRoom(String threadId) {
    if (threadId.trim().isEmpty) {
      return;
    }

    _socket?.emit('join_room', threadId);

    debugPrint('📥 Joined room: $threadId');
  }

  // ─────────────────────────────────────────────────────────────
  // CHAT: SEND MESSAGE
  // ─────────────────────────────────────────────────────────────

  void sendMessage({
    required String threadId,
    required String senderId,
    required String message,
  }) {
    final trimmed = message.trim();

    if (threadId.isEmpty || senderId.isEmpty || trimmed.isEmpty) {
      return;
    }

    final payload = {
      'threadId': threadId,
      'senderId': senderId,
      'message': trimmed,
    };

    _socket?.emit('send_message', payload);

    debugPrint('📤 Sent message: $payload');
  }

  // ─────────────────────────────────────────────────────────────
  // CHAT: RECEIVE MESSAGE
  // ─────────────────────────────────────────────────────────────

  void onReceiveMessage(
    void Function(Map<String, dynamic> data) callback,
  ) {
    _socket?.off('receive_message');

    _socket?.on('receive_message', (data) {
      if (data is Map) {
        callback(Map<String, dynamic>.from(data));
      }
    });
  }

  // ─────────────────────────────────────────────────────────────
  // EVENTS: EVENTS UPDATED
  // ─────────────────────────────────────────────────────────────

  void onEventsUpdated(
    void Function(Map<String, dynamic> data) callback,
  ) {
    _socket?.off('events_updated');

    _socket?.on('events_updated', (data) {
      if (data is Map) {
        callback(Map<String, dynamic>.from(data));
      } else {
        callback({});
      }
    });
  }

  // ─────────────────────────────────────────────────────────────
  // CONTENT: CONTENT UPDATED
  // ─────────────────────────────────────────────────────────────

  void onContentUpdated(
    void Function(Map<String, dynamic> data) callback,
  ) {
    _socket?.off('content_updated');

    _socket?.on('content_updated', (data) {
      if (data is Map) {
        callback(Map<String, dynamic>.from(data));
      } else {
        callback({});
      }
    });
  }

  void onUserStatusChanged(
  void Function(Map<String, dynamic> data) callback,
) {
  void removeAllListeners() {
  removeChatListeners();
  removeEventListeners();
  removeContentListeners();
  _socket?.off('user_status_changed');
}

  _socket?.on('user_status_changed', (data) {
    if (data is Map) {
      callback(Map<String, dynamic>.from(data));
    }
  });
}

  // ─────────────────────────────────────────────────────────────
  // REMOVE LISTENERS
  // ─────────────────────────────────────────────────────────────

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
    removeChatListeners();
    removeEventListeners();
    removeContentListeners();
  }
}