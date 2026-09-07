import { Hono } from 'hono';
import { eq, and, asc, desc, gte, count } from 'drizzle-orm';
import { db } from '../db';
import { workoutPlans, workoutDays, workoutExercises, exercises, sets, workoutSessions } from '../db/schema';
import { authMiddleware, Env } from '../middleware/auth';

const workoutRoutes = new Hono<Env>();
workoutRoutes.use('*', authMiddleware);

// GET /api/workouts/today -> Get today's scheduled workout split and target exercises
workoutRoutes.get('/today', async (c) => {
  try {
    const userId = c.get('userId');
    const dayOfWeek = new Date().getDay(); // 0 = Sun, 1 = Mon, ..., 6 = Sat

    // 1. Find active plan
    const plans = await db
      .select()
      .from(workoutPlans)
      .where(and(eq(workoutPlans.userId, userId), eq(workoutPlans.isActive, true)))
      .limit(1);

    if (plans.length === 0) {
      return c.json({
        today: null,
        message: 'No active workout plan found.',
      });
    }

    const plan = plans[0];

    // 2. Find workout day for today
    const days = await db
      .select()
      .from(workoutDays)
      .where(and(eq(workoutDays.planId, plan.id), eq(workoutDays.dayOfWeek, dayOfWeek)))
      .limit(1);

    if (days.length === 0) {
      return c.json({
        today: null,
        message: 'No workout scheduled for today.',
      });
    }

    const day = days[0];

    // 3. Find target exercises for this day
    const targetExercises = await db
      .select({
        workoutExerciseId: workoutExercises.id,
        orderIndex: workoutExercises.orderIndex,
        targetSets: workoutExercises.targetSets,
        targetReps: workoutExercises.targetReps,
        targetWeight: workoutExercises.targetWeight,
        exerciseId: exercises.id,
        exerciseName: exercises.name,
        muscleGroup: exercises.muscleGroup,
        equipment: exercises.equipment,
        instructions: exercises.instructions,
      })
      .from(workoutExercises)
      .innerJoin(exercises, eq(workoutExercises.exerciseId, exercises.id))
      .where(eq(workoutExercises.workoutDayId, day.id))
      .orderBy(asc(workoutExercises.orderIndex));

    // 4. Fetch previous session performance for each exercise
    const exercisesWithHistory = await Promise.all(
      targetExercises.map(async (ex) => {
        const lastSets = await db
          .select({
            setNumber: sets.setNumber,
            weight: sets.weight,
            reps: sets.reps,
            completed: sets.completed,
          })
          .from(sets)
          .innerJoin(workoutSessions, eq(sets.sessionId, workoutSessions.id))
          .where(
            and(
              eq(workoutSessions.userId, userId),
              eq(sets.exerciseId, ex.exerciseId),
              eq(workoutSessions.status, 'completed')
            )
          )
          .orderBy(desc(workoutSessions.completedAt), asc(sets.setNumber))
          .limit(ex.targetSets);

        return {
          id: ex.exerciseId,
          workoutExerciseId: ex.workoutExerciseId,
          name: ex.exerciseName,
          muscleGroup: ex.muscleGroup,
          equipment: ex.equipment,
          instructions: ex.instructions,
          targetSets: ex.targetSets,
          targetReps: ex.targetReps,
          targetWeight: ex.targetWeight,
          lastPerformance: lastSets.map((s) => ({
            setNumber: s.setNumber,
            weight: Number(s.weight),
            reps: Number(s.reps),
            completed: s.completed,
          })),
        };
      })
    );

    // 5. Calculate totals
    const totalSets = exercisesWithHistory.reduce((acc, curr) => acc + curr.targetSets, 0);
    const estimatedMinutes = Math.max(30, exercisesWithHistory.length * 11);

    // 6. Check active session today
    const startOfDay = new Date();
    startOfDay.setHours(0, 0, 0, 0);

    const todaySessions = await db
      .select()
      .from(workoutSessions)
      .where(and(eq(workoutSessions.userId, userId), gte(workoutSessions.startedAt, startOfDay)))
      .orderBy(desc(workoutSessions.startedAt))
      .limit(1);

    const activeSession = todaySessions.length > 0 ? todaySessions[0] : null;

    return c.json({
      today: {
        planId: plan.id,
        workoutDayId: day.id,
        name: day.name,
        dayOfWeek: day.dayOfWeek,
        exerciseCount: exercisesWithHistory.length,
        totalSets,
        estimatedMinutes,
        exercises: exercisesWithHistory,
        activeSession: activeSession
          ? {
              id: activeSession.id,
              status: activeSession.status,
              completedAt: activeSession.completedAt,
              totalVolumeKg: activeSession.totalVolumeKg,
            }
          : null,
      },
    });
  } catch (err: any) {
    return c.json({ error: err.message || 'Error loading today workout' }, 500);
  }
});

// GET /api/workouts/plans -> Get weekly split overview
workoutRoutes.get('/plans', async (c) => {
  try {
    const userId = c.get('userId');
    const plans = await db
      .select()
      .from(workoutPlans)
      .where(eq(workoutPlans.userId, userId))
      .orderBy(desc(workoutPlans.createdAt));

    if (plans.length === 0) {
      return c.json({ plans: [] });
    }

    const plan = plans[0];
    const daysList = await db
      .select({
        id: workoutDays.id,
        dayOfWeek: workoutDays.dayOfWeek,
        name: workoutDays.name,
        exerciseCount: count(workoutExercises.id),
      })
      .from(workoutDays)
      .leftJoin(workoutExercises, eq(workoutDays.id, workoutExercises.workoutDayId))
      .where(eq(workoutDays.planId, plan.id))
      .groupBy(workoutDays.id, workoutDays.dayOfWeek, workoutDays.name)
      .orderBy(asc(workoutDays.dayOfWeek));

    return c.json({
      plan,
      days: daysList.map((d) => ({
        id: d.id,
        dayOfWeek: d.dayOfWeek,
        name: d.name,
        exerciseCount: Number(d.exerciseCount),
      })),
    });
  } catch (err: any) {
    return c.json({ error: err.message }, 500);
  }
});

export default workoutRoutes;
