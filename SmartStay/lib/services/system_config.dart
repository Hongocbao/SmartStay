import 'package:flutter/foundation.dart';
import 'tiered_utility_service.dart';

class BankOption {
  final String bin;
  final String shortName;
  final String fullName;
  const BankOption(this.bin, this.shortName, this.fullName);
}

/// Cấu hình hệ thống dùng chung (tương đương trang /HeThong/CauHinh trên Web):
/// tài khoản VietQR thụ hưởng, biểu giá điện nước bậc thang và cổng IoT.
class SystemConfig extends ChangeNotifier {
  static final SystemConfig _instance = SystemConfig._internal();
  factory SystemConfig() => _instance;
  SystemConfig._internal();

  static const List<BankOption> banks = [
    BankOption('970422', 'MBBank', 'MBBank - Ngân Hàng Quân Đội'),
    BankOption('970415', 'VietinBank', 'VietinBank - Ngân Hàng Công Thương'),
    BankOption('970436', 'Vietcombank', 'Vietcombank - Ngoại Thương Việt Nam'),
    BankOption('970407', 'Techcombank', 'Techcombank - Kỹ Thương Việt Nam'),
  ];

  // 1. Cổng thanh toán VietQR
  String bankBin = '970422';
  String accountNumber = '0987654321';
  String accountHolder = 'SMARTSTAY MANAGEMENT';

  // 3. Cổng IoT & Cloud
  String mqttHost = 'mqtt.smartstay.vn:1883';
  String supabaseHost = 'odasdzyuriucofavonjl.supabase.co';
  int heartbeatSeconds = 30;

  BankOption get bank =>
      banks.firstWhere((b) => b.bin == bankBin, orElse: () => banks.first);

  List<double> get electricPrices => TieredUtilityService.electricTiers
      .map((t) => (t['price'] as num).toDouble())
      .toList();

  List<double> get waterPrices => TieredUtilityService.waterTiers
      .map((t) => (t['price'] as num).toDouble())
      .toList();

  String vietQrUrl({required double amount, required String content}) {
    final info = Uri.encodeComponent(content);
    final holder = Uri.encodeComponent(accountHolder);
    return 'https://img.vietqr.io/image/$bankBin-$accountNumber-compact2.png'
        '?amount=${amount.round()}&addInfo=$info&accountName=$holder';
  }

  void save({
    required String bankBin,
    required String accountNumber,
    required String accountHolder,
    required List<double> electricPrices,
    required List<double> waterPrices,
    required String mqttHost,
    required String supabaseHost,
    required int heartbeatSeconds,
  }) {
    this.bankBin = bankBin;
    this.accountNumber = accountNumber.trim();
    this.accountHolder = accountHolder.trim().toUpperCase();
    for (var i = 0; i < electricPrices.length && i < TieredUtilityService.electricTiers.length; i++) {
      TieredUtilityService.electricTiers[i]['price'] = electricPrices[i];
    }
    for (var i = 0; i < waterPrices.length && i < TieredUtilityService.waterTiers.length; i++) {
      TieredUtilityService.waterTiers[i]['price'] = waterPrices[i];
    }
    this.mqttHost = mqttHost.trim();
    this.supabaseHost = supabaseHost.trim();
    this.heartbeatSeconds = heartbeatSeconds;
    notifyListeners();
  }
}
