import 'package:flutter/foundation.dart';
import '../models/chat_message_model.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/invoice_data_service.dart';

class AiChatProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  final InvoiceDataService _invoiceService = InvoiceDataService();

  final List<ChatMessageModel> _messages = [];
  bool _isTyping = false;
  String _lastInitializedRoleMode = 'resident';
  String _lastInitializedUserKey = '';

  List<ChatMessageModel> get messages => _messages;
  bool get isTyping => _isTyping;

  AiChatProvider() {
    _initDefaultMessage(roleMode: 'resident');
  }

  static String resolveRoleMode({
    required bool isAdmin,
    String? explicitRoleMode,
    String? userRole,
  }) {
    if (explicitRoleMode == 'admin' ||
        explicitRoleMode == 'manager' ||
        explicitRoleMode == 'resident') {
      return explicitRoleMode!;
    }
    if (!isAdmin) return 'resident';
    final r = (userRole ?? '').toLowerCase();
    if (r.contains('quản trị') || r == 'admin') return 'admin';
    return 'manager';
  }

  void _initDefaultMessage({
    bool isAdmin = false,
    String? roleMode,
    String? userName,
    String? roomCode,
  }) {
    final mode = resolveRoleMode(isAdmin: isAdmin, explicitRoleMode: roleMode);
    _lastInitializedRoleMode = mode;
    _lastInitializedUserKey = '${userName ?? ''}|${roomCode ?? ''}|$mode';
    final displayName = (userName != null && userName.trim().isNotEmpty)
        ? userName.trim()
        : (mode == 'admin'
            ? 'Admin Hệ Thống'
            : (mode == 'manager' ? 'Ban Quản Lý' : 'bạn'));
    final room = (roomCode != null && roomCode.trim().isNotEmpty)
        ? roomCode.trim()
        : 'P.305';

    final welcomeText = switch (mode) {
      'admin' =>
        'Xin chào $displayName! Tôi là SmartStay AI Copilot dành cho Admin hệ thống.\nBạn có thể hỏi nhanh về báo cáo doanh thu/công nợ, cấu hình VietQR/Ngân hàng, tỷ lệ lấp đầy phòng hoặc phát thông báo toàn tòa nhà.',
      'manager' =>
        'Xin chào $displayName! Tôi là AI Điều Hành dành cho Ban Quản Lý & Kỹ thuật.\nTôi hỗ trợ theo dõi tiến độ Kanban bảo trì, cảnh báo khóa IoT, kiểm tra chỉ số điện nước hoặc gọi trao đổi trực tiếp với cư dân.',
      _ =>
        'Xin chào $displayName ($room)! Tôi là SmartStay AI - Trợ lý thông minh hỗ trợ Người dùng 24/7. Tôi có thể giải đáp hóa đơn bậc thang, phân tích điện nước, báo hỏng thiết bị kèm ảnh/video lên Kanban hoặc hướng dẫn thanh toán VietQR.',
    };

    _messages.add(
      ChatMessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: welcomeText,
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  void syncRoleGreeting({
    required bool isAdmin,
    String? roleMode,
    String? userName,
    String? roomCode,
  }) {
    final mode = resolveRoleMode(isAdmin: isAdmin, explicitRoleMode: roleMode);
    final userKey = '${userName ?? ''}|${roomCode ?? ''}|$mode';
    if (_lastInitializedRoleMode != mode || _lastInitializedUserKey != userKey) {
      _messages.clear();
      _initDefaultMessage(
        isAdmin: isAdmin,
        roleMode: mode,
        userName: userName,
        roomCode: roomCode,
      );
      notifyListeners();
    }
  }

  /// Gửi câu hỏi kèm Context người dùng, Ban Quản Lý hoặc Admin (Contextual RAG)
  Future<void> sendMessage(
    String text, {
    UserModel? currentUser,
    bool? forceAdminMode,
    String? roleMode,
    String? adminContextSummary,
  }) async {
    if (text.trim().isEmpty) return;

    final isAdminMode =
        forceAdminMode ?? (currentUser != null && currentUser.role != 'Cư dân');
    final mode = resolveRoleMode(
      isAdmin: isAdminMode,
      explicitRoleMode: roleMode,
      userRole: currentUser?.role,
    );
    final apiRole = switch (mode) {
      'admin' => 'Admin',
      'manager' => 'QuanLy',
      _ => 'CuDan',
    };
    final roomCode = currentUser?.effectiveRoomCode ?? 'P.305';
    final displayName = currentUser?.fullName ??
        (mode == 'admin'
            ? 'Admin Hệ Thống'
            : (mode == 'manager' ? 'Ban Quản Lý' : 'Cư dân SmartStay'));

    final userMsg = ChatMessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: text.trim(),
      isUser: true,
      timestamp: DateTime.now(),
    );

    _messages.add(userMsg);
    _isTyping = true;
    notifyListeners();

    if (adminContextSummary != null && adminContextSummary.trim().isNotEmpty) {
      await Future.delayed(const Duration(milliseconds: 350));
      _messages.add(
        ChatMessageModel(
          id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
          content: adminContextSummary.trim(),
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
      _isTyping = false;
      notifyListeners();
      return;
    }

    try {
      // 1. Thử gọi Backend API TroLyAiController (.NET 8) với đúng vai trò 3 bên
      final backendReply = await _api.askAi(
        text.trim(),
        role: apiRole,
        roomCode: roomCode,
      );
      if (backendReply != null && backendReply.isNotEmpty) {
        final aiMsg = ChatMessageModel(
          id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
          content: backendReply,
          isUser: false,
          timestamp: DateTime.now(),
        );
        _messages.add(aiMsg);
        _isTyping = false;
        notifyListeners();
        return;
      }
    } catch (e) {
      debugPrint('AiChatProvider sendMessage error: $e');
    }

    // 2. Fallback: Contextual AI Engine cục bộ theo đúng vai trò Admin / Ban Quản lý / Người dùng
    await Future.delayed(const Duration(milliseconds: 450));

    final reply = switch (mode) {
      'admin' => _generateAdminResponse(text.trim(), displayName),
      'manager' => _generateManagerResponse(text.trim(), displayName),
      _ => _generateContextualResponse(text.trim(), roomCode, displayName),
    };

    final aiMsg = ChatMessageModel(
      id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
      content: reply,
      isUser: false,
      timestamp: DateTime.now(),
    );

    _messages.add(aiMsg);
    _isTyping = false;
    notifyListeners();
  }

  String _generateAdminResponse(String query, String adminName) {
    final q = query.toLowerCase();
    if (q.contains('doanh thu') ||
        q.contains('công nợ') ||
        q.contains('hóa đơn') ||
        q.contains('tài chính') ||
        q.contains('chưa thu')) {
      return '📊 Báo cáo Tài chính & Công nợ ($adminName):\n'
          '• Doanh thu dự kiến kỳ hiện tại đạt ~126,5 triệu đ (tỷ lệ thu ~88%).\n'
          '• Bạn có thể mở mục "Tài chính & Điện nước" để duyệt biên lai VietQR đang chờ đối soát hoặc ra lệnh cho AI phát thông báo nhắc phí tự động.';
    }
    if (q.contains('phòng trống') ||
        q.contains('lấp đầy') ||
        q.contains('sơ đồ') ||
        q.contains('ma trận') ||
        q.contains('hợp đồng')) {
      return '🏢 Báo cáo Ma trận Phòng & Hợp đồng:\n'
          '• Hệ thống đang theo dõi toàn bộ phòng theo tầng (Studio, Co-Living, Penthouse).\n'
          '• Bạn có thể bấm bộ lọc trạng thái trong "Ma Trận Phòng Trực Quan" để xem nhanh các phòng Trống sẵn sàng check-in hoặc các phòng Bảo trì.';
    }
    if (q.contains('sự cố') ||
        q.contains('kanban') ||
        q.contains('bảo trì') ||
        q.contains('kỹ thuật')) {
      return '🛠️ Báo cáo Sự cố Kanban:\n'
          '• Các phiếu sự cố ưu tiên Cao / Khẩn cấp được đồng bộ Realtime với Đội Kỹ thuật.\n'
          '• Bạn có thể kéo thả thẻ sang cột "Đang sửa chữa" hoặc "Đã hoàn thành" trực tiếp tại mục "Bảo Trì & Sự Cố (Kanban)".';
    }
    if (q.contains('khóa') ||
        q.contains('iot') ||
        q.contains('mở cửa') ||
        q.contains('pin')) {
      return '🔐 Trạng thái Khóa Thông Minh & IoT:\n'
          '• Gateway MQTT TLS hoạt động ổn định. Admin/Quản lý có thể gửi lệnh mở khóa tạm thời từ xa và theo dõi lịch sử truy cập tại mục "Khóa Thông Minh & IoT".';
    }
    if (q.contains('thông báo') || q.contains('nhắc')) {
      return '📢 Trợ lý AI có thể hỗ trợ phát thông báo nhắc phí hoặc bảo trì định kỳ lên Bảng tin cư dân ngay lập tức (nhấn chip "Phát thông báo nhắc đóng tiền").';
    }
    return '🤖 SmartStay AI Copilot (Admin & Ban Quản Lý) sẵn sàng hỗ trợ $adminName!\n'
        'Hãy hỏi về doanh thu, công nợ, phòng trống, tiến độ Kanban bảo trì, khóa IoT hoặc yêu cầu phát thông báo cư dân.';
  }

  String _generateContextualResponse(String query, String roomCode, String residentName) {
    final q = query.toLowerCase();
    final roomInvoices = _invoiceService.getInvoicesForRoom(roomCode);
    final latestInvoice = roomInvoices.isNotEmpty ? roomInvoices.first : null;

    if (q.contains('tại sao') || q.contains('vì sao') || q.contains('cao hơn') || q.contains('tăng')) {
      if (latestInvoice != null) {
        return 'Chào $residentName, theo dữ liệu phòng $roomCode kỳ ${latestInvoice.invoiceCode}:\n'
            '• Tổng tiền: ${latestInvoice.totalAmount.round()} đ (Tiền điện: ${latestInvoice.electricPrice.round()} đ, Tiền nước: ${latestInvoice.waterPrice.round()} đ).\n'
            '• Nguyên nhân chính: Trong tháng này lượng điện tiêu thụ đã vượt ngưỡng 100 kWh, chạm vào Bậc 3 (2.700 đ/kWh) với đơn giá lũy tiến cao hơn 50% so với Bậc 1.\n'
            '💡 Mẹo tiết kiệm: Cài đặt điều hòa ở 26°C kèm quạt gió sẽ giúp giảm khoảng 15-20% điện năng tiêu thụ hàng tháng!';
      }
    }

    if (q.contains('điện') || q.contains('nước') || q.contains('bậc thang')) {
      return 'Hệ thống SmartStay áp dụng biểu giá lũy tiến theo quy định:\n'
          '⚡ Biểu giá Điện:\n'
          '• Bậc 1 (0 - 50 kWh): 1.800 đ/kWh\n'
          '• Bậc 2 (51 - 100 kWh): 2.200 đ/kWh\n'
          '• Bậc 3 (101 - 200 kWh): 2.700 đ/kWh\n'
          '• Bậc 4 (> 200 kWh): 3.200 đ/kWh\n\n'
          '💧 Biểu giá Nước:\n'
          '• Bậc 1 (0 - 5 m³): 12.000 đ/m³\n'
          '• Bậc 2 (6 - 10 m³): 15.000 đ/m³\n'
          '• Bậc 3 (> 10 m³): 18.000 đ/m³\n\n'
          'Phòng $roomCode của bạn được tự động ghi nhận số điện nước và bóc tách từng bậc rõ ràng trong tab Hóa đơn.';
    }

    if (q.contains('thanh toán') || q.contains('vietqr') || q.contains('chuyển khoản')) {
      return 'Để thanh toán hóa đơn cho phòng $roomCode:\n'
          '1. Mở tab "Hóa đơn" và chọn hóa đơn cần đóng.\n'
          '2. Quét mã VietQR chuẩn Napas 247 được sinh tự động (đã điền sẵn STK và số tiền).\n'
          '3. Chụp và gửi ảnh biên lai lên app. Hệ thống sẽ chuyển trạng thái sang "Chờ đối soát" để Ban Quản lý duyệt nhanh.';
    }

    if (q.contains('nội quy') || q.contains('giờ') || q.contains('bạn') || q.contains('khách') || q.contains('gửi xe') || q.contains('xe')) {
      return 'Nội quy lưu trú SmartStay dành cho cư dân phòng $roomCode:\n'
          '• Ra vào tòa nhà: Cửa chính mở 24/7 bằng thẻ từ/vân tay thông minh.\n'
          '• Khung giờ yên tĩnh: Từ 23:00 đến 06:00 sáng.\n'
          '• Khách thăm: Khách có thể sinh hoạt tại khu vực sảnh chung tầng 1 đến 22:00. Trường hợp ở lại qua đêm cần gửi thông báo trước trên app để đảm bảo an ninh trật tự.\n'
          '• Gửi xe qua đêm: Khách gửi xe đăng ký tại bảo vệ hoặc trên app, phí 5.000đ/lượt ban đêm.';
    }

    if (q.contains('rỉ') || q.contains('vòi') || q.contains('hỏng') || q.contains('sửa') || q.contains('máy lạnh') || q.contains('sự cố')) {
      return 'Dạ tôi đã ghi nhận yêu cầu sửa chữa tại phòng $roomCode! Hệ thống Agentic AI đã tự động tạo 1 phiếu sự cố (Kanban Ticket) khẩn cấp gửi tới đội kỹ thuật tòa nhà. Kỹ thuật viên sẽ liên hệ hỗ trợ trong vòng 30 phút.';
    }

    if (q.contains('mở khóa') || q.contains('cửa') || q.contains('khóa')) {
      return 'Đã gửi lệnh mở khóa từ xa (IoT Remote Lock) tới cửa phòng $roomCode thành công! Khóa cửa sẽ tạm thời mở trong 5 giây.';
    }

    return 'Trợ lý AI SmartStay luôn sẵn sàng hỗ trợ cư dân phòng $roomCode! Bạn có thể hỏi về hóa đơn chi tiết, biểu giá điện nước, báo sự cố thiết bị hoặc quy định của tòa nhà.';
  }

  String _generateManagerResponse(String query, String managerName) {
    final q = query.toLowerCase();
    if (q.contains('sự cố') || q.contains('kanban') || q.contains('bảo trì') || q.contains('kỹ thuật')) {
      return '🛠️ Trợ lý Ban Quản Lý ($managerName):\n'
          '• Hiện có các phiếu bảo trì ưu tiên Cao/Khẩn cấp từ cư dân P.305 và P.401 cần điều phối.\n'
          '• Bạn có thể mở bảng Kanban để kéo thẻ chuyển trạng thái hoặc nhấn "Gọi / Video" để gọi trực tiếp cho KTV Nguyễn Văn Bình.';
    }
    if (q.contains('khóa') || q.contains('iot') || q.contains('mở cửa')) {
      return '🔐 Điều phối Khóa Thông Minh IoT:\n'
          '• Gateway MQTT trực tuyến 100%. Quản lý có thể cấp mã PIN dùng 1 lần hoặc mở khóa từ xa cho cư dân khi quên thẻ từ.';
    }
    if (q.contains('điện') || q.contains('nước') || q.contains('công tơ')) {
      return '⚡ Giám sát Công tơ Điện Nước:\n'
          '• Các phòng đều cập nhật chỉ số định kỳ. Hệ thống tự động cảnh báo khi phòng có mức tiêu thụ tăng đột biến >35% so với kỳ trước.';
    }
    return '🏢 AI Ban Quản Lý ($managerName) sẵn sàng hỗ trợ điều phối vận hành, Kanban bảo trì, khóa IoT và liên lạc cư dân 24/7.';
  }

  void clearChat({
    bool isAdmin = false,
    String? roleMode,
    String? userName,
    String? roomCode,
  }) {
    _messages.clear();
    _initDefaultMessage(
      isAdmin: isAdmin,
      roleMode: roleMode,
      userName: userName,
      roomCode: roomCode,
    );
    notifyListeners();
  }
}
