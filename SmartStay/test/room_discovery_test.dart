import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartstay/providers/admin_provider.dart';
import 'package:smartstay/providers/auth_provider.dart';
import 'package:smartstay/providers/room_discovery_provider.dart';
import 'package:smartstay/screens/discovery/room_discovery_screen.dart';
import 'package:smartstay/theme/smartstay_theme.dart';
import 'package:smartstay/utils/provider_scope.dart';

void main() {
  testWidgets('RoomDiscoveryScreen hiển thị chuẩn SmartStayTheme Light/Dark không tràn trên 375x812', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ThemeController>(create: (_) => ThemeController()),
          ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
          ChangeNotifierProvider<AdminProvider>(create: (_) => AdminProvider()),
          ChangeNotifierProvider<RoomDiscoveryProvider>(
            create: (_) => RoomDiscoveryProvider(),
          ),
        ],
        child: MaterialApp(
          theme: SmartStayTheme.light(),
          darkTheme: SmartStayTheme.dark(),
          themeMode: ThemeMode.dark,
          home: const RoomDiscoveryScreen(),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 250));

    expect(
      find.text('Khám Phá Phòng Trống & Xem Video Tour Trực Tuyến'),
      findsOneWidget,
    );
    expect(find.text('Phòng trống'), findsOneWidget);
    expect(find.text('Có Video Tour'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
