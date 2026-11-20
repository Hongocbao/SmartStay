import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/room_discovery_models.dart';
import '../services/api_service.dart';
import '../services/api_transport.dart';
import '../services/supabase_direct_service.dart';

/// Provider quản lý Module "Khám phá, Xem Video Tour & Đăng ký thuê phòng trực tuyến".
/// Hỗ trợ lưu bền vững Supabase PostgreSQL + Đồng bộ Real-time + phát Toast thông báo tức thì.
class RoomDiscoveryProvider extends ChangeNotifier {
  final SupabaseDirectService _supabase = SupabaseDirectService();

  List<RoomDiscoveryListing> _listings = [];
  List<RoomRegistrationRequest> _registrations = [];
  bool _isLoading = true;
  bool _isSyncing = false;
  int _lastEventSeq = 0;
  DateTime? _lastSyncedAt;

  final StreamController<String> _realtimeToastController =
      StreamController<String>.broadcast();

  List<RoomDiscoveryListing> get listings => List.unmodifiable(_listings);
  List<RoomRegistrationRequest> get registrations =>
      List.unmodifiable(_registrations);
  bool get isLoading => _isLoading;
  DateTime? get lastSyncedAt => _lastSyncedAt;
  Stream<String> get realtimeToastStream => _realtimeToastController.stream;

  int get pendingRegistrationsCount =>
      _registrations.where((r) => r.isPending).length;

  List<RoomDiscoveryListing> get featuredListings {
    final open = _listings.where((r) => r.isOpenForRent || r.status == 'Trống').toList();
    open.sort((a, b) => b.viewCount.compareTo(a.viewCount));
    return open.take(5).toList();
  }

  RoomDiscoveryProvider() {
    _initDefaultListings();
    syncAll(silent: true, emitToasts: false);
  }

  @override
  void dispose() {
    _realtimeToastController.close();
    super.dispose();
  }

  List<String> get _apiBases => <String>{
        ApiService.baseUrl,
        SupabaseDirectService.renderCloudApiUrl,
      }.toList();

