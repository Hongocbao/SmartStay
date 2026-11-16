import 'package:flutter/material.dart';
import 'utils/provider_scope.dart';
import 'theme/smartstay_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/invoice_provider.dart';
import 'providers/ticket_provider.dart';
import 'providers/community_provider.dart';
import 'providers/ai_chat_provider.dart';
import 'providers/admin_provider.dart';
import 'screens/main_layout.dart';
import 'screens/auth/login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SmartStayApp());
}

class SmartStayApp extends StatelessWidget {
  const SmartStayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeController>(create: (_) => ThemeController()),
        ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
        ChangeNotifierProvider<InvoiceProvider>(create: (_) => InvoiceProvider()),
        ChangeNotifierProvider<TicketProvider>(create: (_) => TicketProvider()),
        ChangeNotifierProvider<CommunityProvider>(create: (_) => CommunityProvider()),
        ChangeNotifierProvider<AiChatProvider>(create: (_) => AiChatProvider()),
        ChangeNotifierProvider<AdminProvider>(create: (_) => AdminProvider()),
      ],
      child: Builder(
        builder: (context) {
          final themeCtrl = context.watch<ThemeController>();
          return MaterialApp(
            title: 'SmartStay - Quản Trị Hệ Sinh Thái Lưu Trú',
            debugShowCheckedModeBanner: false,
            theme: SmartStayTheme.light(),
            darkTheme: SmartStayTheme.dark(),
            themeMode: themeCtrl.mode,
            home: const AppRoot(),
          );
        },
      ),
    );
  }
}

class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.isAuthenticated) {
      return const MainLayout();
    } else {
      return const LoginScreen();
    }
  }
}
