import 'package:flutter/foundation.dart';
import '../models/ticket_model.dart';
import '../services/mock_data_service.dart';
import '../services/supabase_direct_service.dart';

class TicketProvider extends ChangeNotifier {
  final MockDataService _mock = MockDataService();
  final SupabaseDirectService _supabase = SupabaseDirectService();

  List<TicketModel> _tickets = [];
  bool _isLoading = false;

  List<TicketModel> get tickets => _tickets;
  bool get isLoading => _isLoading;

  TicketModel? get activeTicket {
    try {
      return _tickets.firstWhere((t) => t.status == 'Đang sửa' || t.status == 'Chờ xử lý');
    } catch (_) {
      return null;
    }
  }

  TicketProvider() {
    loadTickets();
    syncTicketsFromCloud();
  }

  void loadTickets() {
    _tickets = List.from(_mock.tickets);
    notifyListeners();
  }

  /// Đồng bộ danh sách phiếu sự cố từ Supabase (Phương án A) / Web Admin (smartstay-admin)
  Future<void> syncTicketsFromCloud() async {
    final snapshot = await _supabase.fetchUnifiedSnapshot();
    if (snapshot == null) return;
    final rawList = snapshot['suCos'];
    if (rawList is! List || rawList.isEmpty) return;

    bool changed = false;
    for (final item in rawList) {
      if (item is! Map) continue;
      final id = (item['maPhieuSuCo'] ?? item['MaPhieuSuCo'] ?? 0) as num;
      final code = (item['soPhieuSuCo'] ?? item['SoPhieuSuCo'] ?? '').toString().trim();
      final room = (item['kyHieuPhong'] ?? item['KyHieuPhong'] ?? 'P.305').toString();
      final title = (item['tieuDe'] ?? item['TieuDe'] ?? '').toString().trim();
      final desc = (item['moTa'] ?? item['MoTa'] ?? '').toString().trim();
      final priority = (item['uuTien'] ?? item['UuTien'] ?? 'Trung bình').toString();
      final statusRaw = (item['trangThai'] ?? item['TrangThai'] ?? 'Chờ xử lý').toString();
      final status = statusRaw == 'Đang xử lý' ? 'Đang sửa' : statusRaw;

      if (code.isEmpty || title.isEmpty) continue;
      final idx = _tickets.indexWhere((t) => t.ticketCode == code);
      if (idx != -1) {
        if (_tickets[idx].status != status) {
          _tickets[idx] = _tickets[idx].copyWith(status: status);
          changed = true;
        }
      } else {
        _tickets.insert(
          0,
          TicketModel(
            ticketId: id.toInt() > 0 ? id.toInt() : DateTime.now().millisecondsSinceEpoch % 10000,
            ticketCode: code,
            roomCode: room,
            categoryName: 'Bảo trì kỹ thuật',
            title: title,
            description: desc,
            priority: priority,
            status: status,
            createdAt: DateTime.now(),
            images: const [],
            comments: const [],
            activityLogs: const [],
          ),
        );
        changed = true;
      }
    }
    if (changed) {
      notifyListeners();
    }
  }

  TicketModel? getTicketById(int ticketId) {
    try {
      return _tickets.firstWhere((t) => t.ticketId == ticketId);
    } catch (_) {
      return null;
    }
  }