  void _initDefaultListings() {
    _listings = [
      RoomDiscoveryListing(
        roomId: 102,
        roomCode: 'P.102',
        title: 'Studio Deluxe Tầng 1 • Ban công xanh thoáng mát',
        roomType: 'Studio Deluxe',
        floor: 1,
        area: 32.5,
        capacity: 2,
        rentPrice: 4500000,
        status: 'Trống',
        description:
            'Căn hộ Studio 32.5m² full nội thất gỗ sáng, cửa kính lớn đón gió tự nhiên, bếp riêng khép kín và khóa thông minh vân tay IoT.',
        amenities: const [
          'Khóa vân tay IoT',
          'Máy lạnh Inverter',
          'Ban công riêng',
          'Kệ bếp & Tủ lạnh',
          'Wi-Fi 6',
        ],
        isOpenForRent: true,
        viewCount: 148,
        rating: 4.9,
        imageUrls: const [
          'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&w=900&q=80',
          'https://images.unsplash.com/photo-1554995207-c18c203602cb?auto=format&fit=crop&w=900&q=80',
          'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?auto=format&fit=crop&w=900&q=80',
        ],
        videoTourUrl: 'https://www.w3schools.com/html/mov_bbb.mp4',
        updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      RoomDiscoveryListing(
        roomId: 203,
        roomCode: 'P.203',
        title: 'Co-Living Đơn Tầng 2 • Góc làm việc tràn ngập ánh sáng',
        roomType: 'Co-Living Đơn',
        floor: 2,
        area: 24.0,
        capacity: 1,
        rentPrice: 3200000,
        status: 'Trống',
        description:
            'Thiết kế tối giản chuẩn sinh viên/kỹ sư trẻ, có sẵn bàn học rộng, tủ quần áo âm tường và đồng hồ điện nước thông minh.',
        amenities: const [
          'Bàn học rộng',
          'Khóa vân tay IoT',
          'Máy lạnh Inverter',
          'Wi-Fi 6',
          'Hầm giữ xe 24/7',
        ],
        isOpenForRent: true,
        viewCount: 112,
        rating: 4.8,
        imageUrls: const [
          'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?auto=format&fit=crop&w=900&q=80',
          'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?auto=format&fit=crop&w=900&q=80',
        ],
        videoTourUrl: 'https://www.w3schools.com/html/mov_bbb.mp4',
        updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      RoomDiscoveryListing(
        roomId: 302,
        roomCode: 'P.302',
        title: 'Co-Living Ban Công Tầng 3 • View thành phố cực thoáng',
        roomType: 'Co-Living Đơn',
        floor: 3,
        area: 26.0,
        capacity: 2,
        rentPrice: 3500000,
        status: 'Trống',
        description:
            'Phòng được xem nhiều nhất tuần này! Tầng trung yên tĩnh, cửa sổ lớn hai mặt thoáng, máy giặt dùng chung miễn phí.',
        amenities: const [
          'View thành phố',
          'Ban công riêng',
          'Khóa vân tay IoT',
          'Máy lạnh Inverter',
          'Giặt sấy miễn phí',
        ],
        isOpenForRent: true,
        viewCount: 196,
        rating: 5.0,
        imageUrls: const [
          'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?auto=format&fit=crop&w=900&q=80',
          'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&w=900&q=80',
        ],
        videoTourUrl: 'https://www.w3schools.com/html/mov_bbb.mp4',
        updatedAt: DateTime.now().subtract(const Duration(minutes: 45)),
      ),
      RoomDiscoveryListing(
        roomId: 402,
        roomCode: 'P.402',
        title: 'Studio Ban Công Tầng 4 • Không gian yên tĩnh làm việc',
        roomType: 'Studio Ban công',
        floor: 4,
        area: 28.0,
        capacity: 2,
        rentPrice: 3900000,
        status: 'Trống',
        description:
            'Trang bị rèm cản sáng 2 lớp, đệm cao su non, nhà vệ sinh kính cường lực tách khu khô-ướt sạch sẽ.',
        amenities: const [
          'Rèm cản sáng',
          'Ban công thoáng',
          'Khóa vân tay IoT',
          'Nóng lạnh năng lượng',
        ],
        isOpenForRent: true,
        viewCount: 89,
        rating: 4.9,
        imageUrls: const [
          'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?auto=format&fit=crop&w=900&q=80',
          'https://images.unsplash.com/photo-1554995207-c18c203602cb?auto=format&fit=crop&w=900&q=80',
        ],
        videoTourUrl: 'https://www.w3schools.com/html/mov_bbb.mp4',
        updatedAt: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
      RoomDiscoveryListing(
        roomId: 501,
        roomCode: 'P.501',
        title: 'Sky View Penthouse Tầng 5 • Sân thượng BBQ riêng',
        roomType: 'Sky View Penthouse',
        floor: 5,
        area: 45.0,
        capacity: 3,
        rentPrice: 6200000,
        status: 'Trống',
        description:
            'Căn hộ áp mái cao cấp nhất SmartStay với ban công sân vườn 10m², sofa tiếp khách, tivi 4K và tủ bếp chữ L hiện đại.',
        amenities: const [
          'Sân thượng BBQ',
          'Smart TV 4K',
          'Khóa vân tay IoT',
          'Bếp từ đôi',
          'Sofa tiếp khách',
        ],
        isOpenForRent: true,
        viewCount: 234,
        rating: 5.0,
        imageUrls: const [
          'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=900&q=80',
          'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&w=900&q=80',
        ],
        videoTourUrl: 'https://www.w3schools.com/html/mov_bbb.mp4',
        updatedAt: DateTime.now().subtract(const Duration(minutes: 15)),
      ),
    ];
  }

  RoomDiscoveryListing? findByRoomCode(String roomCode) {
    final target = roomCode.trim().toUpperCase();
    for (final item in _listings) {
      if (item.roomCode.toUpperCase() == target) return item;
    }
    return null;
  }

  /// Đồng bộ cả danh sách phòng mở cho thuê + phiếu đăng ký phòng từ Backend/Supabase
  Future<bool> syncAll({bool silent = true, bool emitToasts = true}) async {
    if (_isSyncing) return false;
    _isSyncing = true;
    if (!silent) {
      _isLoading = true;
      notifyListeners();
    }

    bool ok = false;
    try {
      final results = await Future.wait([
        _fetchListingsFromCloud(emitToasts: emitToasts),
        _fetchRegistrationsFromCloud(),
      ]);
      ok = results[0] || results[1];
      _lastSyncedAt = DateTime.now();
    } finally {
      _isSyncing = false;
      _isLoading = false;
      notifyListeners();
    }
    return ok;
  }

  Future<bool> _fetchListingsFromCloud({required bool emitToasts}) async {
    for (final base in _apiBases) {
      try {
        final uri = Uri.parse(
          '$base/phong-cho-thue/danh-sach?sinceEventSeq=$_lastEventSeq',
        );
        final res = await sendApiRequest(
          method: 'GET',
          uri: uri,
          headers: const {'Accept': 'application/json'},
          timeout: const Duration(seconds: 12),
        );
        if (res.statusCode >= 200 && res.statusCode < 300) {
          final decoded = jsonDecode(res.body);
          if (decoded is Map<String, dynamic> && decoded['success'] == true) {
            final latestSeq = (decoded['latestEventSeq'] as num?)?.toInt() ?? 0;
            final hadPreviousCursor = _lastEventSeq > 0;

            final rawEvents = decoded['recentEvents'];
            if (emitToasts && hadPreviousCursor && rawEvents is List) {
              for (final rawEvt in rawEvents) {
                if (rawEvt is! Map) continue;
                final seq = (rawEvt['seq'] as num?)?.toInt() ?? 0;
                final msg = (rawEvt['message'] ?? '').toString().trim();
                if (seq > _lastEventSeq && msg.isNotEmpty) {
                  if (!_realtimeToastController.isClosed) {
                    _realtimeToastController.add(msg);
                  }
                }
              }
            }
            if (latestSeq > _lastEventSeq) {
              _lastEventSeq = latestSeq;
            }

            final rawRooms = decoded['phongs'];
            if (rawRooms is List && rawRooms.isNotEmpty) {
              final fetched = rawRooms
                  .whereType<Map>()
                  .map((e) => RoomDiscoveryListing.fromJson(
                        Map<String, dynamic>.from(e),
                      ))
                  .toList();

              // Phát hiện thay đổi giá/trạng thái/ảnh nếu đang mở màn hình (dù server vừa khởi động lại)
              if (emitToasts && hadPreviousCursor && _listings.isNotEmpty) {
                for (final next in fetched) {
                  final prev = findByRoomCode(next.roomCode);
                  if (prev != null &&
                      (prev.rentPrice != next.rentPrice ||
                          prev.status != next.status ||
                          prev.title != next.title ||
                          prev.imageUrls.length != next.imageUrls.length ||
                          prev.videoTourUrl != next.videoTourUrl)) {
                    if ((rawEvents is! List || rawEvents.isEmpty) &&
                        !_realtimeToastController.isClosed) {
                      _realtimeToastController.add(
                        'Phòng ${next.roomCode} vừa được cập nhật thông tin',
                      );
                    }
                  }
                }
              }

              _listings = fetched;
              return true;
            }
          }
        }
      } catch (e) {
        debugPrint('RoomDiscoveryProvider._fetchListingsFromCloud fallback: $e');
      }
    }
    return false;
  }

  Future<bool> _fetchRegistrationsFromCloud() async {
    for (final base in _apiBases) {
      try {
        final uri = Uri.parse('$base/phong-cho-thue/dang-ky');
        final res = await sendApiRequest(
          method: 'GET',
          uri: uri,
          headers: const {'Accept': 'application/json'},
          timeout: const Duration(seconds: 12),
        );
        if (res.statusCode >= 200 && res.statusCode < 300) {
          final decoded = jsonDecode(res.body);
          if (decoded is Map<String, dynamic> && decoded['items'] is List) {
            _registrations = (decoded['items'] as List)
                .whereType<Map>()
                .map((e) => RoomRegistrationRequest.fromJson(
                      Map<String, dynamic>.from(e),
                    ))
                .toList();
            return true;
          }
        }
      } catch (e) {
        debugPrint('RoomDiscoveryProvider._fetchRegistrationsFromCloud fallback: $e');
      }
    }
    return false;
  }

  /// Upload ảnh hoặc Video Tour thực tế lên Supabase Storage (`smartstay-media`)
  Future<String?> uploadRoomMedia({
    required Uint8List bytes,
    required String fileName,
    required String contentType,
    required bool isVideo,
  }) {
    return _supabase.uploadMediaBytes(
      bytes: bytes,
      fileName: fileName,
      contentType: contentType,
      folder: isVideo ? 'room-tours' : 'room-photos',
    );
  }

  /// Admin cập nhật thông tin phòng, giá thuê, ảnh, Video Tour & trạng thái mở cho thuê (lưu bền vững Supabase + Real-time)
  Future<RoomDiscoveryListing?> saveRoomListing({
    required int roomId,
    required String roomCode,
    required String title,
    required String roomType,
    required int floor,
    required double area,
    required int capacity,
    required double rentPrice,
    required String status,
    required String description,
    required List<String> amenities,
    required bool isOpenForRent,
    required List<String> imageUrls,
    String? videoTourUrl,
  }) async {
    final cleanCode = roomCode.trim().toUpperCase().startsWith('P.')
        ? roomCode.trim().toUpperCase()
        : 'P.${roomCode.trim().toUpperCase()}';

    final existing = findByRoomCode(cleanCode);
    final optimistic = RoomDiscoveryListing(
      roomId: roomId > 0 ? roomId : (existing?.roomId ?? 308),
      roomCode: cleanCode,
      title: title.trim().isEmpty ? 'Căn hộ $cleanCode • $roomType' : title.trim(),
      roomType: roomType,
      floor: floor,
      area: area,
      capacity: capacity,
      rentPrice: rentPrice,
      status: status,
      description: description.trim(),
      amenities: amenities,
      isOpenForRent: isOpenForRent,
      viewCount: existing?.viewCount ?? 24,
      rating: existing?.rating ?? 4.9,
      imageUrls: imageUrls.isNotEmpty
          ? imageUrls
          : const [
              'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&w=900&q=80',
            ],
      videoTourUrl:
          (videoTourUrl == null || videoTourUrl.trim().isEmpty) ? null : videoTourUrl.trim(),
      updatedAt: DateTime.now(),
    );

    final idx = _listings.indexWhere(
      (r) => r.roomCode.toUpperCase() == cleanCode,
    );
    if (idx != -1) {
      _listings[idx] = optimistic;
    } else {
      _listings.insert(0, optimistic);
    }
    notifyListeners();

    final body = jsonEncode({
      'MaPhong': optimistic.roomId,
      'KyHieuPhong': optimistic.roomCode,
      'TieuDe': optimistic.title,
      'LoaiPhong': optimistic.roomType,
      'SoTang': optimistic.floor,
      'DienTich': optimistic.area,
      'SucChua': optimistic.capacity,
      'GiaThue': optimistic.rentPrice,
      'TrangThai': optimistic.status,
      'MoTa': optimistic.description,
      'TienIchNoiBat': optimistic.amenities,
      'DangMoChoThue': optimistic.isOpenForRent,
      'HinhAnhUrls': optimistic.imageUrls,
      'VideoTourUrl': optimistic.videoTourUrl ?? '',
    });

    for (final base in _apiBases) {
      try {
        final res = await sendApiRequest(
          method: 'POST',
          uri: Uri.parse('$base/phong-cho-thue/cap-nhat-phong'),
          headers: const {'Content-Type': 'application/json'},
          body: body,
          timeout: const Duration(seconds: 20),
        );
        if (res.statusCode >= 200 && res.statusCode < 300) {
          final decoded = jsonDecode(res.body);
          if (decoded is Map<String, dynamic> && decoded['item'] is Map) {
            final serverItem = RoomDiscoveryListing.fromJson(
              Map<String, dynamic>.from(decoded['item'] as Map),
            );
            final sIdx = _listings.indexWhere(
              (r) => r.roomCode.toUpperCase() == serverItem.roomCode.toUpperCase(),
            );
            if (sIdx != -1) {
              _listings[sIdx] = serverItem;
            }
            final evt = decoded['realtimeEvent'];
            if (evt is Map && evt['seq'] is num) {
              final seq = (evt['seq'] as num).toInt();
              if (seq > _lastEventSeq) _lastEventSeq = seq;
            }
            notifyListeners();
            return serverItem;
          }
        }
      } catch (_) {}
    }

    return optimistic;
  }

  /// Tăng lượt xem phòng (phục vụ mục Phòng nổi bật / Được xem nhiều)
  Future<void> incrementViewCount(String roomCode) async {
    final idx = _listings.indexWhere(
      (r) => r.roomCode.toUpperCase() == roomCode.trim().toUpperCase(),
    );
    if (idx != -1) {
      _listings[idx] = _listings[idx].copyWith(
        viewCount: _listings[idx].viewCount + 1,
      );
      notifyListeners();
    }

    for (final base in _apiBases) {
      try {
        final encoded = Uri.encodeComponent(roomCode.trim());
        final res = await sendApiRequest(
          method: 'POST',
          uri: Uri.parse('$base/phong-cho-thue/$encoded/tang-luot-xem'),
          headers: const {'Content-Type': 'application/json'},
          body: '{}',
        );
        if (res.statusCode >= 200 && res.statusCode < 300) break;
      } catch (_) {}
    }
  }

  /// Cư dân / Người tìm phòng gửi phiếu đăng ký thuê mới hoặc xin chuyển phòng lên bảng PhieuDangKyPhong
  Future<RoomRegistrationRequest?> submitRegistration({
    required RoomDiscoveryListing room,
    required String fullName,
    required String phone,
    String? nationalId,
    required String requestType,
    required DateTime expectedMoveInDate,
    String? note,
    int? residentId,
  }) async {
    final maPhieu =
        'DKP-${DateTime.now().millisecondsSinceEpoch % 900000 + 100000}';
    final dateStr =
        '${expectedMoveInDate.year}-${expectedMoveInDate.month.toString().padLeft(2, '0')}-${expectedMoveInDate.day.toString().padLeft(2, '0')}';

    final created = RoomRegistrationRequest(
      maPhieu: maPhieu,
      roomId: room.roomId,
      roomCode: room.roomCode,
      residentId: residentId,
      requestType: requestType,
      fullName: fullName.trim(),
      phone: phone.trim(),
      nationalId: nationalId?.trim(),
      expectedMoveInDate: expectedMoveInDate,
      note: note?.trim(),
      status: 'ChoDuyet',
      createdAt: DateTime.now(),
    );
    _registrations.insert(0, created);
    notifyListeners();

    final body = jsonEncode({
      'MaPhieu': maPhieu,
      'MaPhong': room.roomId,
      'KyHieuPhong': room.roomCode,
      'MaCuDan': residentId,
      'LoaiYeuCau': requestType,
      'HoTen': created.fullName,
      'SoDienThoai': created.phone,
      'SoCanCuoc': created.nationalId,
      'NgayDuKienVaoO': dateStr,
      'GhiChu': created.note,
    });

    for (final base in _apiBases) {
      try {
        final res = await sendApiRequest(
          method: 'POST',
          uri: Uri.parse('$base/phong-cho-thue/dang-ky'),
          headers: const {'Content-Type': 'application/json'},
          body: body,
          timeout: const Duration(seconds: 15),
        );
        if (res.statusCode >= 200 && res.statusCode < 300) {
          final decoded = jsonDecode(res.body);
          if (decoded is Map<String, dynamic> && decoded['item'] is Map) {
            final serverReg = RoomRegistrationRequest.fromJson(
              Map<String, dynamic>.from(decoded['item'] as Map),
            );
            final rIdx = _registrations.indexWhere((x) => x.maPhieu == maPhieu);
            if (rIdx != -1) _registrations[rIdx] = serverReg;
            notifyListeners();
            return serverReg;
          }
          break;
        }
      } catch (_) {}
    }

    return created;
  }

  /// Admin Duyệt (chuyển trạng thái phòng -> Đã đặt & tạo bản nháp Hợp đồng) hoặc Từ chối phiếu đăng ký phòng
  Future<({bool ok, String? draftContractCode})> processRegistration({
    required RoomRegistrationRequest request,
    required bool approve,
    String? rejectReason,
  }) async {
    final nextStatus = approve ? 'DaDuyet' : 'TuChoi';
    String? draftCode = approve
        ? 'HD-NHAP-${DateTime.now().year}-${request.roomCode.replaceAll('.', '')}'
        : null;

    final idx = _registrations.indexWhere((x) => x.maPhieu == request.maPhieu);
    if (idx != -1) {
      _registrations[idx] = _registrations[idx].copyWith(
        status: nextStatus,
        rejectReason: approve ? null : rejectReason,
        draftContractCode: draftCode,
      );
    }

    if (approve) {
      final rIdx = _listings.indexWhere(
        (r) => r.roomCode.toUpperCase() == request.roomCode.toUpperCase(),
      );
      if (rIdx != -1) {
        _listings[rIdx] = _listings[rIdx].copyWith(
          status: 'Đã đặt',
          isOpenForRent: false,
          updatedAt: DateTime.now(),
        );
      }
    }
    notifyListeners();

    final body = jsonEncode({
      'Approve': approve,
      'TrangThai': nextStatus,
      'KyHieuPhong': request.roomCode,
      'LyDoTuChoi': rejectReason,
    });

    for (final base in _apiBases) {
      try {
        final encodedId = Uri.encodeComponent(request.maPhieu);
        final res = await sendApiRequest(
          method: 'POST',
          uri: Uri.parse('$base/phong-cho-thue/dang-ky/$encodedId/xu-ly'),
          headers: const {'Content-Type': 'application/json'},
          body: body,
          timeout: const Duration(seconds: 15),
        );
        if (res.statusCode >= 200 && res.statusCode < 300) {
          final decoded = jsonDecode(res.body);
          if (decoded is Map<String, dynamic>) {
            final serverDraft = decoded['draftContractCode']?.toString();
            if (serverDraft != null && serverDraft.isNotEmpty) {
              draftCode = serverDraft;
              if (idx != -1) {
                _registrations[idx] = _registrations[idx].copyWith(
                  draftContractCode: draftCode,
                );
              }
            }
            final evt = decoded['realtimeEvent'];
            if (evt is Map && evt['seq'] is num) {
              final seq = (evt['seq'] as num).toInt();
              if (seq > _lastEventSeq) _lastEventSeq = seq;
            }
            notifyListeners();
            return (ok: true, draftContractCode: draftCode);
          }
        }
      } catch (_) {}
    }

    return (ok: true, draftContractCode: draftCode);
  }
}
