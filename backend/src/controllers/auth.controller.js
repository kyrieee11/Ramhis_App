const bcrypt = require('bcryptjs');
const { usersCol, ObjectId } = require('../config/db');
const { createAccessToken, createRefreshToken, generateRawResetToken, hashToken } = require('../utils/tokens');
const { sanitizeUser } = require('../utils/sanitize');
const { safeServerError } = require('../utils/errors');
const { sendPasswordResetEmail } = require('../utils/email');

// ── Reset password page ───────────────────────────────────────────────────────
function resetPasswordPage(req, res) {
  const token = String(req.query.token || '');

  if (!token) {
    return res
      .status(400)
      .send('<h2>Missing token.</h2><p>Please request a new reset link.</p>');
  }

  const APP_RESET_LINK_BASE = process.env.APP_RESET_LINK_BASE || 'myapp://reset-password';

  return res.send(`
    <!DOCTYPE html>
    <html>
      <head>
        <meta charset="utf-8" />
        <title>Reset Password</title>
        <style>
          body {
            font-family: Arial, sans-serif;
            background: #f6f8fc;
            padding: 40px;
            color: #1f2937;
          }
          .box {
            max-width: 500px;
            margin: 0 auto;
            background: white;
            border-radius: 12px;
            padding: 24px;
            box-shadow: 0 8px 24px rgba(0,0,0,0.08);
          }
          a.button {
            display: inline-block;
            background: #4766c7;
            color: white;
            text-decoration: none;
            padding: 12px 18px;
            border-radius: 8px;
            margin-top: 16px;
          }
          code {
            word-break: break-all;
            display: block;
            margin-top: 12px;
            background: #f3f4f6;
            padding: 10px;
            border-radius: 8px;
          }
        </style>
      </head>
      <body>
        <div class="box">
          <h2>Password Reset</h2>
          <p>Your token was received successfully.</p>
          <p>If your app supports deep linking, open this link:</p>
          <a class="button" href="${APP_RESET_LINK_BASE}?token=${encodeURIComponent(token)}">
            Open in App
          </a>
          <p>Token:</p>
          <code>${token}</code>
        </div>
      </body>
    </html>
  `);
}

// ── Signup ────────────────────────────────────────────────────────────────────
async function signup(req, res) {
  try {
    const {
      full_name,
      email,
      password,
      account_type,
      contact_number,
      birthdate,
      accepted_terms,
      prc_license_number,
      specialty,
      hospital_clinic,
      organization,
      skills,
    } = req.body;

    const filePath = req.file
      ? `/uploads/verification/${req.file.filename}`
      : '';

    console.log('BODY:', req.body);
    console.log('FILE:', req.file);
    console.log('Saved filePath:', filePath);

    if (!full_name || !email || !password) {
      return res.status(400).json({ message: 'Missing required fields.' });
    }

    const normalizedEmail = String(email).toLowerCase().trim();
    const existing = await usersCol().findOne({ email: normalizedEmail });
    if (existing) {
      return res.status(400).json({ message: 'Email already registered.' });
    }

    const password_hash = await bcrypt.hash(password, 10);
    const parts = String(full_name).trim().split(' ');
    const first_name = parts[0] || '';
    const last_name = parts.slice(1).join(' ') || '';

    const role =
      account_type === 'doctor' ? 'doctor' :
      account_type === 'volunteer' ? 'volunteer' : 'user';

    const newUser = {
      first_name,
      last_name,
      email: normalizedEmail,
      password_hash,
      account_type: account_type || 'user',
      contact_number: contact_number || '',
      birthdate: birthdate || '',
      accepted_terms: accepted_terms === true,
      prc_license_number: prc_license_number || '',
      specialty: specialty || '',
      hospital_clinic: hospital_clinic || '',
      organization: organization || '',
      skills: skills || '',
      license_proof_url: filePath,
      profile_image_url: '',
      role,
      status: account_type === 'doctor' ? 'pending' : 'active',
      is_verified: account_type !== 'doctor',
      created_at: new Date(),
      updated_at: new Date(),
    };

    const result = await usersCol().insertOne(newUser);

    return res.status(201).json({
      message: 'Signup successful.',
      userId: result.insertedId,
    });
  } catch (error) {
    return safeServerError(res, error);
  }
}

