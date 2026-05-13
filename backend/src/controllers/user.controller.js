const path = require('path');
const fs = require('fs');
const bcrypt = require('bcryptjs');
const { usersCol, ObjectId } = require('../config/db');
const { sanitizeUser, normalizeFullName, safeObjectId } = require('../utils/sanitize');
const { safeServerError } = require('../utils/errors');
const { profileDir } = require('../storage/multer');

// ── Get current user ──────────────────────────────────────────────────────────
async function getMe(req, res) {
  try {
    return res.json(sanitizeUser(req.user));
  } catch (error) {
    return safeServerError(res, error);
  }
}

// ── Change password ───────────────────────────────────────────────────────────
async function changePassword(req, res) {
  try {
    const { currentPassword, newPassword } = req.body;

    if (!currentPassword || !newPassword) {
      return res.status(400).json({
        message: 'Current and new password are required.',
      });
    }

    if (newPassword.length < 8) {
      return res.status(400).json({
        message: 'New password must be at least 8 characters.',
      });
    }

    const user = await usersCol().findOne({ _id: req.user._id });

    if (!user || !user.password_hash) {
      return res.status(404).json({ message: 'User not found.' });
    }

    const isMatch = await bcrypt.compare(currentPassword, user.password_hash);
    if (!isMatch) {
      return res.status(400).json({ message: 'Current password is incorrect.' });
    }

    const password_hash = await bcrypt.hash(newPassword, 10);

    await usersCol().updateOne(
      { _id: user._id },
      { $set: { password_hash, updated_at: new Date() } }
    );

    return res.json({ message: 'Password changed successfully.' });
  } catch (error) {
    return safeServerError(res, error);
  }
}

// ── Get all users ─────────────────────────────────────────────────────────────
async function getUsers(req, res) {
  try {
    const users = await usersCol()
      .find({})
      .project({
        password_hash: 0,
        refresh_token: 0,
        reset_token: 0,
        reset_token_expiry: 0,
      })
      .toArray();

    return res.json(
      users.map((user) => ({
        _id: user._id,
        full_name: normalizeFullName(user),
        email: user.email || '',
        account_type: user.account_type || user.role || 'user',
        profile_image_url: user.profile_image_url || '',
        status: user.status || 'active',
      }))
    );
  } catch (error) {
    return safeServerError(res, error);
  }
}

// ── Get approved users (search) ───────────────────────────────────────────────
async function getApprovedUsers(req, res) {
  try {
    const q = String(req.query.q || '').trim();

    const filter = {
      status: { $in: ['active', 'pending'] },
      _id: { $ne: req.user._id },
    };

    if (q) {
      filter.$or = [
        { first_name: { $regex: q, $options: 'i' } },
        { last_name: { $regex: q, $options: 'i' } },
        { email: { $regex: q, $options: 'i' } },
        {
          $expr: {
            $regexMatch: {
              input: { $concat: ['$first_name', ' ', '$last_name'] },
              regex: q,
              options: 'i',
            },
          },
        },
      ];
    }

    const users = await usersCol()
      .find(filter)
      .project({
        password_hash: 0,
        refresh_token: 0,
        reset_token: 0,
        reset_token_expiry: 0,
      })
      .limit(20)
      .toArray();

    return res.json(
      users.map((user) => ({
        _id: user._id,
        full_name: normalizeFullName(user),
        account_type: user.account_type || user.role || 'user',
        email: user.email || '',
        profile_image_url: user.profile_image_url || '',
      }))
    );
  } catch (error) {
    return safeServerError(res, error);
  }
}

// ── Update user ───────────────────────────────────────────────────────────────
async function updateUser(req, res) {
  try {
    const userId = safeObjectId(req.params.id);
    if (!userId) {
      return res.status(400).json({ message: 'Invalid user id.' });
    }

    const { full_name, email, contact_number, birthdate } = req.body;

    let first_name = '';
    let last_name = '';

    if (full_name) {
      const parts = String(full_name).trim().split(' ');
      first_name = parts[0] || '';
      last_name = parts.slice(1).join(' ') || '';
    }

    await usersCol().updateOne(
      { _id: userId },
      {
        $set: {
          first_name,
          last_name,
          email: String(email || '').toLowerCase().trim(),
          contact_number: String(contact_number || '').trim(),
          birthdate: String(birthdate || '').trim(),
          updated_at: new Date(),
        },
      }
    );

    const updatedUser = await usersCol().findOne({ _id: userId });

    return res.json({
      message: 'User updated successfully.',
      user: sanitizeUser(updatedUser),
    });
  } catch (error) {
    return safeServerError(res, error);
  }
}

// ── Update profile image ──────────────────────────────────────────────────────
async function updateProfileImage(req, res) {
  try {
    const userId = safeObjectId(req.params.id);
    if (!userId) {
      return res.status(400).json({ message: 'Invalid user id.' });
    }

    const imageBase64 = String(req.body.imageBase64 || '');
    const fileName = String(req.body.fileName || 'profile.jpg');

    if (!imageBase64) {
      return res.status(400).json({ message: 'Image is required.' });
    }

    const cleanBase64 = imageBase64.replace(/^data:image\/\w+;base64,/, '');
    const ext = path.extname(fileName) || '.jpg';
    const savedFileName = `${userId}_${Date.now()}${ext}`;
    const savedPath = path.join(profileDir, savedFileName);

    fs.writeFileSync(savedPath, Buffer.from(cleanBase64, 'base64'));

    const profileImageUrl = `/uploads/profiles/${savedFileName}`;

    await usersCol().updateOne(
      { _id: userId },
      { $set: { profile_image_url: profileImageUrl, updated_at: new Date() } }
    );

    const updatedUser = await usersCol().findOne({ _id: userId });

    return res.json({
      message: 'Profile image updated successfully.',
      imageUrl: profileImageUrl,
      user: sanitizeUser(updatedUser),
    });
  } catch (error) {
    return safeServerError(res, error);
  }
}

module.exports = {
  getMe,
  changePassword,
  getUsers,
  getApprovedUsers,
  updateUser,
  updateProfileImage,
};