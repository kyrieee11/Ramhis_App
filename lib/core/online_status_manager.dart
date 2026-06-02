class OnlineStatusManager {
  static final Map<String, bool> _onlineUsers = {};
  static final Map<String, DateTime?> _lastSeen = {};

  static void setStatus(
    String userId,
    bool isOnline,
    DateTime? lastSeen,
  ) {
    if (userId.trim().isEmpty) return;

    _onlineUsers[userId] = isOnline;
    _lastSeen[userId] = lastSeen;
  }

  static bool isOnline(String userId) {
    if (userId.trim().isEmpty) return false;

    return _onlineUsers[userId] ?? false;
  }

  static String getLastSeen(String userId) {
    if (userId.trim().isEmpty) return "Offline";

    if (isOnline(userId)) return "Online";

    final t = _lastSeen[userId];

    if (t == null) return "Offline";

    final diff = DateTime.now().difference(t.toLocal());

    if (diff.inMinutes < 1) return "Just now";

    if (diff.inMinutes < 60) {
      return "${diff.inMinutes}m ago";
    }

    if (diff.inHours < 24) {
      return "${diff.inHours}h ago";
    }

    return "${diff.inDays}d ago";
  }

  static void clear() {
    _onlineUsers.clear();
    _lastSeen.clear();
  }
}