import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as io;

import 'package:ramhis_app/core/app_config.dart';
import 'package:ramhis_app/core/session_manager.dart';
import 'package:ramhis_app/models/chat_message_model.dart';
import 'package:ramhis_app/services/api/chat_service.dart';

class ChatRoomWidget extends StatefulWidget {
  const ChatRoomWidget({
    super.key,
    required this.threadId,
    required this.threadTitle,
  });

  final String threadId;
  final String threadTitle;

  @override
  State<ChatRoomWidget> createState() =>
      _ChatRoomWidgetState();
}

class _ChatRoomWidgetState
    extends State<ChatRoomWidget> {
  final TextEditingController _controller =
      TextEditingController();

  final ScrollController _scrollController =
      ScrollController();

  final ChatService _chatService =
      ChatService();

  late io.Socket socket;

  bool isLoading = true;
  bool isSending = false;
  bool _socketInitialized = false;

  String currentUserId = '';

  List<ChatMessageModel> messages = [];

  @override
  void initState() {
    super.initState();

    _loadCurrentUser();
    _loadMessages();
    _initSocket();
  }

  @override
  void dispose() {
    if (_socketInitialized) {
      socket.off('receive_message');
      socket.disconnect();
      socket.dispose();
    }

    _controller.dispose();
    _scrollController.dispose();

    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final response = await http.get(
        Uri.parse(
          '${AppConfig.baseUrl}/me',
        ),
        headers: AuthSession.headers(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)
            as Map<String, dynamic>;

        currentUserId =
            (data['_id'] ?? '')
                .toString();
      }
    } catch (error) {
      debugPrint(
        '❌ Failed to load current user: $error',
      );
    }
  }

  void _initSocket() {
    socket = io.io(
  AppConfig.socketBaseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    _socketInitialized = true;

    socket.connect();

    socket.onConnect((_) {
      debugPrint('✅ Socket connected');

      socket.emit(
        'join_room',
        widget.threadId,
      );
    });

    socket.on(
      'receive_message',
      (data) {
        if (!mounted || data is! Map) {
          return;
        }

        final incoming =
            ChatMessageModel.fromJson(
          Map<String, dynamic>.from(data),
        );

        final alreadyExists =
            messages.any(
          (m) =>
              m.senderId ==
                  incoming.senderId &&
              m.message ==
                  incoming.message &&
              m.createdAt ==
                  incoming.createdAt,
        );

        if (alreadyExists) {
          return;
        }

        setState(() {
          messages.add(incoming);
        });

        _scrollToBottom();
      },
    );

    socket.onDisconnect((_) {
      debugPrint(
        '❌ Socket disconnected',
      );
    });
  }

  Future<void> _loadMessages() async {
    if (!mounted) return;

    setState(() => isLoading = true);

    try {
      final data =
          await _chatService.getMessages(
        widget.threadId,
      );

      if (!mounted) return;

      setState(() {
        messages = data;
        isLoading = false;
      });

      _scrollToBottom();
    } catch (error) {
      debugPrint(
        '❌ Failed to load messages: $error',
      );

      if (!mounted) return;

      setState(() {
        messages = [];
        isLoading = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    final text =
        _controller.text.trim();

    if (text.isEmpty || isSending) {
      return;
    }

    setState(() => isSending = true);

    try {
      final success =
          await _chatService.sendMessage(
        threadId: widget.threadId,
        message: text,
      );

      if (success) {
        socket.emit(
          'send_message',
          {
            'threadId':
                widget.threadId,
            'senderId':
                currentUserId,
            'message': text,
          },
        );

        _controller.clear();

        await _loadMessages();

        _scrollToBottom();
      }
    } catch (error) {
      debugPrint(
        '❌ Failed to send message: $error',
      );
    }

    if (!mounted) return;

    setState(() => isSending = false);
  }

  void _scrollToBottom() {
    Future.delayed(
      const Duration(milliseconds: 100),
      () {
        if (!_scrollController
            .hasClients) {
          return;
        }

        _scrollController.animateTo(
          _scrollController
              .position.maxScrollExtent,
          duration: const Duration(
            milliseconds: 300,
          ),
          curve: Curves.easeOut,
        );
      },
    );
  }

  bool _isMine(
    ChatMessageModel msg,
  ) {
    return msg.senderId ==
        currentUserId;
  }

  String _formatTime(String raw) {
    if (raw.isEmpty) {
      return '';
    }

    try {
      final parsed =
          DateTime.parse(raw)
              .toLocal();

      final hour = parsed.hour == 0
          ? 12
          : parsed.hour > 12
              ? parsed.hour - 12
              : parsed.hour;

      final minute = parsed.minute
          .toString()
          .padLeft(2, '0');

      final suffix =
          parsed.hour >= 12
              ? 'PM'
              : 'AM';

      return '$hour:$minute $suffix';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFF3E5EBE),

      appBar: AppBar(
        backgroundColor:
            const Color(0xFF4766C7),

        elevation: 0,

        iconTheme:
            const IconThemeData(
          color: Colors.white,
        ),

        title: Text(
          widget.threadTitle,
          style: const TextStyle(
            color: Colors.white,
          ),
        ),

        actions: [
          IconButton(
            onPressed: _loadMessages,
            icon: const Icon(
              Icons.refresh,
              color: Colors.white,
            ),
          ),
        ],
      ),

      body: Column(
        children: [
          Expanded(
            child: isLoading
                ? const Center(
                    child:
                        CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  )
                : messages.isEmpty
                    ? const Center(
                        child: Text(
                          'No messages yet.',
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller:
                            _scrollController,
                        padding:
                            const EdgeInsets.all(
                          12,
                        ),
                        itemCount:
                            messages.length,
                        itemBuilder:
                            (
                              context,
                              index,
                            ) {
                              final msg =
                                  messages[index];

                              final isMine =
                                  _isMine(msg);

                              return Align(
                                alignment:
                                    isMine
                                        ? Alignment
                                            .centerRight
                                        : Alignment
                                            .centerLeft,

                                child: Container(
                                  margin:
                                      const EdgeInsets.symmetric(
                                    vertical: 6,
                                  ),

                                  padding:
                                      const EdgeInsets.all(
                                    12,
                                  ),

                                  constraints:
                                      const BoxConstraints(
                                    maxWidth: 260,
                                  ),

                                  decoration:
                                      BoxDecoration(
                                    color:
                                        isMine
                                            ? const Color(
                                                0xFFD95362,
                                              )
                                            : const Color(
                                                0xFFE8F0FF,
                                              ),

                                    borderRadius:
                                        BorderRadius.circular(
                                      18,
                                    ),
                                  ),

                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .end,

                                    children: [
                                      Align(
                                        alignment:
                                            Alignment
                                                .centerLeft,

                                        child: Text(
                                          msg.message,

                                          style:
                                              TextStyle(
                                            color:
                                                isMine
                                                    ? Colors.white
                                                    : Colors.black87,
                                          ),
                                        ),
                                      ),

                                      const SizedBox(
                                        height: 6,
                                      ),

                                      Text(
                                        _formatTime(
                                          msg.createdAt
                                              .toString(),
                                        ),

                                        style:
                                            TextStyle(
                                          fontSize:
                                              11,

                                          color:
                                              isMine
                                                  ? Colors.white70
                                                  : const Color(
                                                      0xFF6B7280,
                                                    ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                      ),
          ),

          Container(
            padding:
                const EdgeInsets.all(10),

            color:
                const Color(0xFF4766C7),

            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller:
                        _controller,

                    minLines: 1,
                    maxLines: 4,

                    textInputAction:
                        TextInputAction
                            .newline,

                    style:
                        const TextStyle(
                      color: Colors.white,
                    ),

                    decoration:
                        InputDecoration(
                      hintText:
                          'Type a message...',

                      hintStyle:
                          const TextStyle(
                        color: Color(
                          0xFFEAF0FF,
                        ),
                      ),

                      filled: true,
                      fillColor:
                          const Color(
                        0xFF5B76D1,
                      ),

                      contentPadding:
                          const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),

                      border:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(
                          20,
                        ),
                        borderSide:
                            BorderSide.none,
                      ),

                      enabledBorder:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(
                          20,
                        ),
                        borderSide:
                            BorderSide.none,
                      ),

                      focusedBorder:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(
                          20,
                        ),
                        borderSide:
                            const BorderSide(
                          color:
                              Colors.white24,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                Container(
                  decoration:
                      const BoxDecoration(
                    color: Color(
                      0xFFD95362,
                    ),
                    shape: BoxShape.circle,
                  ),

                  child: IconButton(
                    onPressed:
                        isSending
                            ? null
                            : _sendMessage,

                    icon:
                        isSending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth:
                                      2,
                                  color:
                                      Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.send,
                                color:
                                    Colors.white,
                              ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}