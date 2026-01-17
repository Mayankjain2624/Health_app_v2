import 'package:flutter/material.dart';
import 'health_data_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Health App'), elevation: 0),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F1419), Color(0xFF1A237E), Color(0xFF0D47A1)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Welcome icon/illustration
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF2196F3).withOpacity(0.8),
                      const Color(0xFF00BCD4).withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Icon(
                  Icons.favorite,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Welcome to Health Dashboard',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Track your daily steps and workouts powered by Health Connect',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 48),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const HealthDataScreen()),
                ),
                icon: const Icon(Icons.trending_up, size: 24),
                label: const Text(
                  'View Health Data',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00BCD4),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 18,
                  ),
                  elevation: 8,
                  shadowColor: const Color(0xFF00BCD4).withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Health data auto-syncs with Health Connect',
                      ),
                      backgroundColor: Color(0xFF1976D2),
                    ),
                  );
                },
                icon: const Icon(Icons.info_outline, size: 20),
                label: const Text('Learn More', style: TextStyle(fontSize: 14)),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF80D8FF),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
