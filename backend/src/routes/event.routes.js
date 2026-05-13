const express = require('express');
const router = express.Router();

const {
  adminGetEvents,
  adminCreateEvent,
  adminUpdateEvent,
  adminDeleteEvent,
  getEvents,
  registerEvent,
  cancelEvent,
  getParticipants,
} = require('../controllers/event.controller');

const { authMiddleware, adminOnly } = require('../middleware/auth');

// ── Admin event routes ────────────────────────────────────────────────────────
router.get('/admin/events', authMiddleware, adminOnly, adminGetEvents);
router.post('/admin/events', authMiddleware, adminOnly, adminCreateEvent);
router.put('/admin/events/:id', authMiddleware, adminOnly, adminUpdateEvent);
router.post('/admin/events/delete', authMiddleware, adminOnly, adminDeleteEvent);

// ── User event routes ─────────────────────────────────────────────────────────
router.get('/events', authMiddleware, getEvents);
router.post('/events/cancel', authMiddleware, cancelEvent);
router.post('/events/:id/register', authMiddleware, registerEvent);
router.get('/events/:id/participants', authMiddleware, getParticipants);

module.exports = router;