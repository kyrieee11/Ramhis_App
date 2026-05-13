const { ObjectId } = require('../config/db');
const { chatThreadsCol, chatMessagesCol } = require('../config/db');
const { normalizeFullName, safeObjectId } = require('../utils/sanitize');
const { safeServerError } = require('../utils/errors');

// ── Open or create direct thread ──────────────────────────────────────────────
async function openDirectThread(req, res) {
  try {
    const otherUserId = String(req.body.userId || '').trim();

    if (!otherUserId || !ObjectId.isValid(otherUserId)) {
      return res.status(400).json({ message: 'Valid userId is required.' });
    }

    if (otherUserId === req.user._id.toString()) {
      return res.status(400).json({ message: 'You cannot chat with yourself.' });
    }

    const { usersCol } = require('../config/db');

    const otherUser = await usersCol().findOne({
      _id: new ObjectId(otherUserId),
      status: { $in: ['active', 'pending'] },
    });

    if (!otherUser) {
      return res.status(404).json({ message: 'Approved user not found.' });
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
}

// ── Get all threads ───────────────────────────────────────────────────────────
async function getThreads(req, res) {
  try {
    const myId = req.user._id.toString();

    const threads = await chatThreadsCol()
      .find({ member_ids: myId })
      .sort({ updated_at: -1 })
      .toArray();

    return res.json(
      threads.map((thread) => {
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
      })
    );
  } catch (error) {
    return safeServerError(res, error);
  }
}

// ── Get messages for a thread ─────────────────────────────────────────────────
async function getMessages(req, res) {
  try {
    const threadObjectId = safeObjectId(
      String(req.params.threadId || '').trim()
    );

    if (!threadObjectId) {
      return res.status(400).json({ message: 'Invalid thread id.' });
    }

    const myId = req.user._id.toString();

    const thread = await chatThreadsCol().findOne({
      _id: threadObjectId,
      member_ids: myId,
    });

    if (!thread) {
      return res.status(404).json({ message: 'Thread not found.' });
    }

    const messages = await chatMessagesCol()
      .find({ thread_id: threadObjectId })
      .sort({ created_at: 1 })
      .toArray();

    await chatThreadsCol().updateOne(
      { _id: threadObjectId },
      { $set: { [`unread_map.${myId}`]: 0 } }
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
}

// ── Send message ──────────────────────────────────────────────────────────────
async function sendMessage(req, res) {
  try {
    const threadObjectId = safeObjectId(
      String(req.params.threadId || '').trim()
    );
    const message = String(req.body.message || '').trim();

    if (!threadObjectId) {
      return res.status(400).json({ message: 'Invalid thread id.' });
    }

    if (!message) {
      return res.status(400).json({ message: 'Message is required.' });
    }

    const myId = req.user._id.toString();

    const thread = await chatThreadsCol().findOne({
      _id: threadObjectId,
      member_ids: myId,
    });

    if (!thread) {
      return res.status(404).json({ message: 'Thread not found.' });
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
      unreadMap[memberId] =
        memberId === myId ? 0 : Number(unreadMap[memberId] || 0) + 1;
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
}

module.exports = {
  openDirectThread,
  getThreads,
  getMessages,
  sendMessage,
};