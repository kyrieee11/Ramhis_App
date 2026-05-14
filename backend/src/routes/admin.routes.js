const express = require('express');
const router = express.Router();

const {
  getAllUsers,
  updateUserStatus,
  getDoctors,
  approveDoctor,
  rejectDoctor,
  getVolunteers,
  updateVolunteerStatus,
} = require('../controllers/admin.controller');

const { authMiddleware, adminOnly } = require('../middleware/auth');

// ── Admin guard — applied to all routes in this file ──────────────────────────
router.use('/admin', authMiddleware, adminOnly);

// ── User management routes ────────────────────────────────────────────────────
router.get('/admin/users', getAllUsers);
router.put('/admin/users/:id/status', updateUserStatus);

// ── Doctor management routes ──────────────────────────────────────────────────
router.get('/admin/doctors', getDoctors);
router.put('/admin/doctors/:id/approve', approveDoctor);
router.put('/admin/doctors/:id/reject', rejectDoctor);

// ── Volunteer management routes ───────────────────────────────────────────────
router.get('/admin/volunteers', getVolunteers);
router.put('/admin/volunteers/:id/status', updateVolunteerStatus);

module.exports = router;