const jwt = require('jsonwebtoken');
const { ObjectId } = require('../config/db');
const { usersCol } = require('../config/db');
const { safeServerError } = require('../utils/errors');

const JWT_SECRET = process.env.JWT_SECRET;

// ── Auth middleware ───────────────────────────────────────────────────────────
async function authMiddleware(req, res, next) {
  try {
    const authHeader = String(req.headers.authorization || '');
    console.log('AUTH HEADER:', authHeader);
    const token = authHeader.startsWith('Bearer ')
      ? authHeader.substring(7)
      : '';

    if (!token) {
      return res.status(401).json({
        message: 'Unauthorized.',
      });
    }

    let decoded;
    try {
      decoded = jwt.verify(token, JWT_SECRET);
    } catch (error) {
  console.log('JWT VERIFY ERROR:', error.message);
  console.log('JWT_SECRET EXISTS:', !!JWT_SECRET);

  return res.status(401).json({
    message: 'Invalid or expired token.',
  });
}

    const user = await usersCol().findOne({
      _id: new ObjectId(decoded.id),
    });

    if (!user) {
      return res.status(401).json({
        message: 'User not found.',
      });
    }

    req.user = user;
    next();
  } catch (error) {
    return safeServerError(res, error);
  }
}

// ── Admin only guard ──────────────────────────────────────────────────────────
function adminOnly(req, res, next) {
  if ((req.user?.role || '').toLowerCase() !== 'admin') {
    return res.status(403).json({
      message: 'Admin access only.',
    });
  }
  next();
}

module.exports = {
  authMiddleware,
  adminOnly,
};