// ── Login ─────────────────────────────────────────────────────────────────────
async function login(req, res) {
  try {
    const email = String(req.body.email || '').toLowerCase().trim();
    const password = String(req.body.password || '');

    if (!email || !password) {
      return res.status(400).json({ message: 'Email and password are required.' });
    }

    const user = await usersCol().findOne({ email });

    if (!user || !user.password_hash) {
      return res.status(401).json({ message: 'Invalid email or password.' });
    }

    const isMatch = await bcrypt.compare(password, user.password_hash);
    if (!isMatch) {
      return res.status(401).json({ message: 'Invalid email or password.' });
    }

    const accessToken = createAccessToken(user);
    const refreshToken = createRefreshToken(user);

    await usersCol().updateOne(
      { _id: user._id },
      { $set: { refresh_token: refreshToken, updated_at: new Date() } }
    );

    return res.json({
      message: 'Login successful.',
      accessToken,
      refreshToken,
      user: sanitizeUser(user),
    });
  } catch (error) {
    return safeServerError(res, error);
  }
}

// ── Refresh token ─────────────────────────────────────────────────────────────
async function refreshToken(req, res) {
  try {
    const token = String(req.body.refreshToken || '');

    if (!token) {
      return res.status(400).json({ message: 'Refresh token is required.' });
    }

    const jwt = require('jsonwebtoken');
    const JWT_REFRESH_SECRET = process.env.JWT_REFRESH_SECRET;

    let decoded;
    try {
      decoded = jwt.verify(token, JWT_REFRESH_SECRET);
    } catch (_) {
      return res.status(401).json({ message: 'Invalid refresh token.' });
    }

    const user = await usersCol().findOne({ _id: new ObjectId(decoded.id) });

    if (!user || user.refresh_token !== token) {
      return res.status(401).json({ message: 'Refresh token not recognized.' });
    }

    const newAccessToken = createAccessToken(user);
    const newRefreshToken = createRefreshToken(user);

    await usersCol().updateOne(
      { _id: user._id },
      { $set: { refresh_token: newRefreshToken, updated_at: new Date() } }
    );

    return res.json({
      accessToken: newAccessToken,
      refreshToken: newRefreshToken,
    });
  } catch (error) {
    return safeServerError(res, error);
  }
}

// ── Logout ────────────────────────────────────────────────────────────────────
async function logout(req, res) {
  try {
    await usersCol().updateOne(
      { _id: req.user._id },
      {
        $unset: { refresh_token: '' },
        $set: { updated_at: new Date() },
      }
    );

    return res.json({ message: 'Logged out successfully.' });
  } catch (error) {
    return safeServerError(res, error);
  }
}

// ── Forgot password ───────────────────────────────────────────────────────────
async function forgotPassword(req, res) {
  try {
    const email = String(req.body.email || '').toLowerCase().trim();

    if (!email) {
      return res.status(400).json({ message: 'Email is required.' });
    }

    const user = await usersCol().findOne({ email });

    if (!user) {
      return res.json({ message: 'If the email exists, a reset link has been sent.' });
    }

    const rawToken = generateRawResetToken();
    const hashedToken = hashToken(rawToken);

    await usersCol().updateOne(
      { _id: user._id },
      {
        $set: {
          reset_token: hashedToken,
          reset_token_expiry: new Date(Date.now() + 15 * 60 * 1000),
          updated_at: new Date(),
        },
      }
    );

    const result = await sendPasswordResetEmail(user, rawToken);

    return res.json(result);
  } catch (error) {
    return safeServerError(res, error);
  }
}

// ── Reset password ────────────────────────────────────────────────────────────
async function resetPassword(req, res) {
  try {
    const token = String(req.body.token || '');
    const newPassword = String(req.body.newPassword || '');

    if (!token || !newPassword) {
      return res.status(400).json({ message: 'Missing fields.' });
    }

    if (newPassword.length < 6) {
      return res.status(400).json({ message: 'Password must be at least 6 characters.' });
    }

    const hashedToken = hashToken(token);

    const user = await usersCol().findOne({
      reset_token: hashedToken,
      reset_token_expiry: { $gt: new Date() },
    });

    if (!user) {
      return res.status(400).json({ message: 'Invalid or expired token.' });
    }

    const password_hash = await bcrypt.hash(newPassword, 10);

    await usersCol().updateOne(
      { _id: user._id },
      {
        $set: { password_hash, updated_at: new Date() },
        $unset: { reset_token: '', reset_token_expiry: '' },
      }
    );

    return res.json({ message: 'Password reset successful.' });
  } catch (error) {
    return safeServerError(res, error);
  }
}

module.exports = {
  resetPasswordPage,
  signup,
  login,
  refreshToken,
  logout,
  forgotPassword,
  resetPassword,
};