import 'dart:async';

import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import 'package:ramhis_app/core/app_config.dart';
import 'package:ramhis_app/features/user/screens/chat_room_screen.dart';
import 'package:ramhis_app/features/user/widgets/bottom_nav.dart';
import 'package:ramhis_app/models/chat_thread_model.dart';
import 'package:ramhis_app/services/api/chat_service.dart';

// ─────────────────────────────────────────────────────────────
// Constants
// ─────────────────────────────────────────────────────────────

const _kPrimary = Color(0xFF5B76F7);
const _kPrimaryDark = Color(0xFF4564E8);
const _kOnline = Color(0xFF22C55E);
const _kTextDark = Color(0xFF1B2559);
const _kTextMid = Color(0xFF7B8BB2);
const _kBackground = Color(0xFFF0F2FF);
const _kCardShadowColor = Colors.black;
const _kDividerColor = Color(0xFFE3E7F4);

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
      ..disconnect()
      ..dispose();
    super.dispose();
  }

  // ── Socket ─────────────────────────────────────────────────

  void _connectSocket() {
    _socket = io.io(
      AppConfig.baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    )..connect();

    _socket!
      ..onConnect((_) => debugPrint('✅ Socket connected'))
      ..onDisconnect((_) => debugPrint('❌ Socket disconnected'))
      ..on('group_chat_created', _onGroupChatCreated);
  }

  Future<void> _onGroupChatCreated(dynamic data) async {
    if (!mounted) return;
    await _loadThreads();
    if (!mounted) return;

    final eventTitle = data is Map
        ? (data['eventTitle'] ?? data['event_title'] ?? 'the event').toString()
        : 'the event';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🎉 You joined $eventTitle group chat!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
    if ('ABCDE'.contains(c)) return const Color(0xFFF44336);
    if ('FGHIJ'.contains(c)) return const Color(0xFF9C27B0);
    if ('KLMNO'.contains(c)) return const Color(0xFF2196F3);
    if ('PQRST'.contains(c)) return const Color(0xFF4CAF50);
    return const Color(0xFFFF9800);
  }

  /// Accent color for a role label.
  Color _roleColor(String role) {
    final r = role.toLowerCase();
    if (r.contains('doctor')) return const Color(0xFF1976D2);
    if (r.contains('volunteer')) return const Color(0xFF388E3C);
    if (r.contains('pharmacist')) return const Color(0xFF7B1FA2);
    if (r.contains('admin')) return const Color(0xFFD32F2F);
    return const Color(0xFF6B4EFF);
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
    double size = 52,
    bool showOnline = true,
    bool isGroup = false,
  }) {
    final bg = isGroup ? _kPrimary : _avatarColor(name);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: bg.withValues(alpha: 0.25),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: isGroup
              ? Icon(Icons.groups_rounded,
                  color: Colors.white, size: size >= 50 ? 28 : 22)
              : Text(
                  _initials(name),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: size >= 50 ? 18 : 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
        ),
        if (showOnline && !isGroup)
          Positioned(
            right: 1,
            bottom: 1,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: _kOnline,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  Widget _roleBadge(String role, {bool isGroup = false}) {
    final color = isGroup ? _kOnline : _roleColor(role);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isGroup ? 'GC' : (role.isEmpty ? 'User' : role),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: _kBackground,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: RefreshIndicator(
                  color: _kPrimary,
                  onRefresh: _loadThreads,
                  child: SizedBox(
                    width: double.infinity,
                    child: Column(
                      children: [
                        if (_searchQuery.trim().isNotEmpty) ...[
                          const SizedBox(height: 14),
                          _buildUserResults(),
                          const SizedBox(height: 8),
                        ],
                        Expanded(child: _buildThreadList()),
                      ],
                    ),
                  ),
                ),
              ),
              const CustomNavBar(currentIndex: 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_kPrimary, _kPrimaryDark],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 20, 14, 8),
            child: Row(
              children: [
                _avatar(name: 'RAMHIS User', size: 48),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Flexible(
                            child: Text(
                              'Messages',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                          if (_totalUnread > 0) ...[
                            const SizedBox(width: 9),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 9, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                    color:
                                        Colors.white.withValues(alpha: 0.18)),
                              ),
                              child: Text(
                                '$_totalUnread unread',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'RAMHIS Chat',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFEAF0FF),
                        ),
                      ),
                    ],
                  ),
                ),
                _headerIconButton(
                  Icons.edit_rounded,
                  onTap: _searchFocusNode.requestFocus,
                ),
                const SizedBox(width: 8),
                _headerIconButton(Icons.refresh_rounded, onTap: _loadThreads),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _buildSearchBar(),
          const SizedBox(height: 22),
        ],
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
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, color: Colors.white, size: 21),
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
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          margin: EdgeInsets.symmetric(horizontal: hasText || focused ? 14 : 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: _kCardShadowColor
                    .withValues(alpha: focused ? 0.16 : 0.10),
                blurRadius: focused ? 20 : 16,
                offset: const Offset(0, 8),
              ),
              if (focused)
                BoxShadow(
                  color: _kPrimary.withValues(alpha: 0.10),
                  blurRadius: 8,
                  spreadRadius: -1,
                ),
            ],
          ),
          child: TextFormField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            textInputAction: TextInputAction.search,
            style: const TextStyle(
                color: _kTextDark, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: '⌘ Search people or messages...',
              hintStyle: const TextStyle(
                  color: _kTextMid, fontWeight: FontWeight.w500),
              prefixIcon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Icon(
                  Icons.search_rounded,
                  key: ValueKey(focused),
                  color: focused ? _kPrimary : _kTextMid,
                ),
              ),
              suffixIcon: hasText
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded, color: _kTextMid),
                      onPressed: _searchController.clear,
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                borderSide: const BorderSide(color: _kPrimary, width: 1.4),
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
            child:
                CircularProgressIndicator(strokeWidth: 2.5, color: _kPrimary),
          ),
        ),
      );
    }

    if (_searchUsers.isEmpty) {
      return _userResultsShell(
        constrained: false,
        child: const Row(
          children: [
            Icon(Icons.person_search_rounded, color: _kTextMid),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'No approved users found',
                style: TextStyle(
                    color: _kTextMid, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );
    }

    return _userResultsShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Text(
              'People',
              style: TextStyle(
                color: _kTextMid,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ),
          ..._searchUsers.map(_buildUserTile),
        ],
      ),
    );
  }

  Widget _userResultsShell({required Widget child, bool constrained = true}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      constraints:
          constrained ? const BoxConstraints(maxHeight: 320) : null,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: _kCardShadowColor.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
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
        highlightColor: _kPrimary.withValues(alpha: 0.06),
        splashColor: _kPrimary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        onTap: _isCreatingChat ? null : () => _startChatWithUser(user),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          child: Row(
            children: [
              _avatar(name: fullName, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            fullName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _kTextDark,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _roleBadge(accountType),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: _kTextMid,
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _isCreatingChat
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: _kPrimary),
                    )
                  : const Icon(Icons.arrow_forward_ios_rounded,
                      size: 16, color: _kTextMid),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThreadList() {
    if (_isLoading) return _buildLoadingState();
    if (_filteredThreads.isEmpty) return _buildEmptyState();

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 22),
      itemCount: _filteredThreads.length,
      separatorBuilder: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Divider(
          height: 14,
          thickness: 1,
          color: _kDividerColor.withValues(alpha: 0.85),
        ),
      ),
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
    final accentColor = isGroup ? _kPrimary : _roleColor(role);
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => _openThread(thread),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: _kCardShadowColor.withValues(alpha: 0.055),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                // Unread indicator bar
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: hasUnread ? 3 : 0,
                  height: 74,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(22),
                      bottomLeft: Radius.circular(22),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        _avatar(
                          name: displayName,
                          size: 54,
                          showOnline: !isGroup,
                          isGroup: isGroup,
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Name row
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      displayName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: _kTextDark,
                                        fontWeight: hasUnread
                                            ? FontWeight.w900
                                            : FontWeight.w700,
                                        fontSize: 15.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _roleBadge(role, isGroup: isGroup),
                                  const SizedBox(width: 8),
                                  if (timestamp.isNotEmpty)
                                    Text(
                                      timestamp,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: hasUnread
                                            ? FontWeight.w800
                                            : FontWeight.w600,
                                        color: hasUnread
                                            ? _kPrimary
                                            : _kTextMid,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Preview row
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      preview,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: hasUnread
                                            ? _kTextDark
                                            : _kTextMid,
                                        fontWeight: hasUnread
                                            ? FontWeight.w800
                                            : FontWeight.w500,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  if (hasUnread) ...[
                                    const SizedBox(width: 10),
                                    Container(
                                      constraints: const BoxConstraints(
                                        minWidth: 24,
                                        minHeight: 24,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 7),
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
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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
      padding: const EdgeInsets.fromLTRB(22, 54, 22, 22),
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(28, 34, 28, 34),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_kPrimary, _kPrimaryDark],
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: _kPrimary.withValues(alpha: 0.22),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 82,
                height: 82,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: const Text('💬', style: TextStyle(fontSize: 40)),
              ),
              const SizedBox(height: 20),
              const Text(
                'No conversations yet',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Search for a user above to start chatting',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFEAF0FF),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 22),
              ElevatedButton.icon(
                onPressed: _searchFocusNode.requestFocus,
                icon: const Icon(Icons.edit_rounded),
                label: const Text('Start New Chat'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: _kPrimary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 12),
                  textStyle:
                      const TextStyle(fontWeight: FontWeight.w900),
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
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 22),
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _buildSkeletonTile(i),
    );
  }

  Widget _buildSkeletonTile(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 850 + (index * 120)),
      curve: Curves.easeInOut,
      builder: (context, value, _) {
        final color =
            Color.lerp(const Color(0xFFE8ECFF), _kBackground, value)!;
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: _kCardShadowColor.withValues(alpha: 0.045),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              _skeletonBox(width: 54, height: 54, color: color, circle: true),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _skeletonBox(
                        width: double.infinity, height: 15, color: color),
                    const SizedBox(height: 10),
                    _skeletonBox(width: 72, height: 18, color: color),
                    const SizedBox(height: 10),
                    _skeletonBox(width: 230, height: 12, color: color),
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
