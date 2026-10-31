import 'package:flutter/foundation.dart';
import '../models/announcement_model.dart';
import '../services/mock_data_service.dart';

class CommunityProvider extends ChangeNotifier {
  final MockDataService _mock = MockDataService();

  List<AnnouncementModel> _announcements = [];
  List<EventModel> _events = [];

  List<AnnouncementModel> get announcements => _announcements;
  List<EventModel> get events => _events;

  CommunityProvider() {
    loadData();
  }

  void loadData() {
    _announcements = List.from(_mock.announcements);
    _events = List.from(_mock.events);
    notifyListeners();
  }

  void toggleEventRegistration(int eventId) {
    final index = _events.indexWhere((e) => e.eventId == eventId);
    if (index != -1) {
      final ev = _events[index];
      final newRegistered = !ev.isRegistered;
      final newCount = ev.currentParticipants + (newRegistered ? 1 : -1);

      _events[index] = ev.copyWith(
        isRegistered: newRegistered,
        currentParticipants: newCount,
      );
      notifyListeners();
    }
  }
}
