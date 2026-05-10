require('dotenv').config();

const express = require('express');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const helmet = require('helmet');
const sgMail = require('@sendgrid/mail');
const rateLimit = require('express-rate-limit');
const { MongoClient, ObjectId } = require('mongodb');
const http = require('http');
const { Server } = require('socket.io');
const path = require('path');
const fs = require('fs');

const multer = require('multer');

// ✅ FIRST: define uploadsDir
const uploadsDir = path.join(__dirname, 'uploads');
if (!fs.existsSync(uploadsDir)) fs.mkdirSync(uploadsDir);

// ✅ THEN: define verificationDir
const verificationDir = path.join(uploadsDir, 'verification');
if (!fs.existsSync(verificationDir)) fs.mkdirSync(verificationDir);

const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, verificationDir);
  },
  filename: function (req, file, cb) {
    const ext = path.extname(file.originalname);
    cb(null, Date.now() + ext);
  },
});

const upload = multer({ storage });

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: { origin: '*' },
});

app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

const PORT = process.env.PORT || 5000;
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017';
const DB_NAME = process.env.DB_NAME || 'ramhis';

const JWT_SECRET = process.env.JWT_SECRET;
const JWT_REFRESH_SECRET = process.env.JWT_REFRESH_SECRET;
const RESET_TOKEN_SECRET = process.env.RESET_TOKEN_SECRET;

const SENDGRID_API_KEY = process.env.SENDGRID_API_KEY;
const SENDGRID_FROM_EMAIL = process.env.SENDGRID_FROM_EMAIL;

const APP_RESET_LINK_BASE =
  process.env.APP_RESET_LINK_BASE || 'myapp://reset-password';
const WEB_RESET_LINK_BASE =
  process.env.WEB_RESET_LINK_BASE || 'http://localhost:5000/reset-password';

if (!JWT_SECRET || !JWT_REFRESH_SECRET || !RESET_TOKEN_SECRET) {
  throw new Error('Missing required JWT/RESET secrets in .env');
}

if (SENDGRID_API_KEY) {
  sgMail.setApiKey(SENDGRID_API_KEY);
}

app.use(helmet());
app.use(cors());
app.use(express.json({ limit: '10mb' }));

app.use((req, _res, next) => {
  console.log(`${req.method} ${req.url}`);
  next();
});

function safeServerError(res, error) {
  console.error('❌ SERVER ERROR:', error?.response?.body || error);
  return res.status(500).json({
    message: 'Internal server error.',
  });
}

const forgotPasswordLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 50,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    message: 'Too many forgot password attempts. Please try again later.',
  },
});

const client = new MongoClient(MONGODB_URI);
let db;


const profileDir = path.join(uploadsDir, 'profiles');

if (!fs.existsSync(uploadsDir)) fs.mkdirSync(uploadsDir);
if (!fs.existsSync(profileDir)) fs.mkdirSync(profileDir);

app.use('/uploads', express.static(uploadsDir));

function usersCol() {
  return db.collection('users');
}

function chatThreadsCol() {
  return db.collection('chat_threads');
}

function chatMessagesCol() {
  return db.collection('chat_messages');
}

function eventsCol() {
  return db.collection('events');
}

function contentCol() {
  return db.collection('content');
}

function hashToken(token) {
  return crypto
    .createHmac('sha256', RESET_TOKEN_SECRET)
    .update(token)
    .digest('hex');
}

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

