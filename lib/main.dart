import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/shift_service.dart';
import 'screens/login_screen.dart';
import 'screens/staff_screen.dart';
import 'screens/leader_screen.dart';
import 'screens/manager_screen.dart';
import 'models/user.dart';

import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ja_JP', null);
  runApp(
    ChangeNotifierProvider(
      create: (context) => ShiftService(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'バイトシフト管理',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          primary: Colors.indigo,
          secondary: Colors.orangeAccent,
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.notoSansJpTextTheme(),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final shiftService = Provider.of<ShiftService>(context);
    final user = shiftService.currentUser;

    if (user == null) {
      return const LoginScreen();
    }

    switch (user.role) {
      case UserRole.staff:
        return const StaffScreen();
      case UserRole.leader:
        return const LeaderScreen();
      case UserRole.manager:
        return const ManagerScreen();
    }
  }
}
