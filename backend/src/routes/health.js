import express from 'express';
import Joi from 'joi';
import { StepSummary, WorkoutSession, SyncLog } from '../models/HealthModels.js';

const router = express.Router();

// Validation schemas
const stepSchema = Joi.object({
  userId: Joi.string().required(),
  date: Joi.string().isoDate().required(),
  steps: Joi.number().integer().min(0).required(),
  updatedAt: Joi.string().isoDate().required(),
});

const workoutSchema = Joi.object({
  userId: Joi.string().required(),
  sessions: Joi.array()
    .items(
      Joi.object({
        userId: Joi.string().required(),
        type: Joi.string().required(),
        start: Joi.string().isoDate().required(),
        end: Joi.string().isoDate().required(),
        durationSeconds: Joi.number().integer().min(0).required(),
        activeCalories: Joi.number().optional(),
        steps: Joi.number().integer().optional(),
        distance: Joi.number().optional(),
        avgHeartRate: Joi.number().optional(),
        peakHeartRate: Joi.number().optional(),
        avgPace: Joi.number().optional(),
      })
    )
    .required(),
});

const syncLogSchema = Joi.object({
  userId: Joi.string().required(),
  action: Joi.string().required(), // e.g., steps, workouts, combined
  status: Joi.string().valid('success', 'failure').required(),
  message: Joi.string().allow('', null),
  stepCount: Joi.number().integer().min(0).optional(),
  workoutCount: Joi.number().integer().min(0).optional(),
});

// POST steps
router.post('/steps', async (req, res) => {
  const { error, value } = stepSchema.validate(req.body);
  if (error) return res.status(400).json({ ok: false, error: error.message });
  try {
    const { userId, date, steps, updatedAt } = value;
    const doc = await StepSummary.findOneAndUpdate(
      { userId, date: new Date(date) },
      { $set: { steps, updatedAt: new Date(updatedAt) } },
      { upsert: true, new: true }
    );
    res.json({ ok: true, data: doc });
  } catch (e) {
    res.status(500).json({ ok: false, error: e.message });
  }
});

// POST workouts
router.post('/workouts', async (req, res) => {
  const { error, value } = workoutSchema.validate(req.body);
  if (error) return res.status(400).json({ ok: false, error: error.message });
  try {
    const { sessions } = value;
    if (!sessions || sessions.length === 0)
      return res.json({ ok: true, data: [], message: 'No sessions to save' });
    const docs = await WorkoutSession.insertMany(
      sessions.map((s) => ({ ...s, start: new Date(s.start), end: new Date(s.end) }))
    );
    res.json({ ok: true, data: docs });
  } catch (e) {
    res.status(500).json({ ok: false, error: e.message });
  }
});

// GET steps
router.get('/steps', async (req, res) => {
  const { userId, start, end } = req.query;
  if (!userId) return res.status(400).json({ ok: false, error: 'userId is required' });
  const filter = { userId };
  if (start) filter.date = { ...filter.date, $gte: new Date(start) };
  if (end) filter.date = { ...filter.date, $lte: new Date(end) };
  try {
    const docs = await StepSummary.find(filter).sort({ date: -1 }).limit(31);
    res.json({ ok: true, data: docs });
  } catch (e) {
    res.status(500).json({ ok: false, error: e.message });
  }
});

// GET workouts
router.get('/workouts', async (req, res) => {
  const { userId, start, end } = req.query;
  if (!userId) return res.status(400).json({ ok: false, error: 'userId is required' });
  const filter = { userId };
  if (start) filter.start = { ...filter.start, $gte: new Date(start) };
  if (end) filter.end = { ...filter.end, $lte: new Date(end) };
  try {
    const docs = await WorkoutSession.find(filter).sort({ start: -1 }).limit(100);
    res.json({ ok: true, data: docs });
  } catch (e) {
    res.status(500).json({ ok: false, error: e.message });
  }
});

// POST sync log
router.post('/sync/logs', async (req, res) => {
  const { error, value } = syncLogSchema.validate(req.body);
  if (error) return res.status(400).json({ ok: false, error: error.message });
  try {
    const doc = await SyncLog.create(value);
    res.json({ ok: true, data: doc });
  } catch (e) {
    res.status(500).json({ ok: false, error: e.message });
  }
});

// GET sync logs
router.get('/sync/logs', async (req, res) => {
  const { userId, limit } = req.query;
  if (!userId) return res.status(400).json({ ok: false, error: 'userId is required' });
  const lim = Math.min(parseInt(limit || '20', 10), 100);
  try {
    const docs = await SyncLog.find({ userId })
      .sort({ createdAt: -1 })
      .limit(lim);
    res.json({ ok: true, data: docs });
  } catch (e) {
    res.status(500).json({ ok: false, error: e.message });
  }
});

export default router;
