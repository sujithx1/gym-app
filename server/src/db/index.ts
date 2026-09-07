import { drizzle } from 'drizzle-orm/postgres-js';
import postgres from 'postgres';
import * as schema from './schema';

const connectionString = process.env.DATABASE_URL || 'postgres://sujith:Sujith%40123@localhost:5432/db';

export const queryClient = postgres(connectionString, { max: 10 });
export const db = drizzle(queryClient, { schema });

// Auto-initialize tables if not exists
export async function initDb() {
  try {
    await queryClient.unsafe(`
      CREATE TABLE IF NOT EXISTS users (
        id TEXT PRIMARY KEY,
        username TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
      );

      CREATE TABLE IF NOT EXISTS workout_plans (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        name TEXT NOT NULL,
        is_active BOOLEAN DEFAULT TRUE NOT NULL,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
      );

      CREATE TABLE IF NOT EXISTS workout_days (
        id TEXT PRIMARY KEY,
        plan_id TEXT NOT NULL REFERENCES workout_plans(id) ON DELETE CASCADE,
        day_of_week INTEGER NOT NULL,
        name TEXT NOT NULL
      );

      CREATE TABLE IF NOT EXISTS exercises (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        muscle_group TEXT NOT NULL,
        equipment TEXT NOT NULL,
        instructions TEXT,
        is_custom BOOLEAN DEFAULT FALSE NOT NULL,
        user_id TEXT REFERENCES users(id) ON DELETE CASCADE
      );

      CREATE TABLE IF NOT EXISTS workout_exercises (
        id TEXT PRIMARY KEY,
        workout_day_id TEXT NOT NULL REFERENCES workout_days(id) ON DELETE CASCADE,
        exercise_id TEXT NOT NULL REFERENCES exercises(id) ON DELETE CASCADE,
        order_index INTEGER NOT NULL,
        target_sets INTEGER DEFAULT 3 NOT NULL,
        target_reps INTEGER DEFAULT 10 NOT NULL,
        target_weight REAL DEFAULT 0 NOT NULL
      );

      CREATE TABLE IF NOT EXISTS workout_sessions (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        workout_day_id TEXT REFERENCES workout_days(id) ON DELETE SET NULL,
        name TEXT NOT NULL,
        started_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
        completed_at TIMESTAMP WITH TIME ZONE,
        status TEXT DEFAULT 'in_progress' NOT NULL,
        notes TEXT,
        total_volume_kg REAL DEFAULT 0,
        duration_minutes INTEGER DEFAULT 0
      );

      CREATE TABLE IF NOT EXISTS sets (
        id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL REFERENCES workout_sessions(id) ON DELETE CASCADE,
        exercise_id TEXT NOT NULL REFERENCES exercises(id) ON DELETE CASCADE,
        set_number INTEGER NOT NULL,
        weight REAL NOT NULL,
        reps INTEGER NOT NULL,
        completed BOOLEAN DEFAULT TRUE NOT NULL,
        completed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );
    `);
    console.log('Database tables initialized successfully');
  } catch (err) {
    console.error('Error initializing database tables:', err);
  }
}
