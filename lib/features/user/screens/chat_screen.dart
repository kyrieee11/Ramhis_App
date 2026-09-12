import 'dart:async';

import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import 'package:ramhis_app/core/app_config.dart';
import 'package:ramhis_app/core/session_manager.dart';
import 'package:ramhis_app/core/online_status_manager.dart';
import 'package:ramhis_app/features/user/screens/chat_room_screen.dart';
import 'package:ramhis_app/features/user/widgets/bottom_nav.dart';
import 'package:ramhis_app/models/chat_thread_model.dart';
import 'package:ramhis_app/services/api/chat_service.dart';

// ─────────────────────────────────────────────────────────────
// Constants
// ─────────────────────────────────────────────────────────────

const _kPrimary = Color(0xFF10539B);
const _kPrimaryDark = Color(0xFF1863B5);
const _kBlueAccent = Color(0xFF8EC1DA);
const _kBlueAccentLight = Color(0xFFE3F2FD);
const _kOnline = Color(0xFF22A06B);
const _kTextDark = Color(0xFF102A43);
const _kTextMid = Color(0xFF526579);
const _kBackground = Color(0xFFF8FAFC);
const _kCardShadowColor = Colors.black;
const _kDividerColor = Color(0xFFE2E8F0);
const _kMedBlue = Color(0xFF5D8FC8);
const _kLightBlue = Color(0xFFEBF3FA);
const _kGray = Color(0xFF8292A6);
const _kLightRed = Color(0xFFFFEFEF);
const _kMedRed = Color(0xFFE58B8B);
const _kDarkRed = Color(0xFFD95C5C);


// ─────────────────────────────────────────────────────────────
// Widget
// ─────────────────────────────────────────────────────────────

class ChatCopyWidget extends StatefulWidget {
  const ChatCopyWidget({super.key});
  

  @override
  State<ChatCopyWidget> createState() => _ChatCopyWidgetState();
}



class _ChatCopyWidgetState extends State<ChatCopyWidget> {
  // Keys & controllers
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final _chatService = ChatService();

  // Socket
  io.Socket? _socket;

  // Timers
  Timer? _searchDebounce;

  // State
  bool _isLoading = true;
  bool _isSearchingUsers = false;
  bool _isCreatingChat = false;
  String _searchQuery = '';
  List<ChatThreadModel> _threads = [];
  List<Map<String, dynamic>> _searchUsers = [];

