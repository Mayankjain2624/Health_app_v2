import mongoose from 'mongoose';

const StepSummarySchema = new mongoose.Schema(
  {
    userId: { type: String, index: true, required: true },
    date: { type: Date, index: true, required: true },
    steps: { type: Number, required: true },
    updatedAt: { type: Date, required: true },
  },
  { timestamps: true }
);

const WorkoutSessionSchema = new mongoose.Schema(
  {
    userId: { type: String, index: true, required: true },
    type: { type: String, required: true },
    activityTypeName: { type: String },
    start: { type: Date, required: true },
    end: { type: Date, required: true },
    durationSeconds: { type: Number, required: true },
    activeCalories: Number,
    steps: Number,
    distance: Number,
    avgHeartRate: Number,
    peakHeartRate: Number,
    avgPace: Number,
  },
  { timestamps: true }
);

const SyncLogSchema = new mongoose.Schema(
  {
    userId: { type: String, index: true, required: true },
    action: { type: String, required: true }, // e.g., steps, workouts
    status: { type: String, enum: ['success', 'failure'], required: true },
    message: { type: String },
    stepCount: { type: Number, default: 0 },
    workoutCount: { type: Number, default: 0 },
  },
  { timestamps: true }
);

export const StepSummary = mongoose.model('StepSummary', StepSummarySchema);
export const WorkoutSession = mongoose.model('WorkoutSession', WorkoutSessionSchema);
export const SyncLog = mongoose.model('SyncLog', SyncLogSchema);
