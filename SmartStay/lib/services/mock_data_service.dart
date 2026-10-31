import '../models/user_model.dart';
import '../models/contract_model.dart';
import '../models/invoice_model.dart';
import '../models/ticket_model.dart';
import '../models/announcement_model.dart';
import '../models/chat_message_model.dart';

class MockDataService {
  static final MockDataService _instance = MockDataService._internal();
  factory MockDataService() => _instance;
  MockDataService._internal();

  UserModel currentUser = UserModel(
    userId: 101,
    username: '2380600133',
    email: 'hongocbao@smartstay.vn',
    phone: '0901234567',
    fullName: 'Hồ Ngọc Bảo',
    role: 'Cư dân',
    residentProfile: ResidentProfile(
      residentId: 101,
      roomCode: 'P.305',
      buildingName: 'Tòa nhà A - Co-Living SmartStay',
      floorNumber: 3,
      dateOfBirth: DateTime(2003, 5, 15),
      gender: 'Nam',
      idCardNumber: '079203001234',
      permanentAddress: '123 Đường Điện Biên Phủ, Phường 25, Bình Thạnh, TP.HCM',
      emergencyContactName: 'Hồ Văn Minh (Phụ huynh)',
      emergencyContactPhone: '0988776655',
    ),
  );

  ContractModel contract = ContractModel(
    contractId: 305,
    contractCode: 'HD-2026-0305',
    roomCode: 'P.305',
    buildingName: 'Tòa nhà A (Tầng 3)',
    startDate: DateTime(2026, 8, 1),
    endDate: DateTime(2027, 7, 31),
    monthlyRent: 3500000,
    depositAmount: 7000000,
    terms: 'Hợp đồng thuê căn hộ Co-Living thông minh thời hạn 12 tháng. '
        'Bao gồm quyền sử dụng các tiện ích chung tại sảnh tầng 1, phòng tự học và sân thượng. '
        'Thanh toán định kỳ hàng tháng từ ngày 1 đến ngày 5.',
    status: 'Đang hiệu lực',
    assets: [
      RoomAssetModel(
        assetId: 1,
        assetName: 'Máy lạnh Inverter Daikin 1.5HP',
        quantity: 1,
        condition: 'Hoạt động tốt, mới 98%',
        compensationValue: 9500000,
      ),
      RoomAssetModel(
        assetId: 2,
        assetName: 'Giường thông minh kèm nệm cao su non',
        quantity: 1,
        condition: 'Mới, nguyên vẹn không trầy xước',
        compensationValue: 4500000,
      ),
      RoomAssetModel(
        assetId: 3,
        assetName: 'Tủ quần áo 2 buồng cánh trượt',
        quantity: 1,
        condition: 'Tốt',
        compensationValue: 3200000,
      ),
      RoomAssetModel(
        assetId: 4,
        assetName: 'Bàn ghế học tập công thái học',
        quantity: 1,
        condition: 'Mới 100%',
        compensationValue: 1800000,
      ),
      RoomAssetModel(
        assetId: 5,
        assetName: 'Khóa cửa vân tay / thẻ từ thông minh',
        quantity: 1,
        condition: 'Hoạt động ổn định',
        compensationValue: 2500000,
      ),
    ],
  );

