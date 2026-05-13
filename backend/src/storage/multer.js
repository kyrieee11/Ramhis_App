const multer = require('multer');
const path = require('path');
const fs = require('fs');

// ── Directory setup ───────────────────────────────────────────────────────────
const uploadsDir = path.join(__dirname, '..', 'uploads');
const verificationDir = path.join(uploadsDir, 'verification');
const profileDir = path.join(uploadsDir, 'profiles');

[uploadsDir, verificationDir, profileDir].forEach((dir) => {
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
});

// ── Verification storage ──────────────────────────────────────────────────────
const verificationStorage = multer.diskStorage({
  destination: (_req, _file, cb) => cb(null, verificationDir),
  filename: (_req, file, cb) => cb(null, Date.now() + path.extname(file.originalname)),
});

// ── Upload middleware ─────────────────────────────────────────────────────────
const upload = multer({ storage: verificationStorage });

module.exports = {
  upload,
  uploadsDir,
  verificationDir,
  profileDir,
};