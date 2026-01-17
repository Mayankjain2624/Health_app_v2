import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../models/step_summary.dart';
import '../models/workout_session.dart';
import '../models/sync_log_entry.dart';
import '../repositories/health_repository.dart';

// Events
abstract class HealthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadHealthData extends HealthEvent {}

class RefreshSteps extends HealthEvent {}

class SyncAllData extends HealthEvent {}

// States
abstract class HealthState extends Equatable {
  @override
  List<Object?> get props => [];
}

class HealthInitial extends HealthState {}

class HealthLoading extends HealthState {}

class HealthLoaded extends HealthState {
  final StepSummary? steps;
  final List<WorkoutSession> workouts;
  final DateTime lastSynced;
  final List<SyncLogEntry> syncLogs;

  HealthLoaded({
    this.steps,
    required this.workouts,
    required this.lastSynced,
    required this.syncLogs,
  });

  @override
  List<Object?> get props => [steps, workouts, lastSynced, syncLogs];

  HealthLoaded copyWith({
    StepSummary? steps,
    List<WorkoutSession>? workouts,
    DateTime? lastSynced,
    List<SyncLogEntry>? syncLogs,
  }) => HealthLoaded(
    steps: steps ?? this.steps,
    workouts: workouts ?? this.workouts,
    lastSynced: lastSynced ?? this.lastSynced,
    syncLogs: syncLogs ?? this.syncLogs,
  );
}

class HealthError extends HealthState {
  final String message;
  HealthError(this.message);
}

class HealthBloc extends Bloc<HealthEvent, HealthState> {
  final HealthRepository repo;

  HealthBloc(this.repo) : super(HealthInitial()) {
    on<LoadHealthData>(_onLoad);
    on<RefreshSteps>(_onRefreshSteps);
    on<SyncAllData>(_onSyncAll);
  }

  Future<void> _onLoad(LoadHealthData event, Emitter<HealthState> emit) async {
    emit(HealthLoading());
    try {
      final steps = await repo.loadTodaySteps();
      final workouts = await repo.loadRecentWorkouts();
      final logs = await repo.fetchSyncLogs(limit: 20);
      emit(
        HealthLoaded(
          steps: steps,
          workouts: workouts,
          lastSynced: DateTime.now(),
          syncLogs: logs,
        ),
      );
    } catch (e) {
      emit(HealthError('Failed to load health data: $e'));
    }
  }

  Future<void> _onRefreshSteps(
    RefreshSteps event,
    Emitter<HealthState> emit,
  ) async {
    final current = state is HealthLoaded ? state as HealthLoaded : null;
    try {
      final steps = await repo.loadTodaySteps();
      if (current != null) {
        emit(current.copyWith(steps: steps));
      } else {
        emit(
          HealthLoaded(
            steps: steps,
            workouts: const [],
            lastSynced: DateTime.now(),
            syncLogs: const [],
          ),
        );
      }
    } catch (e) {
      emit(HealthError('Failed to refresh steps: $e'));
    }
  }

  Future<void> _onSyncAll(SyncAllData event, Emitter<HealthState> emit) async {
    final current = state is HealthLoaded ? state as HealthLoaded : null;
    if (current == null) return;
    try {
      int syncedSteps = 0;
      int syncedWorkouts = 0;

      if (current.steps != null) {
        await repo.syncSteps(current.steps!);
        syncedSteps = current.steps!.steps;
        await repo.logSync(
          action: 'steps',
          status: 'success',
          message: 'Synced ${syncedSteps} steps',
          stepCount: syncedSteps,
        );
      } else {
        await repo.logSync(
          action: 'steps',
          status: 'success',
          message: 'No steps to sync',
          stepCount: 0,
        );
      }

      if (current.workouts.isNotEmpty) {
        await repo.syncWorkouts(current.workouts);
        syncedWorkouts = current.workouts.length;
        await repo.logSync(
          action: 'workouts',
          status: 'success',
          message: 'Synced ${syncedWorkouts} workouts',
          workoutCount: syncedWorkouts,
        );
      } else {
        await repo.logSync(
          action: 'workouts',
          status: 'success',
          message: 'No workouts to sync',
          workoutCount: 0,
        );
      }

      final logs = await repo.fetchSyncLogs(limit: 20);
      emit(current.copyWith(lastSynced: DateTime.now(), syncLogs: logs));
    } catch (e) {
      try {
        await repo.logSync(
          action: 'sync',
          status: 'failure',
          message: e.toString(),
        );
      } catch (_) {}
      emit(HealthError('Sync failed: $e'));
    }
  }
}
