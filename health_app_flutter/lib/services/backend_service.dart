import 'package:dio/dio.dart';
import '../core/config.dart';
import '../models/step_summary.dart';
import '../models/workout_session.dart';
import '../models/sync_log_entry.dart';

class BackendService {
  final Dio _dio = Dio(BaseOptions(baseUrl: AppConfig.baseUrl));

  Future<void> syncSteps(StepSummary summary, {required String userId}) async {
    await _dio.post('/api/steps', data: summary.toJson(userId));
  }

  Future<void> syncWorkouts(
    List<WorkoutSession> sessions, {
    required String userId,
  }) async {
    await _dio.post(
      '/api/workouts',
      data: {
        'userId': userId,
        'sessions': sessions.map((s) => s.toJson(userId)).toList(),
      },
    );
  }

  Future<List<WorkoutSession>> fetchWorkouts({
    required String userId,
    DateTime? start,
    DateTime? end,
  }) async {
    final resp = await _dio.get(
      '/api/workouts',
      queryParameters: {
        'userId': userId,
        if (start != null) 'start': start.toIso8601String(),
        if (end != null) 'end': end.toIso8601String(),
      },
    );
    final list = (resp.data['data'] as List?) ?? [];
    return list
        .map((e) => WorkoutSession.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> createSyncLog({
    required String userId,
    required String action,
    required String status,
    String? message,
    int stepCount = 0,
    int workoutCount = 0,
  }) async {
    await _dio.post(
      '/api/sync/logs',
      data: {
        'userId': userId,
        'action': action,
        'status': status,
        'message': message,
        'stepCount': stepCount,
        'workoutCount': workoutCount,
      },
    );
  }

  Future<List<SyncLogEntry>> fetchSyncLogs({
    required String userId,
    int limit = 20,
  }) async {
    final resp = await _dio.get(
      '/api/sync/logs',
      queryParameters: {'userId': userId, 'limit': limit},
    );
    final list = (resp.data['data'] as List?) ?? [];
    return list
        .map((e) => SyncLogEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
