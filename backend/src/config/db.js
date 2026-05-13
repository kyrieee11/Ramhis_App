const { MongoClient, ObjectId } = require('mongodb');

const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017';
const DB_NAME = process.env.DB_NAME || 'ramhis';

const client = new MongoClient(MONGODB_URI);
let db;

// ── Collection helpers ────────────────────────────────────────────────────────
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

// ── Connect & index setup ─────────────────────────────────────────────────────
async function connectDb() {
  await client.connect();
  db = client.db(DB_NAME);
  console.log(`✅ Connected to MongoDB: ${DB_NAME}`);

  // Users indexes
  await usersCol().createIndex({ email: 1 }, { unique: true });
  await usersCol().createIndex({ reset_token: 1 });
  await usersCol().createIndex({ reset_token_expiry: 1 });

  // Chat indexes
  await chatThreadsCol().createIndex({ member_ids: 1, type: 1 });
  await chatMessagesCol().createIndex({ thread_id: 1, created_at: 1 });

  // Events & content indexes
  await eventsCol().createIndex({ created_at: -1 });
  await contentCol().createIndex({ slug: 1 }, { unique: true });

  // SendGrid status log
  if (process.env.SENDGRID_API_KEY && process.env.SENDGRID_FROM_EMAIL) {
    console.log('✅ SendGrid is configured.');
  } else {
    console.log('⚠️  SendGrid not configured. Using fallback mode.');
  }
}

module.exports = {
  connectDb,
  usersCol,
  chatThreadsCol,
  chatMessagesCol,
  eventsCol,
  contentCol,
  ObjectId,
};