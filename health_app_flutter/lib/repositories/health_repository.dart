import '../models/step_summary.dart';
import '../models/workout_session.dart';
import '../models/sync_log_entry.dart';
import '../services/health_service.dart';
import '../services/backend_service.dart';

class HealthRepository {
  final HealthService healthService;
  final BackendService backendService;
  final String userId;

  HealthRepository({
    required this.healthService,
    required this.backendService,
    required this.userId,
  });

  Future<StepSummary?> loadTodaySteps() async {
    await healthService.requestPermissions();
    return await healthService.getTodaySteps();
  }

  Future<List<WorkoutSession>> loadRecentWorkouts() async {
    await healthService.requestPermissions();
    return await healthService.getRecentWorkouts(days: 7);
  }

  Future<void> syncSteps(StepSummary summary) async {
    await backendService.syncSteps(summary, userId: userId);
  }

  Future<void> syncWorkouts(List<WorkoutSession> sessions) async {
    if (sessions.isEmpty) return;
    await backendService.syncWorkouts(sessions, userId: userId);
  }

  Future<void> logSync({
    required String action,
    required String status,
    String? message,
    int stepCount = 0,
    int workoutCount = 0,
  }) async {
    await backendService.createSyncLog(
      userId: userId,
      action: action,
      status: status,
      message: message,
      stepCount: stepCount,
      workoutCount: workoutCount,
    );
  }

  Future<List<SyncLogEntry>> fetchSyncLogs({int limit = 20}) {
    return backendService.fetchSyncLogs(userId: userId, limit: limit);
  }
}
