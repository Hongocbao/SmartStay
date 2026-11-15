import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartstay/main.dart';
import 'package:smartstay/providers/admin_provider.dart';
import 'package:smartstay/screens/resident_services/resident_services_screen.dart';
import 'package:smartstay/utils/provider_scope.dart';

void main() {
  testWidgets('SmartStay App smoke test - Khởi chạy và hiển thị hệ thống', (WidgetTester tester) async {
    await tester.pumpWidget(const SmartStayApp());
    await tester.pumpAndSettle();

    // Kiểm tra ứng dụng khởi chạy thành công và tìm thấy AppRoot
    expect(find.byType(SmartStayApp), findsOneWidget);
    expect(find.byType(AppRoot), findsOneWidget);
  });

  testWidgets('ResidentServicesScreen không tràn RenderFlex trên màn hình hẹp 360x800', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final adminProvider = AdminProvider();
    addTearDown(adminProvider.dispose);

    final overflowErrors = <FlutterErrorDetails>[];
    final previousOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      final text = details.exceptionAsString();
      if (text.contains('overflowed') || text.contains('RenderFlex')) {
        overflowErrors.add(details);
      }
      if (text.contains('HTTP request failed, statusCode: 400') ||
          text.contains('NetworkImageLoadException')) {
        return;
      }
      previousOnError?.call(details);
    };

    try {
      for (var tabIndex = 0; tabIndex < 4; tabIndex++) {
        await tester.pumpWidget(
          ChangeNotifierProvider<AdminProvider>.value(
            value: adminProvider,
            child: MaterialApp(
              home: ResidentServicesScreen(initialTab: tabIndex),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
      }

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    } finally {
      FlutterError.onError = previousOnError;
    }

    expect(
      overflowErrors,
      isEmpty,
      reason: overflowErrors.map((e) => e.exceptionAsString()).join('\n'),
    );
  });
}