  List<InvoiceModel> invoices = [
    InvoiceModel(
      invoiceId: 101,
      invoiceCode: 'HD-2026-10-305',
      roomCode: 'P.305',
      billingMonth: DateTime(2026, 10, 1),
      issueDate: DateTime(2026, 10, 25),
      dueDate: DateTime(2026, 11, 5),
      roomPrice: 3500000,
      electricPrice: 254000,
      waterPrice: 105000,
      servicePrice: 300000,
      discountPrice: 0,
      totalAmount: 4159000,
      paidAmount: 0,
      qrContent: 'HD1026 P305 HONGOCBAO',
      urlVietQr:
          'https://img.vietqr.io/image/970422-0987654321-compact2.png?amount=4159000&addInfo=HD1026%20P305%20HONGOCBAO&accountName=SMARTSTAY%20MANAGEMENT',
      status: 'Đã phát hành',
      items: [
        InvoiceItemModel(
          itemId: 1,
          itemType: 'TienPhong',
          description: 'Tiền thuê phòng tháng 10/2026',
          quantity: 1,
          unitPrice: 3500000,
          amount: 3500000,
        ),
        InvoiceItemModel(
          itemId: 2,
          itemType: 'Dien',
          description: 'Điện Bậc 1 (0 - 50 kWh) [Chỉ số: 1250 -> 1300]',
          quantity: 50,
          unitPrice: 1800,
          amount: 90000,
        ),
        InvoiceItemModel(
          itemId: 3,
          itemType: 'Dien',
          description: 'Điện Bậc 2 (51 - 100 kWh) [Chỉ số: 1301 -> 1350]',
          quantity: 50,
          unitPrice: 2200,
          amount: 110000,
        ),
        InvoiceItemModel(
          itemId: 4,
          itemType: 'Dien',
          description: 'Điện Bậc 3 (101 - 120 kWh) [Chỉ số: 1351 -> 1370]',
          quantity: 20,
          unitPrice: 2700,
          amount: 54000,
        ),
        InvoiceItemModel(
          itemId: 5,
          itemType: 'Nuoc',
          description: 'Nước Bậc 1 (0 - 5 m³) [Chỉ số: 45 -> 50]',
          quantity: 5,
          unitPrice: 12000,
          amount: 60000,
        ),
        InvoiceItemModel(
          itemId: 6,
          itemType: 'Nuoc',
          description: 'Nước Bậc 2 (6 - 8 m³) [Chỉ số: 51 -> 53]',
          quantity: 3,
          unitPrice: 15000,
          amount: 45000,
        ),
        InvoiceItemModel(
          itemId: 7,
          itemType: 'DichVu',
          description: 'Wifi Internet cáp quang tốc độ cao',
          quantity: 1,
          unitPrice: 100000,
          amount: 100000,
        ),
        InvoiceItemModel(
          itemId: 8,
          itemType: 'DichVu',
          description: 'Vệ sinh khu vực chung & Thu gom rác',
          quantity: 1,
          unitPrice: 50000,
          amount: 50000,
        ),
        InvoiceItemModel(
          itemId: 9,
          itemType: 'DichVu',
          description: 'Phí dịch vụ vận hành & bảo trì tòa nhà',
          quantity: 1,
          unitPrice: 150000,
          amount: 150000,
        ),
      ],
      payments: [],
    ),
    InvoiceModel(
      invoiceId: 100,
      invoiceCode: 'HD-2026-09-305',
      roomCode: 'P.305',
      billingMonth: DateTime(2026, 9, 1),
      issueDate: DateTime(2026, 9, 25),
      dueDate: DateTime(2026, 10, 5),
      roomPrice: 3500000,
      electricPrice: 242000,
      waterPrice: 96000,
      servicePrice: 300000,
      discountPrice: 0,
      totalAmount: 4138000,
      paidAmount: 4138000,
      qrContent: 'HD0926 P305 HONGOCBAO',
      urlVietQr: '',
      status: 'Đã thanh toán',
      items: [
        InvoiceItemModel(
          itemId: 10,
          itemType: 'TienPhong',
          description: 'Tiền thuê phòng tháng 09/2026',
          quantity: 1,
          unitPrice: 3500000,
          amount: 3500000,
        ),
        InvoiceItemModel(
          itemId: 11,
          itemType: 'Dien',
          description: 'Tiền điện tháng 09 (115 kWh)',
          quantity: 115,
          unitPrice: 2104.3,
          amount: 242000,
        ),
        InvoiceItemModel(
          itemId: 12,
          itemType: 'Nuoc',
          description: 'Tiền nước tháng 09 (7.5 m³)',
          quantity: 7.5,
          unitPrice: 12800,
          amount: 96000,
        ),
        InvoiceItemModel(
          itemId: 13,
          itemType: 'DichVu',
          description: 'Dịch vụ cố định (Wifi, Rác, Quản lý)',
          quantity: 1,
          unitPrice: 300000,
          amount: 300000,
        ),
      ],
      payments: [
        PaymentModel(
          paymentId: 55,
          amount: 4138000,
          paymentMethod: 'VietQR - Chuyển khoản',
          paidAt: DateTime(2026, 9, 28, 10, 30),
          receiptImageUrl: 'https://smartstay.vn/receipts/rec_0926_305.png',
          status: 'Đã xác nhận',
          note: 'Ban quản lý đã đối soát thành công.',
        ),
      ],
    ),
  ];

