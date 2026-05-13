const { eventsCol } = require('../config/db');
const { safeObjectId, normalizeFullName } = require('../utils/sanitize');
const { safeServerError } = require('../utils/errors');
const { getEventStatus, isRegistrationOpen, createEventEmitter } = require('../utils/eventHelpers');

let emitEventsUpdated;

function initEventController(io) {
  emitEventsUpdated = createEventEmitter(io);
}

// ── Helper: format event ──────────────────────────────────────────────────────
function formatEvent(event, myUserId = null) {
  const volunteers = Array.isArray(event.volunteers) ? event.volunteers : [];

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
    already_joined: myUserId
      ? volunteers.some((v) => String(v.user_id) === myUserId)
      : false,
  };
}

// ── Admin: get all events ─────────────────────────────────────────────────────
async function adminGetEvents(req, res) {
  try {
    const events = await eventsCol()
      .find({})
      .sort({ created_at: -1 })
      .toArray();

    return res.json(events.map((event) => formatEvent(event)));
  } catch (error) {
    return safeServerError(res, error);
  }
}

// ── Admin: create event ───────────────────────────────────────────────────────
async function adminCreateEvent(req, res) {
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
      return res.status(400).json({ message: 'Title and location are required.' });
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
  } catch (error) {
    return safeServerError(res, error);
  }
}

// ── Admin: update event ───────────────────────────────────────────────────────
async function adminUpdateEvent(req, res) {
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
}

// ── Admin: delete event ───────────────────────────────────────────────────────
async function adminDeleteEvent(req, res) {
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
}

// ── User: get all events ──────────────────────────────────────────────────────
async function getEvents(req, res) {
  try {
    const myUserId = req.user._id.toString();
    const events = await eventsCol()
      .find({})
      .sort({ created_at: -1 })
      .toArray();

    return res.json(events.map((event) => formatEvent(event, myUserId)));
  } catch (error) {
    return safeServerError(res, error);
  }
}

// ── User: register for event ──────────────────────────────────────────────────
async function registerEvent(req, res) {
  try {
    const eventId = safeObjectId(req.params.id);
    if (!eventId) {
      return res.status(400).json({ message: 'Invalid event id.' });
    }

    const event = await eventsCol().findOne({ _id: eventId });
    if (!event) {
      return res.status(404).json({ message: 'Event not found.' });
    }

    if (!isRegistrationOpen(event.mission_date)) {
      return res.status(400).json({ message: 'Registration is closed.' });
    }

    const volunteers = Array.isArray(event.volunteers) ? event.volunteers : [];
    const alreadyJoined = volunteers.some(
      (v) => String(v.user_id) === req.user._id.toString()
    );

    if (alreadyJoined) {
      return res.status(400).json({ message: 'Already joined.' });
    }

    await eventsCol().updateOne(
      { _id: eventId },
      {
        $push: {
          volunteers: {
            user_id: req.user._id.toString(),
            full_name: normalizeFullName(req.user),
            account_type: req.user.account_type || req.user.role || 'user',
          },
        },
        $set: { updated_at: new Date() },
      }
    );

    emitEventsUpdated();
    return res.status(201).json({ message: 'Joined successfully.' });
  } catch (error) {
    return safeServerError(res, error);
  }
}

// ── User: cancel event registration ──────────────────────────────────────────
async function cancelEvent(req, res) {
  try {
    const eventId = safeObjectId(req.body.eventId);
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
        $pull: { volunteers: { user_id: req.user._id.toString() } },
        $set: { updated_at: new Date() },
      }
    );

    emitEventsUpdated();
    return res.json({ message: 'Cancelled successfully.' });
  } catch (error) {
    return safeServerError(res, error);
  }
}

// ── User: get event participants ──────────────────────────────────────────────
async function getParticipants(req, res) {
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
}

module.exports = {
  initEventController,
  adminGetEvents,
  adminCreateEvent,
  adminUpdateEvent,
  adminDeleteEvent,
  getEvents,
  registerEvent,
  cancelEvent,
  getParticipants,
};