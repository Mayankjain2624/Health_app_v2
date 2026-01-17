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
      return true;
    }
    return false;
  }

  Future<bool> requestPermissions() async {
    print('HealthService: requestPermissions() called');

    if (Platform.isAndroid) {
      print('HealthService: Requesting system permissions on Android...');
      try {
        final results = await Future.wait([
          Permission.location.request(),
          Permission.activityRecognition.request(),
        ]);

        final allGranted = results.every((status) => status.isGranted);
        print('HealthService: System permissions granted: $allGranted');
      } catch (e) {
        print('HealthService: Error requesting system permissions: $e');
      }

      await Future.delayed(const Duration(milliseconds: 500));
    }

    final types = <HealthDataType>[
      HealthDataType.STEPS,
      HealthDataType.ACTIVE_ENERGY_BURNED,
      HealthDataType.HEART_RATE,
      HealthDataType.DISTANCE_DELTA,
      if (Platform.isIOS) HealthDataType.DISTANCE_WALKING_RUNNING,
    ];
    final permissions = types.map((t) => HealthDataAccess.READ).toList();

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

    print('HealthService: Requesting Health Connect permissions...');
    try {
      final granted = await _health.requestAuthorization(
        types,
        permissions: permissions,
      );
      print('HealthService: requestAuthorization returned: $granted');
      return granted;
    } catch (e) {
      print('HealthService: Error requesting authorization: $e');
      return false;
    }
  }

  Future<StepSummary?> getTodaySteps() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    try {
      print('HealthService: getTodaySteps() started');

      final permGranted = await requestPermissions();
      print('HealthService: Permission request result: $permGranted');

      print('HealthService: Getting total steps...');
      final steps = await _health.getTotalStepsInInterval(startOfDay, now) ?? 0;
      print('HealthService: Got steps: $steps');

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
      return null;
    }
  }

  Future<List<WorkoutSession>> getRecentWorkouts({int days = 7}) async {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: days));

    try {
      print('HealthService: Requesting workout permissions...');
      await requestPermissions();

      print(
        'HealthService: Fetching workout data for ${days} days (${start} to ${now})...',
      );
      final workoutSessions = <WorkoutSession>[];

      // Try WORKOUT/EXERCISE type first
      List<HealthDataPoint> workoutData = [];
      try {
        workoutData = await _health.getHealthDataFromTypes(
          types: [HealthDataType.WORKOUT],
          startTime: start,
          endTime: now,
        );
        print('HealthService: Got ${workoutData.length} WORKOUT records');
      } catch (e) {
        print('HealthService: Error fetching WORKOUT data: $e');
      }

      // Also try ACTIVE_ENERGY_BURNED to detect workouts
      List<HealthDataPoint> energyData = [];
      try {
        energyData = await _health.getHealthDataFromTypes(
          types: [HealthDataType.ACTIVE_ENERGY_BURNED],
          startTime: start,
          endTime: now,
        );
        print(
          'HealthService: Got ${energyData.length} ACTIVE_ENERGY_BURNED records',
        );
      } catch (e) {
        print('HealthService: Error fetching energy data: $e');
      }

      if (workoutData.isEmpty && energyData.isEmpty) {
        print(
          'HealthService: No workout or energy data found - this may indicate Health Connect not properly configured or no data available in selected date range',
        );
        return [];
      }

      // Fetch heart rate data
      List<HealthDataPoint> heartRateData = [];
      try {
        heartRateData = await _health.getHealthDataFromTypes(
          types: [HealthDataType.HEART_RATE],
          startTime: start,
          endTime: now,
        );
        print('HealthService: Got ${heartRateData.length} heart rate records');
      } catch (e) {
        print('HealthService: Error fetching heart rate: $e');
      }

      // Fetch distance data
      List<HealthDataPoint> distanceData = [];
      try {
        distanceData = await _health.getHealthDataFromTypes(
          types: [HealthDataType.DISTANCE_DELTA],
          startTime: start,
          endTime: now,
        );
        print('HealthService: Got ${distanceData.length} distance records');
      } catch (e) {
        print('HealthService: Error fetching distance: $e');
      }

      // If WORKOUT data exists, use it directly
      if (workoutData.isNotEmpty) {
        print(
          'HealthService: Processing ${workoutData.length} workout records...',
        );
        for (final workout in workoutData) {
          print('HealthService: Processing workout: $workout');

          final sessionStart = workout.dateFrom;
          final sessionEnd = workout.dateTo;

          // Extract calories from WorkoutHealthValue
          double? calories;
          int? steps;
          double? distance;
          String? workoutActivityType;

          try {
            // The value is a WorkoutHealthValue with nested properties
            if (workout.value != null) {
              print(
                'HealthService: Workout value type: ${workout.value.runtimeType}',
              );

              // Cast to WorkoutHealthValue to access properties
              try {
                final workoutValue = workout.value as dynamic;
                if (workoutValue.totalEnergyBurned != null) {
                  calories = (workoutValue.totalEnergyBurned as num).toDouble();
                }
                if (workoutValue.totalSteps != null) {
                  steps = (workoutValue.totalSteps as num).toInt();
                }
                if (workoutValue.totalDistance != null) {
                  distance = (workoutValue.totalDistance as num).toDouble();
                }
                // Get the activity type
                if (workoutValue.workoutActivityType != null) {
                  final fullType = workoutValue.workoutActivityType.toString();
                  // Extract just the enum name (e.g., "RUNNING" from "HealthWorkoutActivityType.RUNNING")
                  workoutActivityType = fullType.contains('.')
                      ? fullType.split('.').last
                      : fullType;
                  print(
                    'HealthService: Workout activity type: $workoutActivityType',
                  );
                }
              } catch (e) {
                print(
                  'HealthService: Could not access WorkoutHealthValue properties: $e',
                );
              }
            }
          } catch (e) {
            print('HealthService: Error extracting workout data: $e');
          }

          // Correlate with distance records if not in workout
          if (distance == null) {
            final sessionDistance = distanceData.where((d) {
              return !d.dateFrom.isAfter(
                    sessionEnd.add(const Duration(minutes: 5)),
                  ) &&
                  !d.dateTo.isBefore(
                    sessionStart.subtract(const Duration(minutes: 5)),
                  );
            }).toList();

            if (sessionDistance.isNotEmpty) {
              distance = sessionDistance.fold<double>(0.0, (sum, d) {
                try {
                  return sum + ((d.value as num?)?.toDouble() ?? 0.0);
                } catch (e) {
                  print('HealthService: Error parsing distance value: $e');
                  return sum;
                }
              });
            }
          }

          final session = WorkoutSession(
            type: _parseExerciseType(workoutActivityType ?? 'OTHER'),
            activityTypeName: _formatActivityTypeName(
              workoutActivityType ?? 'OTHER',
            ),
            start: sessionStart,
            end: sessionEnd,
            duration: sessionEnd.difference(sessionStart),
            activeCalories: calories,
            steps: steps,
            distance: distance,
            avgHeartRate: null,
            peakHeartRate: null,
            avgPace: null,
          );

          workoutSessions.add(session);
          print(
            'HealthService: Added workout: ${session.duration.inMinutes} min, ${session.activeCalories} cal, ${session.distance} m',
          );
        }
      }
      // Otherwise group ACTIVE_ENERGY_BURNED into workout sessions
      else if (energyData.isNotEmpty) {
        print(
          'HealthService: Grouping ${energyData.length} energy records into workout sessions...',
        );
        energyData.sort((a, b) => a.dateFrom.compareTo(b.dateFrom));

        int i = 0;
        while (i < energyData.length) {
          final current = energyData[i];
          var sessionStart = current.dateFrom;
          var sessionEnd = current.dateTo;
          var totalCalories = (current.value as num).toDouble();

          // Group consecutive points within 10 minutes
          int j = i + 1;
          while (j < energyData.length) {
            final next = energyData[j];
            if (next.dateFrom.difference(sessionEnd).inMinutes <= 10) {
              totalCalories += (next.value as num).toDouble();
              sessionEnd = next.dateTo;
              j++;
            } else {
              break;
            }
          }

          // Get heart rate for this session
          double? avgHeartRate;
          final sessionHeartRates = heartRateData.where((h) {
            return !h.dateFrom.isAfter(
                  sessionEnd.add(const Duration(minutes: 5)),
                ) &&
                !h.dateTo.isBefore(
                  sessionStart.subtract(const Duration(minutes: 5)),
                );
          }).toList();

          if (sessionHeartRates.isNotEmpty) {
            final rates = sessionHeartRates
                .map((h) => (h.value as num).toDouble())
                .toList();
            avgHeartRate =
                rates.fold<double>(0.0, (sum, r) => sum + r) / rates.length;
          }

          // Get distance for this session
          double? totalDistance;
          final sessionDistance = distanceData.where((d) {
            return !d.dateFrom.isAfter(
                  sessionEnd.add(const Duration(minutes: 5)),
                ) &&
                !d.dateTo.isBefore(
                  sessionStart.subtract(const Duration(minutes: 5)),
                );
          }).toList();

          if (sessionDistance.isNotEmpty) {
            totalDistance = sessionDistance.fold<double>(
              0.0,
              (sum, d) => sum + (d.value as num).toDouble(),
            );
          }

          final session = WorkoutSession(
            type: ExerciseType.other,
            activityTypeName: 'Other',
            start: sessionStart,
            end: sessionEnd,
            duration: sessionEnd.difference(sessionStart),
            activeCalories: totalCalories > 0 ? totalCalories : null,
            steps: null,
            distance: totalDistance,
            avgHeartRate: avgHeartRate,
            peakHeartRate: null,
            avgPace: null,
          );

          workoutSessions.add(session);
          i = j;
        }
      }

      workoutSessions.sort((a, b) => b.start.compareTo(a.start));
      print(
        'HealthService: Created ${workoutSessions.length} workout sessions',
      );

      // Cache
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'cache_workouts',
        jsonEncode(
          workoutSessions
              .map(
                (w) => {
                  'type': w.type.name,
                  'activityTypeName': w.activityTypeName,
                  'start': w.start.toIso8601String(),
                  'end': w.end.toIso8601String(),
                  'durationSeconds': w.duration.inSeconds,
                  'activeCalories': w.activeCalories,
                  'distance': w.distance,
                  'avgHeartRate': w.avgHeartRate,
                },
              )
              .toList(),
        ),
      );

      return workoutSessions;
    } catch (e) {
      print('HealthService: Error: $e');
      return [];
    }
  }

  ExerciseType _parseExerciseType(String typeString) {
    final normalized = typeString.toLowerCase();

    // Google Fit / Health Connect activity type names
    // Running types
    if (normalized.contains('run')) return ExerciseType.running;

    // Cycling types
    if (normalized.contains('bike') || normalized.contains('cycling'))
      return ExerciseType.cycling;

    // Walking types
    if (normalized.contains('walk')) return ExerciseType.walking;

    // Yoga types
    if (normalized.contains('yoga')) return ExerciseType.yoga;

    // Strength/weight training types
    if (normalized.contains('strength') || normalized.contains('weight'))
      return ExerciseType.strengthTraining;

    // All other sports and activities default to other
    // This includes: cricket, skiing, swimming, dancing, football, basketball, tennis, etc.
    return ExerciseType.other;
  }

  String _formatActivityTypeName(String typeString) {
    // Convert "RUNNING_TREADMILL" -> "Running Treadmill"
    // Convert "CROSS_COUNTRY_SKIING" -> "Cross Country Skiing"
    // Convert "OTHER" -> "Other"
    if (typeString.isEmpty) return 'Other';
    return typeString
        .split('_')
        .map((word) {
          if (word.isEmpty) return '';
          return word[0].toUpperCase() +
              (word.length > 1 ? word.substring(1).toLowerCase() : '');
        })
        .where((word) => word.isNotEmpty)
        .join(' ');
  }
}
