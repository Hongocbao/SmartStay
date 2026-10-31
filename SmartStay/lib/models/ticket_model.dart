class TicketModel {
  final int ticketId;
  final String ticketCode;
  final String roomCode;
  final String categoryName;
  final String? technicianName;
  final String title;
  final String description;
  final String priority; // Thấp, Trung bình, Cao, Khẩn cấp
  final String status; // Chờ xử lý, Đang sửa, Hoàn thành, Từ chối
  final DateTime createdAt;
  final DateTime? deadline;
  final DateTime? completedAt;
  final double? materialCost;
  final int? rating;
  final String? ratingComment;
  final List<TicketImageModel> images;
  final List<TicketCommentModel> comments;
  final List<TicketActivityLogModel> activityLogs;

  TicketModel({
    required this.ticketId,
    required this.ticketCode,
    required this.roomCode,
    required this.categoryName,
    this.technicianName,
    required this.title,
    required this.description,
    required this.priority,
    required this.status,
    required this.createdAt,
    this.deadline,
    this.completedAt,
    this.materialCost,
    this.rating,
    this.ratingComment,
    this.images = const [],
    this.comments = const [],
    this.activityLogs = const [],
  });

  int get statusStep {
    switch (status) {
      case 'Chờ xử lý':
        return 0;
      case 'Đang sửa':
        return 1;
      case 'Hoàn thành':
        return 2;
      default:
        return 0;
    }
  }

  // SLA Deadline tính theo mức độ ưu tiên nếu chưa có deadline cụ thể
  DateTime get effectiveDeadline {
    if (deadline != null) return deadline!;
    switch (priority) {
      case 'Khẩn cấp':
        return createdAt.add(const Duration(hours: 4));
      case 'Cao':
        return createdAt.add(const Duration(hours: 12));
      case 'Trung bình':
        return createdAt.add(const Duration(hours: 24));
      case 'Thấp':
      default:
        return createdAt.add(const Duration(hours: 48));
    }
  }

  Duration get remainingTime => effectiveDeadline.difference(DateTime.now());
  bool get isOverdue => status != 'Hoàn thành' && remainingTime.isNegative;

  TicketModel copyWith({
    int? ticketId,
    String? ticketCode,
    String? roomCode,
    String? categoryName,
    String? technicianName,
    String? title,
    String? description,
    String? priority,
    String? status,
    DateTime? createdAt,
    DateTime? deadline,
    DateTime? completedAt,
    double? materialCost,
    int? rating,
    String? ratingComment,
    List<TicketImageModel>? images,
    List<TicketCommentModel>? comments,
    List<TicketActivityLogModel>? activityLogs,
  }) {
    return TicketModel(
      ticketId: ticketId ?? this.ticketId,
      ticketCode: ticketCode ?? this.ticketCode,
      roomCode: roomCode ?? this.roomCode,
      categoryName: categoryName ?? this.categoryName,
      technicianName: technicianName ?? this.technicianName,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      deadline: deadline ?? this.deadline,
      completedAt: completedAt ?? this.completedAt,
      materialCost: materialCost ?? this.materialCost,
      rating: rating ?? this.rating,
      ratingComment: ratingComment ?? this.ratingComment,
      images: images ?? this.images,
      comments: comments ?? this.comments,
      activityLogs: activityLogs ?? this.activityLogs,
    );
  }

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    return TicketModel(
      ticketId: json['ticketId'] ?? 0,
      ticketCode: json['ticketCode'] ?? '',
      roomCode: json['roomCode'] ?? '',
      categoryName: json['categoryName'] ?? 'Chung',
      technicianName: json['technicianName'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      priority: json['priority'] ?? 'Trung bình',
      status: json['status'] ?? 'Chờ xử lý',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      deadline: json['deadline'] != null ? DateTime.tryParse(json['deadline']) : null,
      completedAt: json['completedAt'] != null ? DateTime.tryParse(json['completedAt']) : null,
      materialCost: (json['materialCost'] as num?)?.toDouble(),
      rating: json['rating'],
      ratingComment: json['ratingComment'],
      images: (json['images'] as List<dynamic>?)
              ?.map((e) => TicketImageModel.fromJson(e))
              .toList() ??
          [],
      comments: (json['comments'] as List<dynamic>?)
              ?.map((e) => TicketCommentModel.fromJson(e))
              .toList() ??
          [],
      activityLogs: (json['activityLogs'] as List<dynamic>?)
              ?.map((e) => TicketActivityLogModel.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ticketId': ticketId,
      'ticketCode': ticketCode,
      'roomCode': roomCode,
      'categoryName': categoryName,
      'technicianName': technicianName,
      'title': title,
      'description': description,
      'priority': priority,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'deadline': deadline?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'materialCost': materialCost,
      'rating': rating,
      'ratingComment': ratingComment,
      'images': images.map((e) => e.toJson()).toList(),
      'comments': comments.map((e) => e.toJson()).toList(),
      'activityLogs': activityLogs.map((e) => e.toJson()).toList(),
    };
  }
}

class TicketActivityLogModel {
  final int logId;
  final String action; // Tạo phiếu, Phân công, Bắt đầu sửa, Hoàn thành, Đánh giá
  final String actorName;
  final String? note;
  final DateTime timestamp;

  TicketActivityLogModel({
    required this.logId,
    required this.action,
    required this.actorName,
    this.note,
    required this.timestamp,
  });

  TicketActivityLogModel copyWith({
    int? logId,
    String? action,
    String? actorName,
    String? note,
    DateTime? timestamp,
  }) {
    return TicketActivityLogModel(
      logId: logId ?? this.logId,
      action: action ?? this.action,
      actorName: actorName ?? this.actorName,
      note: note ?? this.note,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  factory TicketActivityLogModel.fromJson(Map<String, dynamic> json) {
    return TicketActivityLogModel(
      logId: json['logId'] ?? 0,
      action: json['action'] ?? '',
      actorName: json['actorName'] ?? '',
      note: json['note'],
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'logId': logId,
      'action': action,
      'actorName': actorName,
      'note': note,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class TicketImageModel {
  final int imageId;
  final String mediaUrl;
  final String imageType; // TruocSuaChua, NghiemThu

  TicketImageModel({
    required this.imageId,
    required this.mediaUrl,
    required this.imageType,
  });

  TicketImageModel copyWith({
    int? imageId,
    String? mediaUrl,
    String? imageType,
  }) {
    return TicketImageModel(
      imageId: imageId ?? this.imageId,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      imageType: imageType ?? this.imageType,
    );
  }

  factory TicketImageModel.fromJson(Map<String, dynamic> json) {
    return TicketImageModel(
      imageId: json['imageId'] ?? 0,
      mediaUrl: json['mediaUrl'] ?? '',
      imageType: json['imageType'] ?? 'TruocSuaChua',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'imageId': imageId,
      'mediaUrl': mediaUrl,
      'imageType': imageType,
    };
  }
}

class TicketCommentModel {
  final int commentId;
  final String authorName;
  final String content;
  final DateTime createdAt;
  final bool isFromResident;

  TicketCommentModel({
    required this.commentId,
    required this.authorName,
    required this.content,
    required this.createdAt,
    required this.isFromResident,
  });

  TicketCommentModel copyWith({
    int? commentId,
    String? authorName,
    String? content,
    DateTime? createdAt,
    bool? isFromResident,
  }) {
    return TicketCommentModel(
      commentId: commentId ?? this.commentId,
      authorName: authorName ?? this.authorName,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      isFromResident: isFromResident ?? this.isFromResident,
    );
  }

  factory TicketCommentModel.fromJson(Map<String, dynamic> json) {
    return TicketCommentModel(
      commentId: json['commentId'] ?? 0,
      authorName: json['authorName'] ?? '',
      content: json['content'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      isFromResident: json['isFromResident'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'commentId': commentId,
      'authorName': authorName,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'isFromResident': isFromResident,
    };
  }
}
