const express = require('express');
const router = express.Router();

const {
  resetPasswordPage,
  signup,
  login,
  refreshToken,
  logout,
  forgotPassword,
  resetPassword,
} = require('../controllers/auth.controller');

const { authMiddleware } = require('../middleware/auth');
const { forgotPasswordLimiter } = require('../middleware/rateLimiter');
const { upload } = require('../storage/multer');

// ── Public routes ─────────────────────────────────────────────────────────────
router.get('/reset-password', resetPasswordPage);
router.post('/signup', upload.single('license_file'), signup);
router.post('/login', login);
router.post('/auth/refresh', refreshToken);
router.post('/auth/forgot-password', forgotPasswordLimiter, forgotPassword);
router.post('/auth/reset-password', resetPassword);

// ── Protected routes ──────────────────────────────────────────────────────────
router.post('/auth/logout', authMiddleware, logout);

module.exports = router;