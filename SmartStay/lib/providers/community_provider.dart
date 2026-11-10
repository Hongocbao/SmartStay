import 'package:flutter/foundation.dart';
import '../models/announcement_model.dart';
import '../services/mock_data_service.dart';
import '../services/supabase_direct_service.dart';

class CommunityProvider extends ChangeNotifier {
  final MockDataService _mock = MockDataService();
  final SupabaseDirectService _supabase = SupabaseDirectService();

  List<AnnouncementModel> _announcements = [];
  List<EventModel> _events = [];

  List<AnnouncementModel> get announcements => _announcements;
  List<EventModel> get events => _events;

  CommunityProvider() {
    loadData();
    syncAnnouncementsFromCloud();
  }

  void loadData() {
    _announcements = List.from(_mock.announcements);
    _events = List.from(_mock.events);
    notifyListeners();
  }

  /// Đồng bộ thông báo từ Supabase (Phương án A) / Web Admin (smartstay-admin)
  Future<void> syncAnnouncementsFromCloud() async {
    final snapshot = await _supabase.fetchUnifiedSnapshot();
    if (snapshot == null) return;
    final rawList = snapshot['thongBaos'];
    if (rawList is! List || rawList.isEmpty) return;

    bool changed = false;
    for (final item in rawList) {
      if (item is! Map) continue;
      final id = (item['maThongBao'] ?? item['MaThongBao'] ?? 0) as num;
      final title = (item['tieuDe'] ?? item['TieuDe'] ?? '').toString().trim();
      final content = (item['noiDung'] ?? item['NoiDung'] ?? '').toString().trim();
      final scope = (item['phamViNhan'] ?? item['PhamViNhan'] ?? 'Toàn tòa nhà').toString();
      final urgent = (item['laKhanCap'] ?? item['LaKhanCap']) == true;
      final createdRaw = (item['thoiDiemCongBo'] ?? item['ThoiDiemCongBo'] ?? '').toString();

      if (title.isEmpty) continue;
      final exists = _announcements.any(
        (a) => a.announcementId == id.toInt() || a.title.toLowerCase() == title.toLowerCase(),
      );
      if (!exists) {
        _announcements.insert(
          0,
          AnnouncementModel(
            announcementId: id.toInt() > 0 ? id.toInt() : DateTime.now().millisecondsSinceEpoch % 100000,
            title: title,
            content: content,
            scope: scope,
            createdAt: DateTime.tryParse(createdRaw) ?? DateTime.now(),
            isImportant: urgent,
          ),
        );
        changed = true;
      }
    }
    if (changed) {
      notifyListeners();
    }
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

  /// Phát sóng thông báo mới qua Firebase FCM (tương đương /ThongBao/Index trên Web)
  void broadcastAnnouncement({
    required String title,
    required String content,
    required String scope,
    required bool isImportant,
  }) {
    final newItem = AnnouncementModel(
      announcementId: DateTime.now().millisecondsSinceEpoch % 100000,
      title: title.trim(),
      content: content.trim(),
      scope: scope,
      createdAt: DateTime.now(),
      isImportant: isImportant,
    );
    _announcements.insert(0, newItem);
    notifyListeners();
    _supabase.syncNotice(
      title: title.trim(),
      content: content.trim(),
      scope: scope,
      isImportant: isImportant,
    );
  }

  void deleteAnnouncement(int announcementId) {
    _announcements.removeWhere((a) => a.announcementId == announcementId);
    notifyListeners();
  }

  /// Tạo sự kiện cộng đồng nội khu mới
  void createEvent({
    required String title,
    required String description,
    required String location,
    required DateTime startTime,
    required int maxParticipants,
  }) {
    final newEvent = EventModel(
      eventId: DateTime.now().millisecondsSinceEpoch % 100000,
      title: title.trim(),
      description: description.trim(),
      location: location.trim(),
      startTime: startTime,
      endTime: startTime.add(const Duration(hours: 3)),
      registrationDeadline: startTime.subtract(const Duration(hours: 6)),
      maxParticipants: maxParticipants,
      currentParticipants: 1,
      isRegistered: false,
    );
    _events.insert(0, newEvent);
    notifyListeners();
  }

  /// Xuất danh sách điểm danh cư dân tham gia sự kiện (Excel/CSV)
  String exportEventAttendanceCsv(EventModel event) {
    final sb = StringBuffer();
    sb.writeln('STT,Họ và Tên Cư Dân,Phòng,Số Điện Thoại,Trạng Thái Đăng Ký,Điểm Danh');
    final sampleResidents = [
      ['1', 'Hồ Ngọc Bảo', 'P.305', '0901234567', 'Đã đăng ký', 'Có mặt'],
      ['2', 'Nguyễn Dương Bảo', 'P.201', '0902234567', 'Đã đăng ký', 'Có mặt'],
      ['3', 'Trần Hoàng Gia Bảo', 'P.401', '0903234567', 'Đã đăng ký', 'Chưa điểm danh'],
      ['4', 'Trần Văn Nam', 'P.301', '0912345678', 'Đã đăng ký', 'Có mặt'],
      ['5', 'Lê Thị Thu', 'P.103', '0934567890', 'Đã đăng ký', 'Có mặt'],
    ];
    for (final r in sampleResidents) {
      sb.writeln('${r[0]},"${r[1]}",${r[2]},${r[3]},"${r[4]}","${r[5]}"');
    }
    return sb.toString();
  }
}
