import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;

  SocketService._internal();

  io.Socket? socket;

  void connect() {
    if (socket != null && socket!.connected) return; // ✅ prevent duplicate

    socket = io.io(
      'http://10.0.2.2:5000',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect() // ✅ use manual connect
          .build(),
    );

    socket!.connect(); // ✅ single connection

    socket!.onConnect((_) {
      debugPrint('✅ Connected to socket');
    });

    socket!.onDisconnect((_) {
      debugPrint('❌ Disconnected from socket');
    });

    socket!.on('content_updated', (data) {
      debugPrint('📡 RAW SOCKET EVENT: $data');
    });
  }

  void listenContentUpdate(Function(dynamic) callback) {
    socket?.off('content_updated'); // ✅ prevent duplicate listeners
    socket?.on('content_updated', callback);
  }

  void removeContentUpdateListener() {
    socket?.off('content_updated');
  }

  void dispose() {
    socket?.disconnect(); // safer than dispose
    socket = null;
  }
}