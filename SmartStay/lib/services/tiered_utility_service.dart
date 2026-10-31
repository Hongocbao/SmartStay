import '../models/invoice_model.dart';

class TierDetail {
  final int tierNumber;
  final String tierName;
  final double quantity;
  final double unitPrice;
  final double totalAmount;

  TierDetail({
    required this.tierNumber,
    required this.tierName,
    required this.quantity,
    required this.unitPrice,
    required this.totalAmount,
  });
}

class CalculationResult {
  final double totalQuantity;
  final double totalAmount;
  final List<TierDetail> tiers;

  CalculationResult({
    required this.totalQuantity,
    required this.totalAmount,
    required this.tiers,
  });
}

class TieredUtilityService {
  // Biểu giá Điện bậc thang (áp dụng cho khu lưu trú Co-Living / Sinh viên)
  static final List<Map<String, dynamic>> electricTiers = [
    {'tier': 1, 'name': 'Bậc 1 (0 - 50 kWh)', 'min': 0, 'max': 50, 'price': 1800.0},
    {'tier': 2, 'name': 'Bậc 2 (51 - 100 kWh)', 'min': 50, 'max': 100, 'price': 2200.0},
    {'tier': 3, 'name': 'Bậc 3 (101 - 200 kWh)', 'min': 100, 'max': 200, 'price': 2700.0},
    {'tier': 4, 'name': 'Bậc 4 (> 200 kWh)', 'min': 200, 'max': double.infinity, 'price': 3200.0},
  ];

  // Biểu giá Nước bậc thang
  static final List<Map<String, dynamic>> waterTiers = [
    {'tier': 1, 'name': 'Bậc 1 (0 - 5 m³)', 'min': 0, 'max': 5, 'price': 12000.0},
    {'tier': 2, 'name': 'Bậc 2 (6 - 10 m³)', 'min': 5, 'max': 10, 'price': 15000.0},
    {'tier': 3, 'name': 'Bậc 3 (> 10 m³)', 'min': 10, 'max': double.infinity, 'price': 18000.0},
  ];

  /// Tính tiền điện theo bậc thang
  static CalculationResult calculateElectricity(double totalKwh) {
    if (totalKwh <= 0) {
      return CalculationResult(totalQuantity: 0, totalAmount: 0, tiers: []);
    }

    double remaining = totalKwh;
    double totalAmount = 0;
    List<TierDetail> details = [];

    for (var tier in electricTiers) {
      double min = (tier['min'] as num).toDouble();
      double max = (tier['max'] as num).toDouble();
      double price = (tier['price'] as num).toDouble();
      double capacity = max - min;

      if (remaining > 0) {
        double usedInTier = remaining > capacity ? capacity : remaining;
        double amount = usedInTier * price;
        totalAmount += amount;
        remaining -= usedInTier;

        details.add(TierDetail(
          tierNumber: tier['tier'],
          tierName: tier['name'],
          quantity: usedInTier,
          unitPrice: price,
          totalAmount: amount,
        ));
      } else {
        break;
      }
    }

    return CalculationResult(
      totalQuantity: totalKwh,
      totalAmount: totalAmount,
      tiers: details,
    );
  }

  /// Tính tiền nước theo bậc thang
  static CalculationResult calculateWater(double totalM3) {
    if (totalM3 <= 0) {
      return CalculationResult(totalQuantity: 0, totalAmount: 0, tiers: []);
    }

    double remaining = totalM3;
    double totalAmount = 0;
    List<TierDetail> details = [];

    for (var tier in waterTiers) {
      double min = (tier['min'] as num).toDouble();
      double max = (tier['max'] as num).toDouble();
      double price = (tier['price'] as num).toDouble();
      double capacity = max - min;

      if (remaining > 0) {
        double usedInTier = remaining > capacity ? capacity : remaining;
        double amount = usedInTier * price;
        totalAmount += amount;
        remaining -= usedInTier;

        details.add(TierDetail(
          tierNumber: tier['tier'],
          tierName: tier['name'],
          quantity: usedInTier,
          unitPrice: price,
          totalAmount: amount,
        ));
      } else {
        break;
      }
    }

    return CalculationResult(
      totalQuantity: totalM3,
      totalAmount: totalAmount,
      tiers: details,
    );
  }

  /// Chuyển đổi kết quả tính toán thành các mục chi tiết trong hóa đơn (InvoiceItemModel)
  static List<InvoiceItemModel> buildInvoiceItems({
    required int baseItemId,
    required double roomRentPrice,
    required CalculationResult electricResult,
    required CalculationResult waterResult,
    double fixedServicePrice = 300000.0,
  }) {
    List<InvoiceItemModel> items = [];
    int currentId = baseItemId;

    // 1. Tiền phòng
    items.add(InvoiceItemModel(
      itemId: currentId++,
      itemType: 'TienPhong',
      description: 'Tiền thuê phòng tháng theo hợp đồng',
      quantity: 1,
      unitPrice: roomRentPrice,
      amount: roomRentPrice,
    ));

    // 2. Các bậc điện
    for (var tier in electricResult.tiers) {
      items.add(InvoiceItemModel(
        itemId: currentId++,
        itemType: 'Dien',
        description: 'Điện sinh hoạt: ${tier.tierName}',
        quantity: tier.quantity,
        unitPrice: tier.unitPrice,
        amount: tier.totalAmount,
      ));
    }

    // 3. Các bậc nước
    for (var tier in waterResult.tiers) {
      items.add(InvoiceItemModel(
        itemId: currentId++,
        itemType: 'Nuoc',
        description: 'Nước sinh hoạt: ${tier.tierName}',
        quantity: tier.quantity,
        unitPrice: tier.unitPrice,
        amount: tier.totalAmount,
      ));
    }

    // 4. Phí dịch vụ cố định (Wifi, bảo vệ, rác, thang máy)
    items.add(InvoiceItemModel(
      itemId: currentId++,
      itemType: 'DichVu',
      description: 'Combo dịch vụ (Internet cáp quang 300Mbps, rác, camera 24/7)',
      quantity: 1,
      unitPrice: fixedServicePrice,
      amount: fixedServicePrice,
    ));

    return items;
  }
}
