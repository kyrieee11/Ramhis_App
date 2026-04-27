class EventModel {
  final String id;
  final String title;
  final String description;
  final String location;
  final String operationDays;
  final String callTime;
  final String meetingPlace;
  final List<dynamic> volunteers;
  final bool alreadyJoined;
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
    required this.volunteers,
    required this.alreadyJoined,
    required this.status,
    required this.missionDate,
    required this.registrationOpen,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: (json['_id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      location: (json['location'] ?? '').toString(),
      operationDays: (json['operation_days'] ?? '').toString(),
      callTime: (json['call_time'] ?? '').toString(),
      meetingPlace: (json['meeting_place'] ?? '').toString(),
      volunteers: List<dynamic>.from(json['volunteers'] ?? const []),
      alreadyJoined: json['already_joined'] == true,
      status: (json['status'] ?? 'Upcoming').toString(),
      missionDate: (json['mission_date'] ?? '').toString(),
      registrationOpen: json['registration_open'] == true,
    );
  }
}