  // ── Lifecycle ──────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    Future.microtask(_loadThreads);
    _connectSocket();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    _searchFocusNode.dispose();
    _socket
  ?..off('group_chat_created')
  ..off('user_status_changed')
  ..disconnect()
  ..dispose();
    super.dispose();
  }

  // ── Socket ─────────────────────────────────────────────────

  void _connectSocket() {
  _socket = io.io(
    AppConfig.socketBaseUrl,
    io.OptionBuilder()
        .setTransports(['websocket'])
        .disableAutoConnect()
        .build(),
  )..connect();

  _socket!
    ..onConnect((_) {
      debugPrint('✅ Socket connected');

      final userId =
          AuthSession.currentUser?['_id'] ??
          AuthSession.currentUser?['id'] ??
          '';

      if (userId.toString().isNotEmpty) {
        _socket?.emit(
          'user_online',
          userId.toString(),
        );
      }
    })
    ..onDisconnect(
      (_) => debugPrint('❌ Socket disconnected'),
    )
    ..on('group_chat_created', _onGroupChatCreated)
    ..on('user_status_changed', (data) {
      if (data is! Map) return;

      final userId =
          data['userId']?.toString() ?? '';

      final isOnline =
          data['isOnline'] == true;

      final lastSeenString =
          data['lastSeen']?.toString();

      final lastSeen =
          lastSeenString != null
              ? DateTime.tryParse(lastSeenString)
              : null;

      OnlineStatusManager.setStatus(
        userId,
        isOnline,
        lastSeen,
      );

      if (mounted) {
        setState(() {});
      }
    });
}
Future<void> _onGroupChatCreated(dynamic data) async {
  debugPrint('📦 group_chat_created: $data');

  if (!mounted) return;

  await _loadThreads();
}

  // ── Search ─────────────────────────────────────────────────

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (!mounted) return;
    setState(() => _searchQuery = query);

    _searchDebounce?.cancel();

    if (query.isEmpty) {
      setState(() {
        _searchUsers = [];
        _isSearchingUsers = false;
      });
      return;
    }

    _searchDebounce = Timer(const Duration(milliseconds: 350), () async {
      if (!mounted) return;
      setState(() => _isSearchingUsers = true);
      try {
        final users = await _chatService.searchApprovedUsers(query);
        if (!mounted) return;
        setState(() {
          _searchUsers = users;
          _isSearchingUsers = false;
        });
      } catch (e) {
        debugPrint('❌ User search failed: $e');
        if (!mounted) return;
        setState(() {
          _searchUsers = [];
          _isSearchingUsers = false;
        });
      }
    });
  }

  // ── Data ───────────────────────────────────────────────────

  Future<void> _loadThreads() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final data = await _chatService.getThreads();
      if (!mounted) return;
      setState(() {
        _threads = data;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Load threads failed: $e');
      if (!mounted) return;
      setState(() {
        _threads = [];
        _isLoading = false;
      });
    }
  }

  List<ChatThreadModel> get _filteredThreads {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return _threads;
    return _threads
        .where((t) =>
            t.displayName.toLowerCase().contains(q) ||
            t.lastMessage.toLowerCase().contains(q))
        .toList();
  }

  int get _totalUnread =>
      _threads.fold(0, (sum, t) => sum + t.unread);

  // ── Navigation ─────────────────────────────────────────────

  Future<void> _openThread(ChatThreadModel thread) async {
    if (thread.id.isEmpty) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatRoomWidget(
  threadId: thread.id,
  threadTitle: thread.displayName,
  otherUserId: thread.otherUserId,
  isOnline: thread.isOnline,
  lastSeen: thread.lastSeen,
),
      ),
    );
    if (mounted) await _loadThreads();
  }

  Future<void> _startChatWithUser(Map<String, dynamic> user) async {
    final userId = (user['_id'] ?? user['id'] ?? '').toString();
    final fullName = (user['full_name'] ?? user['name'] ?? 'Chat').toString();
    if (userId.isEmpty || _isCreatingChat) return;

    setState(() => _isCreatingChat = true);
    try {
      final result = await _chatService.createOrOpenDirectThread(userId);
      if (!mounted) return;
      setState(() => _isCreatingChat = false);

      if (result == null) {
        _showSnack('Unable to open chat.');
        return;
      }

      final threadId = (result['id'] ?? result['_id'] ?? '').toString();
      final threadName = (result['name'] ?? fullName).toString();

      if (threadId.isEmpty) {
        _showSnack('Invalid chat thread.');
        return;
      }

      _searchController.clear();
      await _loadThreads();
      if (!mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              ChatRoomWidget(threadId: threadId, threadTitle: threadName),
        ),
      );
      if (mounted) await _loadThreads();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isCreatingChat = false);
      _showSnack(e.toString());
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  // ── Helpers ────────────────────────────────────────────────

  /// Initials from a display name (max 2 chars).
  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'R';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  /// Background color keyed to the first letter of a name.
  Color _avatarColor(String name) {
    final c = name.trim().isEmpty ? 'A' : name.trim()[0].toUpperCase();
    if ('ABCDE'.contains(c)) return _kBlueAccent;
    if ('FGHIJ'.contains(c)) return _kMedBlue;
    if ('KLMNO'.contains(c)) return _kPrimary;
    if ('PQRST'.contains(c)) return _kPrimary;
    return _kMedRed;
  }

  /// Accent color for a role label.
  Color _roleColor(String role) {
    final r = role.toLowerCase();
    if (r.contains('doctor')) return _kPrimary;
    if (r.contains('volunteer')) return _kPrimary;
    if (r.contains('pharmacist')) return _kMedBlue;
    if (r.contains('admin')) return _kDarkRed;
    return _kPrimary;
  }

  /// Infer a role string from a display name.
  String _roleFromName(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('dr.') || lower.contains('doctor')) return 'Doctor';
    if (lower.contains('pharma')) return 'Pharmacist';
    if (lower.contains('admin')) return 'Admin';
    return 'Volunteer';
  }

  /// Human-readable timestamp: time today, "Yesterday", or m/d/yyyy.
  String _friendlyTime(String raw) {
    if (raw.isEmpty) return '';
    try {
      final dt = DateTime.parse(raw).toLocal();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final day = DateTime(dt.year, dt.month, dt.day);
      if (day == today) return _formatHHMM(dt);
      if (day == today.subtract(const Duration(days: 1))) return 'Yesterday';
      return '${dt.month}/${dt.day}/${dt.year}';
    } catch (_) {
      return raw;
    }
  }

  /// Format a DateTime as "h:mm AM/PM".
  String _formatHHMM(DateTime dt) {
    final h = dt.hour == 0 ? 12 : dt.hour > 12 ? dt.hour - 12 : dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m ${dt.hour >= 12 ? 'PM' : 'AM'}';
  }

  // ── Sub-widgets ────────────────────────────────────────────

  Widget _avatar({
    required String name,
    String userId = '',
    double size = 52,
    bool showOnline = true,
    bool isGroup = false,
  }) {
    final initials = _initials(name);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: isGroup
                  ? const [_kPrimary, _kMedBlue]
                  : const [_kPrimary, _kBlueAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: Colors.white,
              width: size >= 55 ? 2.5 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: _kPrimary.withValues(alpha: 0.16),
                blurRadius: 9,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: isGroup
              ? Icon(
                  Icons.groups_rounded,
                  color: Colors.white,
                  size: size >= 55 ? 29 : 22,
                )
              : Text(
                  initials,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: size >= 55 ? 18 : 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
        ),
        if (showOnline && !isGroup)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: size >= 55 ? 15 : 13,
              height: size >= 55 ? 15 : 13,
              decoration: BoxDecoration(
                color: OnlineStatusManager.isOnline(userId)
                    ? _kOnline
                    : _kTextMid,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _roleBadge(String role, {bool isGroup = false}) {
    final color = isGroup ? _kPrimary : _roleColor(role);
    final label = isGroup
        ? 'Group'
        : (role.isEmpty ? 'User' : role);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: isGroup
            ? _kLightBlue.withValues(alpha: 0.80)
            : color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isGroup
              ? _kMedBlue.withValues(alpha: 0.55)
              : color.withValues(alpha: 0.18),
        ),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: isGroup ? _kPrimary : color,
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final bool keyboardOpen =
        MediaQuery.of(context).viewInsets.bottom > 0;

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: _kBackground,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: RefreshIndicator(
                  color: _kPrimary,
                  backgroundColor: Colors.white,
                  onRefresh: _loadThreads,
                  child: Column(
                    children: [
                      if (_searchQuery.trim().isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _buildUserResults(),
                        const SizedBox(height: 4),
                      ],
                      Expanded(
                        child: _buildThreadList(),
                      ),
                    ],
                  ),
                ),
              ),
              if (!keyboardOpen)
                const CustomNavBar(currentIndex: 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 18, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_kPrimary, _kMedBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Messages',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 29,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        height: 1,
                      ),
                    ),
                    SizedBox(height: 7),
                    Text(
                      'RAMHIS Chat',
                      style: TextStyle(
                        color: _kLightBlue,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
              _headerIconButton(
                Icons.refresh_rounded,
                onTap: _loadThreads,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSearchBar(),
        ],
      ),
    );
  }

  Widget _unreadBadge() {
    return Container(
      constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: _kMedBlue,
        shape: BoxShape.circle,
      ),
      child: Text(
        _totalUnread > 99 ? '99+' : '$_totalUnread',
        style: const TextStyle(
          color: _kPrimary,
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _headerIconButton(IconData icon, {required VoidCallback onTap}) {
    return Material(
      color: Colors.white.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          width: 43,
          height: 43,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.38),
            ),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    final hasText = _searchQuery.trim().isNotEmpty;

    return AnimatedBuilder(
      animation: _searchFocusNode,
      builder: (context, _) {
        final focused = _searchFocusNode.hasFocus;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: focused
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.55),
              width: focused ? 1.6 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _kPrimary.withValues(alpha: 0.12),
                blurRadius: focused ? 14 : 9,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextFormField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            textInputAction: TextInputAction.search,
            style: const TextStyle(
              color: _kTextDark,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: 'Search people or messages...',
              hintStyle: const TextStyle(
                color: _kTextMid,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: _kPrimary,
                size: 20,
              ),
              suffixIcon: hasText
                  ? IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: _kTextMid,
                        size: 18,
                      ),
                      onPressed: _searchController.clear,
                    )
                  : null,
              filled: true,
              fillColor: Colors.transparent,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
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
                borderSide: BorderSide.none,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserResults() {
    if (_isSearchingUsers) {
      return _userResultsShell(
        child: const Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.3,
              color: _kPrimary,
            ),
          ),
        ),
      );
    }

    if (_searchUsers.isEmpty) {
      return _userResultsShell(
        constrained: false,
        child: const Row(
          children: [
            Icon(Icons.person_search_rounded, color: _kPrimary),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'No approved users found',
                style: TextStyle(
                  color: _kTextMid,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return _userResultsShell(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(4, 0, 4, 5),
              child: Text(
                'PEOPLE',
                style: TextStyle(
                  color: _kTextMid,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ),
            ..._searchUsers.map(_buildUserTile),
          ],
        ),
      ),
    );
  }

  Widget _userResultsShell({
    required Widget child,
    bool constrained = true,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      constraints: constrained
          ? const BoxConstraints(maxHeight: 220)
          : null,
      padding: const EdgeInsets.fromLTRB(13, 11, 13, 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kLightBlue),
        boxShadow: [
          BoxShadow(
            color: _kPrimary.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildUserTile(Map<String, dynamic> user) {
    final fullName =
        (user['full_name'] ?? user['name'] ?? 'User').toString();
    final accountType =
        (user['account_type'] ?? user['role'] ?? 'User').toString();
    final email = (user['email'] ?? accountType).toString();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: _isCreatingChat ? null : () => _startChatWithUser(user),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
          child: Row(
            children: [
              _avatar(
                name: fullName,
                userId: (user['_id'] ?? user['id'] ?? '').toString(),
                size: 42,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _kTextDark,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _kTextMid,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _roleBadge(accountType),
              const SizedBox(width: 8),
              _isCreatingChat
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _kPrimary,
                      ),
                    )
                  : const Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: _kTextMid,
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThreadList() {
    if (_isLoading) return _buildLoadingState();

    if (_filteredThreads.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 22),
      itemCount: _filteredThreads.length,
      separatorBuilder: (_, __) => const SizedBox(height: 1),
      itemBuilder: (_, i) => _buildChatTile(_filteredThreads[i]),
    );
  }

  Widget _buildChatTile(ChatThreadModel thread) {
    final hasUnread = thread.unread > 0;
    final displayName = thread.displayName;
    final isGroup = thread.isGroup;

    final role = isGroup
        ? 'Group • ${thread.memberCount} members'
        : _roleFromName(displayName);

    final preview = isGroup
        ? thread.lastMessage.isEmpty
            ? 'Group • ${thread.memberCount} members'
            : 'Group • ${thread.memberCount} members • ${thread.lastMessage}'
        : thread.lastMessage.isEmpty
            ? 'No messages yet'
            : 'You: ${thread.lastMessage}';

    final timestamp =
        _friendlyTime(thread.updatedAt?.toIso8601String() ?? '');

    return _PressableTile(
      onTap: () => _openThread(thread),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _openThread(thread),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 11,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: hasUnread
                    ? _kMedBlue.withValues(alpha: 0.85)
                    : _kLightBlue.withValues(alpha: 0.75),
                width: hasUnread ? 1.2 : 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: _kPrimary.withValues(alpha: 0.055),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _avatar(
                  name: displayName,
                  userId: thread.otherUserId,
                  size: 56,
                  showOnline: !isGroup,
                  isGroup: isGroup,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: _kTextDark,
                                fontSize: 15,
                                fontWeight: hasUnread
                                    ? FontWeight.w900
                                    : FontWeight.w800,
                              ),
                            ),
                          ),
                          if (timestamp.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Text(
                              timestamp,
                              style: TextStyle(
                                color: hasUnread
                                    ? _kPrimary
                                    : _kTextMid,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          _roleBadge(role, isGroup: isGroup),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              preview,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: hasUnread
                                    ? _kTextDark
                                    : _kTextMid,
                                fontSize: 11.8,
                                fontWeight: hasUnread
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (hasUnread) ...[
                  const SizedBox(width: 8),
                  Container(
                    constraints: const BoxConstraints(
                      minWidth: 22,
                      minHeight: 22,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: _kPrimary,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      thread.unread > 99
                          ? '99+'
                          : '${thread.unread}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ] else
                  const Padding(
                    padding: EdgeInsets.only(left: 5),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: _kTextMid,
                      size: 21,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 34, 18, 24),
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(26, 30, 26, 30),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_kPrimary, _kMedBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: _kPrimary.withValues(alpha: 0.16),
                blurRadius: 20,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.32),
                  ),
                ),
                child: const Icon(
                  Icons.forum_outlined,
                  color: Colors.white,
                  size: 34,
                ),
              ),
              const SizedBox(height: 17),
              const Text(
                'No conversations yet',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                'Search for an approved user above to start chatting.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _kLightBlue,
                  fontSize: 12.5,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 19),
              ElevatedButton.icon(
                onPressed: _searchFocusNode.requestFocus,
                icon: const Icon(Icons.edit_rounded, size: 17),
                label: const Text('Start New Chat'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: _kPrimary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 11,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 22),
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(height: 7),
      itemBuilder: (_, i) => _buildSkeletonTile(i),
    );
  }

  Widget _buildSkeletonTile(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.15, end: 0.75),
      duration: Duration(milliseconds: 700 + (index * 100)),
      curve: Curves.easeInOut,
      builder: (context, value, _) {
        final color =
            Color.lerp(_kLightBlue, _kBackground, value)!;

        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 13,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _kLightBlue),
          ),
          child: Row(
            children: [
              _skeletonBox(
                width: 56,
                height: 56,
                color: color,
                circle: true,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _skeletonBox(
                      width: double.infinity,
                      height: 14,
                      color: color,
                    ),
                    const SizedBox(height: 9),
                    _skeletonBox(
                      width: 190,
                      height: 11,
                      color: color,
                    ),
                    const SizedBox(height: 8),
                    _skeletonBox(
                      width: 105,
                      height: 10,
                      color: color,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _skeletonBox({
    required double width,
    required double height,
    required Color color,
    bool circle = false,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.circular(999),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Pressable tile wrapper
// ─────────────────────────────────────────────────────────────

class _PressableTile extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _PressableTile({required this.child, required this.onTap});

  @override
  State<_PressableTile> createState() => _PressableTileState();
}

class _PressableTileState extends State<_PressableTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOut,
      scale: _pressed ? 0.98 : 1.0,
      child: Listener(
        onPointerDown: (_) => setState(() => _pressed = true),
        onPointerUp: (_) => setState(() => _pressed = false),
        onPointerCancel: (_) => setState(() => _pressed = false),
        child: widget.child,
      ),
    );
  }
}
