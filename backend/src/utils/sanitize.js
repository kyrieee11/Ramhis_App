const { ObjectId } = require('../config/db');

// ── User sanitizer ────────────────────────────────────────────────────────────
function sanitizeUser(user) {
  return {
    _id: user._id.toString(),
    email: user.email || '',
    first_name: user.first_name || '',
    last_name: user.last_name || '',
    full_name: `${user.first_name || ''} ${user.last_name || ''}`.trim() || 'User',
    contact_number: user.contact_number || '',
    birthdate: user.birthdate || '',
    profile_image_url: user.profile_image_url || '',
    account_type: user.account_type || user.role || 'user',
    role: user.role || 'user',
    status: user.status || 'active',
    specialty: user.specialty || '',
    organization: user.organization || '',
    skills: user.skills || '',
    prc_license_number: user.prc_license_number || '',
    is_verified: user.is_verified === true,
  };
}

// ── Name normalizer ───────────────────────────────────────────────────────────
function normalizeFullName(user) {
  return (
    `${user.first_name || ''} ${user.last_name || ''}`.trim() ||
    user.email ||
    'User'
  );
}

// ── Safe ObjectId ─────────────────────────────────────────────────────────────
function safeObjectId(value) {
  return ObjectId.isValid(value) ? new ObjectId(value) : null;
}

module.exports = {
  sanitizeUser,
  normalizeFullName,
  safeObjectId,
};