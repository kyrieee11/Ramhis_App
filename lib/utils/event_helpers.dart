// lib/utils/event_helpers.dart
//
// Shared event-related helpers used by both EventsWidget (events screen)
// and HomeScreen (home feed notifications), so date parsing and
// success-checking logic only lives in one place.
//
// Adjust the import path in home_screen.dart / events_widget.dart to
// wherever you place this file, e.g.:
//   import 'package:ramhis_app/utils/event_helpers.dart';

import 'package:ramhis_app/models/event_model.dart';

/// Parses an event's date using the same precedence used across the app:
/// 1. `event.date` — prefer the ISO calendar date portion (YYYY-MM-DD) so
///    a trailing time/timezone offset can never shift the date by a day.
/// 2. `event.date` — fall back to a general DateTime.tryParse.
/// 3. `event.operationDays` — fall back to a parseable date string, or a
///    display-style date such as "August 17, 2026".
DateTime? parseEventDate(EventModel event) {
  final rawDate = event.date.trim();

  if (rawDate.isNotEmpty) {
    // Preserve the date portion for ISO date/datetime strings, avoiding
    // timezone-offset surprises near midnight.
    final isoMatch = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(rawDate);

    if (isoMatch != null) {
      final year = int.tryParse(isoMatch.group(1)!);
      final month = int.tryParse(isoMatch.group(2)!);
      final day = int.tryParse(isoMatch.group(3)!);

      if (year != null && month != null && day != null) {
        return DateTime(year, month, day);
      }
    }

    final parsed = DateTime.tryParse(rawDate);

    if (parsed != null) {
      return DateTime(parsed.year, parsed.month, parsed.day);
    }
  }

  // Fall back to operationDays when event.date is unavailable/unparseable.
  final operationDays = event.operationDays.trim();

  if (operationDays.isNotEmpty) {
    final parsed = DateTime.tryParse(operationDays);

    if (parsed != null) {
      return DateTime(parsed.year, parsed.month, parsed.day);
    }

    // Support display-style dates such as "August 17, 2026".
    final match = RegExp(
      r'\b(January|February|March|April|May|June|July|August|September|October|November|December)'
      r'\s+(\d{1,2})(?:st|nd|rd|th)?(?:,\s*|\s+)(\d{4})',
      caseSensitive: false,
    ).firstMatch(operationDays);

    if (match != null) {
      const months = {
        'january': 1,
        'february': 2,
        'march': 3,
        'april': 4,
        'may': 5,
        'june': 6,
        'july': 7,
        'august': 8,
        'september': 9,
        'october': 10,
        'november': 11,
        'december': 12,
      };

      final month = months[match.group(1)!.toLowerCase()];
      final day = int.tryParse(match.group(2)!);
      final year = int.tryParse(match.group(3)!);

      if (month != null && day != null && year != null) {
        return DateTime(year, month, day);
      }
    }
  }

  return null;
}

/// True if the event's date is strictly before today (date-only compare,
/// so an event happening today still counts as joinable/current).
bool isPastEventDate(EventModel event) {
  final eventDate = parseEventDate(event);

  if (eventDate == null) return false;

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  return eventDate.isBefore(today);
}

/// Formats a date as "August 17, 2026" using the same parsing precedence
/// as [parseEventDate], falling back to the raw string or a placeholder.
String formatEventDateDisplay(EventModel event) {
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  final parsed = parseEventDate(event);

  if (parsed != null) {
    return '${months[parsed.month - 1]} ${parsed.day}, ${parsed.year}';
  }

  final rawDate = event.date.trim();
  if (rawDate.isNotEmpty) return rawDate;

  final operationDays = event.operationDays.trim();
  if (operationDays.isNotEmpty) return operationDays;

  return 'Date to be announced';
}

/// Strict success check for EventService responses (join / leave / delete).
///
/// NOTE: intentionally does NOT treat "result['message'] != null" as
/// success on its own, since error responses commonly include a message
/// field too (e.g. `{"message": "Event not found"}`). If your backend
/// ever returns a bare message-only response on success with no `ok`/
/// `success` flag, update this in one place rather than three.
bool isEventActionSuccessful(Map<String, dynamic> result) {
  if (result['ok'] == true || result['success'] == true) return true;
  if (result['ok'] == false || result['success'] == false) return false;

  // Backend didn't send an explicit ok/success flag — fall back to
  // absence of an "error"-shaped payload as a weaker signal.
  final hasError = result['error'] != null || result['errors'] != null;
  return !hasError;
}

/// Display-only title casing. The stored/database title is unchanged.
String titleCaseEventText(String text) {
  if (text.trim().isEmpty) return text;

  return text
      .trim()
      .split(RegExp(r'\s+'))
      .map(
        (word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}',
      )
      .join(' ');
}
