// controllers/auth_controller.js

const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const path = require('path');

const {
  usersCol,
} = require('../config/db');

const {
  sanitizeUser,
  normalizeFullName,
  hashToken,
} = require('../utils/helpers');

const {
  createAccessToken,
  createRefreshToken,
} = require('../utils/tokens');

const {
  sendResetPasswordEmail,
} = require('../config/sendgrid');

const JWT_SECRET = process.env.JWT_SECRET;
const JWT_REFRESH_SECRET =
  process.env.JWT_REFRESH_SECRET;

/**
 * =========================
 * SIGNUP
 * =========================
 */

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
      return res.status(400).json({
        message: 'Missing required fields.',
      });
    }

    const normalizedEmail =
      String(email).toLowerCase().trim();

    const existing =
      await usersCol().findOne({
        email: normalizedEmail,
      });

    if (existing) {
      return res.status(400).json({
        message: 'Email already registered.',
      });
    }

    const password_hash =
      await bcrypt.hash(password, 10);

    const parts =
      String(full_name).trim().split(' ');

    const first_name = parts[0] || '';

    const last_name =
      parts.slice(1).join(' ') || '';

    const newUser = {
      first_name,
      last_name,

      email: normalizedEmail,

      password_hash,

      account_type:
        account_type || 'user',

      contact_number:
        contact_number || '',

      birthdate:
        birthdate || '',

      accepted_terms:
        accepted_terms === true,

      prc_license_number:
        prc_license_number || '',

      specialty:
        specialty || '',

      hospital_clinic:
        hospital_clinic || '',

      organization:
        organization || '',

      skills:
        skills || '',

      license_proof_url:
        filePath,

      profile_image_url: '',

      role:
        account_type === 'doctor'
          ? 'doctor'
          : account_type === 'volunteer'
          ? 'volunteer'
          : 'user',

      status:
        account_type === 'doctor'
          ? 'pending'
          : 'active',

      is_verified:
        account_type === 'doctor'
          ? false
          : true,

      created_at: new Date(),
      updated_at: new Date(),
    };

    const result =
      await usersCol().insertOne(newUser);

    return res.status(201).json({
      message: 'Signup successful.',
      userId: result.insertedId,
    });
  } catch (error) {
    console.error(error);

    return res.status(500).json({
      message: 'Signup failed.',
    });
  }
}

/**
 * =========================
 * LOGIN
 * =========================
 */

async function login(req, res) {
  try {
    const email =
      String(req.body.email || '')
        .toLowerCase()
        .trim();

    const password =
      String(req.body.password || '');

    if (!email || !password) {
      return res.status(400).json({
        message:
          'Email and password are required.',
      });
    }

    const user =
      await usersCol().findOne({
        email,
      });

    if (!user || !user.password_hash) {
      return res.status(401).json({
        message:
          'Invalid email or password.',
      });
    }

    const isMatch =
      await bcrypt.compare(
        password,
        user.password_hash
      );

    if (!isMatch) {
      return res.status(401).json({
        message:
          'Invalid email or password.',
      });
    }

    const accessToken =
      createAccessToken(user);

    const refreshToken =
      createRefreshToken(user);

    await usersCol().updateOne(
      { _id: user._id },
      {
        $set: {
          refresh_token:
            refreshToken,

          updated_at:
            new Date(),
        },
      }
    );

    return res.json({
      message: 'Login successful.',

      accessToken,
      refreshToken,

      user: sanitizeUser(user),
    });
  } catch (error) {
    console.error(error);

    return res.status(500).json({
      message: 'Login failed.',
    });
  }
}

/**
 * =========================
 * REFRESH TOKEN
 * =========================
 */

async function refreshToken(req, res) {
  try {
    const refreshToken =
      String(req.body.refreshToken || '');

    if (!refreshToken) {
      return res.status(400).json({
        message:
          'Refresh token is required.',
      });
    }

    let decoded;

    try {
      decoded = jwt.verify(
        refreshToken,
        JWT_REFRESH_SECRET
      );
    } catch (_) {
      return res.status(401).json({
        message:
          'Invalid refresh token.',
      });
    }

    const user =
      await usersCol().findOne({
        _id: decoded.id,
      });

    if (
      !user ||
      user.refresh_token !== refreshToken
    ) {
      return res.status(401).json({
        message:
          'Refresh token not recognized.',
      });
    }

    const newAccessToken =
      createAccessToken(user);

    const newRefreshToken =
      createRefreshToken(user);

    await usersCol().updateOne(
      { _id: user._id },
      {
        $set: {
          refresh_token:
            newRefreshToken,

          updated_at:
            new Date(),
        },
      }
    );

    return res.json({
      accessToken:
        newAccessToken,

      refreshToken:
        newRefreshToken,
    });
  } catch (error) {
    console.error(error);

    return res.status(500).json({
      message:
        'Refresh token failed.',
    });
  }
}

