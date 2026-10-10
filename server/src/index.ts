import { env } from './env';
import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { initDb, queryClient } from './db';
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
app.use(logger());

// Global Error Handler
app.onError((err, c) => {
  console.error(`\n❌ [UNHANDLED ERROR] ${c.req.method} ${c.req.url}`);
  console.error('Message:', err.message);
  if (err.stack) console.error('Stack:', err.stack);
  return c.json({
    error: err.message || 'Internal Server Error',
    details: String(err),
  }, 500);
});

// Root check & DB diagnostics
app.get('/', async (c) => {
  let dbStatus = 'unknown';
  let dbError: string | null = null;
  try {
    await queryClient`SELECT 1`;
    dbStatus = 'connected';
  } catch (err: any) {
    dbStatus = 'error';
    dbError = err?.message || String(err);
    console.error('❌ Database health check failed on GET /:', err);
  }

  return c.json({
    status: dbStatus === 'connected' ? 'online' : 'degraded',
    database: dbStatus,
    dbError,
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
initDb().then(() => {
  console.log('✅ PostgreSQL database ready & tables verified.');
}).catch((err) => {
  console.error('❌ PostgreSQL database connection/initialization error:', err);
});

const PORT = env.PORT;
console.log(`Server starting on port ${PORT}...`);
console.log(`Database target: ${env.DATABASE_URL.replace(/:[^:@]+@/, ':****@')}`);

export default {
  port: PORT,
  fetch: app.fetch,
};
