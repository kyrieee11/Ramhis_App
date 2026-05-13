const express = require('express');
const router = express.Router();

const {
  openDirectThread,
  getThreads,
  getMessages,
  sendMessage,
} = require('../controllers/chat.controller');

const { authMiddleware } = require('../middleware/auth');

// ── All routes protected ──────────────────────────────────────────────────────
router.use(authMiddleware);

// ── Thread routes ─────────────────────────────────────────────────────────────
router.post('/chat/direct', openDirectThread);
router.get('/chat/threads', getThreads);

// ── Message routes ────────────────────────────────────────────────────────────
router.get('/chat/threads/:threadId/messages', getMessages);
router.post('/chat/threads/:threadId/messages', sendMessage);

module.exports = router;