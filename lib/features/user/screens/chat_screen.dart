import 'dart:async';

import 'package:flutter/material.dart';

import 'package:ramhis_app/features/user/screens/chat_room_screen.dart';
import 'package:ramhis_app/features/user/widgets/bottom_nav.dart';
import 'package:ramhis_app/models/chat_thread_model.dart';
import 'package:ramhis_app/services/api/chat_service.dart';

class ChatCopyWidget extends StatefulWidget {
  const ChatCopyWidget({super.key});

  @override
  State<ChatCopyWidget> createState() => _ChatCopyWidgetState();
}

class _ChatCopyWidgetState extends State<ChatCopyWidget> {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();
  final ChatService _chatService = ChatService();

  Timer? _searchDebounce;

  bool isLoading = true;
  bool isSearchingUsers = false;
  bool isCreatingChat = false;

  String searchQuery = '';

  List<ChatThreadModel> threads = [];
  List<Map<String, dynamic>> searchUsers = [];

  @override
  void initState() {
    super.initState();
    searchController.addListener(_onSearchChanged);
    Future.microtask(_loadThreads);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = searchController.text.trim();

    if (!mounted) return;

    setState(() {
      searchQuery = query;
    });

    _searchDebounce?.cancel();

    if (query.isEmpty) {
      setState(() {
        searchUsers = [];
        isSearchingUsers = false;
      });
      return;
    }

    _searchDebounce = Timer(
      const Duration(milliseconds: 350),
      () async {
        if (!mounted) return;

        setState(() => isSearchingUsers = true);

        try {
          final users = await _chatService.searchApprovedUsers(query);

          if (!mounted) return;

          setState(() {
            searchUsers = users;
            isSearchingUsers = false;
          });
        } catch (error) {
          debugPrint('❌ Search users failed: $error');

          if (!mounted) return;

          setState(() {
            searchUsers = [];
            isSearchingUsers = false;
          });
        }
      },
    );
  }

  Future<void> _loadThreads() async {
    if (!mounted) return;

    setState(() => isLoading = true);

    try {
      final data = await _chatService.getThreads();

      if (!mounted) return;

      setState(() {
        threads = data;
        isLoading = false;
      });
    } catch (error) {
      debugPrint('❌ Load threads failed: $error');

      if (!mounted) return;

      setState(() {
        threads = [];
        isLoading = false;
      });
    }
  }

