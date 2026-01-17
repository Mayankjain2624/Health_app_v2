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
        return Icons.pedal_bike;
      case ExerciseType.walking:
        return Icons.directions_walk;
      case ExerciseType.strengthTraining:
        return Icons.fitness_center;
      case ExerciseType.yoga:
        return Icons.self_improvement;
      case ExerciseType.other:
        return Icons.sports;
    }
  }

  Color _colorFor(ExerciseType t) {
    switch (t) {
      case ExerciseType.running:
        return Colors.red;
      case ExerciseType.cycling:
        return Colors.green;
      case ExerciseType.walking:
        return Colors.orange;
      case ExerciseType.strengthTraining:
        return Colors.purple;
      case ExerciseType.yoga:
        return Colors.teal;
      case ExerciseType.other:
        return const Color(0xFF1976D2);
    }
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('MMM d, hh:mm a');
    final accentColor = _colorFor(session.type);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: const Color(0xFF1E1E1E),
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1E1E1E),
              const Color(0xFF1E1E1E).withOpacity(0.9),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                            session.type.name
                                .replaceFirst(
                                  session.type.name[0],
                                  session.type.name[0].toUpperCase(),
                                )
                                .replaceAll(RegExp(r'([A-Z])'), r' $1')
                                .trim(),
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
              // Stats section
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatBox(
                      '${session.duration.inMinutes}',
                      'DURATION',
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
                      'CALORIES',
                      Icons.local_fire_department,
                      accentColor,
                    ),
                    if (session.distance != null) ...[
                      Container(
                        width: 1,
                        height: 40,
                        color: accentColor.withOpacity(0.2),
                      ),
                      _buildStatBox(
                        '${session.distance?.toStringAsFixed(2) ?? '-'}',
                        'KM',
                        Icons.location_on,
                        accentColor,
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
