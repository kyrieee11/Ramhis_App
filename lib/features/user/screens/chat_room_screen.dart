import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import 'package:ramhis_app/core/app_config.dart';
import 'package:ramhis_app/core/session_manager.dart';
import 'package:ramhis_app/core/online_status_manager.dart';
import 'package:ramhis_app/models/chat_message_model.dart';
import 'package:ramhis_app/services/api/chat_service.dart';

class ChatRoomWidget extends StatefulWidget {
  const ChatRoomWidget({
    super.key,
    required this.threadId,
    required this.threadTitle,
    this.otherUserId = '',
    this.isOnline = false,
    this.lastSeen = '',
  });

  final String threadId;
  final String threadTitle;
  final String otherUserId;
  final bool isOnline;
  final String lastSeen;

  @override
  State<ChatRoomWidget> createState() => _ChatRoomWidgetState();
}

class _ChatRoomWidgetState extends State<ChatRoomWidget> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();

  late io.Socket socket;

  bool isLoading = true;
  bool isSending = false;
  bool isUploadingFile = false;
  bool _socketInitialized = false;
  bool _showScrollToBottom = false;

  bool otherUserOnline = false;
  DateTime? otherUserLastSeen;

  String currentUserId = '';

  List<ChatMessageModel> messages = [];

  @override
  void initState() {
    super.initState();

    otherUserOnline = widget.isOnline;

    if (widget.lastSeen.trim().isNotEmpty) {
      otherUserLastSeen = DateTime.tryParse(widget.lastSeen);
    }

    if (widget.otherUserId.trim().isNotEmpty) {
      OnlineStatusManager.setStatus(
        widget.otherUserId,
        widget.isOnline,
        otherUserLastSeen,
      );
    }

    _initSocket();
    _loadCurrentUserThenMessages();
  }

  @override
  void dispose() {
    if (_socketInitialized) {
      socket
        ..off('receive_message')
        ..off('user_status_changed')
        ..disconnect()
        ..dispose();
    }
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUserThenMessages() async {
    await _loadCurrentUser();
    await _loadMessages();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final localUser = AuthSession.currentUser;
      final localId = (
        localUser?['_id'] ??
        localUser?['id'] ??
        localUser?['userId'] ??
        ''
      ).toString().trim();

      if (localId.isNotEmpty) {
        currentUserId = localId;
        debugPrint('✅ Current user from session: $currentUserId');
        return;
      }

      final possibleUrls = [
        '${AppConfig.baseUrl}/auth/me',
        '${AppConfig.baseUrl}/me',
        '${AppConfig.baseUrl}/users/me',
      ];

      for (final url in possibleUrls) {
        final response = await http.get(
          Uri.parse(url),
          headers: AuthSession.headers(),
        );

        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body);
          final user = decoded is Map<String, dynamic>
              ? (decoded['user'] ?? decoded['data'] ?? decoded)
              : null;

          if (user is Map<String, dynamic>) {
            final id = (
              user['_id'] ??
              user['id'] ??
              user['userId'] ??
              ''
            ).toString().trim();

            if (id.isNotEmpty) {
              currentUserId = id;
              debugPrint('✅ Current user loaded from API: $currentUserId');
              return;
            }
          }
        }
      }

      debugPrint('⚠️ Current user ID could not be resolved.');
    } catch (e) {
      debugPrint('❌ Failed to load current user: $e');
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
      socket.emit('join_room', widget.threadId);
    });

    socket.on('receive_message', (data) {
      if (!mounted || data is! Map) return;

      final incoming = ChatMessageModel.fromJson(
        Map<String, dynamic>.from(data),
      );

      final alreadyExists = messages.any((m) =>
          m.senderId == incoming.senderId &&
          m.message == incoming.message &&
          m.createdAt == incoming.createdAt);

      if (alreadyExists) return;

      setState(() => messages.add(incoming));
      _scrollToBottom();
    });

    socket.on('user_status_changed', (data) {
      if (data is! Map) return;

      final changedUserId = data['userId']?.toString() ?? '';
      final isOnline = data['isOnline'] == true;
      final lastSeenString = data['lastSeen']?.toString();

      final parsedLastSeen = lastSeenString != null
          ? DateTime.tryParse(lastSeenString)
          : null;

      OnlineStatusManager.setStatus(
        changedUserId,
        isOnline,
        parsedLastSeen,
      );

      if (changedUserId == widget.otherUserId && mounted) {
        setState(() {
          otherUserOnline = isOnline;
          otherUserLastSeen = parsedLastSeen;
        });
      }
    });

    socket.onDisconnect((_) => debugPrint('❌ Socket disconnected'));
  }

  Future<void> _loadMessages() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final data = await _chatService.getMessages(widget.threadId);
      if (!mounted) return;
      setState(() {
        messages = data;
        isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      debugPrint('❌ Failed to load messages: $e');
      if (!mounted) return;
      setState(() {
        messages = [];
        isLoading = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || isSending) return;

    setState(() => isSending = true);

    try {
      final success = await _chatService.sendMessage(
        threadId: widget.threadId,
        message: text,
      );

      if (success) {
        socket.emit('send_message', {
          'threadId': widget.threadId,
          'senderId': currentUserId,
          'message': text,
        });

        _controller.clear();
        await _loadMessages();
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('❌ Failed to send message: $e');
    }

    if (!mounted) return;
    setState(() => isSending = false);
  }

  Future<void> _pickAndSendFile() async {
    if (isUploadingFile || isSending) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.any,
      );

      if (result == null || result.files.isEmpty) return;

      final filePath = result.files.single.path;

      if (filePath == null || filePath.isEmpty) {
        if (!mounted) return;
        _showSnack('Unable to read selected file.');
        return;
      }

      if (!mounted) return;
      setState(() => isUploadingFile = true);

      final caption = _controller.text.trim();
      final uploaded = await _chatService.sendFileMessage(
        threadId: widget.threadId,
        filePath: filePath,
        message: caption,
      );

      if (!mounted) return;

      if (uploaded == null) {
        _showSnack('Failed to send file.');
        return;
      }

      _controller.clear();
      await _loadMessages();
      _scrollToBottom();
    } catch (e) {
      debugPrint('❌ Failed to send file: $e');
      if (!mounted) return;
      _showSnack('Failed to send file: $e');
    } finally {
      if (mounted) setState(() => isUploadingFile = false);
    }
  }

  String _absoluteFileUrl(String rawUrl) {
    final url = rawUrl.trim();
    if (url.isEmpty) return '';

    if (url.startsWith('http://localhost') &&
        AppConfig.baseUrl.contains('10.0.2.2')) {
      return url.replaceFirst('http://localhost', 'http://10.0.2.2');
    }

    if (url.startsWith('http://127.0.0.1') &&
        AppConfig.baseUrl.contains('10.0.2.2')) {
      return url.replaceFirst('http://127.0.0.1', 'http://10.0.2.2');
    }

    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    if (url.startsWith('/')) return '${AppConfig.baseUrl}$url';
    return '${AppConfig.baseUrl}/$url';
  }

  Future<void> _openFile(ChatMessageModel msg) async {
    final fileUrl = _absoluteFileUrl(msg.fileUrl);
    if (fileUrl.isEmpty) return;

    try {
      final opened = await launchUrl(
        Uri.parse(fileUrl),
        mode: LaunchMode.externalApplication,
      );
      if (!opened && mounted) _showSnack('Unable to open file.');
    } catch (e) {
      debugPrint('❌ Failed to open file: $e');
      if (mounted) _showSnack('Unable to open file.');
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  bool _handleScrollNotification(ScrollNotification n) {
    if (n.metrics.axis != Axis.vertical) return false;
    final shouldShow = n.metrics.pixels < n.metrics.maxScrollExtent - 180;
    if (shouldShow != _showScrollToBottom && mounted) {
      setState(() => _showScrollToBottom = shouldShow);
    }
    return false;
  }

  String _normalizeId(dynamic value) {
    if (value == null) return '';
    if (value is Map) {
      return (value['_id'] ?? value['id'] ?? value[r'$oid'] ?? '')
          .toString()
          .trim();
    }
    return value.toString().trim();
  }

  bool _isMine(ChatMessageModel msg) {
    final senderId = _normalizeId(msg.senderId);
    final myId = _normalizeId(currentUserId);
    if (senderId.isEmpty || myId.isEmpty) return false;
    return senderId == myId;
  }

  String _formatTime(String raw) {
    if (raw.isEmpty) return '';
    try {
      final dt = DateTime.parse(raw).toLocal();
      final h = dt.hour == 0 ? 12 : dt.hour > 12 ? dt.hour - 12 : dt.hour;
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m ${dt.hour >= 12 ? 'PM' : 'AM'}';
    } catch (_) {
      return '';
    }
  }

  Color _avatarColor(String name) {
    final c = name.trim().isEmpty ? 'A' : name.trim()[0].toUpperCase();
    if ('ABCDE'.contains(c)) return const Color(0xFFF44336);
    if ('FGHIJ'.contains(c)) return const Color(0xFF9C27B0);
    if ('KLMNO'.contains(c)) return const Color(0xFF2196F3);
    if ('PQRST'.contains(c)) return const Color(0xFF4CAF50);
    return const Color(0xFFFF9800);
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  Color _senderRoleColor() {
    final lower = widget.threadTitle.toLowerCase();
    if (lower.contains('dr.') || lower.contains('doctor')) {
      return const Color(0xFF1976D2);
    }
    if (lower.contains('pharma')) return const Color(0xFF7B1FA2);
    if (lower.contains('admin')) return const Color(0xFFD32F2F);
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

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _shouldShowDateSeparator(int index) {
    if (index == 0) return true;
    final curr = _parseDate(messages[index].createdAt.toString());
    final prev = _parseDate(messages[index - 1].createdAt.toString());
    if (curr == null || prev == null) return false;
    return !_sameDay(curr, prev);
  }

  String _dateLabel(String raw) {
    final date = _parseDate(raw);
    if (date == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);

    if (day == today) return 'Today';
    if (day == today.subtract(const Duration(days: 1))) return 'Yesterday';

    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _statusText() {
    if (widget.otherUserId.trim().isEmpty) {
      return otherUserOnline ? 'Online' : 'Offline';
    }

    return OnlineStatusManager.getLastSeen(widget.otherUserId);
  }

  Color _statusColor() {
    return otherUserOnline
        ? const Color(0xFF22C55E)
        : const Color(0xFFEAF0FF);
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canSend = _controller.text.trim().isNotEmpty &&
        !isSending &&
        !isUploadingFile;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3949AB),
        elevation: 0,
        toolbarHeight: 72,
        iconTheme: const IconThemeData(color: Colors.white),
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
                      color: otherUserOnline
                          ? const Color(0xFF22C55E)
                          : const Color(0xFF9CA3AF),
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
                  Text(
                    _statusText(),
                    style: TextStyle(
                      color: _statusColor(),
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
            icon: const Icon(Icons.videocam_rounded, color: Colors.white),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.call_rounded, color: Colors.white),
          ),
          IconButton(
            onPressed: _loadMessages,
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
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
                              padding: const EdgeInsets.fromLTRB(14, 16, 14, 20),
                              itemCount: messages.length,
                              itemBuilder: (context, index) {
                                final msg = messages[index];
                                return Column(
                                  children: [
                                    if (_shouldShowDateSeparator(index))
                                      _buildDateSeparator(
                                        _dateLabel(msg.createdAt.toString()),
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
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.76,
        ),
        child: Column(
          crossAxisAlignment:
              isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMine)
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
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
              child: msg.isFile
                  ? _buildFileMessageContent(msg, isMine)
                  : Text(
                      msg.message,
                      style: TextStyle(
                        color: isMine
                            ? Colors.white
                            : const Color(0xFF2D2363),
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
                  _formatTime(msg.createdAt.toString()),
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

  Widget _buildFileMessageContent(ChatMessageModel msg, bool isMine) {
    final fileUrl = _absoluteFileUrl(msg.fileUrl);
    final fileName = msg.fileName.trim().isNotEmpty
        ? msg.fileName.trim()
        : 'Attachment';
    final fileSize = _formatFileSize(msg.fileSize);

    if (msg.isImage && fileUrl.isNotEmpty) {
      return Column(
        crossAxisAlignment:
            isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: GestureDetector(
              onTap: () => _openFile(msg),
              child: Image.network(
                fileUrl,
                width: 220,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    width: 220,
                    height: 150,
                    alignment: Alignment.center,
                    color: Colors.black.withOpacity(0.06),
                    child: const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                },
                errorBuilder: (_, __, ___) => Container(
                  width: 220,
                  height: 140,
                  alignment: Alignment.center,
                  color: Colors.black.withOpacity(0.06),
                  child: const Icon(Icons.broken_image_rounded, size: 36),
                ),
              ),
            ),
          ),
          if (msg.message.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              msg.message,
              style: TextStyle(
                color: isMine ? Colors.white : const Color(0xFF2D2363),
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
            ),
          ],
        ],
      );
    }

    return InkWell(
      onTap: () => _openFile(msg),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        constraints: const BoxConstraints(minWidth: 210),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMine
              ? Colors.white.withOpacity(0.12)
              : const Color(0xFFF1F3FA),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isMine
                ? Colors.white.withOpacity(0.22)
                : const Color(0xFFE1E5F3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isMine
                    ? Colors.white.withOpacity(0.18)
                    : const Color(0xFF3949AB).withOpacity(0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.insert_drive_file_rounded,
                color: isMine ? Colors.white : const Color(0xFF3949AB),
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isMine
                          ? Colors.white
                          : const Color(0xFF2D2363),
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    fileSize.isEmpty
                        ? 'Tap to open'
                        : '$fileSize • Tap to open',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isMine
                          ? Colors.white.withOpacity(0.78)
                          : const Color(0xFF7B739A),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (msg.message.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      msg.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isMine
                            ? Colors.white
                            : const Color(0xFF2D2363),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
            top: BorderSide(color: Colors.black.withOpacity(0.06)),
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
              onPressed: isUploadingFile ? null : _pickAndSendFile,
              icon: isUploadingFile
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF3949AB),
                      ),
                    )
                  : const Icon(
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
                  if (mounted) setState(() {});
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
                    borderSide:
                        const BorderSide(color: Color(0xFFCAD0EA)),
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

  Widget _skeletonBubble({required bool isMine, required double width}) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.35, end: 1),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOut,
        builder: (_, value, child) => Opacity(opacity: value, child: child),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          width: width,
          height: 52,
          decoration: BoxDecoration(
            color: isMine ? const Color(0xFFD9DFF8) : Colors.white,
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