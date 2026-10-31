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

  List<ChatMessageModel> get messages => _messages;
  bool get isTyping => _isTyping;

  AiChatProvider() {
    _initDefaultMessage();
  }

  void _initDefaultMessage() {
    _messages.add(
      ChatMessageModel(
        id: '1',
        content:
            'Xin chào! Tôi là SmartStay AI - Trợ lý thông minh hỗ trợ cư dân 24/7. Tôi có thể giải đáp chi tiết về hóa đơn bậc thang, phân tích điện nước tiêu thụ, tra cứu tiến độ xử lý sự cố hoặc nội quy tòa nhà. Bạn cần tôi hỗ trợ điều gì hôm nay?',
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  /// Gửi câu hỏi kèm Context người dùng (Contextual RAG)
  Future<void> sendMessage(String text, {UserModel? currentUser}) async {
    if (text.trim().isEmpty) return;

    final userMsg = ChatMessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: text.trim(),
      isUser: true,
      timestamp: DateTime.now(),
    );

    _messages.add(userMsg);
    _isTyping = true;
    notifyListeners();

    // 1. Thử gọi Backend API TroLyAiController (.NET 8)
    final backendReply = await _api.askAi(text.trim());
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

    // 2. Fallback: Contextual AI Engine cục bộ đọc trực tiếp hóa đơn và thông tin phòng của cư dân
    await Future.delayed(const Duration(milliseconds: 700));

    final roomCode = currentUser?.effectiveRoomCode ?? 'P.305';
    final residentName = currentUser?.fullName ?? 'bạn';
    final reply = _generateContextualResponse(text.trim(), roomCode, residentName);

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

    if (q.contains('nội quy') || q.contains('giờ') || q.contains('bạn') || q.contains('khách')) {
      return 'Nội quy lưu trú SmartStay dành cho cư dân:\n'
          '• Ra vào tòa nhà: Cửa chính mở 24/7 bằng thẻ từ/vân tay thông minh.\n'
          '• Khung giờ yên tĩnh: Từ 23:00 đến 06:00 sáng.\n'
          '• Khách thăm: Khách có thể sinh hoạt tại khu vực sảnh chung tầng 1 đến 22:00. Trường hợp ở lại qua đêm cần gửi thông báo trước trên app để đảm bảo an ninh trật tự.';
    }

    return 'Trợ lý AI SmartStay luôn sẵn sàng hỗ trợ cư dân phòng $roomCode! Bạn có thể hỏi về hóa đơn chi tiết, biểu giá điện nước, báo sự cố thiết bị hoặc quy định của tòa nhà.';
  }

  void clearChat() {
    _messages.clear();
    _initDefaultMessage();
    notifyListeners();
  }
}
