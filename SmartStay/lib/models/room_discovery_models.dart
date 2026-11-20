class RoomDiscoveryListing {
  final int roomId;
  final String roomCode;
  final String title;
  final String roomType;
  final int floor;
  final double area;
  final int capacity;
  final double rentPrice;
  final String status; // Trống, Đang ở, Đã đặt, Bảo trì
  final String description;
  final List<String> amenities;
  final bool isOpenForRent;
  final int viewCount;
  final double rating;
  final List<String> imageUrls;
  final String? videoTourUrl;
  final DateTime updatedAt;

  const RoomDiscoveryListing({
    required this.roomId,
    required this.roomCode,
    required this.title,
    required this.roomType,
    required this.floor,
    required this.area,
    required this.capacity,
    required this.rentPrice,
    required this.status,
    required this.description,
    required this.amenities,
    required this.isOpenForRent,
    required this.viewCount,
    required this.rating,
    required this.imageUrls,
    this.videoTourUrl,
    required this.updatedAt,
  });

  bool get hasVideoTour => videoTourUrl != null && videoTourUrl!.trim().isNotEmpty;

  String get coverImageUrl => imageUrls.isNotEmpty
      ? imageUrls.first
      : 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&w=900&q=80';

  RoomDiscoveryListing copyWith({
    int? roomId,
    String? roomCode,
    String? title,
    String? roomType,
    int? floor,
    double? area,
    int? capacity,
    double? rentPrice,
    String? status,
    String? description,
    List<String>? amenities,
    bool? isOpenForRent,
    int? viewCount,
    double? rating,
    List<String>? imageUrls,
    String? videoTourUrl,
    bool clearVideoTour = false,
    DateTime? updatedAt,
  }) {
    return RoomDiscoveryListing(
      roomId: roomId ?? this.roomId,
      roomCode: roomCode ?? this.roomCode,
      title: title ?? this.title,
      roomType: roomType ?? this.roomType,
      floor: floor ?? this.floor,
      area: area ?? this.area,
      capacity: capacity ?? this.capacity,
      rentPrice: rentPrice ?? this.rentPrice,
      status: status ?? this.status,
      description: description ?? this.description,
      amenities: amenities ?? this.amenities,
      isOpenForRent: isOpenForRent ?? this.isOpenForRent,
      viewCount: viewCount ?? this.viewCount,
      rating: rating ?? this.rating,
      imageUrls: imageUrls ?? this.imageUrls,
      videoTourUrl: clearVideoTour ? null : (videoTourUrl ?? this.videoTourUrl),
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory RoomDiscoveryListing.fromJson(Map<String, dynamic> json) {
    final rawImages = json['hinhAnhUrls'] ?? json['HinhAnhUrls'];
    final images = rawImages is List
        ? rawImages
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList()
        : <String>[];

    final rawAmenities = json['tienIchNoiBat'] ?? json['TienIchNoiBat'];
    final amenities = rawAmenities is List
        ? rawAmenities
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList()
        : (rawAmenities is String && rawAmenities.trim().isNotEmpty
            ? rawAmenities
                .split(RegExp(r'[,;|]'))
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList()
            : <String>[
                'Khóa vân tay IoT',
                'Máy lạnh Inverter',
                'Wi-Fi 6 tốc độ cao',
              ]);

    final rawVideo = (json['videoTourUrl'] ?? json['VideoTourUrl'] ?? '').toString().trim();
    final updatedRaw = (json['capNhatLuc'] ?? json['CapNhatLuc'] ?? '').toString();

    return RoomDiscoveryListing(
      roomId: ((json['maPhong'] ?? json['MaPhong'] ?? 0) as num).toInt(),
      roomCode: (json['kyHieuPhong'] ?? json['KyHieuPhong'] ?? 'P.102').toString(),
      title: (json['tieuDe'] ?? json['TieuDe'] ?? json['TieuDeChoThue'] ?? 'Căn hộ SmartStay')
          .toString(),
      roomType: (json['loaiPhong'] ?? json['LoaiPhong'] ?? 'Studio SmartStay').toString(),
      floor: ((json['soTang'] ?? json['SoTang'] ?? 1) as num).toInt(),
      area: ((json['dienTich'] ?? json['DienTich'] ?? 26) as num).toDouble(),
      capacity: ((json['sucChua'] ?? json['SucChua'] ?? 2) as num).toInt(),
      rentPrice: ((json['giaThue'] ?? json['GiaThue'] ?? 3500000) as num).toDouble(),
      status: (json['trangThai'] ?? json['TrangThai'] ?? 'Trống').toString(),
      description: (json['moTa'] ?? json['MoTa'] ?? '').toString(),
      amenities: amenities,
      isOpenForRent: (json['dangMoChoThue'] ?? json['DangMoChoThue'] ?? true) == true,
      viewCount: ((json['luotXem'] ?? json['LuotXem'] ?? 24) as num).toInt(),
      rating: ((json['diemDanhGia'] ?? json['DiemDanhGia'] ?? 4.8) as num).toDouble(),
      imageUrls: images.isNotEmpty
          ? images
          : const [
              'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&w=900&q=80',
            ],
      videoTourUrl: rawVideo.isEmpty ? null : rawVideo,
      updatedAt: DateTime.tryParse(updatedRaw) ?? DateTime.now(),
    );
  }
}

class RoomRegistrationRequest {
  final String maPhieu;
  final int roomId;
  final String roomCode;
  final int? residentId;
  final String requestType; // ThueMoi | ChuyenPhong
  final String fullName;
  final String phone;
  final String? nationalId;
  final DateTime expectedMoveInDate;
  final String? note;
  final String status; // ChoDuyet | DaDuyet | TuChoi
  final String? rejectReason;
  final int? draftContractId;
  final String? draftContractCode;
  final DateTime createdAt;

  const RoomRegistrationRequest({
    required this.maPhieu,
    required this.roomId,
    required this.roomCode,
    this.residentId,
    required this.requestType,
    required this.fullName,
    required this.phone,
    this.nationalId,
    required this.expectedMoveInDate,
    this.note,
    required this.status,
    this.rejectReason,
    this.draftContractId,
    this.draftContractCode,
    required this.createdAt,
  });

  bool get isPending => status == 'ChoDuyet';
  bool get isApproved => status == 'DaDuyet';
  bool get isRejected => status == 'TuChoi';

  String get requestTypeLabel =>
      requestType == 'ChuyenPhong' ? 'Xin chuyển phòng' : 'Đăng ký thuê mới';

  String get statusLabel {
    switch (status) {
      case 'DaDuyet':
        return 'Đã duyệt';
      case 'TuChoi':
        return 'Từ chối';
      default:
        return 'Chờ duyệt';
    }
  }

  RoomRegistrationRequest copyWith({
    String? status,
    String? rejectReason,
    int? draftContractId,
    String? draftContractCode,
  }) {
    return RoomRegistrationRequest(
      maPhieu: maPhieu,
      roomId: roomId,
      roomCode: roomCode,
      residentId: residentId,
      requestType: requestType,
      fullName: fullName,
      phone: phone,
      nationalId: nationalId,
      expectedMoveInDate: expectedMoveInDate,
      note: note,
      status: status ?? this.status,
      rejectReason: rejectReason ?? this.rejectReason,
      draftContractId: draftContractId ?? this.draftContractId,
      draftContractCode: draftContractCode ?? this.draftContractCode,
      createdAt: createdAt,
    );
  }

  factory RoomRegistrationRequest.fromJson(Map<String, dynamic> json) {
    final moveInRaw =
        (json['ngayDuKienVaoO'] ?? json['NgayDuKienVaoO'] ?? '').toString();
    final createdRaw = (json['taoLuc'] ?? json['TaoLuc'] ?? '').toString();
    return RoomRegistrationRequest(
      maPhieu: (json['maPhieu'] ?? json['MaPhieu'] ?? '').toString(),
      roomId: ((json['maPhong'] ?? json['MaPhong'] ?? 0) as num).toInt(),
      roomCode: (json['kyHieuPhong'] ?? json['KyHieuPhong'] ?? 'P.102').toString(),
      residentId: (json['maCuDan'] ?? json['MaCuDan']) is num
          ? ((json['maCuDan'] ?? json['MaCuDan']) as num).toInt()
          : null,
      requestType:
          (json['loaiYeuCau'] ?? json['LoaiYeuCau'] ?? 'ThueMoi').toString(),
      fullName: (json['hoTen'] ?? json['HoTen'] ?? 'Khách đăng ký').toString(),
      phone: (json['soDienThoai'] ?? json['SoDienThoai'] ?? '').toString(),
      nationalId: (json['soCanCuoc'] ?? json['SoCanCuoc'])?.toString(),
      expectedMoveInDate:
          DateTime.tryParse(moveInRaw) ?? DateTime.now().add(const Duration(days: 3)),
      note: (json['ghiChu'] ?? json['GhiChu'])?.toString(),
      status: (json['trangThai'] ?? json['TrangThai'] ?? 'ChoDuyet').toString(),
      rejectReason: (json['lyDoTuChoi'] ?? json['LyDoTuChoi'])?.toString(),
      draftContractId: (json['maHopDongTao'] ?? json['MaHopDongTao']) is num
          ? ((json['maHopDongTao'] ?? json['MaHopDongTao']) as num).toInt()
          : null,
      draftContractCode:
          (json['draftContractCode'] ?? json['DraftContractCode'])?.toString(),
      createdAt: DateTime.tryParse(createdRaw) ?? DateTime.now(),
    );
  }
}
