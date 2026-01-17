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

    // Workouts can be stored under multiple data types in Health Connect
    final types = [HealthDataType.WORKOUT, HealthDataType.ACTIVE_ENERGY_BURNED];

    try {
      print('HealthService: Requesting permissions for workouts...');
      final permGranted = await requestPermissions();
      print('HealthService: Workout permissions granted: $permGranted');

      print('HealthService: Getting workouts from Health Connect...');

      // Fetch workout data
      List<HealthDataPoint> allData = [];

      for (var type in types) {
        try {
          print('HealthService: Fetching $type data...');
          final data = await _health.getHealthDataFromTypes(
            types: [type],
            startTime: start,
            endTime: now,
          );
          print('HealthService: Got ${data.length} records for $type');
          allData.addAll(data);
        } catch (e) {
          print('HealthService: Error fetching $type: $e');
          // Continue with next type
        }
      }

      print('HealthService: Got ${allData.length} total workout records');

      // If we got no data, check if permissions are actually granted
      if (allData.isEmpty) {
        // Check if we actually have permissions
        try {
          final hasPerms = await _health.hasPermissions(types);
          if (hasPerms == true) {
            // We have permissions but just no workouts - return empty list
            print(
              'HealthService: No workouts found but permissions granted - returning empty list',
            );
            return [];
          }
        } catch (e) {
          print('HealthService: Error checking workout permissions: $e');
        }

        // Permissions not granted, try cache
        final prefs = await SharedPreferences.getInstance();
        final jsonStr = prefs.getString('cache_workouts');
        if (jsonStr == null) {
          // No cache and no permissions, return empty list (not mock data)
          print(
            'HealthService: No workouts found and no permissions - returning empty list',
          );
          return [];
        }
      }

      final workouts = allData.map((d) {
        final s = d.dateFrom;
        final e = d.dateTo;
        return WorkoutSession(
          type: ExerciseType.other,
          start: s,
          end: e,
          duration: e.difference(s),
          activeCalories: null,
          steps: null,
          distance: null,
          avgHeartRate: null,
          peakHeartRate: null,
          avgPace: null,
        );
      }).toList();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'cache_workouts',
        jsonEncode(
          workouts
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
      return workouts;
    } catch (e) {
      print('HealthService: Error getting workouts: $e');
      // Try cache first
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('cache_workouts');
      if (jsonStr != null) {
        final list = (jsonDecode(jsonStr) as List).cast<Map<String, dynamic>>();
        return list.map((e) => WorkoutSession.fromJson(e)).toList();
      }
      // Return empty list instead of mock workouts
      print(
        'HealthService: Returning empty workouts list (no real data and no cache)',
      );
      return [];
    }
  }
}