  /// Tạo phiếu sự cố mới (loại bỏ dữ liệu tĩnh cố định)
  Future<bool> createTicket({
    required String categoryName,
    required String title,
    required String description,
    required String priority,
    String? roomCode,
    String? authorName,
    String? imageUrl,
  }) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));

    final effectiveRoom = (roomCode != null && roomCode.isNotEmpty) ? roomCode : 'P.305';
    final effectiveAuthor = (authorName != null && authorName.isNotEmpty) ? authorName : 'Cư dân';
    final newTicketId = DateTime.now().millisecondsSinceEpoch % 10000;
    final now = DateTime.now();

    final newTicket = TicketModel(
      ticketId: newTicketId,
      ticketCode: 'SC-${now.year}-${(newTicketId % 900) + 100}',
      roomCode: effectiveRoom,
      categoryName: categoryName,
      technicianName: null, // Ban Quản lý sẽ phân công sau
      title: title,
      description: description,
      priority: priority,
      status: 'Chờ xử lý',
      createdAt: now,
      images: (imageUrl != null && imageUrl.isNotEmpty)
          ? [
              TicketImageModel(
                imageId: DateTime.now().millisecondsSinceEpoch % 1000,
                mediaUrl: imageUrl,
                imageType: 'TruocSuaChua',
              )
            ]
          : [],
      comments: [
        TicketCommentModel(
          commentId: 1,
          authorName: effectiveAuthor,
          content: 'Cư dân đã gửi phiếu báo sự cố vào hệ thống.',
          createdAt: now,
          isFromResident: true,
        ),
      ],
      activityLogs: [
        TicketActivityLogModel(
          logId: 1,
          action: 'Tạo phiếu sự cố',
          actorName: effectiveAuthor,
          note: 'Mức độ ưu tiên: $priority',
          timestamp: now,
        ),
      ],
    );

    _tickets.insert(0, newTicket);
    _isLoading = false;
    notifyListeners();
    _supabase.syncTicket(
      ticketCode: newTicket.ticketCode,
      roomCode: effectiveRoom,
      title: title,
      description: description,
      priority: priority,
      status: 'Chờ xử lý',
    );
    return true;
  }

  Future<void> addComment(int ticketId, String content, {String? authorName, bool isResident = true}) async {
    final index = _tickets.indexWhere((t) => t.ticketId == ticketId);
    if (index != -1) {
      final t = _tickets[index];
      final newComment = TicketCommentModel(
        commentId: DateTime.now().millisecondsSinceEpoch % 10000,
        authorName: authorName ?? (isResident ? 'Cư dân' : 'Kỹ thuật viên'),
        content: content,
        createdAt: DateTime.now(),
        isFromResident: isResident,
      );

      final updatedComments = List<TicketCommentModel>.from(t.comments)..add(newComment);
      _tickets[index] = t.copyWith(comments: updatedComments);
      notifyListeners();
    }
  }

  Future<void> rateTicket(int ticketId, int rating, String comment) async {
    final index = _tickets.indexWhere((t) => t.ticketId == ticketId);
    if (index != -1) {
      final t = _tickets[index];
      final log = TicketActivityLogModel(
        logId: DateTime.now().millisecondsSinceEpoch % 10000,
        action: 'Đánh giá chất lượng',
        actorName: 'Cư dân',
        note: 'Đã chấm $rating★: $comment',
        timestamp: DateTime.now(),
      );

      _tickets[index] = t.copyWith(
        rating: rating,
        ratingComment: comment,
        activityLogs: List<TicketActivityLogModel>.from(t.activityLogs)..add(log),
      );
      notifyListeners();
    }
  }

  /// Phân công kỹ thuật viên (Đúng đặc tả: Giữ nguyên "Chờ xử lý", KHÔNG tự ý chuyển sang "Đang sửa")
  void assignTechnician(int ticketId, String techName, {String assignerName = 'Quản lý vận hành'}) {
    final index = _tickets.indexWhere((t) => t.ticketId == ticketId);
    if (index != -1) {
      final t = _tickets[index];
      final log = TicketActivityLogModel(
        logId: DateTime.now().millisecondsSinceEpoch % 10000,
        action: 'Phân công kỹ thuật viên',
        actorName: assignerName,
        note: 'Đã giao phụ trách cho KTV $techName',
        timestamp: DateTime.now(),
      );

      _tickets[index] = t.copyWith(
        technicianName: techName,
        // Giữ nguyên trạng thái Chờ xử lý cho đến khi KTV có mặt bấm Bắt đầu
        activityLogs: List<TicketActivityLogModel>.from(t.activityLogs)..add(log),
      );
      notifyListeners();
    }
  }

  /// Kỹ thuật viên bấm Bắt đầu sửa chữa (Chuyển sang "Đang sửa" và ghi nhận audit log)
  void startRepair(int ticketId, {String? technicianName}) {
    final index = _tickets.indexWhere((t) => t.ticketId == ticketId);
    if (index != -1) {
      final t = _tickets[index];
      final actor = technicianName ?? t.technicianName ?? 'Kỹ thuật viên';
      final log = TicketActivityLogModel(
        logId: DateTime.now().millisecondsSinceEpoch % 10000,
        action: 'Bắt đầu sửa chữa',
        actorName: actor,
        note: 'Kỹ thuật viên đã có mặt tại hiện trường và bắt đầu xử lý sự cố',
        timestamp: DateTime.now(),
      );

      _tickets[index] = t.copyWith(
        status: 'Đang sửa',
        activityLogs: List<TicketActivityLogModel>.from(t.activityLogs)..add(log),
      );
      notifyListeners();
    }
  }

  /// Kỹ thuật viên / Quản lý bấm Hoàn thành (Cập nhật vật tư, thời gian hoàn thành & ghi log)
  void completeRepair(int ticketId, {double? materialCost, String? note, String? technicianName}) {
    final index = _tickets.indexWhere((t) => t.ticketId == ticketId);
    if (index != -1) {
      final t = _tickets[index];
      final actor = technicianName ?? t.technicianName ?? 'Kỹ thuật viên';
      final log = TicketActivityLogModel(
        logId: DateTime.now().millisecondsSinceEpoch % 10000,
        action: 'Hoàn thành sửa chữa',
        actorName: actor,
        note: note ?? (materialCost != null && materialCost > 0
            ? 'Đã thay thế linh kiện (Chi phí vật tư: ${materialCost.round()} đ)'
            : 'Đã khắc phục xong sự cố, nghiệm thu tốt'),
        timestamp: DateTime.now(),
      );

      _tickets[index] = t.copyWith(
        status: 'Hoàn thành',
        completedAt: DateTime.now(),
        materialCost: materialCost ?? 0.0,
        activityLogs: List<TicketActivityLogModel>.from(t.activityLogs)..add(log),
      );
      notifyListeners();
    }
  }

  /// Cập nhật trạng thái trực tiếp
  void updateTicketStatus(int ticketId, String newStatus, {String actorName = 'Hệ thống', String? note}) {
    final index = _tickets.indexWhere((t) => t.ticketId == ticketId);
    if (index != -1) {
      final t = _tickets[index];
      final log = TicketActivityLogModel(
        logId: DateTime.now().millisecondsSinceEpoch % 10000,
        action: 'Chuyển trạng thái sang $newStatus',
        actorName: actorName,
        note: note,
        timestamp: DateTime.now(),
      );

      _tickets[index] = t.copyWith(
        status: newStatus,
        completedAt: newStatus == 'Hoàn thành' ? DateTime.now() : t.completedAt,
        activityLogs: List<TicketActivityLogModel>.from(t.activityLogs)..add(log),
      );
      notifyListeners();
    }
  }
}
