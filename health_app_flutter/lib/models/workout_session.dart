enum ExerciseType { running, cycling, walking, strengthTraining, yoga, other }

class WorkoutSession {
  final ExerciseType type;
  final DateTime start;
  final DateTime end;
  final Duration duration;
  final double? activeCalories;
  final int? steps;
  final double? distance;
  final double? avgHeartRate;
  final double? peakHeartRate;
  final double? avgPace;

  WorkoutSession({
    required this.type,
    required this.start,
    required this.end,
    required this.duration,
    this.activeCalories,
    this.steps,
    this.distance,
    this.avgHeartRate,
    this.peakHeartRate,
    this.avgPace,
  });

  Map<String, dynamic> toJson(String userId) => {
    'userId': userId,
    'type': type.name,
    'start': start.toIso8601String(),
    'end': end.toIso8601String(),
    'durationSeconds': duration.inSeconds,
    'activeCalories': activeCalories,
    'steps': steps,
    'distance': distance,
    'avgHeartRate': avgHeartRate,
    'peakHeartRate': peakHeartRate,
    'avgPace': avgPace,
  };

  factory WorkoutSession.fromJson(Map<String, dynamic> json) => WorkoutSession(
    type: ExerciseType.values.firstWhere(
      (e) => e.name == (json['type'] as String? ?? 'other'),
      orElse: () => ExerciseType.other,
    ),
    start: DateTime.parse(json['start'] as String),
    end: DateTime.parse(json['end'] as String),
    duration: Duration(seconds: (json['durationSeconds'] as num).toInt()),
    activeCalories: (json['activeCalories'] as num?)?.toDouble(),
    steps: (json['steps'] as num?)?.toInt(),
    distance: (json['distance'] as num?)?.toDouble(),
    avgHeartRate: (json['avgHeartRate'] as num?)?.toDouble(),
    peakHeartRate: (json['peakHeartRate'] as num?)?.toDouble(),
    avgPace: (json['avgPace'] as num?)?.toDouble(),
  );
}
