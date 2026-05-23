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
  bool _showScrollToBottom = false;

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

  Color _avatarColor(String name) {
    final first = name.trim().isEmpty ? 'A' : name.trim()[0].toUpperCase();

    if ('ABCDE'.contains(first)) {
      return const Color(0xFFF44336);
    }

    if ('FGHIJ'.contains(first)) {
      return const Color(0xFF9C27B0);
    }

    if ('KLMNO'.contains(first)) {
      return const Color(0xFF2196F3);
    }

    if ('PQRST'.contains(first)) {
      return const Color(0xFF4CAF50);
    }

    return const Color(0xFFFF9800);
  }

  String _initials(String name) {
    final cleanName = name.trim();

    if (cleanName.isEmpty) return '?';

    final parts = cleanName.split(RegExp(r'\s+'));

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  Color _senderRoleColor() {
    final lower = widget.threadTitle.toLowerCase();

    if (lower.contains('dr.') || lower.contains('doctor')) {
      return const Color(0xFF1976D2);
    }

    if (lower.contains('pharma')) {
      return const Color(0xFF7B1FA2);
    }

    if (lower.contains('admin')) {
      return const Color(0xFFD32F2F);
    }

    return const Color(0xFF388E3C);
  }

  DateTime? _parseDate(String raw) {
    if (raw.isEmpty) return null;

    try {
      return DateTime.parse(raw).toLocal();
    } catch (_) {
      return null;
    }
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day;
  }

  bool _shouldShowDateSeparator(int index) {
    if (index == 0) return true;

    final current = _parseDate(messages[index].createdAt.toString());
    final previous = _parseDate(messages[index - 1].createdAt.toString());

    if (current == null || previous == null) {
      return false;
    }

    return !_sameDay(current, previous);
  }

  String _dateLabel(String raw) {
    final date = _parseDate(raw);

    if (date == null) return '';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDay = DateTime(date.year, date.month, date.day);

    if (messageDay == today) {
      return 'Today';
    }

    if (messageDay == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    }

    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) {
      return false;
    }

    final shouldShow =
        notification.metrics.pixels <
            notification.metrics.maxScrollExtent - 180;

    if (shouldShow != _showScrollToBottom && mounted) {
      setState(() {
        _showScrollToBottom = shouldShow;
      });
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final canSend =
        _controller.text.trim().isNotEmpty && !isSending;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3949AB),
        elevation: 0,
        toolbarHeight: 72,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: _avatarColor(widget.threadTitle),
                  child: Text(
                    _initials(widget.threadTitle),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Positioned(
                  right: -1,
                  bottom: -1,
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF3949AB),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.threadTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Online',
                    style: TextStyle(
                      color: Color(0xFFEAF0FF),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.videocam_rounded,
              color: Colors.white,
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.call_rounded,
              color: Colors.white,
            ),
          ),
          IconButton(
            onPressed: _loadMessages,
            icon: const Icon(
              Icons.refresh_rounded,
              color: Colors.white,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                isLoading
                    ? _buildLoadingBubbles()
                    : messages.isEmpty
                        ? _buildEmptyMessages()
                        : NotificationListener<ScrollNotification>(
                            onNotification: _handleScrollNotification,
                            child: ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.fromLTRB(
                                14,
                                16,
                                14,
                                20,
                              ),
                              itemCount: messages.length,
                              itemBuilder: (
                                context,
                                index,
                              ) {
                                final msg = messages[index];
                                final showSeparator =
                                    _shouldShowDateSeparator(index);

                                return Column(
                                  children: [
                                    if (showSeparator)
                                      _buildDateSeparator(
                                        _dateLabel(
                                          msg.createdAt.toString(),
                                        ),
                                      ),
                                    _buildMessageBubble(msg),
                                  ],
                                );
                              },
                            ),
                          ),
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: AnimatedScale(
                    scale: _showScrollToBottom ? 1 : 0,
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutBack,
                    child: AnimatedOpacity(
                      opacity: _showScrollToBottom ? 1 : 0,
                      duration: const Duration(milliseconds: 180),
                      child: Material(
                        color: const Color(0xFF3949AB),
                        shape: const CircleBorder(),
                        elevation: 4,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: _scrollToBottom,
                          child: const SizedBox(
                            width: 44,
                            height: 44,
                            child: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildInputBar(canSend),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessageModel msg) {
    final isMine = _isMine(msg);

    return Align(
      alignment:
          isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.76,
        ),
        child: Column(
          crossAxisAlignment:
              isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMine) ...[
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 4),
                child: Text(
                  widget.threadTitle,
                  style: TextStyle(
                    color: _senderRoleColor(),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 11,
              ),
              decoration: BoxDecoration(
                color: isMine ? const Color(0xFF3949AB) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isMine ? 18 : 4),
                  topRight: Radius.circular(isMine ? 4 : 18),
                  bottomLeft: const Radius.circular(18),
                  bottomRight: const Radius.circular(18),
                ),
                boxShadow: isMine
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
              ),
              child: Text(
                msg.message,
                style: TextStyle(
                  color: isMine ? Colors.white : const Color(0xFF2D2363),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.35,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(
                    msg.createdAt.toString(),
                  ),
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFF7B739A),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (isMine) ...[
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.done_rounded,
                    size: 14,
                    color: Color(0xFF7B739A),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSeparator(String label) {
    if (label.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFE2E6F5),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF7B739A),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputBar(bool canSend) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: Colors.black.withOpacity(0.06),
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 18,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: () {},
              icon: const Icon(
                Icons.attach_file_rounded,
                color: Color(0xFF7B739A),
              ),
            ),
            Expanded(
              child: TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 4,
                onChanged: (_) {
                  if (mounted) {
                    setState(() {});
                  }
                },
                textInputAction: TextInputAction.newline,
                style: const TextStyle(
                  color: Color(0xFF2D2363),
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: const TextStyle(
                    color: Color(0xFF7B739A),
                    fontWeight: FontWeight.w500,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF1F3FA),
                  suffixIcon: IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.emoji_emotions_outlined,
                      color: Color(0xFF7B739A),
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: const BorderSide(
                      color: Color(0xFFCAD0EA),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              decoration: BoxDecoration(
                color: canSend
                    ? const Color(0xFF3949AB)
                    : const Color(0xFFCBD2E1),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: canSend ? _sendMessage : null,
                icon: isSending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.arrow_upward_rounded,
                        color: Colors.white,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingBubbles() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 20, 14, 20),
      children: [
        _skeletonBubble(isMine: false, width: 220),
        _skeletonBubble(isMine: true, width: 180),
        _skeletonBubble(isMine: false, width: 260),
        _skeletonBubble(isMine: true, width: 210),
      ],
    );
  }

  Widget _skeletonBubble({
    required bool isMine,
    required double width,
  }) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.35, end: 1),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOut,
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: child,
          );
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          width: width,
          height: 52,
          decoration: BoxDecoration(
            color: isMine
                ? const Color(0xFFD9DFF8)
                : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(isMine ? 18 : 4),
              topRight: Radius.circular(isMine ? 4 : 18),
              bottomLeft: const Radius.circular(18),
              bottomRight: const Radius.circular(18),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyMessages() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                color: Color(0xFF3949AB),
                size: 42,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'No messages yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF2D2363),
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'Say hello! 👋',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF7B739A),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}