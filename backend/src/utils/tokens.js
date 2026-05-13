const jwt = require('jsonwebtoken');
const crypto = require('crypto');

const JWT_SECRET = process.env.JWT_SECRET;
const JWT_REFRESH_SECRET = process.env.JWT_REFRESH_SECRET;
const RESET_TOKEN_SECRET = process.env.RESET_TOKEN_SECRET;

if (!JWT_SECRET || !JWT_REFRESH_SECRET || !RESET_TOKEN_SECRET) {
  throw new Error('Missing required JWT/RESET secrets in .env');
}

// ── Token creators ────────────────────────────────────────────────────────────
function createAccessToken(user) {
  return jwt.sign(
    {
      id: user._id.toString(),
      email: user.email,
      role: user.role || 'user',
      status: user.status || 'active',
    },
    JWT_SECRET,
    { expiresIn: '15m' }
  );
}

function createRefreshToken(user) {
  return jwt.sign(
    {
      id: user._id.toString(),
      email: user.email,
      role: user.role || 'user',
      status: user.status || 'active',
    },
    JWT_REFRESH_SECRET,
    { expiresIn: '7d' }
  );
}

// ── Reset token ───────────────────────────────────────────────────────────────
function generateRawResetToken() {
  return crypto.randomBytes(32).toString('hex');
}

function hashToken(token) {
  return crypto
    .createHmac('sha256', RESET_TOKEN_SECRET)
    .update(token)
    .digest('hex');
}

module.exports = {
  createAccessToken,
  createRefreshToken,
  generateRawResetToken,
  hashToken,
};