/**
 * =========================
 * CURRENT USER
 * =========================
 */

async function getCurrentUser(req, res) {
  try {
    return res.json(
      sanitizeUser(req.user)
    );
  } catch (error) {
    console.error(error);

    return res.status(500).json({
      message:
        'Failed to fetch current user.',
    });
  }
}

/**
 * =========================
 * LOGOUT
 * =========================
 */

async function logout(req, res) {
  try {
    await usersCol().updateOne(
      { _id: req.user._id },
      {
        $unset: {
          refresh_token: '',
        },

        $set: {
          updated_at:
            new Date(),
        },
      }
    );

    return res.json({
      message:
        'Logged out successfully.',
    });
  } catch (error) {
    console.error(error);

    return res.status(500).json({
      message:
        'Logout failed.',
    });
  }
}

/**
 * =========================
 * FORGOT PASSWORD
 * =========================
 */

async function forgotPassword(req, res) {
  try {
    const email =
      String(req.body.email || '')
        .toLowerCase()
        .trim();

    if (!email) {
      return res.status(400).json({
        message:
          'Email is required.',
      });
    }

    const user =
      await usersCol().findOne({
        email,
      });

    if (!user) {
      return res.json({
        message:
          'If the email exists, a reset link has been sent.',
      });
    }

    const rawToken =
      crypto.randomBytes(32).toString('hex');

    const hashedToken =
      hashToken(rawToken);

    await usersCol().updateOne(
      { _id: user._id },
      {
        $set: {
          reset_token:
            hashedToken,

          reset_token_expiry:
            new Date(
              Date.now() +
                15 * 60 * 1000
            ),

          updated_at:
            new Date(),
        },
      }
    );

    const emailResult =
      await sendResetPasswordEmail(
        user.email,
        rawToken
      );

    return res.json({
      message:
        'Reset email sent successfully.',

      ...emailResult,
    });
  } catch (error) {
    console.error(error);

    return res.status(500).json({
      message:
        'Forgot password failed.',
    });
  }
}

/**
 * =========================
 * RESET PASSWORD
 * =========================
 */

async function resetPassword(req, res) {
  try {
    const token =
      String(req.body.token || '');

    const newPassword =
      String(req.body.newPassword || '');

    if (!token || !newPassword) {
      return res.status(400).json({
        message:
          'Missing fields.',
      });
    }

    if (newPassword.length < 6) {
      return res.status(400).json({
        message:
          'Password must be at least 6 characters.',
      });
    }

    const hashedToken =
      hashToken(token);

    const user =
      await usersCol().findOne({
        reset_token:
          hashedToken,

        reset_token_expiry: {
          $gt: new Date(),
        },
      });

    if (!user) {
      return res.status(400).json({
        message:
          'Invalid or expired token.',
      });
    }

    const password_hash =
      await bcrypt.hash(
        newPassword,
        10
      );

    await usersCol().updateOne(
      { _id: user._id },
      {
        $set: {
          password_hash,

          updated_at:
            new Date(),
        },

        $unset: {
          reset_token: '',
          reset_token_expiry: '',
        },
      }
    );

    return res.json({
      message:
        'Password reset successful.',
    });
  } catch (error) {
    console.error(error);

    return res.status(500).json({
      message:
        'Reset password failed.',
    });
  }
}

/**
 * =========================
 * CHANGE PASSWORD
 * =========================
 */

async function changePassword(req, res) {
  try {
    const {
      currentPassword,
      newPassword,
    } = req.body;

    if (
      !currentPassword ||
      !newPassword
    ) {
      return res.status(400).json({
        message:
          'Current and new password are required.',
      });
    }

    if (newPassword.length < 8) {
      return res.status(400).json({
        message:
          'New password must be at least 8 characters.',
      });
    }

    const user =
      await usersCol().findOne({
        _id: req.user._id,
      });

    if (!user || !user.password_hash) {
      return res.status(404).json({
        message:
          'User not found.',
      });
    }

    const isMatch =
      await bcrypt.compare(
        currentPassword,
        user.password_hash
      );

    if (!isMatch) {
      return res.status(400).json({
        message:
          'Current password is incorrect.',
      });
    }

    const password_hash =
      await bcrypt.hash(
        newPassword,
        10
      );

    await usersCol().updateOne(
      { _id: user._id },
      {
        $set: {
          password_hash,

          updated_at:
            new Date(),
        },
      }
    );

    return res.json({
      message:
        'Password changed successfully.',
    });
  } catch (error) {
    console.error(error);

    return res.status(500).json({
      message:
        'Change password failed.',
    });
  }
}

module.exports = {
  signup,
  login,
  refreshToken,
  getCurrentUser,
  logout,
  forgotPassword,
  resetPassword,
  changePassword,
};