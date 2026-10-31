import 'package:flutter_test/flutter_test.dart';
import 'package:smartstay/services/tiered_utility_service.dart';

void main() {
  group('Kiểm thử thuật toán tính tiền Điện bậc thang lũy tiến', () {
    test('Điện tiêu thụ 0 kWh phải trả 0 đ', () {
      final res = TieredUtilityService.calculateElectricity(0);
      expect(res.totalAmount, 0.0);
      expect(res.tiers.isEmpty, true);
    });

    test('Điện tiêu thụ 45 kWh (chỉ thuộc Bậc 1)', () {
      final res = TieredUtilityService.calculateElectricity(45);
      expect(res.tiers.length, 1);
      expect(res.tiers[0].quantity, 45);
      expect(res.tiers[0].unitPrice, 1800.0);
      expect(res.totalAmount, 45 * 1800.0); // 81.000 đ
    });

    test('Điện tiêu thụ 120 kWh (trải dài 3 bậc: 50 kWh B1, 50 kWh B2, 20 kWh B3)', () {
      final res = TieredUtilityService.calculateElectricity(120);
      expect(res.tiers.length, 3);

      expect(res.tiers[0].quantity, 50);
      expect(res.tiers[0].totalAmount, 50 * 1800.0); // 90.000

      expect(res.tiers[1].quantity, 50);
      expect(res.tiers[1].totalAmount, 50 * 2200.0); // 110.000

      expect(res.tiers[2].quantity, 20);
      expect(res.tiers[2].totalAmount, 20 * 2700.0); // 54.000

      expect(res.totalAmount, 254000.0);
    });

    test('Điện tiêu thụ 250 kWh (chạm tới Bậc 4: 50 kWh vượt mức 200 kWh)', () {
      final res = TieredUtilityService.calculateElectricity(250);
      expect(res.tiers.length, 4);

      expect(res.tiers[0].totalAmount, 50 * 1800.0); // 90.000
      expect(res.tiers[1].totalAmount, 50 * 2200.0); // 110.000
      expect(res.tiers[2].totalAmount, 100 * 2700.0); // 270.000
      expect(res.tiers[3].quantity, 50);
      expect(res.tiers[3].totalAmount, 50 * 3200.0); // 160.000

      expect(res.totalAmount, 630000.0);
    });
  });

  group('Kiểm thử thuật toán tính tiền Nước sinh hoạt bậc thang', () {
    test('Nước tiêu thụ 7 m³ (5 m³ B1 + 2 m³ B2)', () {
      final res = TieredUtilityService.calculateWater(7);
      expect(res.tiers.length, 2);

      expect(res.tiers[0].quantity, 5);
      expect(res.tiers[0].totalAmount, 5 * 12000.0); // 60.000

      expect(res.tiers[1].quantity, 2);
      expect(res.tiers[1].totalAmount, 2 * 15000.0); // 30.000

      expect(res.totalAmount, 90000.0);
    });

    test('Nước tiêu thụ 15 m³ (chạm tới Bậc 3)', () {
      final res = TieredUtilityService.calculateWater(15);
      expect(res.tiers.length, 3);

      expect(res.tiers[0].totalAmount, 5 * 12000.0); // 60.000
      expect(res.tiers[1].totalAmount, 5 * 15000.0); // 75.000
      expect(res.tiers[2].quantity, 5);
      expect(res.tiers[2].totalAmount, 5 * 18000.0); // 90.000

      expect(res.totalAmount, 225000.0);
    });
  });
}
