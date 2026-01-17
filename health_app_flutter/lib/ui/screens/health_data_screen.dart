import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import '../../bloc/health_bloc.dart';
import '../../repositories/health_repository.dart';
import '../../services/health_service.dart';
import '../../services/backend_service.dart';
import '../widgets/summary_card.dart';
import '../widgets/workout_card.dart';

class HealthDataScreen extends StatefulWidget {
  const HealthDataScreen({super.key});

  @override
  State<HealthDataScreen> createState() => _HealthDataScreenState();
}

class _HealthDataScreenState extends State<HealthDataScreen> {
  bool _healthConnectMissing = false;

  @override
  void initState() {
    super.initState();
    _checkHealthConnect();
  }

  Future<void> _checkHealthConnect() async {
    final healthService = HealthService();
    final available = await healthService.isHealthDataSourceAvailable();
    if (!available) {
      setState(() {
        _healthConnectMissing = true;
      });
    }
  }

  void _openPlayStore() async {
    const url =
        'https://play.google.com/store/apps/details?id=com.google.android.apps.healthdata';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HealthBloc(
        HealthRepository(
          healthService: HealthService(),
          backendService: BackendService(),
          userId: 'demo-user-1',
        ),
      )..add(LoadHealthData()),
      child: Scaffold(
        appBar: AppBar(title: const Text('Health Dashboard')),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0F1419), Color(0xFF1A237E), Color(0xFF0D47A1)],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
          child: _healthConnectMissing
              ? _buildHealthConnectMissingDialog()
              : BlocBuilder<HealthBloc, HealthState>(
                  builder: (context, state) {
                    if (state is HealthLoading || state is HealthInitial) {
                      return const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF2196F3),
                          ),
                        ),
                      );
                    }
                    if (state is HealthError) {
                      return Center(child: Text(state.message));
                    }
                    final loaded = state as HealthLoaded;
                    return ListView(
                      children: [
                        SummaryCard(
                          summary: loaded.steps,
                          lastSynced: loaded.lastSynced,
                          onRefresh: () =>
                              context.read<HealthBloc>().add(RefreshSteps()),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 12,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Recent Workouts',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: () => context.read<HealthBloc>().add(
                                  SyncAllData(),
                                ),
                                icon: const Icon(Icons.cloud_upload, size: 18),
                                label: const Text('Sync'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF00BCD4),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (loaded.workouts.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.fitness_center,
                                  size: 64,
                                  color: Colors.white.withOpacity(0.3),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No workouts found',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.6),
                                    fontSize: 16,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        else
                          ...loaded.workouts
                              .map((w) => WorkoutCard(session: w))
                              .toList(),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text(
                                'Sync History',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: loaded.syncLogs.isEmpty
                                ? Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Text(
                                      'No sync history yet. Tap Sync to push data.',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                      ),
                                    ),
                                  )
                                : ListView.separated(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: loaded.syncLogs.length,
                                    separatorBuilder: (_, __) => Divider(
                                      height: 1,
                                      color: Colors.white.withOpacity(0.08),
                                    ),
                                    itemBuilder: (ctx, i) {
                                      final log = loaded.syncLogs[i];
                                      final success = log.status == 'success';
                                      return ListTile(
                                        dense: true,
                                        leading: Icon(
                                          success
                                              ? Icons.check_circle
                                              : Icons.error,
                                          color: success
                                              ? Colors.lightGreenAccent
                                              : Colors.redAccent,
                                        ),
                                        title: Text(
                                          '${log.action} - ${log.status}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              log.message ?? 'No details',
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(
                                                  0.7,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _buildCountDisplay(log),
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(
                                                  0.6,
                                                ),
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                        trailing: Text(
                                          _formatTime(log.createdAt),
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(
                                              0.7,
                                            ),
                                            fontSize: 12,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    );
                  },
                ),
        ),
      ),
    );
  }

  void _openHealthConnect() async {
    // Try to open Health Connect settings directly
    if (Platform.isAndroid) {
      try {
        // Android deeplink to Health Connect settings
        await launchUrl(
          Uri.parse(
            'android-app://com.google.android.healthconnect.controller/',
          ),
          mode: LaunchMode.externalApplication,
        );
      } catch (e) {
        print('Error launching Health Connect: $e');
      }
    }
  }

  Widget _buildHealthConnectMissingDialog() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.health_and_safety, size: 64, color: Colors.red),
            const SizedBox(height: 24),
            const Text(
              'Manual Permission Setup Required',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                border: Border.all(color: Colors.blue.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Health Connect permission dialog has a bug on Android 15. '
                'You must manually enable permissions:\n\n'
                '1️⃣  Tap "Open Health Connect" below\n'
                '2️⃣  Go to Settings ⚙️\n'
                '3️⃣  Find "Health App" in the list\n'
                '4️⃣  Toggle ON all permissions (Steps, Workouts, Heart Rate, etc.)\n'
                '5️⃣  Return to this app\n'
                '6️⃣  Tap "Check Permissions" below\n\n'
                'Then you\'ll see real health data! 🎉',
                style: TextStyle(fontSize: 14, height: 1.8),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _openHealthConnect,
              icon: const Icon(Icons.apps),
              label: const Text('Open Health Connect'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                setState(() {
                  _healthConnectMissing = false;
                });
                _checkHealthConnect();
              },
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text('✓ Check Permissions'),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatTime(DateTime dt) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final dateOnly = DateTime(dt.year, dt.month, dt.day);
  if (dateOnly == today) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
  return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

String _buildCountDisplay(dynamic log) {
  if (log.action == 'steps' && log.stepCount > 0) {
    return '📊 ${log.stepCount} steps synced';
  } else if (log.action == 'workouts' && log.workoutCount > 0) {
    return '🏃 ${log.workoutCount} workouts synced';
  } else if (log.action == 'sync' || log.action == 'combined') {
    final parts = <String>[];
    if (log.stepCount > 0) parts.add('📊 ${log.stepCount} steps');
    if (log.workoutCount > 0) parts.add('🏃 ${log.workoutCount} workouts');
    return parts.isNotEmpty ? parts.join(' • ') : '✓ Sync complete';
  }
  return '✓ Synced successfully';
}

String _buildCountInfo(dynamic log) {
  final parts = <String>[];

  // Show counts based on action type
  if (log.action == 'steps' && log.stepCount > 0) {
    parts.add('📊 ${log.stepCount} steps');
  } else if (log.action == 'workouts' && log.workoutCount > 0) {
    parts.add('🏃 ${log.workoutCount} workouts');
  }

  // Show both if combined sync
  if (log.action == 'sync' || log.action == 'combined') {
    if (log.stepCount > 0) {
      parts.add('📊 ${log.stepCount} steps');
    }
    if (log.workoutCount > 0) {
      parts.add('🏃 ${log.workoutCount} workouts');
    }
  }

  return parts.isEmpty ? '' : parts.join(' • ');
}