  List<TicketModel> tickets = [
    TicketModel(
      ticketId: 201,
      ticketCode: 'SC-2026-089',
      roomCode: 'P.305',
      categoryName: 'Máy lạnh',
      technicianName: 'Nguyễn Văn Bình (Kỹ thuật điện lạnh)',
      title: 'Máy lạnh không lạnh sâu và bị rỉ nước ở dàn lạnh',
      description:
          'Máy lạnh phòng P.305 bật 20 độ nhưng gió không mát, khoảng 30 phút sau có nước nhỏ giọt xuống sàn gỗ.',
      priority: 'Cao',
      status: 'Đang sửa',
      createdAt: DateTime(2026, 10, 29, 9, 15),
      deadline: DateTime(2026, 10, 31, 17, 0),
      images: [
        TicketImageModel(
          imageId: 1,
          mediaUrl: 'https://smartstay.vn/uploads/ticket_ac_water.jpg',
          imageType: 'TruocSuaChua',
        ),
      ],
      comments: [
        TicketCommentModel(
          commentId: 1,
          authorName: 'Hồ Ngọc Bảo',
          content: 'Nhờ kỹ thuật ghé kiểm tra sớm giúp em với ạ, em ở phòng cả ngày.',
          createdAt: DateTime(2026, 10, 29, 9, 20),
          isFromResident: true,
        ),
        TicketCommentModel(
          commentId: 2,
          authorName: 'Nguyễn Văn Bình (Kỹ thuật)',
          content: 'Chào em, chiều nay 14h30 anh sẽ lên vệ sinh máng thoát nước và nạp bổ sung gas nhé.',
          createdAt: DateTime(2026, 10, 29, 10, 5),
          isFromResident: false,
        ),
      ],
    ),
    TicketModel(
      ticketId: 195,
      ticketCode: 'SC-2026-074',
      roomCode: 'P.305',
      categoryName: 'Điện',
      technicianName: 'Trần Văn Tuấn',
      title: 'Thay bóng đèn LED chiếu sáng bàn học',
      description: 'Bóng đèn LED dài trên kệ sách bàn học bị chớp nháy liên tục khi bật công tắc.',
      priority: 'Trung bình',
      status: 'Hoàn thành',
      createdAt: DateTime(2026, 10, 20, 14, 0),
      deadline: DateTime(2026, 10, 21, 17, 0),
      completedAt: DateTime(2026, 10, 21, 10, 30),
      rating: 5,
      ratingComment: 'Anh kỹ thuật đến đúng giờ, thay bóng mới rất sáng và nhiệt tình.',
      images: [],
      comments: [
        TicketCommentModel(
          commentId: 10,
          authorName: 'Trần Văn Tuấn',
          content: 'Đã thay thế bộ tăng phô và bóng LED Philips 12W mới cho phòng.',
          createdAt: DateTime(2026, 10, 21, 10, 25),
          isFromResident: false,
        ),
      ],
    ),
  ];

