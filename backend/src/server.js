require('dotenv').config();

const http = require('http');
const { Server } = require('socket.io');

const app = require('./app');
const { connectDb } = require('./config/db');
const registerChatSocket = require('./sockets/chat.socket');
const { initEventController } = require('./controllers/event.controller');
const { initContentController } = require('./controllers/content.controller');

const PORT = process.env.PORT || 5000;

// ── HTTP server ───────────────────────────────────────────────────────────────
const server = http.createServer(app);

// ── Socket.io ─────────────────────────────────────────────────────────────────
const io = new Server(server, {
  cors: { origin: '*' },
});

// ── Init controllers that need io ─────────────────────────────────────────────
registerChatSocket(io);
initEventController(io);
initContentController(io);

// ── Start server ──────────────────────────────────────────────────────────────
connectDb()
  .then(() => {
    server.listen(PORT, () => {
      console.log(`🚀 Server running with Socket.io on port ${PORT}`);
    });
  })
  .catch((err) => {
    console.error('❌ Failed to connect to MongoDB:', err);
    process.exit(1);
  });