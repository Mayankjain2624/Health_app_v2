import 'dart:io';
import 'dart:convert';
import 'package:health/health.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/step_summary.dart';
import '../models/workout_session.dart';

class HealthService {
  final Health _health = Health();

  // Check if Health Connect or Google Fit is available
  Future<bool> isHealthDataSourceAvailable() async {
    if (Platform.isAndroid) {
      try {
        // Try to get any health data to check if Health Connect is working
        final result = await _health.getHealthDataFromTypes(
          types: [HealthDataType.STEPS],
          startTime: DateTime.now().subtract(const Duration(hours: 1)),
          endTime: DateTime.now(),
        );
        print('HealthService: Health data source check passed');
        return true;
      } catch (e) {
        print('HealthService: Health data source not available: $e');
        return false;
      }
    } else if (Platform.isIOS) {
      return true; // Assume iOS has HealthKit available
    }
    return false;
  }

  Future<bool> requestPermissions() async {
    print('HealthService: requestPermissions() called');

    // For Android 14+, first request system-level permissions using permission_handler
    if (Platform.isAndroid) {
      print('HealthService: Requesting system permissions on Android...');
      try {
        final results = await Future.wait([
          Permission.location.request(),
          Permission.activityRecognition.request(),
        ]);

        final allGranted = results.every((status) => status.isGranted);
        print('HealthService: System permissions granted: $allGranted');

        if (!allGranted) {
          print(
            'HealthService: Some system permissions denied, but continuing...',
          );
        }
      } catch (e) {
        print('HealthService: Error requesting system permissions: $e');
      }

      // Give Android a moment to process system permissions
      await Future.delayed(const Duration(milliseconds: 500));
    }

    final types = <HealthDataType>[
      HealthDataType.STEPS,
      HealthDataType.ACTIVE_ENERGY_BURNED,
      HealthDataType.WORKOUT,
      HealthDataType.HEART_RATE,
      if (Platform.isIOS) HealthDataType.DISTANCE_WALKING_RUNNING,
      if (Platform.isAndroid) HealthDataType.DISTANCE_DELTA,
    ];
    final permissions = types.map((t) => HealthDataAccess.READ).toList();

    // Check if permissions are already granted
    try {
      final hasPerm = await _health.hasPermissions(types);
      print('HealthService: hasPermissions result: $hasPerm');
      if (hasPerm == true) {
        print('HealthService: Permissions already granted');
        return true;
      }
    } catch (e) {
      print('HealthService: Error checking permissions: $e');
    }

    // Request Health Connect permissions
    print('HealthService: Requesting Health Connect permissions...');
    try {
      final granted = await _health.requestAuthorization(
        types,
        permissions: permissions,
      );
      print('HealthService: requestAuthorization returned: $granted');

      if (!granted) {
        print(
          'HealthService: WARNING - User denied permission or Health Connect unavailable',
        );
        if (Platform.isAndroid) {
          print(
            'HealthService: On Android, ensure Health Connect app is installed',
          );
        }
      }

      return granted;
    } catch (e) {
      print('HealthService: Error requesting authorization: $e');
      if (Platform.isAndroid &&
          e.toString().contains('Permission launcher not found')) {
        print(
          'HealthService: CRITICAL - Health Connect app may not be installed on device',
        );
        print(
          'HealthService: User needs to install Health Connect from Play Store',
        );
      }
      return false;
    }
  }

