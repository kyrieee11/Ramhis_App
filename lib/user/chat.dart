import 'dart:async';

import 'package:flutter/material.dart';

import '../models/chat_thread_model.dart';
import '../services/chat_service.dart';
import '../widgets/bottom_nav.dart';
import 'chat_room.dart';

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
    _loadThreads();
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

    _searchDebounce = Timer(const Duration(milliseconds: 350), () async {
      if (!mounted) return;

      setState(() => isSearchingUsers = true);

      final users = await _chatService.searchApprovedUsers(query);

      if (!mounted) return;
      setState(() {
        searchUsers = users;
        isSearchingUsers = false;
      });
    });
  }

  Future<void> _loadThreads() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    final data = await _chatService.getThreads();

    if (!mounted) return;
    setState(() {
      threads = data;
      isLoading = false;
    });
  }

  List<ChatThreadModel> get filteredThreads {
    final query = searchQuery.trim().toLowerCase();
    if (query.isEmpty) return threads;

    return threads.where((item) {
      return item.name.toLowerCase().contains(query) ||
          item.lastMessage.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _startChatWithUser(Map<String, dynamic> user) async {
    final userId = (user['_id'] ?? '').toString();
    final fullName = (user['full_name'] ?? 'Chat').toString();

    if (userId.isEmpty || isCreatingChat) return;

    setState(() => isCreatingChat = true);

    final result = await _chatService.createOrOpenDirectThread(userId);

    if (!mounted) return;
    setState(() => isCreatingChat = false);

    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open chat.')),
      );
      return;
    }

    final threadId = (result['id'] ?? '').toString();
    final threadName = (result['name'] ?? fullName).toString();

    if (threadId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid chat thread.')),
      );
      return;
    }

    await _loadThreads();

    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatRoomWidget(
          threadId: threadId,
          threadTitle: threadName,
        ),
      ),
    );
  }

  void _openThread(ChatThreadModel thread) {
    if (thread.id.isEmpty) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatRoomWidget(
          threadId: thread.id,
          threadTitle: thread.name,
        ),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: const Color(0xFF3E5EBE),
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadThreads,
                  child: Container(
                    width: double.infinity,
                    color: const Color(0xFF3E5EBE),
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        const Text(
                          'Chats',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _buildSearchBar(),
                        if (searchQuery.trim().isNotEmpty) ...[
                          const SizedBox(height: 10),
                          _buildUserResults(),
                        ],
                        const SizedBox(height: 10),
                        Expanded(
                          child: isLoading
                              ? const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                )
                              : filteredThreads.isEmpty
                                  ? _buildEmptyState()
                                  : ListView.separated(
                                      padding: const EdgeInsets.all(14),
                                      itemCount: filteredThreads.length,
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(height: 12),
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

              /// ✅ REPLACED NAVBAR HERE
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
      color: const Color(0xFF4766C7),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF5B76D1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.chat_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'RAMHIS Chat',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          IconButton(
            onPressed: _loadThreads,
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextFormField(
        controller: searchController,
        focusNode: searchFocusNode,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search users or chats',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    searchController.clear();
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Color(0xFF5B76D1)),
          ),
        ),
      ),
    );
  }

  Widget _buildUserResults() {
    if (isSearchingUsers) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (searchUsers.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Text(
          'No approved users found',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F0FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: searchUsers.map((user) {
          final fullName = (user['full_name'] ?? 'User').toString();
          final accountType = (user['account_type'] ?? '').toString();

          return ListTile(
            enabled: !isCreatingChat,
            leading: const CircleAvatar(
              backgroundColor: Color(0xFF5B76D1),
              child: Icon(Icons.person, color: Colors.white),
            ),
            title: Text(
              fullName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              accountType,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: isCreatingChat
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _startChatWithUser(user),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChatTile(ChatThreadModel thread) {
    final unread = thread.unread;
    final timestamp = _formatTime(thread.updatedAt);

    return InkWell(
      onTap: () => _openThread(thread),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F0FF),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Color(0xFF5B76D1),
              child: Icon(Icons.person, color: Colors.white),
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
                          thread.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      if (timestamp.isNotEmpty)
                        Text(
                          timestamp,
                          style: const TextStyle(fontSize: 11),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    thread.lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xFF475467)),
                  ),
                ],
              ),
            ),
            if (unread > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Color(0xFFD95362),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  unread > 99 ? '99+' : unread.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 80),
        Center(
          child: Text(
            'No chats found',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}