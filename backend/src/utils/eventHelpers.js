// ── Event status ──────────────────────────────────────────────────────────────
function getEventStatus(missionDate) {
  if (!missionDate) return 'Upcoming';

  const now = new Date();
  const start = new Date(missionDate);
  start.setHours(0, 0, 0, 0);

  const end = new Date(missionDate);
  end.setHours(23, 59, 59, 999);

  if (now < start) return 'Upcoming';
  if (now > end) return 'Done';
  return 'Ongoing';
}

// ── Registration open check ───────────────────────────────────────────────────
function isRegistrationOpen(missionDate) {
  if (!missionDate) return true;

  const closeAt = new Date(missionDate);
  closeAt.setDate(closeAt.getDate() - 7);
  closeAt.setHours(0, 0, 0, 0);

  return new Date() < closeAt;
}

// ── Socket emitter ────────────────────────────────────────────────────────────
function createEventEmitter(io) {
  return function emitEventsUpdated() {
    io.emit('events_updated', {
      message: 'Events were updated',
      timestamp: new Date().toISOString(),
    });
  };
}

module.exports = {
  getEventStatus,
  isRegistrationOpen,
  createEventEmitter,
};