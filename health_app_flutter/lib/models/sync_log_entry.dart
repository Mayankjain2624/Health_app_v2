class SyncLogEntry {
  final String action;
  final String status;
  final String? message;
  final int stepCount;
  final int workoutCount;
  final DateTime createdAt;

  SyncLogEntry({
    required this.action,
    required this.status,
    required this.createdAt,
    this.message,
    this.stepCount = 0,
    this.workoutCount = 0,
  });

  factory SyncLogEntry.fromJson(Map<String, dynamic> json) => SyncLogEntry(
    action: json['action'] as String? ?? 'unknown',
    status: json['status'] as String? ?? 'unknown',
    message: json['message'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
    stepCount: (json['stepCount'] as num?)?.toInt() ?? 0,
    workoutCount: (json['workoutCount'] as num?)?.toInt() ?? 0,
  );
}
