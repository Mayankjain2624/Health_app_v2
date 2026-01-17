import 'package:flutter/material.dart';
import 'ui/screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Health App',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF2196F3), // Bright Blue
          secondary: const Color(0xFF00BCD4), // Cyan
          surface: const Color(0xFF0F1419), // Very Dark Blue-Black
          onSurface: Colors.white,
          onPrimary: Colors.white,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFF0D47A1), // Deep Blue
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        scaffoldBackgroundColor: const Color(
          0xFF0F1419,
        ), // Deep Blue-Black gradient base
        cardColor: const Color(0xFF1A237E), // Dark Blue
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2196F3),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
          ),
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 28,
          ),
          headlineSmall: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
          bodyLarge: TextStyle(color: Color(0xFFE8E8E8), fontSize: 16),
          bodyMedium: TextStyle(color: Color(0xFFB0B0B0), fontSize: 14),
          labelMedium: TextStyle(
            color: Color(0xFF80D8FF),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
