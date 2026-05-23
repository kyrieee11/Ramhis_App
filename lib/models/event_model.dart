class EventModel {
  final String id;
  final String title;
  final String description;
  final String location;

  final String operationDays;
  final String callTime;
  final String meetingPlace;

  final String date;
  final String startTime;
  final String endTime;
  final String type;
  final String imageUrl;

  final List<dynamic> volunteers;
  final List<dynamic> participants;

  final bool alreadyJoined;
  final String joinStatus;
  final String participantStatus;
  final String status;
  final String missionDate;
  final bool registrationOpen;

  const EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.operationDays,
    required this.callTime,
    required this.meetingPlace,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.type,
    required this.imageUrl,
    required this.volunteers,
    required this.participants,
    required this.alreadyJoined,
    required this.joinStatus,
    required this.participantStatus,
    required this.status,
    required this.missionDate,
    required this.registrationOpen,
  });

  factory EventModel.fromJson(
    Map<String, dynamic> json, [
    String currentUserId = '',
  ]) {
    final joinStatus = _getJoinStatus(json, currentUserId);

    return EventModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      location: (json['location'] ?? '').toString(),
      operationDays:
          (json['operation_days'] ?? json['date'] ?? '').toString(),
      callTime:
          (json['call_time'] ?? json['startTime'] ?? '').toString(),
      meetingPlace:
          (json['meeting_place'] ?? json['location'] ?? '').toString(),
      date: (json['date'] ?? '').toString(),
      startTime: (json['startTime'] ?? '').toString(),
      endTime: (json['endTime'] ?? '').toString(),
      type: (json['type'] ?? 'Other').toString(),
      imageUrl: (
        json['imageUrl'] ??
            json['image_url'] ??
            json['image'] ??
            ''
      ).toString(),
      volunteers: List<dynamic>.from(
        json['volunteers'] ?? const [],
      ),
      participants: List<dynamic>.from(
        json['participants'] ??
            json['attendees'] ??
            const [],
      ),
      alreadyJoined:
          json['already_joined'] == true ||
          json['alreadyJoined'] == true ||
          joinStatus != 'None',
      joinStatus: joinStatus,
      participantStatus: joinStatus,
      status: (json['status'] ?? 'Upcoming').toString(),
      missionDate:
          (json['mission_date'] ?? json['date'] ?? '').toString(),
      registrationOpen:
          json['registrationOpen'] != false &&
          json['registration_open'] != false,
    );
  }

  static String _getJoinStatus(
    Map<String, dynamic> json,
    String currentUserId,
  ) {
    final directStatus =
        json['participantStatus'] ??
        json['joinStatus'] ??
        json['join_status'];

    if (directStatus != null && directStatus.toString().isNotEmpty) {
      return directStatus.toString();
    }

    if (currentUserId.isEmpty) {
      return 'None';
    }

    final participants = json['participants'] as List? ?? [];

    for (final participant in participants) {
      if (participant is! Map) continue;

      final rawUser =
          participant['userId'] ??
          participant['user'] ??
          participant['_id'] ??
          '';

      String uid;

      if (rawUser is Map) {
        uid = (
          rawUser['_id'] ??
              rawUser['id'] ??
              rawUser['userId'] ??
              ''
        ).toString();
      } else {
        uid = rawUser.toString();
      }

      if (uid == currentUserId) {
        return (
          participant['status'] ??
              participant['participantStatus'] ??
              'Pending'
        ).toString();
      }
    }

    return 'None';
  }

  // ─────────────────────────────────────────────
  // DEBUG ONLY — mock factory for UI testing
  // ─────────────────────────────────────────────
  factory EventModel.mock({
    required String id,
    required String title,
    required String status,
    required String type,
    required String location,
    required String date,
    required String startTime,
    required String endTime,
    required String description,
  }) {
    return EventModel(
      id: id,
      title: title,
      description: description,
      location: location,
      operationDays: date,
      callTime: startTime,
      meetingPlace: location,
      date: date,
      startTime: startTime,
      endTime: endTime,
      type: type,
      imageUrl: '',
      volunteers: const [],
      participants: const [],
      alreadyJoined: false,
      joinStatus: 'None',
      participantStatus: 'None',
      status: status,
      missionDate: date,
      registrationOpen: true,
    );
  }
}