// ── Chat socket handler ───────────────────────────────────────────────────────
function registerChatSocket(io) {
  io.on('connection', (socket) => {
    console.log('⚡ User connected:', socket.id);

    // ── Join room ───────────────────────────────────────────────────────────
    socket.on('join_room', (threadId) => {
      if (!threadId) return;
      socket.join(threadId);
      console.log(`👥 Joined room: ${threadId}`);
    });

    // ── Send message ────────────────────────────────────────────────────────
    socket.on('send_message', (data) => {
      const { threadId, senderId, message } = data || {};

      if (!threadId || !message) return;

      socket.to(threadId).emit('receive_message', {
        id: '',
        threadId,
        senderId: senderId || '',
        message,
        createdAt: new Date().toISOString(),
      });
    });

    // ── Disconnect ──────────────────────────────────────────────────────────
    socket.on('disconnect', () => {
      console.log('❌ User disconnected:', socket.id);
    });
  });
}

module.exports = registerChatSocket;