import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import dotenv from 'dotenv';
import mongoose from 'mongoose';
import healthRouter from './routes/health.js';

dotenv.config();

const app = express();
app.use(helmet());
app.use(cors());
app.use(express.json({ limit: '1mb' }));
app.use(morgan('dev'));

app.get('/health', (req, res) => res.json({ ok: true }));
app.use('/api', healthRouter);

const port = process.env.PORT || 3000;
const uri = process.env.MONGODB_URI || 'mongodb://localhost:27017/healthapp';

mongoose
  .connect(uri)
  .then(() => {
    console.log('MongoDB connected');
    app.listen(port, () => console.log(`Server running on port ${port}`));
  })
  .catch((err) => {
    console.error('MongoDB connection error:', err.message);
    process.exit(1);
  });
