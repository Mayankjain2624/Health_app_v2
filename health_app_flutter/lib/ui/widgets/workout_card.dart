import 'package:flutter/material.dart';
import '../../models/workout_session.dart';
import 'package:intl/intl.dart';

class WorkoutCard extends StatelessWidget {
  final WorkoutSession session;
  const WorkoutCard({super.key, required this.session});

  IconData _iconFor(ExerciseType t) {
    switch (t) {
      case ExerciseType.running:
        return Icons.directions_run;
      case ExerciseType.cycling:
        return Icons.two_wheeler;
      case ExerciseType.walking:
        return Icons.directions_walk;
      case ExerciseType.strengthTraining:
        return Icons.fitness_center;
      case ExerciseType.yoga:
        return Icons.self_improvement;
      case ExerciseType.other:
        return Icons.sports_basketball;
    }
  }

  Color _colorFor(ExerciseType t) {
    switch (t) {
      case ExerciseType.running:
        return const Color(0xFFB0BEC5); // Subtle gray-blue
      case ExerciseType.cycling:
        return const Color(0xFF90A4AE); // Subtle blue-gray
      case ExerciseType.walking:
        return const Color(0xFFA1887F); // Subtle brown-gray
      case ExerciseType.strengthTraining:
        return const Color(0xFF78909C); // Subtle slate gray
      case ExerciseType.yoga:
        return const Color(0xFF80CBC4); // Subtle teal-gray
      case ExerciseType.other:
        return const Color(0xFF81D4FA); // Subtle light blue
    }
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('MMM d, hh:mm a');
    final accentColor = _colorFor(session.type);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: const Color(0xFF1A1A1A),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accentColor.withOpacity(0.3), width: 1.5),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [const Color(0xFF1A1A1A), const Color(0xFF262626)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon and title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          accentColor.withOpacity(0.8),
                          accentColor.withOpacity(0.4),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _iconFor(session.type),
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            session.activityTypeName,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: accentColor,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          df.format(session.start),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFB0B0B0),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Primary stats section
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: accentColor.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    // First row: Duration, Calories, Distance (if available)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatBox(
                          '${session.duration.inMinutes}',
                          'MIN',
                          Icons.timer,
                          accentColor,
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: accentColor.withOpacity(0.2),
                        ),
                        _buildStatBox(
                          '${session.activeCalories?.toStringAsFixed(0) ?? '-'}',
                          'CAL',
                          Icons.local_fire_department,
                          accentColor,
                        ),
                        if (session.distance != null &&
                            session.distance! > 0) ...[
                          Container(
                            width: 1,
                            height: 40,
                            color: accentColor.withOpacity(0.2),
                          ),
                          _buildStatBox(
                            '${(session.distance! / 1000).toStringAsFixed(2)}',
                            'KM',
                            Icons.location_on,
                            accentColor,
                          ),
                        ],
                      ],
                    ),
                    // Second row: Heart rate data (if available)
                    if (session.avgHeartRate != null ||
                        session.peakHeartRate != null) ...[
                      const SizedBox(height: 14),
                      Divider(color: accentColor.withOpacity(0.2), height: 1),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          if (session.avgHeartRate != null)
                            _buildStatBox(
                              '${session.avgHeartRate?.toStringAsFixed(0) ?? '-'}',
                              'AVG BPM',
                              Icons.favorite,
                              accentColor,
                            ),
                          if (session.avgHeartRate != null &&
                              session.peakHeartRate != null)
                            Container(
                              width: 1,
                              height: 40,
                              color: accentColor.withOpacity(0.2),
                            ),
                          if (session.peakHeartRate != null)
                            _buildStatBox(
                              '${session.peakHeartRate?.toStringAsFixed(0) ?? '-'}',
                              'PEAK BPM',
                              Icons.favorite_border,
                              accentColor,
                            ),
                          if ((session.avgHeartRate != null ||
                                  session.peakHeartRate != null) &&
                              session.avgPace != null)
                            Container(
                              width: 1,
                              height: 40,
                              color: accentColor.withOpacity(0.2),
                            ),
                          if (session.avgPace != null &&
                              session.distance != null &&
                              session.distance! > 0)
                            _buildStatBox(
                              '${(session.avgPace! * 60).toStringAsFixed(1)}',
                              'MIN/KM',
                              Icons.speed,
                              accentColor,
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatBox(
    String value,
    String label,
    IconData icon,
    Color accentColor,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: accentColor, size: 18),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: accentColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: accentColor.withOpacity(0.7),
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}
