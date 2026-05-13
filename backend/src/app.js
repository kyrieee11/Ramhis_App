const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const path = require('path');

const logger = require('./middleware/logger');

const authRoutes = require('./routes/auth.routes');
const userRoutes = require('./routes/user.routes');
const adminRoutes = require('./routes/admin.routes');
const eventRoutes = require('./routes/event.routes');
const contentRoutes = require('./routes/content.routes');
const chatRoutes = require('./routes/chat.routes');

const app = express();

// ── Core middleware ───────────────────────────────────────────────────────────
app.use(helmet());
app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));
app.use(logger);

// ── Health check ──────────────────────────────────────────────────────────────
app.get('/', (_req, res) => {
  return res.json({
    ok: true,
    message: 'RAMHIS backend is running.',
  });
});

// ── Routes ────────────────────────────────────────────────────────────────────
app.use(authRoutes);
app.use(userRoutes);
app.use(adminRoutes);
app.use(eventRoutes);
app.use(contentRoutes);
app.use(chatRoutes);

module.exports = app;