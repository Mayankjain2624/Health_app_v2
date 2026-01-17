class StepSummary {
  final DateTime date;
  final int steps;
  final DateTime lastUpdated;

  StepSummary({
    required this.date,
    required this.steps,
    required this.lastUpdated,
  });

  Map<String, dynamic> toJson(String userId) => {
    'userId': userId,
    'date': date.toIso8601String(),
    'steps': steps,
    'updatedAt': lastUpdated.toIso8601String(),
  };

  factory StepSummary.fromJson(Map<String, dynamic> json) => StepSummary(
    date: DateTime.parse(json['date'] as String),
    steps: json['steps'] as int,
    lastUpdated: DateTime.parse(json['updatedAt'] as String),
  );
}
