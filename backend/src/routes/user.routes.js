const express = require('express');
const router = express.Router();

const {
  getMe,
  changePassword,
  getUsers,
  getApprovedUsers,
  updateUser,
  updateProfileImage,
} = require('../controllers/user.controller');

const { authMiddleware } = require('../middleware/auth');

// ── Current user routes ───────────────────────────────────────────────────────
router.get('/me', authMiddleware, getMe);
router.put('/me/change-password', authMiddleware, changePassword);

// ── User list routes ──────────────────────────────────────────────────────────
router.get('/users', authMiddleware, getUsers);
router.get('/users/approved', authMiddleware, getApprovedUsers);

// ── User update routes ────────────────────────────────────────────────────────
router.put('/users/:id', authMiddleware, updateUser);
router.put('/users/:id/profile-image', authMiddleware, updateProfileImage);

module.exports = router;