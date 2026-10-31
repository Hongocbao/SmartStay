import 'package:flutter_test/flutter_test.dart';
import 'package:smartstay/main.dart';

void main() {
  testWidgets('SmartStay App smoke test - Khởi chạy và hiển thị hệ thống', (WidgetTester tester) async {
    await tester.pumpWidget(const SmartStayApp());
    await tester.pumpAndSettle();

    // Kiểm tra ứng dụng khởi chạy thành công và tìm thấy AppRoot
    expect(find.byType(SmartStayApp), findsOneWidget);
    expect(find.byType(AppRoot), findsOneWidget);
  });
}