  List<AnnouncementModel> announcements = [
    AnnouncementModel(
      announcementId: 1,
      title: 'Bảo trì hệ thống thang máy Tòa nhà A',
      content:
          'Ban Quản lý thông báo: Để đảm bảo an toàn vận hành, kỹ thuật viên sẽ tiến hành bảo dưỡng định kỳ thang máy số 1 từ 14:00 đến 16:30 Chủ Nhật ngày 01/11/2026. Trong thời gian này cư dân vui lòng sử dụng thang bộ hoặc thang máy số 2.',
      scope: 'Tòa nhà A',
      createdAt: DateTime(2026, 10, 29, 8, 0),
      isImportant: true,
    ),
    AnnouncementModel(
      announcementId: 2,
      title: 'Nhắc nhở chốt chỉ số điện nước kỳ tháng 10/2026',
      content:
          'Hệ thống đã tự động ghi nhận chỉ số điện nước tháng 10/2026 và phát hành hóa đơn. Cư dân vui lòng kiểm tra chi tiết trên ứng dụng và hoàn tất thanh toán trước ngày 05/11/2026.',
      scope: 'Toàn hệ sinh thái',
      createdAt: DateTime(2026, 10, 25, 10, 0),
      isImportant: false,
    ),
    AnnouncementModel(
      announcementId: 3,
      title: 'Quy định giữ trật tự và an ninh sau 23:00',
      content:
          'Nhằm tạo không gian nghỉ ngơi yên tĩnh cho cộng đồng cư dân, Ban Quản lý đề nghị tất cả phòng hạn chế gây tiếng ồn lớn sau 23h đêm. Vui lòng đóng cửa nhẹ nhàng và tuân thủ nội quy tòa nhà.',
      scope: 'Toàn hệ sinh thái',
      createdAt: DateTime(2026, 10, 22, 17, 0),
      isImportant: false,
    ),
  ];

  List<EventModel> events = [
    EventModel(
      eventId: 1,
      title: 'Giải chạy bộ nội khu KTXRace 2026 - Kết nối cộng đồng',
      description:
          'Giải chạy phong trào cự ly 5km xung quanh khuôn viên công viên ven sông, nhằm nâng cao sức khỏe và kết nối các thành viên sinh sống tại SmartStay. Có áo thi đấu, huy chương và tiệc nướng BBQ sau giải chạy!',
      location: 'Sân trung tâm Tòa A & Đường chạy ven sông',
      startTime: DateTime(2026, 11, 8, 6, 0),
      endTime: DateTime(2026, 11, 8, 10, 30),
      registrationDeadline: DateTime(2026, 11, 5, 23, 59),
      maxParticipants: 60,
      currentParticipants: 42,
      isRegistered: true,
    ),
    EventModel(
      eventId: 2,
      title: 'Workshop: Kỹ năng sống & Tự lập cho sinh viên Co-Living',
      description:
          'Buổi chia sẻ thân mật cùng khách mời tâm lý học về cách quản lý tài chính cá nhân, sống hòa thuận trong không gian chia sẻ và cân bằng giữa việc học - làm việc.',
      location: 'Phòng sinh hoạt cộng đồng tầng 1 (Lounge A)',
      startTime: DateTime(2026, 11, 14, 18, 30),
      endTime: DateTime(2026, 11, 14, 20, 30),
      registrationDeadline: DateTime(2026, 11, 12, 18, 0),
      maxParticipants: 40,
      currentParticipants: 28,
      isRegistered: false,
    ),
  ];

