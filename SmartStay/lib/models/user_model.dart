class UserModel {
  final int userId;
  final String username;
  final String email;
  final String phone;
  final String fullName;
  final String role;
  final String? roomCode;
  final bool mustChangePassword;
  final ResidentProfile? residentProfile;

  UserModel({
    required this.userId,
    required this.username,
    required this.email,
    required this.phone,
    required this.fullName,
    required this.role,
    this.roomCode,
    this.mustChangePassword = false,
    this.residentProfile,
  });

  String get effectiveRoomCode => roomCode ?? residentProfile?.roomCode ?? 'P.101';

  UserModel copyWith({
    int? userId,
    String? username,
    String? email,
    String? phone,
    String? fullName,
    String? role,
    String? roomCode,
    bool? mustChangePassword,
    ResidentProfile? residentProfile,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      roomCode: roomCode ?? this.roomCode,
      mustChangePassword: mustChangePassword ?? this.mustChangePassword,
      residentProfile: residentProfile ?? this.residentProfile,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['userId'] ?? 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      fullName: json['fullName'] ?? '',
      role: json['role'] ?? 'Cư dân',
      roomCode: json['roomCode'],
      mustChangePassword: json['mustChangePassword'] ?? false,
      residentProfile: json['residentProfile'] != null
          ? ResidentProfile.fromJson(json['residentProfile'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      'email': email,
      'phone': phone,
      'fullName': fullName,
      'role': role,
      'roomCode': roomCode,
      'mustChangePassword': mustChangePassword,
      'residentProfile': residentProfile?.toJson(),
    };
  }
}

class ResidentProfile {
  final int residentId;
  final String roomCode;
  final String buildingName;
  final int floorNumber;
  final DateTime dateOfBirth;
  final String gender;
  final String idCardNumber;
  final String permanentAddress;
  final String emergencyContactName;
  final String emergencyContactPhone;

  ResidentProfile({
    required this.residentId,
    required this.roomCode,
    required this.buildingName,
    required this.floorNumber,
    required this.dateOfBirth,
    required this.gender,
    required this.idCardNumber,
    required this.permanentAddress,
    required this.emergencyContactName,
    required this.emergencyContactPhone,
  });

  ResidentProfile copyWith({
    int? residentId,
    String? roomCode,
    String? buildingName,
    int? floorNumber,
    DateTime? dateOfBirth,
    String? gender,
    String? idCardNumber,
    String? permanentAddress,
    String? emergencyContactName,
    String? emergencyContactPhone,
  }) {
    return ResidentProfile(
      residentId: residentId ?? this.residentId,
      roomCode: roomCode ?? this.roomCode,
      buildingName: buildingName ?? this.buildingName,
      floorNumber: floorNumber ?? this.floorNumber,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      idCardNumber: idCardNumber ?? this.idCardNumber,
      permanentAddress: permanentAddress ?? this.permanentAddress,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
    );
  }

  factory ResidentProfile.fromJson(Map<String, dynamic> json) {
    return ResidentProfile(
      residentId: json['residentId'] ?? 0,
      roomCode: json['roomCode'] ?? '',
      buildingName: json['buildingName'] ?? '',
      floorNumber: json['floorNumber'] ?? 1,
      dateOfBirth: DateTime.tryParse(json['dateOfBirth'] ?? '') ?? DateTime(2003, 1, 1),
      gender: json['gender'] ?? 'Nam',
      idCardNumber: json['idCardNumber'] ?? '',
      permanentAddress: json['permanentAddress'] ?? '',
      emergencyContactName: json['emergencyContactName'] ?? '',
      emergencyContactPhone: json['emergencyContactPhone'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'residentId': residentId,
      'roomCode': roomCode,
      'buildingName': buildingName,
      'floorNumber': floorNumber,
      'dateOfBirth': dateOfBirth.toIso8601String(),
      'gender': gender,
      'idCardNumber': idCardNumber,
      'permanentAddress': permanentAddress,
      'emergencyContactName': emergencyContactName,
      'emergencyContactPhone': emergencyContactPhone,
    };
  }
}
