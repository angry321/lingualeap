import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/app_providers.dart';
import 'screens/home_navigation_screen.dart';
import 'services/db_service.dart';
import 'services/settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SQLite FFI for Windows / Linux / macOS desktop support
  await DBService.initializeFfiIfNeeded();

  // Initialize local preferences
  final settingsService = await SettingsService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(settingsService),
        ),
        ChangeNotifierProvider(
          create: (_) => WordsProvider()..loadWords(),
        ),
        ChangeNotifierProvider(
          create: (_) => MaterialsProvider()..loadMaterials(),
        ),
      ],
      child: const LinguaLeapApp(),
    ),
  );
}

class LinguaLeapApp extends StatelessWidget {
  const LinguaLeapApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();

    return MaterialApp(
      title: 'LinguaLeap',
      debugShowCheckedModeBanner: false,
      themeMode: settingsProvider.themeMode,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3F51B5), // Deep Indigo
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
        ),
        cardTheme: CardTheme(
          elevation: 1.5,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5C6BC0),
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      home: const HomeNavigationScreen(),
    );
  }
}
