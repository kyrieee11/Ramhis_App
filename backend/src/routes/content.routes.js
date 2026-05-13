const express = require('express');
const router = express.Router();

const {
  adminGetContent,
  adminCreateContent,
  adminUpdateContent,
  getHomepageContent,
} = require('../controllers/content.controller');

const { authMiddleware, adminOnly } = require('../middleware/auth');

// ── Public routes ─────────────────────────────────────────────────────────────
router.get('/content/homepage_content', getHomepageContent);

// ── Admin content routes ──────────────────────────────────────────────────────
router.get('/admin/content', authMiddleware, adminOnly, adminGetContent);
router.post('/admin/content', authMiddleware, adminOnly, adminCreateContent);
router.put('/admin/content/:id', authMiddleware, adminOnly, adminUpdateContent);

module.exports = router;