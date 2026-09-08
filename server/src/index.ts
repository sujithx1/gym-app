import 'dotenv/config';
import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { initDb } from './db';
import authRoutes from './routes/auth';
import workoutRoutes from './routes/workouts';
import sessionRoutes from './routes/sessions';
import exerciseRoutes from './routes/exercises';
import progressRoutes from './routes/progress';
import { logger } from 'hono/logger';

const app = new Hono();



// Enable CORS for Flutter app
app.use('*', cors({
  origin: '*',
  allowMethods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowHeaders: ['Content-Type', 'Authorization'],
}));
app.use(logger())
// Root check
app.get('/', (c) => {
  return c.json({
    status: 'online',
    app: 'Gym Workout Tracker Backend API',
    version: '1.0.0',
    time: new Date().toISOString(),
  });
});

// Mount Routes
app.route('/api/auth', authRoutes);
app.route('/api/workouts', workoutRoutes);
app.route('/api/sessions', sessionRoutes);
app.route('/api/exercises', exerciseRoutes);
app.route('/api/progress', progressRoutes);

// Initialize Database on Startup
// initDb().then(() => {
//   console.log('PostgreSQL database ready.');
// }).catch((err) => {
//   console.error('Database connection warning:', err);
// });

const PORT = Number(process.env.PORT) || 3001;
console.log(`Server starting on port ${PORT}...`);

export default {
  port: PORT,
  fetch: app.fetch,
};