  List<ChatMessageModel> chatMessages = [
    ChatMessageModel(
      id: '1',
      content:
          'Xin chào bạn Bảo! Mình là SmartStay AI - Trợ lý ảo hỗ trợ cư dân 24/7. Bạn cần mình giải đáp về hóa đơn, cách tính điện nước bậc thang, báo hỏng thiết bị hay quy định lưu trú nào không?',
      isUser: false,
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
  ];

  // AI response generator
  String getAiResponse(String question) {
    final q = question.toLowerCase();
    if (q.contains('điện') || q.contains('nước') || q.contains('bậc thang')) {
      return 'Hệ thống SmartStay áp dụng biểu giá bậc thang lũy tiến minh bạch:\n'
          '⚡ Biểu giá Điện:\n'
          '• Bậc 1 (0 - 50 kWh): 1.800 đ/kWh\n'
          '• Bậc 2 (51 - 100 kWh): 2.200 đ/kWh\n'
          '• Bậc 3 (101 - 200 kWh): 2.700 đ/kWh\n'
          '• Bậc 4 (> 200 kWh): 3.200 đ/kWh\n\n'
          '💧 Biểu giá Nước:\n'
          '• Bậc 1 (0 - 5 m³): 12.000 đ/m³\n'
          '• Bậc 2 (6 - 10 m³): 15.000 đ/m³\n'
          '• Bậc 3 (> 10 m³): 18.000 đ/m³\n\n'
          'Trong hóa đơn tháng 10 của phòng bạn (P.305), lượng điện tiêu thụ là 120 kWh và nước là 8 m³ đã được tính chi tiết theo từng bậc!';
    } else if (q.contains('thanh toán') || q.contains('vietqr') || q.contains('chuyển khoản')) {
      return 'Để thanh toán hóa đơn bằng VietQR:\n'
          '1. Vào tab "Hóa đơn" trên ứng dụng và chọn hóa đơn tháng cần thanh toán.\n'
          '2. Bấm "Thanh toán VietQR ngay". Hệ thống sẽ tạo mã QR động có sẵn số tiền và nội dung phòng P.305.\n'
          '3. Mở app ngân hàng bất kỳ để quét mã.\n'
          '4. Sau khi chuyển xong, bạn có thể tải ảnh biên lai lên app để Ban Quản lý đối soát nhanh trong vòng 1-2 giờ làm việc.';
    } else if (q.contains('sự cố') || q.contains('sửa') || q.contains('hỏng') || q.contains('máy lạnh')) {
      return 'Khi thiết bị trong phòng gặp sự cố:\n'
          '1. Bạn vào tab "Sự cố" -> Bấm nút "+" (Báo sự cố mới).\n'
          '2. Chọn danh mục sự cố (Máy lạnh, Điện, Nước, Nội thất...).\n'
          '3. Mô tả tình trạng và mức độ ưu tiên.\n'
          '4. Phiếu sẽ được chuyển ngay lên bảng Kanban của Ban Quản lý và phân công Kỹ thuật viên xử lý.\n'
          'Hiện tại sự cố máy lạnh (SC-2026-089) của phòng bạn đang ở trạng thái "Đang sửa" và dự kiến hoàn tất trong chiều nay.';
    } else if (q.contains('nội quy') || q.contains('giờ giấc') || q.contains('bạn bè')) {
      return 'Một số nội quy quan trọng tại SmartStay Co-Living:\n'
          '• Giờ đóng cổng chính: Tự do ra vào 24/7 bằng thẻ từ/vân tay thông minh.\n'
          '• Khung giờ yên tĩnh: Từ 23:00 đến 06:00 sáng hôm sau.\n'
          '• Tiếp khách: Khách ngoài được vào phòng sinh hoạt chung tại tầng 1 đến 22:00. Ở lại qua đêm cần đăng ký trước với Ban Quản lý trên app.';
    } else {
      return 'Cảm ơn câu hỏi của bạn! Ban Quản lý SmartStay luôn sẵn sàng đồng hành cùng cư dân phòng P.305. '
          'Nếu cần hỗ trợ kỹ thuật khẩn cấp ngoài giờ hành chính, bạn có thể liên hệ hotline hotline nội bộ: 1900 8899 hoặc gửi phiếu báo sự cố khẩn cấp trên app nhé!';
    }
  }
}