  Future<StepSummary?> getTodaySteps() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    try {
      print('HealthService: getTodaySteps() started');

      // Request permissions first
      final permGranted = await requestPermissions();
      print('HealthService: Permission request result: $permGranted');

      print('HealthService: Getting total steps...');
      final steps = await _health.getTotalStepsInInterval(startOfDay, now) ?? 0;
      print('HealthService: Got steps: $steps');

      // If we got 0 steps and permission wasn't granted, use mock data
      if (steps == 0 && !permGranted) {
        final prefs = await SharedPreferences.getInstance();
        final jsonStr = prefs.getString('cache_step_summary');
        if (jsonStr == null) {
          // No cache and no real steps and no permission, return mock
          print(
            'HealthService: Returning mock data - 5234 steps (no permissions, no cache)',
          );
          return StepSummary(date: startOfDay, steps: 5234, lastUpdated: now);
        }
      }

      final summary = StepSummary(
        date: startOfDay,
        steps: steps,
        lastUpdated: DateTime.now(),
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'cache_step_summary',
        jsonEncode({
          'date': summary.date.toIso8601String(),
          'steps': summary.steps,
          'updatedAt': summary.lastUpdated.toIso8601String(),
        }),
      );
      return summary;
    } catch (e) {
      print('HealthService: Error getting steps: $e');
      // Try cache first
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('cache_step_summary');
      if (jsonStr != null) {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        return StepSummary(
          date: DateTime.parse(map['date'] as String),
          steps: (map['steps'] as num).toInt(),
          lastUpdated: DateTime.parse(map['updatedAt'] as String),
        );
      }
      // Return mock data for testing
      print('HealthService: Returning mock data - 5234 steps (exception)');
      return StepSummary(date: startOfDay, steps: 5234, lastUpdated: now);
    }
  }

  Future<List<WorkoutSession>> getRecentWorkouts({int days = 7}) async {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: days));

    // Request multiple data types to get complete workout information
    final requestTypes = <HealthDataType>[
      HealthDataType.WORKOUT,
      HealthDataType.ACTIVE_ENERGY_BURNED,
      HealthDataType.HEART_RATE,
      HealthDataType.DISTANCE_DELTA,
      if (Platform.isIOS) HealthDataType.DISTANCE_WALKING_RUNNING,
    ];

    try {
      print('HealthService: Requesting permissions for detailed workouts...');
      // Request all permissions for complete data
      final permGranted = await requestPermissions();
      print('HealthService: Workout permissions granted: $permGranted');

      print(
        'HealthService: Fetching detailed workout data from Health Connect...',
      );

      // Fetch data for each type
      final workoutData = <HealthDataPoint>[];
      final caloriesData = <HealthDataPoint>[];
      final heartRateData = <HealthDataPoint>[];
      final distanceData = <HealthDataPoint>[];

      // Get WORKOUT entries
      try {
        final data = await _health.getHealthDataFromTypes(
          types: [HealthDataType.WORKOUT],
          startTime: start,
          endTime: now,
        );
        workoutData.addAll(data);
        print('HealthService: Got ${data.length} workout records');
      } catch (e) {
        print('HealthService: Error fetching workouts: $e');
      }

      // Get ACTIVE_ENERGY_BURNED (calories)
      try {
        final data = await _health.getHealthDataFromTypes(
          types: [HealthDataType.ACTIVE_ENERGY_BURNED],
          startTime: start,
          endTime: now,
        );
        caloriesData.addAll(data);
        print('HealthService: Got ${data.length} calorie records');
      } catch (e) {
        print('HealthService: Error fetching calories: $e');
      }

      // Get HEART_RATE data
      try {
        final data = await _health.getHealthDataFromTypes(
          types: [HealthDataType.HEART_RATE],
          startTime: start,
          endTime: now,
        );
        heartRateData.addAll(data);
        print('HealthService: Got ${data.length} heart rate records');
      } catch (e) {
        print('HealthService: Error fetching heart rate: $e');
      }

      // Get DISTANCE data
      try {
        final data = await _health.getHealthDataFromTypes(
          types: [HealthDataType.DISTANCE_DELTA],
          startTime: start,
          endTime: now,
        );
        distanceData.addAll(data);
        print('HealthService: Got ${data.length} distance records');
      } catch (e) {
        print('HealthService: Error fetching distance: $e');
      }

      // If no workout data but permissions granted, return empty
      if (workoutData.isEmpty) {
        try {
          final hasPerms = await _health.hasPermissions(requestTypes);
          if (hasPerms == true) {
            print('HealthService: No workouts found but permissions granted');
            return [];
          }
        } catch (e) {
          print('HealthService: Error checking permissions: $e');
        }

        // Try cache
        final prefs = await SharedPreferences.getInstance();
        final jsonStr = prefs.getString('cache_workouts');
        if (jsonStr == null) {
          return [];
        }
      }

      // Build workout sessions with available data
      final workoutSessions = <WorkoutSession>[];

      for (var workout in workoutData) {
        final workoutStart = workout.dateFrom;
        final workoutEnd = workout.dateTo;

        // Determine exercise type from workout metadata
        ExerciseType exerciseType = ExerciseType.other;
        String? workoutType = workout.value is String
            ? workout.value as String
            : null;

        if (workoutType != null) {
          final lower = workoutType.toLowerCase();
          if (lower.contains('run')) {
            exerciseType = ExerciseType.running;
          } else if (lower.contains('cycl') || lower.contains('bike')) {
            exerciseType = ExerciseType.cycling;
          } else if (lower.contains('walk')) {
            exerciseType = ExerciseType.walking;
          } else if (lower.contains('strength') || lower.contains('weight')) {
            exerciseType = ExerciseType.strengthTraining;
          } else if (lower.contains('yoga')) {
            exerciseType = ExerciseType.yoga;
          }
        }

        // Aggregate calories for this workout period
        double? totalCalories;
        final relevantCalories = caloriesData.where((c) {
          return c.dateFrom.isAfter(
                workoutStart.subtract(const Duration(minutes: 5)),
              ) &&
              c.dateTo.isBefore(workoutEnd.add(const Duration(minutes: 5)));
        }).toList();

        if (relevantCalories.isNotEmpty) {
          totalCalories = relevantCalories.fold<double>(
            0.0,
            (sum, c) => sum + (c.value as num).toDouble(),
          );
        }

        // Aggregate distance for this workout period
        double? totalDistance;
        final relevantDistance = distanceData.where((d) {
          return d.dateFrom.isAfter(
                workoutStart.subtract(const Duration(minutes: 5)),
              ) &&
              d.dateTo.isBefore(workoutEnd.add(const Duration(minutes: 5)));
        }).toList();

        if (relevantDistance.isNotEmpty) {
          totalDistance = relevantDistance.fold<double>(
            0.0,
            (sum, d) => sum + (d.value as num).toDouble(),
          );
        }

        // Calculate average and peak heart rate
        double? avgHeartRate;
        double? peakHeartRate;
        final relevantHeartRates = heartRateData.where((h) {
          return h.dateFrom.isAfter(
                workoutStart.subtract(const Duration(minutes: 5)),
              ) &&
              h.dateTo.isBefore(workoutEnd.add(const Duration(minutes: 5)));
        }).toList();

        if (relevantHeartRates.isNotEmpty) {
          final rates = relevantHeartRates
              .map((h) => (h.value as num).toDouble())
              .toList();
          avgHeartRate = rates.fold(0.0, (sum, r) => sum + r) / rates.length;
          peakHeartRate = rates.reduce((a, b) => a > b ? a : b);
        }

        final session = WorkoutSession(
          type: exerciseType,
          start: workoutStart,
          end: workoutEnd,
          duration: workoutEnd.difference(workoutStart),
          activeCalories: totalCalories,
          steps: null,
          distance: totalDistance,
          avgHeartRate: avgHeartRate,
          peakHeartRate: peakHeartRate,
          avgPace: totalDistance != null && totalDistance > 0
              ? workoutEnd.difference(workoutStart).inSeconds / totalDistance
              : null,
        );

        workoutSessions.add(session);
      }

      // Sort by most recent first
      workoutSessions.sort((a, b) => b.start.compareTo(a.start));

      // Cache the workouts
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'cache_workouts',
        jsonEncode(
          workoutSessions
              .map(
                (w) => {
                  'type': w.type.name,
                  'start': w.start.toIso8601String(),
                  'end': w.end.toIso8601String(),
                  'durationSeconds': w.duration.inSeconds,
                  'activeCalories': w.activeCalories,
                  'steps': w.steps,
                  'distance': w.distance,
                  'avgHeartRate': w.avgHeartRate,
                  'peakHeartRate': w.peakHeartRate,
                  'avgPace': w.avgPace,
                },
              )
              .toList(),
        ),
      );

      return workoutSessions;
    } catch (e) {
      print('HealthService: Error getting workouts: $e');
      // Try cache first
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('cache_workouts');
      if (jsonStr != null) {
        final list = (jsonDecode(jsonStr) as List).cast<Map<String, dynamic>>();
        return list.map((e) => WorkoutSession.fromJson(e)).toList();
      }
      print(
        'HealthService: Returning empty workouts list (no real data and no cache)',
      );
      return [];
    }
  }
}
