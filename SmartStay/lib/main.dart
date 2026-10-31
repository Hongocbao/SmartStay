import 'package:flutter/material.dart';
import 'utils/provider_scope.dart';
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
        ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
        ChangeNotifierProvider<InvoiceProvider>(create: (_) => InvoiceProvider()),
        ChangeNotifierProvider<TicketProvider>(create: (_) => TicketProvider()),
        ChangeNotifierProvider<CommunityProvider>(create: (_) => CommunityProvider()),
        ChangeNotifierProvider<AiChatProvider>(create: (_) => AiChatProvider()),
        ChangeNotifierProvider<AdminProvider>(create: (_) => AdminProvider()),
      ],
      child: MaterialApp(
        title: 'SmartStay - Quản Trị Hệ Sinh Thái Lưu Trú',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2563EB),
            primary: const Color(0xFF2563EB),
            secondary: const Color(0xFF0284C7),
            surface: Colors.white,
          ),
          scaffoldBackgroundColor: const Color(0xFFF8FAFC),
          fontFamily: 'Roboto',
          appBarTheme: const AppBarTheme(
            surfaceTintColor: Colors.transparent,
            backgroundColor: Colors.white,
          ),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2563EB),
            brightness: Brightness.dark,
          ),
        ),
        themeMode: ThemeMode.light,
        home: const AppRoot(),
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
