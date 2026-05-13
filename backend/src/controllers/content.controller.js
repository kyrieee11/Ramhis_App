const { contentCol } = require('../config/db');
const { safeObjectId } = require('../utils/sanitize');
const { safeServerError } = require('../utils/errors');

let io;

function initContentController(ioInstance) {
  io = ioInstance;
}

// ── Helper: emit content updated ──────────────────────────────────────────────
function emitContentUpdated(slug) {
  io.emit('content_updated', {
    message: 'Homepage content updated',
    slug: String(slug || 'homepage_content'),
    timestamp: new Date().toISOString(),
  });
}

// ── Admin: get all content ────────────────────────────────────────────────────
async function adminGetContent(req, res) {
  try {
    const content = await contentCol()
      .find({})
      .sort({ created_at: -1 })
      .toArray();

    return res.json(content);
  } catch (error) {
    return safeServerError(res, error);
  }
}

// ── Admin: create content ─────────────────────────────────────────────────────
async function adminCreateContent(req, res) {
  try {
    const { slug, title, body, sections = {} } = req.body;

    if (!slug || !title) {
      return res.status(400).json({ message: 'Slug and title are required.' });
    }

    const existing = await contentCol().findOne({ slug: String(slug) });
    if (existing) {
      return res.status(400).json({ message: 'Content slug already exists.' });
    }

    const result = await contentCol().insertOne({
      slug: String(slug),
      title: String(title),
      body: String(body || ''),
      sections,
      created_at: new Date(),
      updated_at: new Date(),
    });

    emitContentUpdated(slug);

    return res.status(201).json({
      message: 'Content created successfully.',
      _id: result.insertedId,
    });
  } catch (error) {
    return safeServerError(res, error);
  }
}

// ── Admin: update content ─────────────────────────────────────────────────────
async function adminUpdateContent(req, res) {
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

    emitContentUpdated(slug);

    return res.json({ message: 'Content updated successfully.' });
  } catch (error) {
    return safeServerError(res, error);
  }
}

// ── Public: get homepage content ──────────────────────────────────────────────
async function getHomepageContent(req, res) {
  try {
    const content = await contentCol().findOne({ slug: 'homepage_content' });

    if (!content) {
      return res.status(404).json(null);
    }

    return res.json(content);
  } catch (error) {
    return safeServerError(res, error);
  }
}

module.exports = {
  initContentController,
  adminGetContent,
  adminCreateContent,
  adminUpdateContent,
  getHomepageContent,
};