  List<ChatThreadModel> get filteredThreads {
    final query = searchQuery.trim().toLowerCase();

    if (query.isEmpty) {
      return threads;
    }

    return threads.where((item) {
      return item.name.toLowerCase().contains(query) ||
          item.lastMessage.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _startChatWithUser(Map<String, dynamic> user) async {
    final userId = (user['_id'] ?? user['id'] ?? '').toString();
    final fullName = (user['full_name'] ?? user['name'] ?? 'Chat').toString();

    if (userId.isEmpty || isCreatingChat) return;

    setState(() => isCreatingChat = true);

    try {
      final result = await _chatService.createOrOpenDirectThread(userId);

      if (!mounted) return;

      setState(() => isCreatingChat = false);

      if (result == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open chat.')),
        );
        return;
      }

      final threadId = (result['id'] ?? result['_id'] ?? '').toString();
      final threadName = (result['name'] ?? fullName).toString();

      if (threadId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid chat thread.')),
        );
        return;
      }

      searchController.clear();
      await _loadThreads();

      if (!mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatRoomWidget(
            threadId: threadId,
            threadTitle: threadName,
          ),
        ),
      );

      if (!mounted) return;
      await _loadThreads();
    } catch (error) {
      if (!mounted) return;

      setState(() => isCreatingChat = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  Future<void> _openThread(ChatThreadModel thread) async {
    if (thread.id.isEmpty) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatRoomWidget(
          threadId: thread.id,
          threadTitle: thread.name,
        ),
      ),
    );

    if (!mounted) return;
    await _loadThreads();
  }

  String _formatTime(String raw) {
    if (raw.isEmpty) return '';

    try {
      final parsed = DateTime.parse(raw).toLocal();
      final hour = parsed.hour == 0
          ? 12
          : parsed.hour > 12
              ? parsed.hour - 12
              : parsed.hour;
      final minute = parsed.minute.toString().padLeft(2, '0');
      final suffix = parsed.hour >= 12 ? 'PM' : 'AM';

      return '$hour:$minute $suffix';
    } catch (_) {
      return raw;
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

  Color _roleColor(String role) {
    final normalized = role.toLowerCase();

    if (normalized.contains('doctor')) {
      return const Color(0xFF1976D2);
    }

    if (normalized.contains('volunteer')) {
      return const Color(0xFF388E3C);
    }

    if (normalized.contains('pharmacist')) {
      return const Color(0xFF7B1FA2);
    }

    if (normalized.contains('admin')) {
      return const Color(0xFFD32F2F);
    }

    return const Color(0xFF6B4EFF);
  }

  String _initials(String name) {
    final cleanName = name.trim();

    if (cleanName.isEmpty) return 'R';

    final parts = cleanName.split(RegExp(r'\s+'));

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  String _roleFromName(String name) {
    final lower = name.toLowerCase();

    if (lower.contains('dr.') || lower.contains('doctor')) {
      return 'Doctor';
    }

    if (lower.contains('pharma')) {
      return 'Pharmacist';
    }

    if (lower.contains('admin')) {
      return 'Admin';
    }

    return 'Volunteer';
  }

  String _friendlyTime(String raw) {
    if (raw.isEmpty) return '';

    try {
      final parsed = DateTime.parse(raw).toLocal();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final date = DateTime(parsed.year, parsed.month, parsed.day);

      if (date == today) {
        return _formatTime(raw);
      }

      if (date == today.subtract(const Duration(days: 1))) {
        return 'Yesterday';
      }

      return '${parsed.month}/${parsed.day}/${parsed.year}';
    } catch (_) {
      return _formatTime(raw);
    }
  }

  Widget _avatar({
    required String name,
    double size = 52,
    bool showOnline = true,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _avatarColor(name),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _avatarColor(name).withValues(alpha: 0.25),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Text(
            _initials(name),
            style: TextStyle(
              color: Colors.white,
              fontSize: size >= 50 ? 18 : 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (showOnline)
          Positioned(
            right: 1,
            bottom: 1,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E),
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

  Widget _roleBadge(String role) {
    final color = _roleColor(role);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        role.isEmpty ? 'User' : role,
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

  int get _totalUnread {
    return threads.fold<int>(
      0,
      (sum, item) => sum + item.unread,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: const Color(0xFFF0F2FF),
        body: SafeArea(
          child: Column(
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF5B76F7),
                      Color(0xFF4564E8),
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 14),
                    _buildSearchBar(),
                    const SizedBox(height: 22),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  color: const Color(0xFF5B76F7),
                  onRefresh: _loadThreads,
                  child: Container(
                    width: double.infinity,
                    color: const Color(0xFFF0F2FF),
                    child: Column(
                      children: [
                        if (searchQuery.trim().isNotEmpty) ...[
                          const SizedBox(height: 14),
                          _buildUserResults(),
                          const SizedBox(height: 8),
                        ],
                        Expanded(
                          child: isLoading
                              ? _buildLoadingState()
                              : filteredThreads.isEmpty
                                  ? _buildEmptyState()
                                  : ListView.separated(
                                      physics:
                                          const AlwaysScrollableScrollPhysics(),
                                      padding: const EdgeInsets.fromLTRB(
                                        16,
                                        18,
                                        16,
                                        22,
                                      ),
                                      itemCount: filteredThreads.length,
                                      separatorBuilder: (_, __) => Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                        ),
                                        child: Divider(
                                          height: 14,
                                          thickness: 1,
                                          color: const Color(0xFFE3E7F4)
                                              .withValues(alpha: 0.85),
                                        ),
                                      ),
                                      itemBuilder: (context, index) {
                                        return _buildChatTile(
                                          filteredThreads[index],
                                        );
                                      },
                                    ),
                        ),
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
    const currentUserName = 'RAMHIS User';

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 20, 14, 8),
      child: Row(
        children: [
          _avatar(
            name: currentUserName,
            size: 48,
            showOnline: true,
          ),
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
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.18),
                          ),
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
          Material(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                searchFocusNode.requestFocus();
              },
              child: const SizedBox(
                width: 42,
                height: 42,
                child: Icon(
                  Icons.edit_rounded,
                  color: Colors.white,
                  size: 21,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _loadThreads,
              child: const SizedBox(
                width: 42,
                height: 42,
                child: Icon(
                  Icons.refresh_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final hasText = searchQuery.trim().isNotEmpty;

    return AnimatedBuilder(
      animation: searchFocusNode,
      builder: (context, _) {
        final focused = searchFocusNode.hasFocus;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          margin: EdgeInsets.symmetric(
            horizontal: hasText || focused ? 14 : 18,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: focused ? 0.16 : 0.10),
                blurRadius: focused ? 20 : 16,
                offset: const Offset(0, 8),
              ),
              if (focused)
                BoxShadow(
                  color: const Color(0xFF5B76F7).withValues(alpha: 0.10),
                  blurRadius: 8,
                  spreadRadius: -1,
                  offset: const Offset(0, 0),
                ),
            ],
          ),
          child: TextFormField(
            controller: searchController,
            focusNode: searchFocusNode,
            textInputAction: TextInputAction.search,
            style: const TextStyle(
              color: Color(0xFF1B2559),
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: '⌘ Search people or messages...',
              hintStyle: const TextStyle(
                color: Color(0xFF7B8BB2),
                fontWeight: FontWeight.w500,
              ),
              prefixIcon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Icon(
                  Icons.search_rounded,
                  key: ValueKey(focused),
                  color: focused
                      ? const Color(0xFF5B76F7)
                      : const Color(0xFF7B8BB2),
                ),
              ),
              suffixIcon: hasText
                  ? IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Color(0xFF7B8BB2),
                      ),
                      onPressed: searchController.clear,
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
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
                  color: Color(0xFF5B76F7),
                  width: 1.4,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserResults() {
    if (isSearchingUsers) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Color(0xFF5B76F7),
            ),
          ),
        ),
      );
    }

    if (searchUsers.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Row(
          children: [
            Icon(
              Icons.person_search_rounded,
              color: Color(0xFF7B8BB2),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'No approved users found',
                style: TextStyle(
                  color: Color(0xFF7B8BB2),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Text(
              'People',
              style: TextStyle(
                color: Color(0xFF7B8BB2),
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ),
          ...searchUsers.map((user) {
            final fullName = (user['full_name'] ?? user['name'] ?? 'User')
                .toString();
            final accountType = (user['account_type'] ?? user['role'] ?? 'User')
                .toString();
            final email = (user['email'] ?? accountType).toString();

            return Material(
              color: Colors.transparent,
              child: InkWell(
                highlightColor: const Color(0xFF5B76F7).withValues(alpha: 0.06),
                splashColor: const Color(0xFF5B76F7).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                onTap: isCreatingChat ? null : () => _startChatWithUser(user),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      _avatar(
                        name: fullName,
                        size: 44,
                        showOnline: true,
                      ),
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
                                      color: Color(0xFF1B2559),
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
                                color: Color(0xFF7B8BB2),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      isCreatingChat
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF5B76F7),
                              ),
                            )
                          : const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 16,
                              color: Color(0xFF7B8BB2),
                            ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildChatTile(ChatThreadModel thread) {
    final unread = thread.unread;
    final timestamp = _friendlyTime(thread.updatedAt.toString());
    final hasUnread = unread > 0;
    final role = _roleFromName(thread.name);
    final accentColor = _roleColor(role);
    final preview = thread.lastMessage.isEmpty
        ? 'No messages yet'
        : 'You: ${thread.lastMessage}';

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
                  color: Colors.black.withValues(alpha: 0.055),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: hasUnread ? 3 : 0,
                  height: 74,
                  margin: const EdgeInsets.only(left: 0),
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
                          name: thread.name,
                          size: 54,
                          showOnline: true,
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      thread.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: const Color(0xFF1B2559),
                                        fontWeight: hasUnread
                                            ? FontWeight.w900
                                            : FontWeight.w700,
                                        fontSize: 15.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _roleBadge(role),
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
                                            ? const Color(0xFF5B76F7)
                                            : const Color(0xFF7B8BB2),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      preview,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: hasUnread
                                            ? const Color(0xFF1B2559)
                                            : const Color(0xFF7B8BB2),
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
                                        horizontal: 7,
                                      ),
                                      alignment: Alignment.center,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF5B76F7),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        unread > 99 ? '99+' : unread.toString(),
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
              colors: [
                Color(0xFF5B76F7),
                Color(0xFF4564E8),
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF5B76F7).withValues(alpha: 0.22),
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
                child: const Text(
                  '💬',
                  style: TextStyle(fontSize: 40),
                ),
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
                onPressed: () {
                  searchFocusNode.requestFocus();
                },
                icon: const Icon(Icons.edit_rounded),
                label: const Text('Start New Chat'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF5B76F7),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  textStyle: const TextStyle(
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

  Widget _featureHint(String emoji, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF1B2559),
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 22),
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, index) => _buildSkeletonTile(index),
    );
  }

  Widget _buildSkeletonTile(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 850 + (index * 120)),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        final color = Color.lerp(
          const Color(0xFFE8ECFF),
          const Color(0xFFF0F2FF),
          value,
        )!;

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.045),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              _skeletonBox(
                width: 54,
                height: 54,
                color: color,
                isCircle: true,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _skeletonBox(
                      width: double.infinity,
                      height: 15,
                      color: color,
                    ),
                    const SizedBox(height: 10),
                    _skeletonBox(
                      width: 72,
                      height: 18,
                      color: color,
                    ),
                    const SizedBox(height: 10),
                    _skeletonBox(
                      width: 230,
                      height: 12,
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
    bool isCircle = false,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isCircle ? null : BorderRadius.circular(999),
      ),
    );
  }
}

class _PressableTile extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _PressableTile({
    required this.child,
    required this.onTap,
  });

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
      scale: _pressed ? 0.98 : 1,
      child: Listener(
        onPointerDown: (_) {
          setState(() => _pressed = true);
        },
        onPointerUp: (_) {
          setState(() => _pressed = false);
        },
        onPointerCancel: (_) {
          setState(() => _pressed = false);
        },
        child: widget.child,
      ),
    );
  }
}