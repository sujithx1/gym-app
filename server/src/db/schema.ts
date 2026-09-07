import { pgTable, text, timestamp, integer, boolean, real } from 'drizzle-orm/pg-core';
import { sql } from 'drizzle-orm';

export const users = pgTable('users', {
  id: text('id').primaryKey(),
  username: text('username').notNull().unique(),
  passwordHash: text('password_hash').notNull(),
  createdAt: timestamp('created_at').defaultNow().notNull(),
});

export const workoutPlans = pgTable('workout_plans', {
  id: text('id').primaryKey(),
  userId: text('user_id').notNull().references(() => users.id, { onDelete: 'cascade' }),
  name: text('name').notNull(),
  isActive: boolean('is_active').default(true).notNull(),
  createdAt: timestamp('created_at').defaultNow().notNull(),
});

export const workoutDays = pgTable('workout_days', {
  id: text('id').primaryKey(),
  planId: text('plan_id').notNull().references(() => workoutPlans.id, { onDelete: 'cascade' }),
  dayOfWeek: integer('day_of_week').notNull(), // 0 = Sun, 1 = Mon, 2 = Tue, 3 = Wed, 4 = Thu, 5 = Fri, 6 = Sat
  name: text('name').notNull(), // e.g. "Chest & Triceps"
});

export const exercises = pgTable('exercises', {
  id: text('id').primaryKey(),
  name: text('name').notNull(),
  muscleGroup: text('muscle_group').notNull(), // Chest, Back, Shoulders, Biceps, Triceps, Legs, Abs, Cardio
  equipment: text('equipment').notNull(), // Barbell, Dumbbell, Machine, Bodyweight, Cable
  instructions: text('instructions'),
  isCustom: boolean('is_custom').default(false).notNull(),
  userId: text('user_id').references(() => users.id, { onDelete: 'cascade' }),
});

export const workoutExercises = pgTable('workout_exercises', {
  id: text('id').primaryKey(),
  workoutDayId: text('workout_day_id').notNull().references(() => workoutDays.id, { onDelete: 'cascade' }),
  exerciseId: text('exercise_id').notNull().references(() => exercises.id, { onDelete: 'cascade' }),
  orderIndex: integer('order_index').notNull(),
  targetSets: integer('target_sets').default(3).notNull(),
  targetReps: integer('target_reps').default(10).notNull(),
  targetWeight: real('target_weight').default(0).notNull(),
});

export const workoutSessions = pgTable('workout_sessions', {
  id: text('id').primaryKey(),
  userId: text('user_id').notNull().references(() => users.id, { onDelete: 'cascade' }),
  workoutDayId: text('workout_day_id').references(() => workoutDays.id, { onDelete: 'set null' }),
  name: text('name').notNull(),
  startedAt: timestamp('started_at').defaultNow().notNull(),
  completedAt: timestamp('completed_at'),
  status: text('status').default('in_progress').notNull(), // 'in_progress' | 'completed'
  notes: text('notes'),
  totalVolumeKg: real('total_volume_kg').default(0),
  durationMinutes: integer('duration_minutes').default(0),
});

export const sets = pgTable('sets', {
  id: text('id').primaryKey(),
  sessionId: text('session_id').notNull().references(() => workoutSessions.id, { onDelete: 'cascade' }),
  exerciseId: text('exercise_id').notNull().references(() => exercises.id, { onDelete: 'cascade' }),
  setNumber: integer('set_number').notNull(),
  weight: real('weight').notNull(),
  reps: integer('reps').notNull(),
  completed: boolean('completed').default(true).notNull(),
  completedAt: timestamp('completed_at').defaultNow(),
});
