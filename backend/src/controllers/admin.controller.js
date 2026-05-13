const { usersCol } = require('../config/db');
const { normalizeFullName, safeObjectId } = require('../utils/sanitize');
const { safeServerError } = require('../utils/errors');

// ── Get all users ─────────────────────────────────────────────────────────────
async function getAllUsers(req, res) {
  try {
    const users = await usersCol()
      .find({})
      .project({
        password_hash: 0,
        refresh_token: 0,
        reset_token: 0,
        reset_token_expiry: 0,
      })
      .sort({ created_at: -1 })
      .toArray();

    return res.json(
      users.map((u) => ({
        _id: u._id,
        full_name: normalizeFullName(u),
        email: u.email || '',
        role: u.role || 'user',
        account_type: u.account_type || 'user',
        status: u.status || 'active',
        created_at: u.created_at || null,
      }))
    );
  } catch (error) {
    return safeServerError(res, error);
  }
}

// ── Update user status ────────────────────────────────────────────────────────
async function updateUserStatus(req, res) {
  try {
    const userId = safeObjectId(req.params.id);
    const { status } = req.body;

    if (!userId) {
      return res.status(400).json({ message: 'Invalid user id.' });
    }

    if (!status) {
      return res.status(400).json({ message: 'Status is required.' });
    }

    await usersCol().updateOne(
      { _id: userId },
      {
        $set: {
          status: String(status).toLowerCase(),
          updated_at: new Date(),
        },
      }
    );

    return res.json({ message: 'User updated successfully.' });
  } catch (error) {
    return safeServerError(res, error);
  }
}

// ── Get all doctors ───────────────────────────────────────────────────────────
async function getDoctors(req, res) {
  try {
    const doctors = await usersCol()
      .find({ account_type: 'doctor' })
      .project({
        password_hash: 0,
        refresh_token: 0,
        reset_token: 0,
        reset_token_expiry: 0,
      })
      .sort({ created_at: -1 })
      .toArray();

    return res.json(
      doctors.map((doctor) => ({
        user_id: doctor._id,
        _id: doctor._id,
        full_name: normalizeFullName(doctor),
        email: doctor.email || '',
        contact_number: doctor.contact_number || '',
        birthdate: doctor.birthdate || '',
        specialty: doctor.specialty || '',
        hospital_clinic: doctor.hospital_clinic || '',
        prc_license_number: doctor.prc_license_number || '',
        license_proof_url: doctor.license_proof_url || '',
        profile_image_url: doctor.profile_image_url || '',
        status: doctor.status || 'pending',
        verification_status:
          doctor.status === 'active' ? 'Approved' :
          doctor.status === 'rejected' ? 'Rejected' : 'Pending',
        is_verified: doctor.is_verified === true,
        created_at: doctor.created_at || null,
        updated_at: doctor.updated_at || null,
      }))
    );
  } catch (error) {
    return safeServerError(res, error);
  }
}

// ── Approve doctor ────────────────────────────────────────────────────────────
async function approveDoctor(req, res) {
  try {
    const userId = safeObjectId(req.params.id);

    if (!userId) {
      return res.status(400).json({ message: 'Invalid user id.' });
    }

    const result = await usersCol().updateOne(
      { _id: userId, account_type: 'doctor' },
      {
        $set: {
          status: 'active',
          is_verified: true,
          updated_at: new Date(),
        },
      }
    );

    if (result.matchedCount === 0) {
      return res.status(404).json({ message: 'Doctor not found.' });
    }

    return res.json({ message: 'Doctor approved successfully.' });
  } catch (error) {
    return safeServerError(res, error);
  }
}

// ── Reject doctor ─────────────────────────────────────────────────────────────
async function rejectDoctor(req, res) {
  try {
    const userId = safeObjectId(req.params.id);

    if (!userId) {
      return res.status(400).json({ message: 'Invalid user id.' });
    }

    const result = await usersCol().updateOne(
      { _id: userId, account_type: 'doctor' },
      {
        $set: {
          status: 'rejected',
          is_verified: false,
          updated_at: new Date(),
        },
      }
    );

    if (result.matchedCount === 0) {
      return res.status(404).json({ message: 'Doctor not found.' });
    }

    return res.json({ message: 'Doctor rejected successfully.' });
  } catch (error) {
    return safeServerError(res, error);
  }
}

// ── Get all volunteers ────────────────────────────────────────────────────────
async function getVolunteers(req, res) {
  try {
    const volunteers = await usersCol()
      .find({ $or: [{ account_type: 'volunteer' }, { account_type: 'user' }] })
      .project({
        password_hash: 0,
        refresh_token: 0,
        reset_token: 0,
        reset_token_expiry: 0,
      })
      .sort({ created_at: -1 })
      .toArray();

    return res.json(
      volunteers.map((v) => ({
        user_id: v._id,
        _id: v._id,
        full_name: normalizeFullName(v),
        email: v.email || '',
        contact_number: v.contact_number || '',
        birthdate: v.birthdate || '',
        organization: v.organization || '',
        skills: v.skills || 'General Volunteer',
        status: v.status || 'active',
        created_at: v.created_at || null,
        profile_image_url: v.profile_image_url || '',
      }))
    );
  } catch (error) {
    return safeServerError(res, error);
  }
}

// ── Update volunteer status ───────────────────────────────────────────────────
async function updateVolunteerStatus(req, res) {
  try {
    const userId = safeObjectId(req.params.id);
    const { status } = req.body;

    if (!userId) {
      return res.status(400).json({ message: 'Invalid user id.' });
    }

    if (!status) {
      return res.status(400).json({ message: 'Status is required.' });
    }

    await usersCol().updateOne(
      { _id: userId },
      {
        $set: {
          status: String(status).toLowerCase(),
          updated_at: new Date(),
        },
      }
    );

    return res.json({ message: 'Volunteer updated successfully.' });
  } catch (error) {
    return safeServerError(res, error);
  }
}

module.exports = {
  getAllUsers,
  updateUserStatus,
  getDoctors,
  approveDoctor,
  rejectDoctor,
  getVolunteers,
  updateVolunteerStatus,
};