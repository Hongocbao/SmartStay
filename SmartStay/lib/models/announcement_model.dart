class AnnouncementModel {
  final int announcementId;
  final String title;
  final String content;
  final String scope;
  final DateTime createdAt;
  final bool isImportant;

  AnnouncementModel({
    required this.announcementId,
    required this.title,
    required this.content,
    required this.scope,
    required this.createdAt,
    this.isImportant = false,
  });

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    return AnnouncementModel(
      announcementId: json['announcementId'] ?? 0,
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      scope: json['scope'] ?? 'Toàn tòa nhà',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      isImportant: json['isImportant'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'announcementId': announcementId,
      'title': title,
      'content': content,
      'scope': scope,
      'createdAt': createdAt.toIso8601String(),
      'isImportant': isImportant,
    };
  }
}

class EventModel {
  final int eventId;
  final String title;
  final String description;
  final String location;
  final DateTime startTime;
  final DateTime endTime;
  final DateTime registrationDeadline;
  final int maxParticipants;
  final int currentParticipants;
  final bool isRegistered;

  EventModel({
    required this.eventId,
    required this.title,
    required this.description,
    required this.location,
    required this.startTime,
    required this.endTime,
    required this.registrationDeadline,
    required this.maxParticipants,
    this.currentParticipants = 0,
    this.isRegistered = false,
  });

  bool get isExpired => DateTime.now().isAfter(registrationDeadline);
  bool get isFull => currentParticipants >= maxParticipants;

  EventModel copyWith({
    bool? isRegistered,
    int? currentParticipants,
  }) {
    return EventModel(
      eventId: eventId,
      title: title,
      description: description,
      location: location,
      startTime: startTime,
      endTime: endTime,
      registrationDeadline: registrationDeadline,
      maxParticipants: maxParticipants,
      currentParticipants: currentParticipants ?? this.currentParticipants,
      isRegistered: isRegistered ?? this.isRegistered,
    );
  }

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      eventId: json['eventId'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      location: json['location'] ?? '',
      startTime: DateTime.tryParse(json['startTime'] ?? '') ?? DateTime.now(),
      endTime: DateTime.tryParse(json['endTime'] ?? '') ?? DateTime.now(),
      registrationDeadline:
          DateTime.tryParse(json['registrationDeadline'] ?? '') ?? DateTime.now(),
      maxParticipants: json['maxParticipants'] ?? 50,
      currentParticipants: json['currentParticipants'] ?? 0,
      isRegistered: json['isRegistered'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'eventId': eventId,
      'title': title,
      'description': description,
      'location': location,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'registrationDeadline': registrationDeadline.toIso8601String(),
      'maxParticipants': maxParticipants,
      'currentParticipants': currentParticipants,
      'isRegistered': isRegistered,
    };
  }
}
