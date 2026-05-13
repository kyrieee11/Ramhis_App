const rateLimit = require('express-rate-limit');

// ── Forgot password limiter ───────────────────────────────────────────────────
const forgotPasswordLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 50,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    message: 'Too many forgot password attempts. Please try again later.',
  },
});

module.exports = {
  forgotPasswordLimiter,
};