function sanitizeUser(user) {
  return {
    _id: user._id.toString(),
    email: user.email || '',
    first_name: user.first_name || '',
    last_name: user.last_name || '',
    full_name:
      `${user.first_name || ''} ${user.last_name || ''}`.trim() || 'User',
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

function normalizeFullName(user) {
  return (
    `${user.first_name || ''} ${user.last_name || ''}`.trim() ||
    user.email ||
    'User'
  );
}

function safeObjectId(value) {
  return ObjectId.isValid(value) ? new ObjectId(value) : null;
}

function adminOnly(req, res, next) {
  if ((req.user?.role || '').toLowerCase() !== 'admin') {
    return res.status(403).json({
      message: 'Admin access only.',
    });
  }
  next();
}

async function connectDb() {
  await client.connect();
  db = client.db(DB_NAME);

  await usersCol().createIndex({ email: 1 }, { unique: true });
  await usersCol().createIndex({ reset_token: 1 });
  await usersCol().createIndex({ reset_token_expiry: 1 });

  await chatThreadsCol().createIndex({ member_ids: 1, type: 1 });
  await chatMessagesCol().createIndex({ thread_id: 1, created_at: 1 });

  await eventsCol().createIndex({ created_at: -1 });
  await contentCol().createIndex({ slug: 1 }, { unique: true });

  if (SENDGRID_API_KEY && SENDGRID_FROM_EMAIL) {
    console.log('✅ SendGrid is configured.');
  } else {
    console.log('⚠️ SendGrid not configured. Using fallback mode.');
  }
}

async function authMiddleware(req, res, next) {
  try {
    const authHeader = String(req.headers.authorization || '');
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
    } catch (_) {
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

app.get('/', (_req, res) => {
  return res.json({
    ok: true,
    message: 'RAMHIS backend is running.',
  });
});

app.get('/reset-password', (req, res) => {
  const token = String(req.query.token || '');

  if (!token) {
    return res
      .status(400)
      .send('<h2>Missing token.</h2><p>Please request a new reset link.</p>');
  }

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
          <a class="button" href="${APP_RESET_LINK_BASE}?token=${encodeURIComponent(
            token
          )}">Open in App</a>
          <p>Token:</p>
          <code>${token}</code>
        </div>
      </body>
    </html>
  `);
});

// SIGNUP
app.post('/signup', upload.single('license_file'), async (req, res) => {  try {
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

    const normalizedEmail = String(email).toLowerCase().trim();
    const existing = await usersCol().findOne({ email: normalizedEmail });

    if (existing) {
      return res.status(400).json({
        message: 'Email already registered.',
      });
    }

    const password_hash = await bcrypt.hash(password, 10);
    const parts = String(full_name).trim().split(' ');
    const first_name = parts[0] || '';
    const last_name = parts.slice(1).join(' ') || '';

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

       role: account_type === 'doctor'
    ? 'doctor'
    : account_type === 'volunteer'
    ? 'volunteer'
    : 'user',
    
      status: account_type === 'doctor' ? 'pending' : 'active',
      is_verified: account_type === 'doctor' ? false : true,
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
});

// LOGIN
app.post('/login', async (req, res) => {
  try {
    const email = String(req.body.email || '').toLowerCase().trim();
    const password = String(req.body.password || '');

    if (!email || !password) {
      return res.status(400).json({
        message: 'Email and password are required.',
      });
    }

    const user = await usersCol().findOne({ email });

    if (!user || !user.password_hash) {
      return res.status(401).json({
        message: 'Invalid email or password.',
      });
    }

    const isMatch = await bcrypt.compare(password, user.password_hash);

    if (!isMatch) {
      return res.status(401).json({
        message: 'Invalid email or password.',
      });
    }

    const accessToken = createAccessToken(user);
    const refreshToken = createRefreshToken(user);

    await usersCol().updateOne(
      { _id: user._id },
      {
        $set: {
          refresh_token: refreshToken,
          updated_at: new Date(),
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
    return safeServerError(res, error);
  }
});

// REFRESH TOKEN
app.post('/auth/refresh', async (req, res) => {
  try {
    const refreshToken = String(req.body.refreshToken || '');

    if (!refreshToken) {
      return res.status(400).json({
        message: 'Refresh token is required.',
      });
    }

    let decoded;
    try {
      decoded = jwt.verify(refreshToken, JWT_REFRESH_SECRET);
    } catch (_) {
      return res.status(401).json({
        message: 'Invalid refresh token.',
      });
    }

    const user = await usersCol().findOne({
      _id: new ObjectId(decoded.id),
    });

    if (!user || user.refresh_token !== refreshToken) {
      return res.status(401).json({
        message: 'Refresh token not recognized.',
      });
    }

    const newAccessToken = createAccessToken(user);
    const newRefreshToken = createRefreshToken(user);

    await usersCol().updateOne(
      { _id: user._id },
      {
        $set: {
          refresh_token: newRefreshToken,
          updated_at: new Date(),
        },
      }
    );

    return res.json({
      accessToken: newAccessToken,
      refreshToken: newRefreshToken,
    });
  } catch (error) {
    return safeServerError(res, error);
  }
});

// CURRENT USER
app.get('/me', authMiddleware, async (req, res) => {
  try {
    return res.json(sanitizeUser(req.user));
  } catch (error) {
    return safeServerError(res, error);
  }
});

// ADMIN USERS
app.get('/admin/users', authMiddleware, adminOnly, async (req, res) => {
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

    const mapped = users.map((u) => ({
      _id: u._id,
      full_name: normalizeFullName(u),
      email: u.email || '',
      role: u.role || 'user',
      account_type: u.account_type || 'user',
      status: u.status || 'active',
      created_at: u.created_at || null,
    }));

    return res.json(mapped);
  } catch (err) {
    return safeServerError(res, err);
  }
});

// CHANGE PASSWORD
// CHANGE PASSWORD
app.put('/me/change-password', authMiddleware, async (req, res) => {
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
      return res.status(404).json({
        message: 'User not found.',
      });
    }

    const isMatch = await bcrypt.compare(currentPassword, user.password_hash);

    if (!isMatch) {
      return res.status(400).json({
        message: 'Current password is incorrect.',
      });
    }

    const password_hash = await bcrypt.hash(newPassword, 10);

    await usersCol().updateOne(
      { _id: user._id },
      {
        $set: {
          password_hash,
          updated_at: new Date(),
        },
      }
    );

    return res.json({
      message: 'Password changed successfully.',
    });
  } catch (error) {
    return safeServerError(res, error);
  }
});

app.put('/admin/users/:id/status', authMiddleware, adminOnly, async (req, res) => {
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
      { $set: { status: String(status).toLowerCase(), updated_at: new Date() } }
    );

    return res.json({ message: 'User updated successfully.' });
  } catch (err) {
    return safeServerError(res, err);
  }
});

// ADMIN DOCTORS
app.get('/admin/doctors', authMiddleware, adminOnly, async (req, res) => {
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

    const mapped = doctors.map((doctor) => ({
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
        doctor.status === 'active'
          ? 'Approved'
          : doctor.status === 'rejected'
          ? 'Rejected'
          : 'Pending',

      is_verified: doctor.is_verified === true,
      created_at: doctor.created_at || null,
      updated_at: doctor.updated_at || null,
    }));

    return res.json(mapped);
  } catch (err) {
    return safeServerError(res, err);
  }
});

app.put(
  '/admin/doctors/:id/approve',
  authMiddleware,
  adminOnly,
  async (req, res) => {
    try {
      const userId = safeObjectId(req.params.id);

      if (!userId) {
        return res.status(400).json({ message: 'Invalid user id.' });
      }

      const result = await usersCol().updateOne(
        {
          _id: userId,
          account_type: 'doctor',
        },
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
    } catch (err) {
      return safeServerError(res, err);
    }
  }
);

app.put(
  '/admin/doctors/:id/reject',
  authMiddleware,
  adminOnly,
  async (req, res) => {
    try {
      const userId = safeObjectId(req.params.id);

      if (!userId) {
        return res.status(400).json({ message: 'Invalid user id.' });
      }

      const result = await usersCol().updateOne(
        {
          _id: userId,
          account_type: 'doctor',
        },
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
    } catch (err) {
      return safeServerError(res, err);
    }
  }
);

// ADMIN VOLUNTEERS
app.get('/admin/volunteers', authMiddleware, adminOnly, async (req, res) => {
  try {
    const volunteers = await usersCol()
      .find({
        $or: [{ account_type: 'volunteer' }, { account_type: 'user' }],
      })
      .project({
        password_hash: 0,
        refresh_token: 0,
        reset_token: 0,
        reset_token_expiry: 0,
      })
      .sort({ created_at: -1 })
      .toArray();

    const mapped = volunteers.map((v) => ({
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
}));

    return res.json(mapped);
  } catch (err) {
    return safeServerError(res, err);
  }
});

app.put(
  '/admin/volunteers/:id/status',
  authMiddleware,
  adminOnly,
  async (req, res) => {
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
    } catch (err) {
      return safeServerError(res, err);
    }
  }
);

function getEventStatus(missionDate) {
  if (!missionDate) return 'Upcoming';

  const now = new Date();
  const date = new Date(missionDate);

  const start = new Date(date);
  start.setHours(0, 0, 0, 0);

  const end = new Date(date);
  end.setHours(23, 59, 59, 999);

  if (now < start) return 'Upcoming';
  if (now > end) return 'Done';
  return 'Ongoing';
}

function isRegistrationOpen(missionDate) {
  if (!missionDate) return true;

  const now = new Date();
  const closeAt = new Date(missionDate);
  closeAt.setDate(closeAt.getDate() - 7);
  closeAt.setHours(0, 0, 0, 0);

  return now < closeAt;
}

function emitEventsUpdated() {
  io.emit('events_updated', {
    message: 'Events were updated',
    timestamp: new Date().toISOString(),
  });
}

// ADMIN EVENTS
app.get('/admin/events', authMiddleware, adminOnly, async (req, res) => {
  try {
    const events = await eventsCol().find({}).sort({ created_at: -1 }).toArray();

    const mapped = events.map((event) => ({
      ...event,
      _id: event._id.toString(),
      status: getEventStatus(event.mission_date),
      registration_open: isRegistrationOpen(event.mission_date),
    }));

    return res.json(mapped);
  } catch (err) {
    return safeServerError(res, err);
  }
});

app.post('/admin/events', authMiddleware, adminOnly, async (req, res) => {
  try {
    const {
      title,
      description,
      location,
      operation_days,
      call_time,
      meeting_place,
      mission_date,
    } = req.body;

    if (!title || !location) {
      return res.status(400).json({
        message: 'Title and location are required.',
      });
    }

    await eventsCol().insertOne({
      title: String(title).trim(),
      description: String(description || '').trim(),
      location: String(location).trim(),
      operation_days: String(operation_days || '').trim(),
      call_time: String(call_time || '').trim(),
      meeting_place: String(meeting_place || '').trim(),
      mission_date: mission_date ? new Date(mission_date) : null,
      volunteers: [],
      created_at: new Date(),
      updated_at: new Date(),
    });

    emitEventsUpdated();

    return res.status(201).json({ message: 'Event created successfully.' });
  } catch (err) {
    return safeServerError(res, err);
  }
});

app.get('/events', authMiddleware, async (req, res) => {
  try {
    const myUserId = req.user._id.toString();

    const events = await eventsCol()
      .find({})
      .sort({ created_at: -1 })
      .toArray();

    const mapped = events.map((event) => {
      const volunteers = Array.isArray(event.volunteers) ? event.volunteers : [];

      const alreadyJoined = volunteers.some(
        (v) => String(v.user_id) === myUserId
      );

      return {
        _id: event._id.toString(),
        title: event.title || '',
        description: event.description || '',
        location: event.location || '',
        operation_days: event.operation_days || '',
        call_time: event.call_time || '',
        meeting_place: event.meeting_place || '',
        mission_date: event.mission_date || null,
        status: getEventStatus(event.mission_date),
        registration_open: isRegistrationOpen(event.mission_date),
        volunteers,
        already_joined: alreadyJoined,
      };
    });

    return res.json(mapped);
  } catch (error) {
    return safeServerError(res, error);
  }
});

app.post('/events/cancel', authMiddleware, async (req, res) => {
  try {
    const eventId = safeObjectId(req.body.eventId);
    const userId = req.user._id.toString();

    if (!eventId) {
      return res.status(400).json({ message: 'Invalid event id.' });
    }

    const event = await eventsCol().findOne({ _id: eventId });

    if (!event) {
      return res.status(404).json({ message: 'Event not found.' });
    }

    await eventsCol().updateOne(
      { _id: eventId },
      {
        $pull: {
          volunteers: {
            user_id: userId,
          },
        },
        $set: {
          updated_at: new Date(),
        },
      }
    );

    emitEventsUpdated();

    return res.json({ message: 'Cancelled successfully.' });
  } catch (error) {
    return safeServerError(res, error);
  }
});


app.post('/events/:id/register', authMiddleware, async (req, res) => {
  try {
    const eventId = safeObjectId(req.params.id);
    const userId = req.user._id;

    if (!eventId) {
      return res.status(400).json({ message: 'Invalid event id.' });
    }

    const event = await eventsCol().findOne({ _id: eventId });

    if (!event) {
      return res.status(404).json({ message: 'Event not found.' });
    }

    if (!isRegistrationOpen(event.mission_date)) {
      return res.status(400).json({
        message: 'Registration is closed.',
      });
    }

    const volunteers = Array.isArray(event.volunteers) ? event.volunteers : [];

    const alreadyJoined = volunteers.some(
      (v) => String(v.user_id) === userId.toString()
    );

    if (alreadyJoined) {
      return res.status(400).json({ message: 'Already joined.' });
    }

    await eventsCol().updateOne(
      { _id: eventId },
      {
        $push: {
          volunteers: {
            user_id: userId.toString(),
            full_name: normalizeFullName(req.user),
            account_type: req.user.account_type || req.user.role || 'user',
          },
        },
        $set: {
          updated_at: new Date(),
        },
      }
    );

    emitEventsUpdated();

    return res.status(201).json({
      message: 'Joined successfully.',
    });
  } catch (error) {
    return safeServerError(res, error);
  }
});

app.get('/events/:id/participants', authMiddleware, async (req, res) => {
  try {
    const eventId = safeObjectId(req.params.id);

    if (!eventId) {
      return res.status(400).json({ message: 'Invalid event id.' });
    }

    const event = await eventsCol().findOne({ _id: eventId });

    if (!event) {
      return res.status(404).json({ message: 'Event not found.' });
    }

    return res.json(Array.isArray(event.volunteers) ? event.volunteers : []);
  } catch (error) {
    return safeServerError(res, error);
  }
});

app.put('/admin/events/:id', authMiddleware, adminOnly, async (req, res) => {
  try {
    const eventId = safeObjectId(req.params.id);

    if (!eventId) {
      return res.status(400).json({ message: 'Invalid event id.' });
    }

    const {
      title,
      description,
      location,
      operation_days,
      call_time,
      meeting_place,
      mission_date,
    } = req.body;

    await eventsCol().updateOne(
      { _id: eventId },
      {
        $set: {
          title: String(title || '').trim(),
          description: String(description || '').trim(),
          location: String(location || '').trim(),
          operation_days: String(operation_days || '').trim(),
          call_time: String(call_time || '').trim(),
          meeting_place: String(meeting_place || '').trim(),
          mission_date: mission_date ? new Date(mission_date) : null,
          updated_at: new Date(),
        },
      }
    );

    emitEventsUpdated();

    return res.json({ message: 'Event updated successfully.' });
  } catch (error) {
    return safeServerError(res, error);
  }
});

app.post('/admin/events/delete', authMiddleware, adminOnly, async (req, res) => {
  try {
    const eventId = safeObjectId(req.body.eventId);

    if (!eventId) {
      return res.status(400).json({ message: 'Invalid event id.' });
    }

    const result = await eventsCol().deleteOne({ _id: eventId });

    if (result.deletedCount === 0) {
      return res.status(404).json({ message: 'Event not found.' });
    }

    emitEventsUpdated();

    return res.json({ message: 'Event deleted successfully.' });
  } catch (error) {
    return safeServerError(res, error);
  }
});

// ADMIN CONTENT CMS
// =======================

// =======================
// ADMIN CONTENT CMS
// =======================

app.get('/admin/content', authMiddleware, adminOnly, async (req, res) => {
  try {
    const data = await contentCol().find({}).sort({ created_at: -1 }).toArray();
    return res.json(data);
  } catch (err) {
    return safeServerError(res, err);
  }
});

app.post('/admin/content', authMiddleware, adminOnly, async (req, res) => {
  try {
    const { slug, title, body, sections = {} } = req.body;

    if (!slug || !title) {
      return res.status(400).json({
        message: 'Slug and title are required.',
      });
    }

    const existing = await contentCol().findOne({ slug: String(slug) });

    if (existing) {
      return res.status(400).json({
        message: 'Content slug already exists.',
      });
    }

    const doc = {
      slug: String(slug),
      title: String(title),
      body: String(body || ''),
      sections,
      created_at: new Date(),
      updated_at: new Date(),
    };

    const result = await contentCol().insertOne(doc);

    io.emit('content_updated', {
      message: 'Homepage content updated',
      slug: String(slug),
      timestamp: new Date().toISOString(),
    });

    return res.status(201).json({
      message: 'Content created successfully.',
      _id: result.insertedId,
    });
  } catch (err) {
    return safeServerError(res, err);
  }
});

app.put('/admin/content/:id', authMiddleware, adminOnly, async (req, res) => {
  try {
    const contentId = safeObjectId(req.params.id);

    if (!contentId) {
      return res.status(400).json({ message: 'Invalid content id.' });
    }

    const { slug, title, body, sections = {} } = req.body;

    await contentCol().updateOne(
      { _id: contentId },
      {
        $set: {
          slug: String(slug || ''),
          title: String(title || ''),
          body: String(body || ''),
          sections,
          updated_at: new Date(),
        },
      }
    );

    io.emit('content_updated', {
      message: 'Homepage content updated',
      slug: String(slug || 'homepage_content'),
      timestamp: new Date().toISOString(),
    });

    return res.json({ message: 'Content updated successfully.' });
  } catch (err) {
    return safeServerError(res, err);
  }
});

// =======================
// USER CONTENT FOR HOME PAGE
// =======================

app.get('/content/homepage_content', async (req, res) => {
  try {
    const content = await contentCol().findOne({
      slug: 'homepage_content',
    });

    if (!content) {
      return res.status(404).json(null);
    }

    return res.json(content);
  } catch (err) {
    return safeServerError(res, err);
  }
});

// BASIC USERS LIST
app.get('/users', authMiddleware, async (req, res) => {
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

    const mapped = users.map((user) => ({
      _id: user._id,
      full_name: normalizeFullName(user),
      email: user.email || '',
      account_type: user.account_type || user.role || 'user',
      profile_image_url: user.profile_image_url || '',
      status: user.status || 'active',
    }));

    return res.json(mapped);
  } catch (error) {
    return safeServerError(res, error);
  }
});

// UPDATE USER PROFILE
app.put('/users/:id', authMiddleware, async (req, res) => {
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
});

// UPDATE PROFILE IMAGE
app.put('/users/:id/profile-image', authMiddleware, async (req, res) => {
  try {
    const userId = safeObjectId(req.params.id);

    if (!userId) {
      return res.status(400).json({
        message: 'Invalid user id.',
      });
    }

    const imageBase64 = String(req.body.imageBase64 || '');
    const fileName = String(req.body.fileName || 'profile.jpg');

    if (!imageBase64) {
      return res.status(400).json({
        message: 'Image is required.',
      });
    }

    const cleanBase64 = imageBase64.replace(/^data:image\/\w+;base64,/, '');
    const ext = path.extname(fileName) || '.jpg';
    const savedFileName = `${userId}_${Date.now()}${ext}`;
    const savedPath = path.join(profileDir, savedFileName);

    fs.writeFileSync(savedPath, Buffer.from(cleanBase64, 'base64'));

    const profileImageUrl = `/uploads/profiles/${savedFileName}`;

    await usersCol().updateOne(
      { _id: userId },
      {
        $set: {
          profile_image_url: profileImageUrl,
          updated_at: new Date(),
        },
      }
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
});

// LOGOUT
app.post('/auth/logout', authMiddleware, async (req, res) => {
  try {
    await usersCol().updateOne(
      { _id: req.user._id },
      {
        $unset: {
          refresh_token: '',
        },
        $set: {
          updated_at: new Date(),
        },
      }
    );

    return res.json({
      message: 'Logged out successfully.',
    });
  } catch (error) {
    return safeServerError(res, error);
  }
});

// SEARCH APPROVED USERS
app.get('/users/approved', authMiddleware, async (req, res) => {
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

    const mapped = users.map((user) => ({
      _id: user._id,
      full_name: normalizeFullName(user),
      account_type: user.account_type || user.role || 'user',
      email: user.email || '',
      profile_image_url: user.profile_image_url || '',
    }));

    return res.json(mapped);
  } catch (error) {
    return safeServerError(res, error);
  }
});

// CREATE OR OPEN DIRECT CHAT THREAD
app.post('/chat/direct', authMiddleware, async (req, res) => {
  try {
    const otherUserId = String(req.body.userId || '').trim();

    if (!otherUserId || !ObjectId.isValid(otherUserId)) {
      return res.status(400).json({
        message: 'Valid userId is required.',
      });
    }

    if (otherUserId === req.user._id.toString()) {
      return res.status(400).json({
        message: 'You cannot chat with yourself.',
      });
    }

    const otherUser = await usersCol().findOne({
      _id: new ObjectId(otherUserId),
      status: { $in: ['active', 'pending'] },
    });

    if (!otherUser) {
      return res.status(404).json({
        message: 'Approved user not found.',
      });
    }

    const myId = req.user._id.toString();
    const theirId = otherUser._id.toString();
    const sortedMemberIds = [myId, theirId].sort();

    let thread = await chatThreadsCol().findOne({
      type: 'direct',
      member_ids: sortedMemberIds,
    });

    if (!thread) {
      const myName = normalizeFullName(req.user);
      const otherName = normalizeFullName(otherUser);

      const insertResult = await chatThreadsCol().insertOne({
        type: 'direct',
        member_ids: sortedMemberIds,
        created_by: req.user._id,
        created_at: new Date(),
        updated_at: new Date(),
        last_message: '',
        unread_map: {
          [myId]: 0,
          [theirId]: 0,
        },
        member_profiles: [
          {
            user_id: req.user._id,
            display_name: myName,
            account_type: req.user.account_type || req.user.role || 'user',
          },
          {
            user_id: otherUser._id,
            display_name: otherName,
            account_type: otherUser.account_type || otherUser.role || 'user',
          },
        ],
      });

      thread = await chatThreadsCol().findOne({ _id: insertResult.insertedId });
    }

    const otherName =
      thread.member_profiles?.find(
        (p) => String(p.user_id) === otherUser._id.toString()
      )?.display_name || normalizeFullName(otherUser);

    return res.json({
      id: thread._id.toString(),
      name: otherName,
    });
  } catch (error) {
    return safeServerError(res, error);
  }
});

// GET CHAT THREADS
app.get('/chat/threads', authMiddleware, async (req, res) => {
  try {
    const myId = req.user._id.toString();

    const threads = await chatThreadsCol()
      .find({
        member_ids: myId,
      })
      .sort({ updated_at: -1 })
      .toArray();

    const mapped = threads.map((thread) => {
      const otherProfile =
        (thread.member_profiles || []).find(
          (p) => String(p.user_id) !== myId
        ) || null;

      return {
        _id: thread._id,
        name: otherProfile?.display_name || thread.name || 'User Chat',
        last_message: thread.last_message || 'No messages yet',
        unread: Number(thread.unread_map?.[myId] || 0),
        updated_at: thread.updated_at || thread.created_at || new Date(),
      };
    });

    return res.json(mapped);
  } catch (error) {
    return safeServerError(res, error);
  }
});

// GET CHAT MESSAGES
app.get('/chat/threads/:threadId/messages', authMiddleware, async (req, res) => {
  try {
    const threadId = String(req.params.threadId || '').trim();
    const threadObjectId = safeObjectId(threadId);

    if (!threadObjectId) {
      return res.status(400).json({
        message: 'Invalid thread id.',
      });
    }

    const myId = req.user._id.toString();

    const thread = await chatThreadsCol().findOne({
      _id: threadObjectId,
      member_ids: myId,
    });

    if (!thread) {
      return res.status(404).json({
        message: 'Thread not found.',
      });
    }

    const messages = await chatMessagesCol()
      .find({ thread_id: threadObjectId })
      .sort({ created_at: 1 })
      .toArray();

    await chatThreadsCol().updateOne(
      { _id: threadObjectId },
      {
        $set: {
          [`unread_map.${myId}`]: 0,
        },
      }
    );

    return res.json(
      messages.map((msg) => ({
        _id: msg._id,
        thread_id: msg.thread_id,
        sender_id: msg.sender_id?.toString() || '',
        message: msg.message || '',
        created_at: msg.created_at || new Date(),
      }))
    );
  } catch (error) {
    return safeServerError(res, error);
  }
});

// SEND CHAT MESSAGE
app.post('/chat/threads/:threadId/messages', authMiddleware, async (req, res) => {
  try {
    const threadId = String(req.params.threadId || '').trim();
    const message = String(req.body.message || '').trim();
    const threadObjectId = safeObjectId(threadId);

    if (!threadObjectId) {
      return res.status(400).json({
        message: 'Invalid thread id.',
      });
    }

    if (!message) {
      return res.status(400).json({
        message: 'Message is required.',
      });
    }

    const myId = req.user._id.toString();

    const thread = await chatThreadsCol().findOne({
      _id: threadObjectId,
      member_ids: myId,
    });

    if (!thread) {
      return res.status(404).json({
        message: 'Thread not found.',
      });
    }

    const now = new Date();

    const messageDoc = {
      thread_id: threadObjectId,
      sender_id: req.user._id,
      message,
      created_at: now,
    };

    const insertResult = await chatMessagesCol().insertOne(messageDoc);

    const unreadMap = { ...(thread.unread_map || {}) };
    for (const memberId of thread.member_ids || []) {
      if (memberId === myId) {
        unreadMap[memberId] = 0;
      } else {
        unreadMap[memberId] = Number(unreadMap[memberId] || 0) + 1;
      }
    }

    await chatThreadsCol().updateOne(
      { _id: threadObjectId },
      {
        $set: {
          last_message: message,
          updated_at: now,
          unread_map: unreadMap,
        },
      }
    );

    return res.status(201).json({
      _id: insertResult.insertedId,
      thread_id: threadObjectId,
      sender_id: req.user._id.toString(),
      message,
      created_at: now,
    });
  } catch (error) {
    return safeServerError(res, error);
  }
});

// FORGOT PASSWORD
app.post('/auth/forgot-password', forgotPasswordLimiter, async (req, res) => {
  try {
    const email = String(req.body.email || '').toLowerCase().trim();

    if (!email) {
      return res.status(400).json({
        message: 'Email is required.',
      });
    }

    const user = await usersCol().findOne({ email });

    if (!user) {
      return res.json({
        message: 'If the email exists, a reset link has been sent.',
      });
    }

    const rawToken = crypto.randomBytes(32).toString('hex');
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

    const appResetLink = `${APP_RESET_LINK_BASE}?token=${encodeURIComponent(
      rawToken
    )}`;

    const webResetLink = `${WEB_RESET_LINK_BASE}?token=${encodeURIComponent(
      rawToken
    )}`;

    if (!SENDGRID_API_KEY || !SENDGRID_FROM_EMAIL) {
      console.log('🔗 APP RESET LINK:', appResetLink);
      console.log('🔗 WEB RESET LINK:', webResetLink);

      return res.json({
        message: 'Reset link generated (fallback mode).',
        resetLink: appResetLink,
        appResetLink,
        webResetLink,
      });
    }

    await sgMail.send({
      to: user.email,
      from: {
        email: SENDGRID_FROM_EMAIL,
        name: 'RAMHIS Support',
      },
      subject: 'Reset your password',
      html: `
        <div style="font-family: Arial, sans-serif; color: #1f2937; line-height: 1.6;">
          <h2>Reset Password</h2>
          <p>You requested to reset your password.</p>
          <p>Open in app:</p>
          <p>
            <a href="${appResetLink}" style="display:inline-block;background:#4766C7;color:#ffffff;text-decoration:none;padding:12px 18px;border-radius:8px;">
              Open in App
            </a>
          </p>
          <p>If the button above does not work, use this browser link:</p>
          <p>
            <a href="${webResetLink}">${webResetLink}</a>
          </p>
          <p>This link will expire in 15 minutes.</p>
        </div>
      `,
    });

    console.log('✅ Email sent to:', user.email);
    console.log('🔗 APP RESET LINK:', appResetLink);
    console.log('🔗 WEB RESET LINK:', webResetLink);

    return res.json({
      message: 'Reset email sent successfully.',
      resetLink: appResetLink,
      appResetLink,
      webResetLink,
    });
  } catch (error) {
    return safeServerError(res, error);
  }
});

// RESET PASSWORD
app.post('/auth/reset-password', async (req, res) => {
  try {
    const token = String(req.body.token || '');
    const newPassword = String(req.body.newPassword || '');

    if (!token || !newPassword) {
      return res.status(400).json({
        message: 'Missing fields.',
      });
    }

    if (newPassword.length < 6) {
      return res.status(400).json({
        message: 'Password must be at least 6 characters.',
      });
    }

    const hashedToken = hashToken(token);

    const user = await usersCol().findOne({
      reset_token: hashedToken,
      reset_token_expiry: { $gt: new Date() },
    });

    if (!user) {
      return res.status(400).json({
        message: 'Invalid or expired token.',
      });
    }

    const password_hash = await bcrypt.hash(newPassword, 10);

    await usersCol().updateOne(
      { _id: user._id },
      {
        $set: {
          password_hash,
          updated_at: new Date(),
        },
        $unset: {
          reset_token: '',
          reset_token_expiry: '',
        },
      }
    );

    return res.json({
      message: 'Password reset successful.',
    });
  } catch (error) {
    return safeServerError(res, error);
  }
});

// SOCKET CONNECTION
io.on('connection', (socket) => {
  console.log('⚡ User connected:', socket.id);

  socket.on('join_room', (threadId) => {
    if (!threadId) return;
    socket.join(threadId);
    console.log(`👥 Joined room: ${threadId}`);
  });

  socket.on('send_message', (data) => {
    const { threadId, senderId, message } = data || {};

    if (!threadId || !message) return;

    socket.to(threadId).emit('receive_message', {
      id: '',
      threadId,
      senderId: senderId || '',
      message,
      createdAt: new Date().toISOString(),
    });
  });

  socket.on('disconnect', () => {
    console.log('❌ User disconnected:', socket.id);
  });
});

connectDb()
  .then(() => {
    server.listen(PORT, () => {
      console.log(`🚀 Server running with Socket.io on port ${PORT}`);
    });
  })
  .catch((err) => {
    console.error('❌ Failed to connect to MongoDB:', err);
    process.exit(1);
  });